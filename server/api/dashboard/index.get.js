import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
    const currentUser = await requireAuth(event)

    const role = currentUser.role_name

    let concernWhere = ''
    const concernParams = []

    /*
     * Superadmin
     * Can see all concerns.
     */
    if (role === 'superadmin') {
        concernWhere = ''
    }

    /*
     * Admin
     * Can see concerns assigned to their organization.
     */
    else if (role === 'admin') {
        concernWhere = `
            WHERE c.assigned_organization_id = ?
        `

        concernParams.push(
            currentUser.organization_id
        )
    }

    /*
     * User
     * Can see only concerns created by themselves.
     */
    else if (role === 'user') {
        concernWhere = `
            WHERE c.created_by = ?
        `

        concernParams.push(
            currentUser.id
        )
    }

    /*
     * Status summary
     */
    const [statusRows] = await db.query(
        `
        SELECT
            c.status,
            COUNT(*) AS total
        FROM concerns c
        ${concernWhere}
        GROUP BY c.status
        ORDER BY c.status
        `,
        concernParams
    )

    /*
     * Priority summary
     */
    const [priorityRows] = await db.query(
        `
        SELECT
            c.priority,
            COUNT(*) AS total
        FROM concerns c
        ${concernWhere}
        GROUP BY c.priority
        ORDER BY c.priority
        `,
        concernParams
    )

    /*
     * Organization summary
     *
     * Superadmin:
     * Shows all organizations.
     *
     * Admin:
     * Shows their own organization.
     *
     * User:
     * Shows organizations related to their concerns.
     */
    let organizationQuery = ''
    let organizationParams = []

    if (role === 'superadmin') {
        organizationQuery = `
            SELECT
                o.id,
                o.name,
                COUNT(c.id) AS total_concerns
            FROM organizations o
            LEFT JOIN concerns c
                ON c.assigned_organization_id = o.id
            WHERE o.status = 'active'
              AND o.deleted_at IS NULL
            GROUP BY o.id, o.name
            ORDER BY total_concerns DESC, o.name ASC
        `
    }

    else if (role === 'admin') {
        organizationQuery = `
            SELECT
                o.id,
                o.name,
                COUNT(c.id) AS total_concerns
            FROM organizations o
            LEFT JOIN concerns c
                ON c.assigned_organization_id = o.id
            WHERE o.id = ?
              AND o.status = 'active'
              AND o.deleted_at IS NULL
            GROUP BY o.id, o.name
            ORDER BY o.name ASC
        `

        organizationParams.push(
            currentUser.organization_id
        )
    }

    else {
        organizationQuery = `
            SELECT
                o.id,
                o.name,
                COUNT(c.id) AS total_concerns
            FROM organizations o
            INNER JOIN concerns c
                ON c.assigned_organization_id = o.id
            WHERE c.created_by = ?
              AND o.status = 'active'
              AND o.deleted_at IS NULL
            GROUP BY o.id, o.name
            ORDER BY total_concerns DESC, o.name ASC
        `

        organizationParams.push(
            currentUser.id
        )
    }

    const [organizationRows] = await db.query(
        organizationQuery,
        organizationParams
    )

    /*
     * Recent concerns
     */
    const [recentRows] = await db.query(
        `
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

        ${concernWhere}

        ORDER BY c.created_at DESC

        LIMIT 10
        `,
        concernParams
    )

    /*
     * Total concerns
     */
    const [totalRows] = await db.query(
        `
        SELECT
            COUNT(*) AS total
        FROM concerns c
        ${concernWhere}
        `,
        concernParams
    )

    return {
        success: true,

        summary: {
            total: Number(
                totalRows[0]?.total || 0
            )
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
            total_concerns: Number(
                row.total_concerns
            )
        })),

        recentConcerns: recentRows
    }
})
