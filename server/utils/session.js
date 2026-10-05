import crypto from 'crypto'
import db from './db.js'

const SESSION_COOKIE_NAME = 'cms_session'
const SESSION_DURATION_HOURS = 8

function generateSessionToken() {
  return crypto.randomBytes(32).toString('hex')
}

function hashSessionToken(token) {
  return crypto
    .createHash('sha256')
    .update(token)
    .digest('hex')
}

export async function createSession(userId, event) {
  const token = generateSessionToken()
  const tokenHash = hashSessionToken(token)

  const expiresAt = new Date(
    Date.now() + SESSION_DURATION_HOURS * 60 * 60 * 1000
  )

  await db.query(
    `
    INSERT INTO user_sessions (
      user_id,
      session_token_hash,
      expires_at
    )
    VALUES (?, ?, ?)
    `,
    [userId, tokenHash, expiresAt]
  )

  setCookie(event, SESSION_COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    expires: expiresAt
  })

  return {
    expiresAt
  }
}

export async function getSessionUser(event) {
  const token = getCookie(event, SESSION_COOKIE_NAME)

  if (!token) {
    return null
  }

  const tokenHash = hashSessionToken(token)

  const [rows] = await db.query(
    `
    SELECT
      u.id,
      u.username,
      u.first_name,
      u.middle_name,
      u.last_name,
      u.profile_photo,
      u.status,
      r.id AS role_id,
      r.name AS role_name,
      o.id AS organization_id,
      o.name AS organization_name
    FROM user_sessions s
    INNER JOIN users u
      ON u.id = s.user_id
    INNER JOIN roles r
      ON r.id = u.role_id
    LEFT JOIN organizations o
      ON o.id = u.organization_id
    WHERE s.session_token_hash = ?
      AND s.revoked_at IS NULL
      AND s.expires_at > NOW()
      AND u.status = 'active'
    LIMIT 1
    `,
    [tokenHash]
  )

  if (rows.length === 0) {
    return null
  }

  return rows[0]
}

export async function destroySession(event) {
  const token = getCookie(event, SESSION_COOKIE_NAME)

  if (token) {
    const tokenHash = hashSessionToken(token)

    await db.query(
      `
      UPDATE user_sessions
      SET revoked_at = NOW()
      WHERE session_token_hash = ?
      `,
      [tokenHash]
    )
  }

  deleteCookie(event, SESSION_COOKIE_NAME, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/'
  })
}