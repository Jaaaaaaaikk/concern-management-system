import db from './db.js'

const BATCH_SIZE = 1000
const MAX_BATCHES_PER_RUN = 10

/** Permanently remove inactive session rows older than the six-month retention period. */
export async function purgeExpiredSessions() {
  let deletedCount = 0

  for (let batch = 0; batch < MAX_BATCHES_PER_RUN; batch += 1) {
    const [result] = await db.query(
      `
        DELETE FROM user_sessions
        WHERE created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)
          AND (
            revoked_at IS NOT NULL
            OR expires_at <= NOW()
          )
        ORDER BY created_at ASC
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
