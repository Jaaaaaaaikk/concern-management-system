import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireAuth(event)

  const [rows] = await db.query(`
    SELECT
      id,
      name,
      description,
      status,
      created_at
    FROM concern_types
    WHERE status = 'active'
    ORDER BY name ASC
  `)

  return {
    success: true,
    concernTypes: rows
  }
})