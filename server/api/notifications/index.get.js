import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)

  const [[countRow], [rows]] = await Promise.all([
    db.query(
      `
        SELECT COUNT(*) AS unread_count
        FROM in_app_notifications
        WHERE user_id = ?
          AND read_at IS NULL
      `,
      [user.id]
    ),
    db.query(
      `
        SELECT
          notification.id,
          notification.event_type,
          notification.concern_id,
          notification.title,
          notification.message,
          notification.created_at,
          notification.read_at,
          concern.concern_number
        FROM in_app_notifications notification
        LEFT JOIN concerns concern
          ON concern.id = notification.concern_id
        WHERE notification.user_id = ?
        ORDER BY notification.created_at DESC, notification.id DESC
        LIMIT 30
      `,
      [user.id]
    )
  ])

  return {
    success: true,
    unreadCount: Number(countRow?.unread_count || 0),
    notifications: rows.map((notification) => ({
      ...notification,
      href: notification.concern_id
        ? `/concerns?openConcern=${notification.concern_id}`
        : null
    }))
  }
})
