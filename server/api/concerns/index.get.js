import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event)

  let query = `
    SELECT
      c.id,
      c.concern_number,
      c.title,
      c.description,
      c.concern_type_id,
      ct.name AS concern_type_name,
      c.created_by,
      CONCAT(
        u.first_name,
        ' ',
        u.last_name
      ) AS created_by_name,
      c.assigned_organization_id,
      o.name AS organization_name,
      c.status,
      c.priority,
      c.created_at,
      c.updated_at,
      c.resolved_at,
      c.closed_at
    FROM concerns c

    LEFT JOIN concern_types ct
      ON ct.id = c.concern_type_id

    INNER JOIN users u
      ON u.id = c.created_by

    LEFT JOIN organizations o
      ON o.id = c.assigned_organization_id
  `

  const params = []

  // Superadmin can see all concerns.
  // Admin sees concerns assigned to their organization.
  // User sees only concerns they created.
  if (currentUser.role_name === 'admin') {
    query += `
      WHERE c.assigned_organization_id = ?
    `

    params.push(currentUser.organization_id)
  } else if (currentUser.role_name === 'user') {
    query += `
      WHERE c.created_by = ?
    `

    params.push(currentUser.id)
  }

  query += `
    ORDER BY c.created_at DESC
  `

  const [rows] = await db.query(query, params)

  return {
    success: true,
    concerns: rows
  }
})