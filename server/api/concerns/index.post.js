import db from "../../utils/db.js";

import { requireRole } from "../../utils/require-auth.js";

import fs from "fs/promises";

import path from "path";

import crypto from "crypto";

export default defineEventHandler(async (event) => {
  const currentUser = await requireRole(event, ["admin", "user"]);

  /*
   * Read multipart form data.
   */

  const parts = await readMultipartFormData(event);

  if (!parts) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid form data.",
    });
  }

  /*
   * Convert multipart fields into an object.
   *
   * Multiple uploaded images use the same field name:
   * "image"
   */

  const fields = {};
  const imageFiles = [];

  for (const part of parts) {
    if (part.name === "image" && part.filename) {
      imageFiles.push(part);
    } else if (part.name) {
      fields[part.name] = part.data?.toString() || "";
    }
  }

  const title = fields.title?.trim();

  const description = fields.description?.trim();

  const concernTypeId = fields.concern_type_id;

  const assignedOrganizationId = fields.assigned_organization_id;

  const priority = fields.priority || "medium";

  /*
   * Validate title.
   */

  if (!title) {
    throw createError({
      statusCode: 400,
      statusMessage: "Concern title is required.",
    });
  }

  /*
   * Validate description.
   */

  if (!description) {
    throw createError({
      statusCode: 400,
      statusMessage: "Concern description is required.",
    });
  }

  /*
   * Validate concern type.
   */

  if (!concernTypeId || Number.isNaN(Number(concernTypeId))) {
    throw createError({
      statusCode: 400,
      statusMessage: "Concern type is required.",
    });
  }

  /*
   * Validate priority.
   */

  const validPriorities = ["low", "medium", "high", "urgent"];

  if (!validPriorities.includes(priority)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid priority.",
    });
  }

  /*
   * Validate assigned organization.
   */

  if (!assignedOrganizationId || Number.isNaN(Number(assignedOrganizationId))) {
    throw createError({
      statusCode: 400,
      statusMessage: "Assigned organization is required.",
    });
  }

  /*
   * Validate uploaded images.
   *
   * Images are optional.
   *
   * Maximum:
   * 5 MB per image.
   */

  const validImageTypes = [
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
  ];

  const maxImageSize = 5 * 1024 * 1024;

  for (const imageFile of imageFiles) {
    if (!validImageTypes.includes(imageFile.type)) {
      throw createError({
        statusCode: 400,
        statusMessage:
          "Invalid image format. Please upload JPG, PNG, GIF, or WEBP.",
      });
    }

    if (imageFile.data.length > maxImageSize) {
      throw createError({
        statusCode: 400,
        statusMessage: "Each image must not exceed 5 MB.",
      });
    }
  }

  /*
   * Verify concern type exists and is active.
   */

  const [concernTypeRows] = await db.query(
    `
            SELECT
                id
            FROM concern_types
            WHERE id = ?
              AND status = 'active'
            LIMIT 1
            `,
    [Number(concernTypeId)],
  );

  if (concernTypeRows.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid or inactive concern type.",
    });
  }

  /*
   * Verify organization exists and is active.
   */

  const [organizationRows] = await db.query(
    `
            SELECT
                id
            FROM organizations
            WHERE id = ?
              AND status = 'active'
              AND deleted_at IS NULL
            LIMIT 1
            `,
    [Number(assignedOrganizationId)],
  );

  if (organizationRows.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid or inactive organization.",
    });
  }

  /*
 * Prevent admin from assigning a concern
 * to their own organization.
 */
  if (
    currentUser.role_name === "admin" &&
    Number(assignedOrganizationId) === Number(currentUser.organization_id)
  ) {
    throw createError({
      statusCode: 403,
      statusMessage: "You cannot assign a concern to your own organization.",
    });
  }

  /*
   * Generate concern number.
   *
   * Example:
   * CON-2026-00001
   */

  const currentYear = new Date().getFullYear();

  const [latestRows] = await db.query(
    `
            SELECT
                concern_number
            FROM concerns
            WHERE concern_number LIKE ?
            ORDER BY id DESC
            LIMIT 1
            `,
    [`CON-${currentYear}-%`],
  );

  let nextNumber = 1;

  if (latestRows.length > 0) {
    const latestNumber = latestRows[0].concern_number.split("-").pop();

    const parsedNumber = Number(latestNumber);

    if (!Number.isNaN(parsedNumber)) {
      nextNumber = parsedNumber + 1;
    }
  }

  const concernNumber = `CON-${currentYear}-${String(nextNumber).padStart(5, "0")}`;

  /*
   * Keep track of all saved files.
   *
   * If something fails later, every
   * already-created file will be removed.
   */

  const savedFilePaths = [];

  /*
   * Start database transaction.
   */

  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    /*
     * Create concern.
     */

    const [result] = await connection.query(
      `
                INSERT INTO concerns (
                    concern_number,
                    title,
                    description,
                    concern_type_id,
                    created_by,
                    assigned_organization_id,
                    status,
                    priority
                )
                VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
                `,
      [
        concernNumber,
        title,
        description,
        Number(concernTypeId),
        currentUser.id,
        Number(assignedOrganizationId),
        priority,
      ],
    );

    const concernId = result.insertId;

    /*
     * Create upload directory
     *
     * public/uploads/concerns
     */

    if (imageFiles.length > 0) {
      const uploadDirectory = path.join(
        process.cwd(),
        "public",
        "uploads",
        "concerns",
      );

      await fs.mkdir(uploadDirectory, {
        recursive: true,
      });

      /*
       * Determine extension based
       * on MIME type.
       */

      const extensionMap = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/gif": ".gif",
        "image/webp": ".webp",
      };

      /*
       * Save every uploaded image.
       */

      for (const imageFile of imageFiles) {
        const extension = extensionMap[imageFile.type] || ".jpg";

        /*
         * Generate unique filename.
         */

        const randomName = crypto.randomBytes(16).toString("hex");

        const fileName = `concern-${concernId}-${randomName}${extension}`;

        const savedFilePath = path.join(uploadDirectory, fileName);

        /*
         * Write image to disk.
         */

        await fs.writeFile(savedFilePath, imageFile.data);

        /*
         * Remember the physical file
         * for cleanup if needed.
         */

        savedFilePaths.push(savedFilePath);

        /*
         * Public path used by browser.
         */

        const filePath = `/uploads/concerns/${fileName}`;

        /*
         * Save attachment information.
         */

        await connection.query(
          `
                    INSERT INTO concern_attachments (
                        concern_id,
                        uploaded_by,
                        file_name,
                        file_path,
                        file_type,
                        file_size
                    )
                    VALUES (?, ?, ?, ?, ?, ?)
                    `,
          [
            concernId,
            currentUser.id,
            imageFile.filename || fileName,
            filePath,
            imageFile.type,
            imageFile.data.length,
          ],
        );
      }
    }

    /*
     * Everything succeeded.
     */

    await connection.commit();

    return {
      success: true,
      message: "Concern created successfully.",
      concernId,
      concernNumber,
    };
  } catch (error) {
    /*
     * Roll back database changes.
     */

    await connection.rollback();

    /*
     * Remove every image that was
     * already saved.
     */

    for (const savedFilePath of savedFilePaths) {
      try {
        await fs.unlink(savedFilePath);
      } catch (fileError) {
        console.error("Failed to remove uploaded image:", fileError);
      }
    }

    console.error("Concern creation error:", error);

    throw createError({
      statusCode: 500,
      statusMessage: "Failed to create concern.",
    });
  } finally {
    connection.release();
  }
});
