import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const query = getQuery(event)
  const page = Math.max(1, Number(query.page) || 1)
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 20))
  const offset = (page - 1) * limit

  const [countRows] = await db.query(
    `
    SELECT COUNT(*) AS total
    FROM user_sessions s
    INNER JOIN users u
      ON u.id = s.user_id
    WHERE u.deleted_at IS NULL
    `
  )

  const [rows] = await db.query(
    `
    SELECT
      s.id,
      s.user_id,
      s.created_at AS login_at,
      s.expires_at,
      s.revoked_at,
      u.username,
      u.first_name,
      u.middle_name,
      u.last_name,
      u.status AS account_status,
      r.name AS role_name,
      o.name AS organization_name,
      CASE
        WHEN s.revoked_at IS NOT NULL THEN 'revoked'
        WHEN s.expires_at > NOW() THEN 'active'
        ELSE 'expired'
      END AS session_status
    FROM user_sessions s
    INNER JOIN users u
      ON u.id = s.user_id
    INNER JOIN roles r
      ON r.id = u.role_id
    LEFT JOIN organizations o
      ON o.id = u.organization_id
    WHERE u.deleted_at IS NULL
    ORDER BY s.created_at DESC
    LIMIT ? OFFSET ?
    `,
    [limit, offset]
  )

  const total = Number(countRows[0]?.total || 0)
  const totalPages = Math.max(1, Math.ceil(total / limit))

  return {
    success: true,
    sessions: rows.map((row) => ({
      ...row,
      full_name: [row.first_name, row.middle_name, row.last_name]
        .filter(Boolean)
        .join(' ') || row.username
    })),
    pagination: {
      page,
      limit,
      total,
      totalPages,
      showingFrom: total === 0 ? 0 : offset + 1,
      showingTo: Math.min(offset + rows.length, total)
    }
  }
})
