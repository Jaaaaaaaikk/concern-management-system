import { destroySession, getSessionUser, isSessionRevoked } from '../../utils/session.js'

export default defineEventHandler(async (event) => {
  const user = await getSessionUser(event)

  if (!user) {
    const revoked = await isSessionRevoked(event)

    if (revoked) {
      await destroySession(event)
    }

    throw createError({
      statusCode: 401,
      statusMessage: revoked ? 'SESSION_REVOKED' : 'Not authenticated.'
    })
  }

  return {
    success: true,
    user
  }
})