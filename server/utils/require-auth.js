import { getSessionUser } from './session.js'

export const SYSTEM_MANAGEMENT_ROLES = ['superadmin', 'system_admin']
export const GLOBAL_CONCERN_ROLES = ['superadmin', 'system_admin', 'system_monitor']

export function canManageSystem(user) {
  return SYSTEM_MANAGEMENT_ROLES.includes(user?.role_name)
}

export function canViewAllConcerns(user) {
  return GLOBAL_CONCERN_ROLES.includes(user?.role_name)
}

export async function requireAuth(event) {
  const user = await getSessionUser(event)

  if (!user) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Not authenticated.'
    })
  }

  return user
}

export async function requireRole(event, allowedRoles) {
  const user = await requireAuth(event)

  if (!allowedRoles.includes(user.role_name)) {
    throw createError({
      statusCode: 403,
      statusMessage: 'You do not have permission to access this resource.'
    })
  }

  return user
}