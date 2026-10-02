import db from '../../../utils/db.js'
import { requireRole } from '../../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireRole(event, ['superadmin'])

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
    SET status = ?
    WHERE id = ?
      AND deleted_at IS NULL
    `,
    [status, userId]
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