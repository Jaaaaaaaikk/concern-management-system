import db from '../../../utils/db.js'
import { requireRole, SYSTEM_MANAGEMENT_ROLES } from '../../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireRole(event, SYSTEM_MANAGEMENT_ROLES)

  const userId = Number(getRouterParam(event, 'id'))

  if (!userId || userId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid user ID.'
    })
  }

  if (userId === currentUser.id) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'You cannot deactivate your own account.'
    })
  }

  const [targetRows] = await db.query(
    `SELECT r.name AS role_name FROM users u INNER JOIN roles r ON r.id = u.role_id WHERE u.id = ? AND u.deleted_at IS NULL LIMIT 1`,
    [userId]
  )

  if (targetRows.length === 0) {
    throw createError({ statusCode: 404, statusMessage: 'User not found.' })
  }

  if (
    currentUser.role_name === 'system_admin' &&
    ['superadmin', 'system_admin'].includes(targetRows[0].role_name)
  ) {
    throw createError({
      statusCode: 403,
      statusMessage: 'System Administrators cannot change Superadmin or System Administrator accounts.'
    })
  }

  const body = await readBody(event)

  const status = body?.status

  if (!['active', 'inactive'].includes(status)) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'Status must be active or inactive.'
    })
  }

  const [result] = await db.query(
    `
    UPDATE users
    SET status = ?, updated_by = ?
    WHERE id = ?
      AND deleted_at IS NULL
    `,
    [status, currentUser.id, userId]
  )

  if (result.affectedRows === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'User not found.'
    })
  }

  return {
    success: true,
    message:
      status === 'active'
        ? 'User activated successfully.'
        : 'User deactivated successfully.'
  }
})