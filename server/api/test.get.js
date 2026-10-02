import { requireRole } from '../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const user = await requireRole(event, ['superadmin'])

  return {
    success: true,
    message: 'Superadmin access confirmed.',
    user: {
      id: user.id,
      username: user.username,
      role: user.role_name
    }
  }
})