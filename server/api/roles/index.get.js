import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const [rows] = await db.query(`
    SELECT
      id,
      name
    FROM roles
    ORDER BY id ASC
  `)

  return {
    success: true,
    roles: rows
  }
})