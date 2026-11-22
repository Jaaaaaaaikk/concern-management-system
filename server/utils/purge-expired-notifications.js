import db from './db.js'

const RETENTION_DAYS = 90
const BATCH_SIZE = 1000
const MAX_BATCHES_PER_RUN = 10

/** Permanently remove notifications that have been read for more than 90 days. */
export async function purgeExpiredNotifications() {
  let deletedCount = 0

  for (let batch = 0; batch < MAX_BATCHES_PER_RUN; batch += 1) {
    const [result] = await db.query(
      `
        DELETE FROM in_app_notifications
        WHERE read_at IS NOT NULL
          AND read_at < DATE_SUB(NOW(), INTERVAL ${RETENTION_DAYS} DAY)
        ORDER BY read_at ASC, id ASC
        LIMIT ${BATCH_SIZE}
      `
    )

    const batchDeleted = Number(result.affectedRows || 0)
    deletedCount += batchDeleted

    if (batchDeleted < BATCH_SIZE) {
      break
    }
  }

  return deletedCount
}
