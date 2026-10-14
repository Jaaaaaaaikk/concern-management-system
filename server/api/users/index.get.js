import db from '../../utils/db.js'

import { requireRole, SYSTEM_MANAGEMENT_ROLES } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {

    await requireRole(event, SYSTEM_MANAGEMENT_ROLES)

    const queryParams = getQuery(event)

    /*
     * PAGINATION
     */

    let page = Number(queryParams.page) || 1

    let limit = Number(queryParams.limit) || 10

    if (page < 1) {
        page = 1
    }

    if (limit < 1) {
        limit = 10
    }

    if (limit > 100) {
        limit = 100
    }

    /*
     * GET TOTAL USERS
     *
     * Only non-deleted users are included.
     */

    const [countRows] = await db.query(`
        SELECT COUNT(*) AS total
        FROM users
        WHERE deleted_at IS NULL
    `)

    const total = Number(
        countRows[0]?.total || 0
    )

    const totalPages = Math.ceil(
        total / limit
    )

    /*
     * If there are no users,
     * keep the page at 1.
     */

    if (total === 0) {

        page = 1

    } else if (page > totalPages) {

        /*
         * If requested page is greater than
         * available pages, use the last page.
         */

        page = totalPages
    }

    const offset = (
        page - 1
    ) * limit

    /*
     * GET USERS FOR CURRENT PAGE
     */

    const [rows] = await db.query(`
        SELECT
            u.id,
            u.username,
            u.first_name,
            u.middle_name,
            u.last_name,
            u.profile_photo,
            u.status,
            u.last_login_at,
            u.created_at,
            u.updated_at,
            u.created_by,
            u.updated_by,
            CONCAT(creator.first_name, ' ', creator.last_name) AS created_by_name,
            CONCAT(updater.first_name, ' ', updater.last_name) AS updated_by_name,
            r.id AS role_id,
            r.name AS role_name,
            o.id AS organization_id,
            o.name AS organization_name
        FROM users u
        INNER JOIN roles r
            ON r.id = u.role_id
        LEFT JOIN organizations o
            ON o.id = u.organization_id
        LEFT JOIN users creator
            ON creator.id = u.created_by
        LEFT JOIN users updater
            ON updater.id = u.updated_by
        WHERE u.deleted_at IS NULL
        ORDER BY u.created_at DESC
        LIMIT ? OFFSET ?
    `, [
        limit,
        offset
    ])

    return {
        success: true,
        users: rows,
        pagination: {
            page,
            limit,
            total,
            totalPages
        }
    }
})