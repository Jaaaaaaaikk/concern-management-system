import db from '../../utils/db.js'
import { hashPassword, verifyPassword } from '../../utils/auth.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event)

  if (!['concern_handler', 'system_monitor', 'requestor'].includes(currentUser.role_name)) {
    throw createError({
      statusCode: 403,
      statusMessage: 'Password changes are not available for this role. Please use Manage Users.'
    })
  }

  const body = await readBody(event)
  const currentPassword = body?.current_password
  const newPassword = body?.new_password

  if (typeof currentPassword !== 'string' || typeof newPassword !== 'string') {
    throw createError({
      statusCode: 400,
      statusMessage: 'Current password and new password are required.'
    })
  }

  if (newPassword.length < 8) {
    throw createError({
      statusCode: 400,
      statusMessage: 'New password must be at least 8 characters long.'
    })
  }

  if (newPassword.length > 72) {
    throw createError({
      statusCode: 400,
      statusMessage: 'New password must not exceed 72 characters.'
    })
  }

  const [users] = await db.query(
    `SELECT password_hash FROM users WHERE id = ? AND deleted_at IS NULL LIMIT 1`,
    [currentUser.id]
  )

  if (users.length === 0 || !(await verifyPassword(currentPassword, users[0].password_hash))) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Current password is incorrect.'
    })
  }

  if (await verifyPassword(newPassword, users[0].password_hash)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Choose a new password different from your current password.'
    })
  }

  const passwordHash = await hashPassword(newPassword)

  await db.query(
    `UPDATE users SET password_hash = ?, updated_by = ? WHERE id = ? AND deleted_at IS NULL`,
    [passwordHash, currentUser.id, currentUser.id]
  )

  return {
    success: true,
    message: 'Password changed successfully.'
  }
})
