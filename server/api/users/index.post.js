import db from '../../utils/db.js'
import { hashPassword } from '../../utils/auth.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const body = await readBody(event)

  const username = body?.username?.trim()
  const password = body?.password
  const firstName = body?.first_name?.trim()
  const middleName = body?.middle_name?.trim() || null
  const lastName = body?.last_name?.trim()
  const roleId = body?.role_id
  const organizationId = body?.organization_id || null

  if (
    !username ||
    !password ||
    !firstName ||
    !lastName ||
    !roleId
  ) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'Username, password, first name, last name, and role are required.'
    })
  }

  if (password.length < 8) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'Password must be at least 8 characters long.'
    })
  }

  try {
    // Check username
    const [existingUsername] = await db.query(
      `
      SELECT id
      FROM users
      WHERE username = ?
        AND deleted_at IS NULL
      LIMIT 1
      `,
      [username]
    )

    if (existingUsername.length > 0) {
      throw createError({
        statusCode: 409,
        statusMessage: 'Username already exists.'
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

    // Organization is required for admin and user accounts
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
          statusMessage: 'Invalid or inactive organization.'
        })
      }
    }

    const passwordHash = await hashPassword(password)

    const [result] = await db.query(
      `
      INSERT INTO users (
        username,
        password_hash,
        first_name,
        middle_name,
        last_name,
        role_id,
        organization_id,
        status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, 'active')
      `,
      [
        username,
        passwordHash,
        firstName,
        middleName,
        lastName,
        roleId,
        organizationId
      ]
    )

    return {
      success: true,
      message: 'User created successfully.',
      userId: result.insertId
    }
  } catch (error) {
    if (
      error?.statusCode &&
      error?.statusCode !== 500
    ) {
      throw error
    }

    if (error.code === 'ER_DUP_ENTRY') {
      throw createError({
        statusCode: 409,
        statusMessage: 'Username already exists.'
      })
    }

    console.error('User creation error:', error)

    throw createError({
      statusCode: 500,
      statusMessage: 'Failed to create user.'
    })
  }
})