import db from '../../../utils/db.js'
import { requireRole } from '../../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const body = await readBody(event)
  const sessionId = Number(body?.session_id)

  if (!Number.isInteger(sessionId) || sessionId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid session ID.'
    })
  }

  const [sessionRows] = await db.query(
    `
      SELECT id, revoked_at, expires_at
      FROM user_sessions
      WHERE id = ?
      LIMIT 1
    `,
    [sessionId]
  )

  if (sessionRows.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'Session not found.'
    })
  }

  if (sessionRows[0].revoked_at) {
    throw createError({
      statusCode: 409,
      statusMessage: 'This session has already been revoked.'
    })
  }

  const [result] = await db.query(
    `
      UPDATE user_sessions
      SET revoked_at = NOW()
      WHERE id = ?
        AND revoked_at IS NULL
    `,
    [sessionId]
  )

  if (result.affectedRows !== 1) {
    throw createError({
      statusCode: 409,
      statusMessage: 'This session could not be revoked right now.'
    })
  }

  return {
    success: true,
    message: 'Session revoked successfully.'
  }
})
