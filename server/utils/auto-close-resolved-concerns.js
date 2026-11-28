import db from "./db.js";
import { notifyConcernParticipants } from "./notifications.js";

const AUTO_CLOSE_AFTER_DAYS = 7;
const AUTO_CLOSE_BATCH_SIZE = 100;

/** Close concerns that have remained resolved for seven days without a close action. */
export async function autoCloseResolvedConcerns() {
  const [eligibleConcerns] = await db.query(
    `
      SELECT id
      FROM concerns
      WHERE status = 'resolved'
        AND resolved_at IS NOT NULL
        AND resolved_at <= DATE_SUB(NOW(), INTERVAL ? DAY)
        AND deleted_at IS NULL
      ORDER BY resolved_at ASC
      LIMIT ${AUTO_CLOSE_BATCH_SIZE}
    `,
    [AUTO_CLOSE_AFTER_DAYS],
  );

  let closedCount = 0;

  for (const candidate of eligibleConcerns) {
    const connection = await db.getConnection();

    try {
      await connection.beginTransaction();

      const [concernRows] = await connection.query(
        `
          SELECT id, concern_number, resolved_at
          FROM concerns
          WHERE id = ?
            AND status = 'resolved'
            AND resolved_at IS NOT NULL
            AND resolved_at <= DATE_SUB(NOW(), INTERVAL ? DAY)
            AND deleted_at IS NULL
          LIMIT 1
          FOR UPDATE
        `,
        [candidate.id, AUTO_CLOSE_AFTER_DAYS],
      );

      if (concernRows.length === 0) {
        await connection.rollback();
        continue;
      }

      const concern = concernRows[0];
      const [updateResult] = await connection.query(
        `
          UPDATE concerns
          SET status = 'closed',
              closed_at = NOW()
          WHERE id = ?
            AND status = 'resolved'
            AND resolved_at = ?
            AND resolved_at <= DATE_SUB(NOW(), INTERVAL ? DAY)
            AND deleted_at IS NULL
        `,
        [concern.id, concern.resolved_at, AUTO_CLOSE_AFTER_DAYS],
      );

      if (updateResult.affectedRows !== 1) {
        await connection.rollback();
        continue;
      }

      await connection.query(
        `
          INSERT INTO concern_status_history (
            concern_id,
            changed_by,
            old_status,
            new_status,
            remarks
          )
          VALUES (?, NULL, 'resolved', 'closed', ?)
        `,
        [
          concern.id,
          `Automatically closed after remaining resolved for ${AUTO_CLOSE_AFTER_DAYS} days without being closed by the requesting organization.`,
        ],
      );

      await notifyConcernParticipants(connection, {
        concernId: concern.id,
        actorUserId: null,
        eventType: "concern_auto_closed",
        title: "Concern automatically closed",
        message: `${concern.concern_number} was automatically closed after remaining resolved for ${AUTO_CLOSE_AFTER_DAYS} days.`,
      });

      await connection.commit();
      closedCount += 1;
    } catch (error) {
      try {
        await connection.rollback();
      } catch (rollbackError) {
        console.error("Automatic concern close rollback failed:", rollbackError);
      }

      console.error(
        `Failed to automatically close resolved concern ${candidate.id}:`,
        error,
      );
    } finally {
      connection.release();
    }
  }

  return closedCount;
}
