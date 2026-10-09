import fs from "node:fs/promises";
import path from "node:path";

import db from "../../../utils/db.js";
import { requireAuth } from "../../../utils/require-auth.js";

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event);

  const concernId = Number(getRouterParam(event, "id"));

  if (!concernId || Number.isNaN(concernId)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern ID.",
    });
  }

  const [concerns] = await db.query(
    `
    SELECT
        id,
        created_by,
        status,
        deleted_at
    FROM concerns
        WHERE id = ?
        LIMIT 1
        `,
    [concernId],
  );

  if (concerns.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: "Concern not found.",
    });
  }

  const concern = concerns[0];

  if (concern.deleted_at) {
    throw createError({
      statusCode: 403,
      statusMessage: "Attachments cannot be added to a trashed concern.",
    });
  }

  if (
    concern.status === "resolved" ||
    concern.status === "closed"
  ) {
    throw createError({
      statusCode: 403,
      statusMessage:
        "Attachments cannot be added because this concern is already completed.",
    });
  }

  const isSuperadmin = currentUser.role_name === "superadmin";

  const isCreator = Number(concern.created_by) === Number(currentUser.id);

  if (!isSuperadmin && !isCreator) {
    throw createError({
      statusCode: 403,
      statusMessage:
        "You do not have permission to add attachments to this concern.",
    });
  }

  const formData = await readMultipartFormData(event);

  if (!formData || formData.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "No images were provided.",
    });
  }

  const imageFiles = formData.filter(
    (item) => item.name === "images" && item.filename && item.data,
  );

  if (imageFiles.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "No valid images were provided.",
    });
  }

  const allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"];

  const maxFileSize = 5 * 1024 * 1024;

  for (const image of imageFiles) {
    if (!allowedTypes.includes(image.type)) {
      throw createError({
        statusCode: 400,
        statusMessage: `${image.filename}: Only JPG, PNG, GIF, and WEBP images are allowed.`,
      });
    }

    if (image.data.length > maxFileSize) {
      throw createError({
        statusCode: 400,
        statusMessage: `${image.filename}: Image size must not exceed 5 MB.`,
      });
    }
  }

  const uploadDirectory = path.join(
    process.cwd(),
    "public",
    "uploads",
    "concerns",
  );

  await fs.mkdir(uploadDirectory, {
    recursive: true,
  });

  const savedFiles = [];

  try {
    for (const image of imageFiles) {
      const extension =
        path.extname(image.filename || "").toLowerCase() ||
        (image.type === "image/jpeg"
          ? ".jpg"
          : image.type === "image/png"
            ? ".png"
            : image.type === "image/gif"
              ? ".gif"
              : ".webp");

      const randomPart = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;

      const fileName = `concern-${concernId}-${randomPart}${extension}`;

      const physicalPath = path.join(uploadDirectory, fileName);

      await fs.writeFile(physicalPath, image.data);

      savedFiles.push({
        fileName,
        physicalPath,
        fileType: image.type,
        fileSize: image.data.length,
      });
    }

    const connection = await db.getConnection();

    try {
      await connection.beginTransaction();

      for (const file of savedFiles) {
        await connection.query(
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
                    VALUES (?, NULL, ?, ?, ?, ?, ?)
                    `,
          [
            concernId,
            currentUser.id,
            file.fileName,
            `/uploads/concerns/${file.fileName}`,
            file.fileType,
            file.fileSize,
          ],
        );
      }

      await connection.commit();
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    for (const file of savedFiles) {
      try {
        await fs.unlink(file.physicalPath);
      } catch {
        // Ignore cleanup errors
      }
    }

    throw createError({
      statusCode: 500,
      statusMessage:
        error?.statusMessage || error?.message || "Failed to save attachments.",
    });
  }

  return {
    success: true,
    message:
      savedFiles.length === 1
        ? "Image added successfully."
        : `${savedFiles.length} images added successfully.`,
    attachments: savedFiles.map((file) => ({
      file_name: file.fileName,
      file_path: `/uploads/concerns/${file.fileName}`,
      file_type: file.fileType,
      file_size: file.fileSize,
    })),
  };
});
