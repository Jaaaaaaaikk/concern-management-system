import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'
import { hashPassword } from '../../utils/auth.js'

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

  /*
  |--------------------------------------------------------------------------
  | Get submitted values
  |--------------------------------------------------------------------------
  */

  const username = body?.username?.trim()

  const firstName = body?.first_name?.trim()
  const middleName = body?.middle_name?.trim() || null
  const lastName = body?.last_name?.trim()

  const roleId = Number(body?.role_id)

  const organizationId = body?.organization_id
    ? Number(body.organization_id)
    : null

  /*
   * Password is optional.
   *
   * If empty or not provided:
   * - existing password will remain unchanged
   *
   * If provided:
   * - it will be validated
   * - hashed
   * - saved to password_hash
   */
  const password =
    typeof body?.password === 'string'
      ? body.password.trim()
      : ''

  /*
  |--------------------------------------------------------------------------
  | Validate required fields
  |--------------------------------------------------------------------------
  */

  if (
    !username ||
    !firstName ||
    !lastName ||
    !roleId
  ) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'Username, first name, last name, and role are required.'
    })
  }

  /*
  |--------------------------------------------------------------------------
  | Validate username length
  |--------------------------------------------------------------------------
  */

  if (username.length < 3) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'Username must be at least 3 characters.'
    })
  }

  /*
  |--------------------------------------------------------------------------
  | Validate password only when changing it
  |--------------------------------------------------------------------------
  */

  if (password && password.length < 8) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'New password must be at least 8 characters.'
    })
  }

  /*
  |--------------------------------------------------------------------------
  | Prevent the currently logged-in superadmin
  | from changing their own role.
  |--------------------------------------------------------------------------
  */

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

  /*
  |--------------------------------------------------------------------------
  | Check if user exists
  |--------------------------------------------------------------------------
  */

  const [userRows] = await db.query(
    `
    SELECT
      id,
      username,
      password_hash
    FROM users
    WHERE id = ?
      AND deleted_at IS NULL
    LIMIT 1
    `,
    [userId]
  )

  if (userRows.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'User not found.'
    })
  }

  /*
  |--------------------------------------------------------------------------
  | Check username uniqueness
  |--------------------------------------------------------------------------
  */

  const [usernameRows] = await db.query(
    `
    SELECT id
    FROM users
    WHERE username = ?
      AND id != ?
      AND deleted_at IS NULL
    LIMIT 1
    `,
    [username, userId]
  )

  if (usernameRows.length > 0) {
    throw createError({
      statusCode: 409,
      statusMessage:
        'Username is already being used by another user.'
    })
  }

  /*
  |--------------------------------------------------------------------------
  | Check role
  |--------------------------------------------------------------------------
  */

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

  /*
  |--------------------------------------------------------------------------
  | Superadmin does not need an organization
  |--------------------------------------------------------------------------
  */

  let finalOrganizationId = organizationId

  if (role.name === 'superadmin') {
    finalOrganizationId = null
  }

  /*
  |--------------------------------------------------------------------------
  | Admin and User require an organization
  |--------------------------------------------------------------------------
  */

  if (
    (role.name === 'admin' || role.name === 'user') &&
    !finalOrganizationId
  ) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'An organization is required for admin and user accounts.'
    })
  }

  /*
  |--------------------------------------------------------------------------
  | Check organization
  |--------------------------------------------------------------------------
  */

  if (finalOrganizationId) {
    const [organizationRows] = await db.query(
      `
      SELECT id
      FROM organizations
      WHERE id = ?
        AND status = 'active'
        AND deleted_at IS NULL
      LIMIT 1
      `,
      [finalOrganizationId]
    )

    if (organizationRows.length === 0) {
      throw createError({
        statusCode: 400,
        statusMessage:
          'Invalid or inactive organization.'
      })
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Update user
  |--------------------------------------------------------------------------
  */

  let result

  if (password) {
    /*
     * New password was provided.
     *
     * Hash it before saving to MySQL.
     */
    const passwordHash = await hashPassword(password)

    const [updateResult] = await db.query(
      `
      UPDATE users
      SET
        username = ?,
        password_hash = ?,
        first_name = ?,
        middle_name = ?,
        last_name = ?,
        role_id = ?,
        organization_id = ?
      WHERE id = ?
        AND deleted_at IS NULL
      `,
      [
        username,
        passwordHash,
        firstName,
        middleName,
        lastName,
        roleId,
        finalOrganizationId,
        userId
      ]
    )

    result = updateResult
  } else {
    /*
     * No new password was provided.
     *
     * IMPORTANT:
     * password_hash is NOT included here.
     * Therefore the existing password remains unchanged.
     */
    const [updateResult] = await db.query(
      `
      UPDATE users
      SET
        username = ?,
        first_name = ?,
        middle_name = ?,
        last_name = ?,
        role_id = ?,
        organization_id = ?
      WHERE id = ?
        AND deleted_at IS NULL
      `,
      [
        username,
        firstName,
        middleName,
        lastName,
        roleId,
        finalOrganizationId,
        userId
      ]
    )

    result = updateResult
  }

  /*
  |--------------------------------------------------------------------------
  | Check update result
  |--------------------------------------------------------------------------
  */

  if (result.affectedRows === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'User not found.'
    })
  }

  return {
    success: true,
    message: password
      ? 'User and password updated successfully.'
      : 'User updated successfully.'
  }
})