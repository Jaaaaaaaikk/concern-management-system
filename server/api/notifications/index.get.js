import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const query = getQuery(event)
  const beforeIdValue = String(query.beforeId || '').trim()
  const beforeId = /^\d+$/.test(beforeIdValue) && BigInt(beforeIdValue) > 0n
    ? beforeIdValue
    : null
  const cursorCondition = beforeId
    ? 'AND notification.id < ?'
    : ''
  const notificationParams = beforeId
    ? [user.id, beforeId]
    : [user.id]

  const [[countRows], [rows]] = await Promise.all([
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
          ${cursorCondition}
        ORDER BY notification.created_at DESC, notification.id DESC
        LIMIT 31
      `,
      notificationParams
    )
  ])

  const hasMore = rows.length > 30
  const pageRows = hasMore ? rows.slice(0, 30) : rows
  const nextCursor = pageRows.length > 0
    ? String(pageRows[pageRows.length - 1].id)
    : null

  return {
    success: true,
    unreadCount: Number(countRows[0]?.unread_count || 0),
    hasMore,
    nextCursor,
    notifications: pageRows.map((notification) => ({
      ...notification,
      href: notification.concern_id
        ? `/concerns?openConcern=${notification.concern_id}`
        : null
    }))
  }
})
