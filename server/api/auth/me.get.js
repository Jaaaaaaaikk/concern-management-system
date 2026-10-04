import { getSessionUser } from '../../utils/session.js'

export default defineEventHandler(async (event) => {
  const user = await getSessionUser(event)

  if (!user) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Not authenticated.'
    })
  }

  return {
    success: true,
    user
  }
})