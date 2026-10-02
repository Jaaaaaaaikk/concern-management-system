import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const [rows] = await db.query(`
    SELECT
      u.id,
      u.username,
      u.first_name,
      u.middle_name,
      u.last_name,
      u.status,
      u.last_login_at,
      u.created_at,

      r.id AS role_id,
      r.name AS role_name,

      o.id AS organization_id,
      o.name AS organization_name

    FROM users u

    INNER JOIN roles r
      ON r.id = u.role_id

    LEFT JOIN organizations o
      ON o.id = u.organization_id

    WHERE u.deleted_at IS NULL

    ORDER BY u.created_at DESC
  `)

  return {
    success: true,
    users: rows
  }
})