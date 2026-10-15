
import db from "../../../utils/db.js";
import { requireAuth } from "../../../utils/require-auth.js";
import { unlink } from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { saveConcernUpload } from "../../../utils/concern-uploads.js";

export default defineEventHandler(async (event) => {
  /*
   * ---------------------------------------------------------
   * AUTHENTICATION
   * ---------------------------------------------------------
   */

  const currentUser = await requireAuth(event);
  const concernId = Number(getRouterParam(event, "id"));

  if (!concernId || Number.isNaN(concernId)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern ID.",
    });
  }

  /*
   * ---------------------------------------------------------
   * READ MULTIPART FORM DATA
   * ---------------------------------------------------------
   */

  const parts = await readMultipartFormData(event);

  if (!parts) {
    throw createError({
      statusCode: 400,
      statusMessage:
        "Invalid request. Please submit the status update as multipart form data.",
    });
  }

  let newStatus = "";
  let remarks = null;
  let targetCommitmentAt = null;

  const evidenceImages = [];

  for (const part of parts) {
    if (!part?.name) continue;

    if (part.name === "status") {
      newStatus = Buffer.isBuffer(part.data)
        ? part.data.toString("utf8").trim()
        : String(part.data || "").trim();

      continue;
    }

    if (part.name === "remarks") {
      const value = Buffer.isBuffer(part.data)
        ? part.data.toString("utf8").trim()
        : String(part.data || "").trim();

      remarks = value || null;
      continue;
    }

    if (part.name === "target_commitment_at") {
      const value = Buffer.isBuffer(part.data)
        ? part.data.toString("utf8").trim()
        : String(part.data || "").trim();

      targetCommitmentAt = value || null;
      continue;
    }

    if (part.name === "images" && part.filename) {
      evidenceImages.push(part);
    }
  }

  /*
   * ---------------------------------------------------------
   * VALID STATUS
   * ---------------------------------------------------------
   */

  const validStatuses = [
    "pending",
    "in_progress",
    "on_hold",
    "resolved",
    "closed",
    "cancelled",
  ];

  if (!validStatuses.includes(newStatus)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern status.",
    });
  }

  /*
   * ---------------------------------------------------------
   * GET CONCERN AND CREATOR ORGANIZATION
   * ---------------------------------------------------------
   */

  const [concernRows] = await db.query(
    `
      SELECT
        c.id,
        c.created_by,
        c.assigned_organization_id,
        c.status,
        c.deleted_at,
        c.target_commitment_at,
        c.resolved_at,
        c.closed_at,
        creator.organization_id AS creator_organization_id
      FROM concerns c
      INNER JOIN users creator
        ON creator.id = c.created_by
      WHERE c.id = ?
      LIMIT 1
    `,
    [concernId],
  );

  if (concernRows.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: "Concern not found.",
    });
  }

  const concern = concernRows[0];

  if (concern.deleted_at) {
    throw createError({
      statusCode: 403,
      statusMessage: "A trashed concern cannot be updated.",
    });
  }

  /*
   * ---------------------------------------------------------
   * USER ROLE AND ORGANIZATION
   * ---------------------------------------------------------
   */

  const userRole = currentUser.role_name;

  const userOrganizationId =
    currentUser.organization_id != null
      ? Number(currentUser.organization_id)
      : null;

  const creatorOrganizationId =
    concern.creator_organization_id != null
      ? Number(concern.creator_organization_id)
      : null;

  const assignedOrganizationId =
    concern.assigned_organization_id != null
      ? Number(concern.assigned_organization_id)
      : null;

  const isCreatorOrganizationAdmin =
    userRole === "concern_handler" &&
    userOrganizationId !== null &&
    creatorOrganizationId !== null &&
    userOrganizationId === creatorOrganizationId;

  const isAssignedOrganizationAdmin =
    userRole === "concern_handler" &&
    userOrganizationId !== null &&
    assignedOrganizationId !== null &&
    userOrganizationId === assignedOrganizationId;

  const isRecipientAdmin = isAssignedOrganizationAdmin;

  /*
   * ---------------------------------------------------------
   * CLOSED / CANCELLED CONCERNS
   * ---------------------------------------------------------
   */

  if (["closed", "cancelled"].includes(concern.status)) {
    throw createError({
      statusCode: 403,
      statusMessage:
        "This concern is already closed or cancelled and cannot be changed.",
    });
  }

  /*
   * ---------------------------------------------------------
   * SAME STATUS
   * ---------------------------------------------------------
   */

  if (concern.status === newStatus) {
    return {
      success: true,
      message: "Concern status is already set to this status.",
      status: concern.status,
    };
  }

  /*
   * ---------------------------------------------------------
   * VALID STATUS TRANSITIONS
   * ---------------------------------------------------------
   *
   * Recipient admin:
   * pending     -> in_progress / on_hold
   * in_progress -> resolved
   * on_hold     -> in_progress
   *
  * Creator-organization admin:
  * resolved    -> in_progress / closed
   *
   * ---------------------------------------------------------
   */

  const allowedTransitions = {
    pending: ["in_progress", "on_hold"],
    in_progress: ["resolved"],
    on_hold: ["in_progress"],
    resolved: ["in_progress", "closed"],
    closed: [],
    cancelled: [],
  };

  const allowedNextStatuses =
    allowedTransitions[concern.status] || [];

  if (!allowedNextStatuses.includes(newStatus)) {
    throw createError({
      statusCode: 400,
      statusMessage:
        `Cannot change concern status from "${concern.status}" to "${newStatus}".`,
    });
  }

  /*
   * ---------------------------------------------------------
   * AUTHORIZATION
   * ---------------------------------------------------------
   */

  if (newStatus === "closed") {
    if (!isCreatorOrganizationAdmin) {
      throw createError({
        statusCode: 403,
        statusMessage:
          "Only an admin in the concern creator's organization can close it.",
      });
    }

    if (concern.status !== "resolved") {
      throw createError({
        statusCode: 400,
        statusMessage: "Only a resolved concern can be closed.",
      });
    }
  } else if (
    isCreatorOrganizationAdmin &&
    concern.status === "resolved" &&
    newStatus === "in_progress"
  ) {
    // Creator handler rejects the reported resolution and returns it for rework.
  } else if (isRecipientAdmin) {
    const allowedForRecipientAdmin = {
      pending: ["in_progress", "on_hold"],
      in_progress: ["resolved"],
      on_hold: ["in_progress"],
    };

    const allowed =
      allowedForRecipientAdmin[concern.status] || [];

    if (!allowed.includes(newStatus)) {
      throw createError({
        statusCode: 403,
        statusMessage:
          "You cannot perform this status change.",
      });
    }
  } else {
    throw createError({
      statusCode: 403,
      statusMessage:
        "You do not have permission to change the status of this concern.",
    });
  }

  /*
   * ---------------------------------------------------------
  * RECIPIENT COMMITMENT START (target_commitment_at)
   * ---------------------------------------------------------
   *
  * Expected frontend value:
  * YYYY-MM-DD
   *
   * MySQL DATETIME value:
  * YYYY-MM-DD 00:00:00
   *
    * The recipient's committed start date cannot be before today.
   *
  * It is stored at local midnight because the chosen value
  * represents a calendar date, not a UTC instant.
   * ---------------------------------------------------------
   */

  const movingToInProgress =
    isRecipientAdmin &&
    newStatus === "in_progress" &&
    concern.status !== "in_progress";

  let historyRemarks = remarks;

  if (movingToInProgress) {
    if (!targetCommitmentAt) {
      throw createError({
        statusCode: 400,
        statusMessage:
          "A committed start date is required before moving the concern to In Progress.",
      });
    }
  }

  if (movingToInProgress || targetCommitmentAt) {
    const normalizedDate = String(targetCommitmentAt)
      .trim()
      .replace("T", " ");

    // Accept legacy date-time values during migration, but persist date-only values at midnight.
    const match = normalizedDate.match(
      /^(\d{4})-(\d{2})-(\d{2})(?: (\d{2}):(\d{2})(?::(\d{2}))?)?$/,
    );

    if (!match) {
      throw createError({
        statusCode: 400,
        statusMessage:
          "Enter a valid commitment date.",
      });
    }

    const [, yearText, monthText, dayText, hourText = "00", minuteText = "00", secondText = "00"] = match;

    const year = Number(yearText);
    const month = Number(monthText);
    const day = Number(dayText);
    const hour = Number(hourText);
    const minute = Number(minuteText);
    const second = Number(secondText);

    const parsedDate = new Date(
      year,
      month - 1,
      day,
      0,
      0,
      0,
      0,
    );

    const isValidDate =
      parsedDate.getFullYear() === year &&
      parsedDate.getMonth() === month - 1 &&
      parsedDate.getDate() === day &&
      hour >= 0 && hour <= 23 &&
      minute >= 0 && minute <= 59 &&
      second >= 0 && second <= 59;

    if (!isValidDate) {
      throw createError({
        statusCode: 400,
        statusMessage:
          "The commitment date is invalid.",
      });
    }

    const now = new Date();

    const today =
      `${now.getFullYear()}-` +
      `${String(now.getMonth() + 1).padStart(2, "0")}-` +
      `${String(now.getDate()).padStart(2, "0")}`;

    const selectedDate =
      `${yearText}-${monthText}-${dayText}`;

    if (selectedDate < today) {
      throw createError({
        statusCode: 400,
        statusMessage:
          "The commitment date cannot be before today.",
      });
    }

    targetCommitmentAt = `${yearText}-${monthText}-${dayText} 00:00:00`;

    if (movingToInProgress) {
      historyRemarks = [
        remarks,
        `Commitment start: ${yearText}-${monthText}-${dayText}`,
      ]
        .filter(Boolean)
        .join("\n");
    }
  }

  /*
   * ---------------------------------------------------------
   * REMARKS REQUIREMENTS
   * ---------------------------------------------------------
   */

  const requiresRemarks =
    (
      isRecipientAdmin &&
      (
        newStatus === "in_progress" ||
        newStatus === "on_hold" ||
        (
          concern.status === "in_progress" &&
          newStatus === "resolved"
        )
      )
    ) ||
    (
      isCreatorOrganizationAdmin &&
      concern.status === "resolved" &&
      newStatus === "in_progress"
    );

  if (requiresRemarks && !remarks) {
    throw createError({
      statusCode: 400,
      statusMessage:
        newStatus === "on_hold"
          ? "Please explain why the concern is being placed on hold."
          : newStatus === "resolved"
            ? "Resolution remarks are required before marking the concern as resolved."
            : isCreatorOrganizationAdmin && newStatus === "in_progress"
              ? "Please explain why the reported resolution is being rejected and what work remains."
              : "Please enter remarks for this status change.",
    });
  }

  /*
   * ---------------------------------------------------------
   * RESOLUTION REQUIREMENTS
   * ---------------------------------------------------------
   */

  const resolvingConcern =
    isRecipientAdmin &&
    concern.status === "in_progress" &&
    newStatus === "resolved";

  if (newStatus === "resolved") {
    if (!resolvingConcern) {
      throw createError({
        statusCode: 403,
        statusMessage:
          "Only an admin in the assigned organization can resolve this concern.",
      });
    }

    if (!remarks) {
      throw createError({
        statusCode: 400,
        statusMessage:
          "Resolution remarks are required before marking the concern as resolved.",
      });
    }

    if (evidenceImages.length === 0) {
      throw createError({
        statusCode: 400,
        statusMessage:
          "At least one resolution evidence image is required before marking the concern as resolved.",
      });
    }
  }

  /*
   * ---------------------------------------------------------
   * ON-HOLD REQUIREMENTS
   * ---------------------------------------------------------
   */

  if (newStatus === "on_hold" && !isRecipientAdmin) {
    throw createError({
      statusCode: 403,
      statusMessage:
        "Only an admin in the assigned organization can put this concern on hold.",
    });
  }

  /*
   * ---------------------------------------------------------
   * EVIDENCE IMAGE VALIDATION
   * ---------------------------------------------------------
   */

  const allowedImageTypes = [
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
  ];

  const maxFileSize = 5 * 1024 * 1024;

  for (const image of evidenceImages) {
    if (!allowedImageTypes.includes(image.type)) {
      throw createError({
        statusCode: 400,
        statusMessage:
          `${image.filename || "Evidence image"} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`,
      });
    }

    if (!image.data || image.data.length === 0) {
      throw createError({
        statusCode: 400,
        statusMessage:
          `${image.filename || "Evidence image"} is empty.`,
      });
    }

    if (image.data.length > maxFileSize) {
      throw createError({
        statusCode: 400,
        statusMessage:
          `${image.filename || "Evidence image"} exceeds the 5 MB limit.`,
      });
    }
  }

  /*
   * ---------------------------------------------------------
   * TRANSACTION
   * ---------------------------------------------------------
   */

  const connection = await db.getConnection();
  const savedFilePaths = [];

  try {
    await connection.beginTransaction();

    /*
     * Lock the concern so concurrent updates cannot
     * silently overwrite each other.
     */

    const [lockedRows] = await connection.query(
      `
        SELECT id, status, deleted_at
        FROM concerns
        WHERE id = ?
        LIMIT 1
        FOR UPDATE
      `,
      [concernId],
    );

    if (lockedRows.length === 0) {
      throw createError({
        statusCode: 404,
        statusMessage: "Concern not found.",
      });
    }

    const lockedConcern = lockedRows[0];

    if (lockedConcern.deleted_at) {
      throw createError({
        statusCode: 403,
        statusMessage: "A trashed concern cannot be updated.",
      });
    }

    if (lockedConcern.status !== concern.status) {
      throw createError({
        statusCode: 409,
        statusMessage:
          "The concern status changed before this update could be saved. Please refresh and try again.",
      });
    }

    /*
     * -----------------------------------------------------
     * UPDATE CONCERN
     * -----------------------------------------------------
     */

    const [updateResult] = await connection.query(
      `
        UPDATE concerns
        SET
          status = ?,

          target_commitment_at = CASE
            WHEN ? = 1
            THEN ?
            ELSE target_commitment_at
          END,

          resolved_at = CASE
            WHEN ? = 'in_progress'
            THEN NULL
            WHEN ? = 'resolved'
            THEN NOW()
            ELSE resolved_at
          END,

          closed_at = CASE
            WHEN ? = 'closed'
            THEN NOW()
            ELSE closed_at
          END

        WHERE id = ?
          AND status = ?
          AND deleted_at IS NULL
      `,
      [
        newStatus,
        movingToInProgress ? 1 : 0,
        movingToInProgress ? targetCommitmentAt : null,
        newStatus,
        newStatus,
        newStatus,
        concernId,
        concern.status,
      ],
    );

    if (updateResult.affectedRows !== 1) {
      throw createError({
        statusCode: 409,
        statusMessage:
          "The concern status could not be updated because the current database status no longer matches the requested transition.",
      });
    }

    /*
     * -----------------------------------------------------
     * STATUS HISTORY
     * -----------------------------------------------------
     */

    const [historyResult] = await connection.query(
      `
        INSERT INTO concern_status_history (
          concern_id,
          changed_by,
          old_status,
          new_status,
          remarks
        )
        VALUES (?, ?, ?, ?, ?)
      `,
      [
        concernId,
        currentUser.id,
        concern.status,
        newStatus,
        historyRemarks,
      ],
    );

    const statusHistoryId = historyResult.insertId;

    /*
     * -----------------------------------------------------
     * SAVE RESOLUTION EVIDENCE
     * -----------------------------------------------------
     */

    if (resolvingConcern && evidenceImages.length > 0) {
      for (const image of evidenceImages) {
        const originalName = image.filename || "evidence";

        const extension =
          path.extname(originalName).toLowerCase() ||
          (
            image.type === "image/jpeg"
              ? ".jpg"
              : image.type === "image/png"
                ? ".png"
                : image.type === "image/gif"
                  ? ".gif"
                  : ".webp"
          );

        const randomPart =
          crypto.randomBytes(16).toString("hex");

        const fileName =
          `status-${concernId}-${randomPart}${extension}`;

        const fileSystemPath = await saveConcernUpload(fileName, image.data);

        const databaseFilePath = `/uploads/concerns/${fileName}`;

        savedFilePaths.push(fileSystemPath);

        await connection.query(
          `
            INSERT INTO concern_status_attachments (
              status_history_id,
              concern_id,
              uploaded_by,
              file_name,
              file_path,
              file_type,
              file_size
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
          `,
          [
            statusHistoryId,
            concernId,
            currentUser.id,
            originalName,
            databaseFilePath,
            image.type,
            image.data.length,
          ],
        );
      }
    }

    /*
     * -----------------------------------------------------
     * COMMIT
     * -----------------------------------------------------
     */

    await connection.commit();

    return {
      success: true,
      status: newStatus,
      message:
        newStatus === "resolved"
          ? "Concern resolved successfully with evidence."
          : newStatus === "closed"
            ? "Concern closed successfully."
            : "Concern status updated successfully.",
    };
  } catch (error) {
    try {
      await connection.rollback();
    } catch (rollbackError) {
      console.error(
        "Concern status rollback error:",
        rollbackError,
      );
    }

    for (const filePath of savedFilePaths) {
      try {
        await unlink(filePath);
      } catch (cleanupError) {
        console.error(
          "Failed to remove uploaded status evidence:",
          cleanupError,
        );
      }
    }

    if (error?.statusCode) {
      throw error;
    }

    console.error("Concern status update error:", error);

    throw createError({
      statusCode: 500,
      statusMessage: "Failed to update concern status.",
    });
  } finally {
    connection.release();
  }
});
