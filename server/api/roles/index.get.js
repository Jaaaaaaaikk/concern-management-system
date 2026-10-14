import db from '../../utils/db.js'
import { requireRole, SYSTEM_MANAGEMENT_ROLES } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireRole(event, SYSTEM_MANAGEMENT_ROLES)

  const [rows] = await db.query(`
    SELECT
      id,
      name
    FROM roles
    ORDER BY id ASC
  `)

  if (currentUser.role_name === 'system_monitor') {
    return {
      success: true,
      roles: []
    }
  }

  const roles = currentUser.role_name === 'system_admin'
    ? rows.filter((role) => ['concern_handler', 'requestor'].includes(role.name))
    : rows

  return {
    success: true,
    roles
  }
})