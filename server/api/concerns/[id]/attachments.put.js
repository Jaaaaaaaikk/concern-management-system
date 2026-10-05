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

  const formData = await readMultipartFormData(event);

  if (!formData) {
    throw createError({
      statusCode: 400,
      statusMessage: "No file uploaded.",
    });
  }

  const attachmentIdField = formData.find(
    (item) => item.name === "attachment_id",
  );

  const imageFile = formData.find(
    (item) => item.name === "image" && item.filename && item.data,
  );

  const attachmentId = Number(attachmentIdField?.data?.toString());

  if (!attachmentId || Number.isNaN(attachmentId)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid attachment ID.",
    });
  }

  if (!imageFile) {
    throw createError({
      statusCode: 400,
      statusMessage: "Replacement image is required.",
    });
  }

  const allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"];

  if (!allowedTypes.includes(imageFile.type)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Only JPEG, PNG, GIF, and WEBP images are allowed.",
    });
  }

  const maxFileSize = 5 * 1024 * 1024;

  if (imageFile.data.length > maxFileSize) {
    throw createError({
      statusCode: 400,
      statusMessage: "Image size must not exceed 5MB.",
    });
  }

  // Check concern
  const [concerns] = await db.query(
    `
    SELECT
        id,
        created_by,
        status
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

  if (
    concern.status === "resolved" ||
    concern.status === "closed"
  ) {
    throw createError({
      statusCode: 403,
      statusMessage:
        "Attachments cannot be replaced because this concern is already completed.",
    });
  }

  // Only the concern creator and superadmin can edit
  // the original concern attachments.
  const isSuperadmin = currentUser.role_name === "superadmin";
  const isCreator = Number(concern.created_by) === Number(currentUser.id);

  if (!isSuperadmin && !isCreator) {
    throw createError({
      statusCode: 403,
      statusMessage: "You are not allowed to edit this attachment.",
    });
  }

  // Make sure this is an original concern attachment,
  // not a comment attachment.
  const [attachments] = await db.query(
    `
        SELECT
            id,
            concern_id,
            file_name,
            file_path
        FROM concern_attachments
        WHERE id = ?
          AND concern_id = ?
          AND comment_id IS NULL
          AND deleted_at IS NULL
        LIMIT 1
        `,
    [attachmentId, concernId],
  );

  if (attachments.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: "Original attachment not found.",
    });
  }

  const oldAttachment = attachments[0];

  const extensionMap = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/gif": ".gif",
    "image/webp": ".webp",
  };

  const extension = extensionMap[imageFile.type];

  const randomName = `${Date.now()}-${Math.random()
    .toString(36)
    .substring(2, 10)}`;

  const newFileName = `concern-${concernId}-${randomName}${extension}`;

  const uploadDir = "public/uploads/concerns";

  const fs = await import("node:fs/promises");
  const path = await import("node:path");

  await fs.mkdir(uploadDir, { recursive: true });

  const newFilePath = path.join(uploadDir, newFileName);

  const publicFilePath = `/uploads/concerns/${newFileName}`;

  try {
    // Save the new file first.
    await fs.writeFile(newFilePath, imageFile.data);

    // Update the same attachment record.
    // edited_at is what makes the frontend show "Edited".
    await db.query(
      `
            UPDATE concern_attachments
            SET
                file_name = ?,
                file_path = ?,
                file_type = ?,
                file_size = ?,
                edited_at = NOW()
            WHERE id = ?
              AND concern_id = ?
              AND comment_id IS NULL
              AND deleted_at IS NULL
            `,
      [
        newFileName,
        publicFilePath,
        imageFile.type,
        imageFile.data.length,
        attachmentId,
        concernId,
      ],
    );

    // Delete the old physical file.
    if (oldAttachment.file_path) {
      const oldFilePath = path.join(
        process.cwd(),
        "public",
        oldAttachment.file_path.replace(/^\/uploads\//, "uploads/"),
      );

      try {
        await fs.unlink(oldFilePath);
      } catch {
        // Ignore if the old physical file
        // no longer exists.
      }
    }

    return {
      success: true,
      message: "Attachment replaced successfully.",
      attachment: {
        id: attachmentId,
        file_name: newFileName,
        file_path: publicFilePath,
        file_type: imageFile.type,
        file_size: imageFile.data.length,
      },
    };
  } catch (error) {
    // Remove the newly uploaded file if the database update fails.
    try {
      await fs.unlink(newFilePath);
    } catch {
      // Ignore cleanup errors.
    }

    throw createError({
      statusCode: 500,
      statusMessage: "Failed to replace attachment.",
    });
  }
});
