import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)

  const [result] = await db.query(
    `
      UPDATE in_app_notifications
      SET read_at = CURRENT_TIMESTAMP
      WHERE user_id = ?
        AND read_at IS NULL
    `,
    [user.id]
  )

  return {
    success: true,
    updatedCount: result.affectedRows
  }
})
