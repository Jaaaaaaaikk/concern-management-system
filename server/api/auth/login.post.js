import db from '../../utils/db.js'
import { verifyPassword } from '../../utils/auth.js'
import { createSession } from '../../utils/session.js'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  const username = body?.username?.trim()
  const password = body?.password

  if (!username || !password) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Username and password are required.'
    })
  }

  const [rows] = await db.query(
    `
    SELECT
      u.id,
      u.username,
      u.password_hash,
      u.first_name,
      u.middle_name,
      u.last_name,
      u.status,
      r.id AS role_id,
      r.name AS role_name,
      o.id AS organization_id,
      o.name AS organization_name
    FROM users u
    INNER JOIN roles r
      ON r.id = u.role_id
    LEFT JOIN organizations o
      ON o.id = u.organization_id
    WHERE u.username = ?
      AND u.deleted_at IS NULL
    LIMIT 1
    `,
    [username]
  )

  if (rows.length === 0) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid username or password.'
    })
  }

  const user = rows[0]

  if (user.status !== 'active') {
    throw createError({
      statusCode: 403,
      statusMessage: 'Your account is not active.'
    })
  }

  const passwordValid = await verifyPassword(
    password,
    user.password_hash
  )

  if (!passwordValid) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid username or password.'
    })
  }

  await db.query(
    `
    UPDATE users
    SET last_login_at = NOW()
    WHERE id = ?
    `,
    [user.id]
  )

  await createSession(user.id, event)

  return {
    success: true,
    message: 'Login successful.',
    user: {
      id: user.id,
      username: user.username,
      first_name: user.first_name,
      middle_name: user.middle_name,
      last_name: user.last_name,
      role_id: user.role_id,
      role_name: user.role_name,
      organization_id: user.organization_id,
      organization_name: user.organization_name
    }
  }
})