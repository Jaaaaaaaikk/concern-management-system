import db from "../../../utils/db.js";
import { requireAuth } from "../../../utils/require-auth.js";
import { readMultipartFormData } from "h3";

import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event);

  const concernId = Number(getRouterParam(event, "id"));

  if (!concernId || Number.isNaN(concernId)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern ID.",
    });
  }

  /*
   * Read multipart form data.
   *
   * This allows the comment to contain:
   * - text only
   * - images only
   * - text + multiple images
   */
  const formData = await readMultipartFormData(event);

  if (!formData) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid form data.",
    });
  }

  const commentField = formData.find((field) => field.name === "comment");

  const comment = commentField?.data?.toString()?.trim() || "";

  /*
   * Get concern.
   */
  const [concernRows] = await db.query(
    `
      SELECT
          id,
          created_by,
          assigned_organization_id,
          status
      FROM concerns
        WHERE id = ?
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

  if (
    concern.status === "resolved" ||
    concern.status === "closed"
  ) {
    throw createError({
      statusCode: 403,
      statusMessage:
        "Comments cannot be added because this concern is already completed.",
    });
  }

  /*
   * Check permission.
   *
   * Superadmin:
   * Can comment on any concern.
   *
   * Creator:
   * Can comment on their own concern.
   *
   * Assigned organization admin:
   * Can comment if the concern is assigned
   * to their organization.
   */
  const isSuperadmin = currentUser.role_name === "superadmin";

  const isCreator = Number(concern.created_by) === Number(currentUser.id);

  const isAssignedAdmin =
    currentUser.role_name === "admin" &&
    Number(concern.assigned_organization_id) ===
      Number(currentUser.organization_id);

  if (!isSuperadmin && !isCreator && !isAssignedAdmin) {
    throw createError({
      statusCode: 403,
      statusMessage: "You do not have permission to comment on this concern.",
    });
  }

  /*
   * Get uploaded image files.
   */
  const imageFiles = formData.filter(
    (field) => field.name === "attachments" && field.filename && field.data,
  );

  /*
   * Require either text or at least one image.
   *
   * This means:
   * - text only = allowed
   * - image only = allowed
   * - text + images = allowed
   * - empty comment with no images = rejected
   */
  if (!comment && imageFiles.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "Comment or attachment is required.",
    });
  }

  /*
   * Insert comment.
   */
  const [result] = await db.query(
    `
        INSERT INTO concern_comments (
            concern_id,
            user_id,
            comment
        )
        VALUES (?, ?, ?)
        `,
    [concernId, currentUser.id, comment],
  );

  const commentId = result.insertId;

  /*
   * Attachment upload directory.
   *
   * Files will be stored under:
   *
   * public/uploads/concerns/
   */
  const uploadDirectory = "public/uploads/concerns";

  /*
   * Make sure the directory exists.
   */
  await mkdir(uploadDirectory, {
    recursive: true,
  });

  const savedAttachments = [];

  /*
   * Allowed image types.
   */
  const allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"];

  /*
   * Maximum size per image:
   * 5 MB
   */
  const maxFileSize = 5 * 1024 * 1024;

  for (const file of imageFiles) {
    if (!allowedTypes.includes(file.type)) {
      throw createError({
        statusCode: 400,
        statusMessage: `Invalid image type: ${file.filename}`,
      });
    }

    if (file.data.length > maxFileSize) {
      throw createError({
        statusCode: 400,
        statusMessage: `Image is too large: ${file.filename}. Maximum size is 5 MB.`,
      });
    }

    const originalName = file.filename;

    const extension = originalName.includes(".")
      ? originalName.substring(originalName.lastIndexOf("."))
      : "";

    const uniqueName = `comment-${commentId}-${Date.now()}-${Math.random()
      .toString(16)
      .slice(2)}${extension}`;

    const filePath = `${uploadDirectory}/${uniqueName}`;

    await writeFile(filePath, file.data);

    const databasePath = `/uploads/concerns/${uniqueName}`;

    const [attachmentResult] = await db.query(
      `
            INSERT INTO concern_attachments (
                concern_id,
                comment_id,
                uploaded_by,
                file_name,
                file_path,
                file_type,
                file_size
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            `,
      [
        concernId,
        commentId,
        currentUser.id,
        originalName,
        databasePath,
        file.type,
        file.data.length,
      ],
    );

    savedAttachments.push({
      id: attachmentResult.insertId,
      file_name: originalName,
      file_path: databasePath,
      file_type: file.type,
      file_size: file.data.length,
    });
  }

  return {
    success: true,
    message: "Comment added successfully.",
    commentId,
    attachments: savedAttachments,
  };
});
