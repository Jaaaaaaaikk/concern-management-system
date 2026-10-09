import { unlink } from "node:fs/promises";
import path from "node:path";
import db from "./db.js";

const EXPIRY_CONDITION =
  "AND deleted_at <= DATE_SUB(NOW(), INTERVAL 30 DAY)";

/**
 * Permanently delete a trashed concern and its uploaded files.
 * Set expiredOnly for scheduled cleanup so a concern restored in
 * the meantime is never removed.
 */
export async function permanentlyDeleteTrashedConcern(
  concernId,
  { expiredOnly = false } = {},
) {
  const connection = await db.getConnection();
  const expiryCondition = expiredOnly ? EXPIRY_CONDITION : "";
  let filePaths = [];

  try {
    await connection.beginTransaction();

    const [concernRows] = await connection.query(
      `
        SELECT id
        FROM concerns
        WHERE id = ?
          AND deleted_at IS NOT NULL
          ${expiryCondition}
        FOR UPDATE
      `,
      [concernId],
    );

    if (concernRows.length === 0) {
      await connection.rollback();
      return false;
    }

    const [attachmentRows] = await connection.query(
      "SELECT file_path FROM concern_attachments WHERE concern_id = ?",
      [concernId],
    );
    const [statusAttachmentRows] = await connection.query(
      "SELECT file_path FROM concern_status_attachments WHERE concern_id = ?",
      [concernId],
    );

    filePaths = [
      ...attachmentRows,
      ...statusAttachmentRows,
    ].map((row) => row.file_path).filter(Boolean);

    const [deleteResult] = await connection.query(
      `
        DELETE FROM concerns
        WHERE id = ?
          AND deleted_at IS NOT NULL
          ${expiryCondition}
      `,
      [concernId],
    );

    if (deleteResult.affectedRows !== 1) {
      await connection.rollback();
      return false;
    }

    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }

  const uploadDirectory = path.resolve(
    process.cwd(),
    "public",
    "uploads",
    "concerns",
  );

  for (const filePath of filePaths) {
    const fileName = path.basename(String(filePath));
    const safePath = path.resolve(uploadDirectory, fileName);

    if (path.dirname(safePath) !== uploadDirectory) {
      continue;
    }

    try {
      await unlink(safePath);
    } catch (error) {
      if (error?.code !== "ENOENT") {
        console.error("Failed to remove purged concern upload:", error);
      }
    }
  }

  return true;
}

/** Purge up to 100 concerns whose 30-day trash retention has expired. */
export async function purgeExpiredTrashedConcerns() {
  const [expiredConcerns] = await db.query(
    `
      SELECT id
      FROM concerns
      WHERE deleted_at IS NOT NULL
        AND deleted_at <= DATE_SUB(NOW(), INTERVAL 30 DAY)
      ORDER BY deleted_at ASC
      LIMIT 100
    `,
  );

  let deletedCount = 0;

  for (const concern of expiredConcerns) {
    try {
      const deleted = await permanentlyDeleteTrashedConcern(
        concern.id,
        { expiredOnly: true },
      );

      if (deleted) {
        deletedCount += 1;
      }
    } catch (error) {
      console.error(
        `Failed to automatically purge expired concern ${concern.id}:`,
        error,
      );
    }
  }

  return deletedCount;
}
