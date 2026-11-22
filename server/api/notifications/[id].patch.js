import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const notificationId = Number(getRouterParam(event, 'id'))

  if (!Number.isSafeInteger(notificationId) || notificationId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid notification ID.'
    })
  }

  const [result] = await db.query(
    `
      UPDATE in_app_notifications
      SET read_at = COALESCE(read_at, CURRENT_TIMESTAMP)
      WHERE id = ?
        AND user_id = ?
    `,
    [notificationId, user.id]
  )

  if (result.affectedRows === 0) {
    const [existingRows] = await db.query(
      `
        SELECT id
        FROM in_app_notifications
        WHERE id = ?
          AND user_id = ?
        LIMIT 1
      `,
      [notificationId, user.id]
    )

    if (existingRows.length === 0) {
      throw createError({
        statusCode: 404,
        statusMessage: 'Notification not found.'
      })
    }
  }

  return { success: true }
})
