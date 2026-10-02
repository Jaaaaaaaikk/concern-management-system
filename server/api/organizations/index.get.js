import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const [rows] = await db.query(`
    SELECT
      id,
      name,
      code,
      description,
      contact_email,
      contact_number,
      address,
      status,
      created_at
    FROM organizations
    WHERE deleted_at IS NULL
    ORDER BY name ASC
  `)

  return {
    success: true,
    organizations: rows
  }
})