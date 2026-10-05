import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const [statusRows] = await db.query(`
    SELECT
      status,
      COUNT(*) AS total
    FROM concerns
    GROUP BY status
    ORDER BY status
  `)

  const [priorityRows] = await db.query(`
    SELECT
      priority,
      COUNT(*) AS total
    FROM concerns
    GROUP BY priority
    ORDER BY priority
  `)

  const [organizationRows] = await db.query(`
    SELECT
      o.id,
      o.name,
      COUNT(c.id) AS total_concerns
    FROM organizations o
    LEFT JOIN concerns c
      ON c.assigned_organization_id = o.id
    GROUP BY o.id, o.name
    ORDER BY total_concerns DESC
  `)

  const [recentRows] = await db.query(`
    SELECT
      c.id,
      c.concern_number,
      c.title,
      c.status,
      c.priority,
      c.created_at,
      CONCAT(
        u.first_name,
        ' ',
        u.last_name
      ) AS created_by_name,
      o.name AS organization_name
    FROM concerns c
    INNER JOIN users u
      ON u.id = c.created_by
    LEFT JOIN organizations o
      ON o.id = c.assigned_organization_id
    ORDER BY c.created_at DESC
    LIMIT 10
  `)

  const [totalRows] = await db.query(`
    SELECT COUNT(*) AS total
    FROM concerns
  `)

  return {
    success: true,

    summary: {
      total: Number(totalRows[0].total)
    },

    status: statusRows.map(row => ({
      status: row.status,
      total: Number(row.total)
    })),

    priority: priorityRows.map(row => ({
      priority: row.priority,
      total: Number(row.total)
    })),

    organizations: organizationRows.map(row => ({
      id: row.id,
      name: row.name,
      total_concerns: Number(row.total_concerns)
    })),

    recentConcerns: recentRows
  }
})