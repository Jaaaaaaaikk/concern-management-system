import db from '../../utils/db.js'

import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {

    const currentUser = await requireAuth(event)

    const queryParams = getQuery(event)

    /*
     * PAGINATION
     *
     * Pagination is optional.
     *
     * If page/limit are not supplied:
     * - return all active organizations
     * - this keeps organization dropdowns working
     *
     * If page/limit are supplied:
     * - return paginated organizations
     */

    const hasPagination =
        queryParams.page !== undefined ||
        queryParams.limit !== undefined

    const organizationWhere = 'deleted_at IS NULL'

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
     * Only use pagination when requested.
     *
     * This preserves the old behavior for:
     *
     * GET /api/organizations
     *
     * which is used by dropdowns.
     */

    if (!hasPagination) {

        const [rows] = await db.query(`
            SELECT
                organizations.id,
                organizations.name,
                organizations.organization_type,
                organizations.description,
                organizations.address,
                organizations.status,
                organizations.created_at,
                organizations.updated_at,
                organizations.created_by,
                organizations.updated_by,
                CONCAT(creator.first_name, ' ', creator.last_name) AS created_by_name,
                CONCAT(updater.first_name, ' ', updater.last_name) AS updated_by_name
            FROM organizations
            LEFT JOIN users creator ON creator.id = organizations.created_by
            LEFT JOIN users updater ON updater.id = organizations.updated_by
            WHERE organizations.deleted_at IS NULL
            ORDER BY organizations.name ASC
        `)

        return {
            success: true,
            organizations: rows
        }
    }

    /*
    * GET TOTAL ORGANIZATIONS IN THE SELECTED STATUS SCOPE
     */

    const [countRows] = await db.query(`
        SELECT COUNT(*) AS total
        FROM organizations
        WHERE ${organizationWhere}
    `)

    const total = Number(
        countRows[0]?.total || 0
    )

    const totalPages = Math.ceil(
        total / limit
    )

    /*
     * If there are no organizations,
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
     * GET ORGANIZATIONS FOR CURRENT PAGE
     */

    const [rows] = await db.query(`
        SELECT
            organizations.id,
            organizations.name,
            organizations.organization_type,
            organizations.description,
            organizations.address,
            organizations.status,
            organizations.created_at,
            organizations.updated_at,
            organizations.created_by,
            organizations.updated_by,
            CONCAT(creator.first_name, ' ', creator.last_name) AS created_by_name,
            CONCAT(updater.first_name, ' ', updater.last_name) AS updated_by_name
        FROM organizations
        LEFT JOIN users creator ON creator.id = organizations.created_by
        LEFT JOIN users updater ON updater.id = organizations.updated_by
        WHERE organizations.deleted_at IS NULL
        ORDER BY organizations.name ASC
        LIMIT ? OFFSET ?
    `, [
        limit,
        offset
    ])

    return {
        success: true,
        organizations: rows,
        pagination: {
            page,
            limit,
            total,
            totalPages
        }
    }
})