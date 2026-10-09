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

  const body = await readBody(event);

  const attachmentId = Number(body?.attachment_id);

  if (!attachmentId || Number.isNaN(attachmentId)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid attachment ID.",
    });
  }

  // Check concern
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
      statusMessage: "Attachments cannot be changed on a trashed concern.",
    });
  }

  if (
    concern.status === "resolved" ||
    concern.status === "closed"
  ) {
    throw createError({
      statusCode: 403,
      statusMessage:
        "Attachments cannot be removed because this concern is already completed.",
    });
  }

  // Only the concern creator and superadmin
  // can remove original concern attachments.
  const isSuperadmin = currentUser.role_name === "superadmin";
  const isCreator = Number(concern.created_by) === Number(currentUser.id);

  if (!isSuperadmin && !isCreator) {
    throw createError({
      statusCode: 403,
      statusMessage: "You are not allowed to remove this attachment.",
    });
  }

  // Only find original concern attachments.
  const [attachments] = await db.query(
    `
        SELECT
            id,
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

  const attachment = attachments[0];

  // Soft delete in database.
  await db.query(
    `
        UPDATE concern_attachments
        SET deleted_at = NOW()
        WHERE id = ?
          AND concern_id = ?
          AND comment_id IS NULL
          AND deleted_at IS NULL
        `,
    [attachmentId, concernId],
  );

  // Remove the physical file.
  if (attachment.file_path) {
    const fs = await import("node:fs/promises");
    const path = await import("node:path");

    const oldFilePath = path.join(
      process.cwd(),
      "public",
      attachment.file_path.replace(/^\/uploads\//, "uploads/"),
    );

    try {
      await fs.unlink(oldFilePath);
    } catch {
      // Ignore if the physical file
      // no longer exists.
    }
  }

  return {
    success: true,
    message: "Attachment removed successfully.",
  };
});
