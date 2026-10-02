import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireRole(event, ['superadmin'])

  const userId = Number(getRouterParam(event, 'id'))

  if (!userId || userId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid user ID.'
    })
  }

  const body = await readBody(event)

  const firstName = body?.first_name?.trim()
  const middleName = body?.middle_name?.trim() || null
  const lastName = body?.last_name?.trim()
  const email = body?.email?.trim() || null
  const contactNumber = body?.contact_number?.trim() || null
  const roleId = body?.role_id
  const organizationId = body?.organization_id || null

  if (
    !firstName ||
    !lastName ||
    !roleId
  ) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'First name, last name, and role are required.'
    })
  }

  // Prevent the currently logged-in superadmin
  // from accidentally changing their own role.
  if (
    userId === currentUser.id &&
    Number(roleId) !== Number(currentUser.role_id)
  ) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'You cannot change your own role.'
    })
  }

  // Check role
  const [roleRows] = await db.query(
    `
    SELECT id, name
    FROM roles
    WHERE id = ?
    LIMIT 1
    `,
    [roleId]
  )

  if (roleRows.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid role.'
    })
  }

  const role = roleRows[0]

  // Admin and user require an organization
  if (
    (role.name === 'admin' || role.name === 'user') &&
    !organizationId
  ) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'An organization is required for admin and user accounts.'
    })
  }

  // Check organization
  if (organizationId) {
    const [organizationRows] = await db.query(
      `
      SELECT id
      FROM organizations
      WHERE id = ?
        AND status = 'active'
        AND deleted_at IS NULL
      LIMIT 1
      `,
      [organizationId]
    )

    if (organizationRows.length === 0) {
      throw createError({
        statusCode: 400,
        statusMessage:
          'Invalid or inactive organization.'
      })
    }
  }

  const [result] = await db.query(
    `
    UPDATE users
    SET
      first_name = ?,
      middle_name = ?,
      last_name = ?,
      email = ?,
      contact_number = ?,
      role_id = ?,
      organization_id = ?
    WHERE id = ?
      AND deleted_at IS NULL
    `,
    [
      firstName,
      middleName,
      lastName,
      email,
      contactNumber,
      roleId,
      organizationId,
      userId
    ]
  )

  if (result.affectedRows === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'User not found.'
    })
  }

  return {
    success: true,
    message: 'User updated successfully.'
  }
})