import db from '../../../utils/db.js'
import { requireRole } from '../../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const [rows] = await db.query(
    `
      SELECT
        id,
        deletion_mode,
        deleted_count,
        date_from,
        date_to,
        created_at
      FROM login_history_deletion_audit
      ORDER BY created_at DESC
      LIMIT 100
    `
  )

  return {
    success: true,
    deletions: rows
  }
})
