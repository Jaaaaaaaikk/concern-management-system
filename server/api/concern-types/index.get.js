import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event)
  const includeInactive = getQuery(event).includeInactive === 'true'

  if (includeInactive && currentUser.role_name !== 'superadmin') {
    throw createError({
      statusCode: 403,
      statusMessage: 'Only superadmins can manage concern categories.'
    })
  }

  const [rows] = await db.query(`
    SELECT
      id,
      name,
      description,
      status,
      created_at
    FROM concern_types
    WHERE (? = 1 OR status = 'active')
    ORDER BY name ASC
  `, [includeInactive ? 1 : 0])

  return {
    success: true,
    concernTypes: rows
  }
})