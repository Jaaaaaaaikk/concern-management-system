import { destroySession } from '../../utils/session.js'

export default defineEventHandler(async (event) => {
  await destroySession(event)

  return {
    success: true,
    message: 'Logout successful.'
  }
})