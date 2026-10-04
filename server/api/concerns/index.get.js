import db from '../../utils/db.js'

import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {

    const currentUser = await requireAuth(event)

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
     * FILTERS
     */
    const search = String(
        queryParams.search || ''
    ).trim()

    const status = String(
        queryParams.status || ''
    ).trim()

    const priority = String(
        queryParams.priority || ''
    ).trim()

    /*
     * WHERE CONDITIONS
     */
    const conditions = []
    const params = []

    /*
     * ROLE-BASED VISIBILITY
     *
     * SUPERADMIN
     *
     * Can see all concerns.
     */
    if (currentUser.role_name === 'superadmin') {

        // No role-based filter.

    }

    /*
     * ADMIN
     *
     * Can see:
     *
     * 1. Concerns they created themselves
     * OR
     * 2. Concerns created by someone in their organization
     * OR
     * 3. Concerns assigned to their organization
     */
    else if (currentUser.role_name === 'admin') {

        conditions.push(`
            (
                c.created_by = ?
                OR u.organization_id = ?
                OR c.assigned_organization_id = ?
            )
        `)

        params.push(
            currentUser.id,
            currentUser.organization_id,
            currentUser.organization_id
        )
    }

    /*
     * REGULAR USER
     *
     * Can see:
     *
     * 1. Concerns they created themselves
     * OR
     * 2. Concerns created by someone in their organization
     *
     * Regular users are NOT treated as the assigned recipient.
     */
    else if (currentUser.role_name === 'user') {

        conditions.push(`
            (
                c.created_by = ?
                OR u.organization_id = ?
            )
        `)

        params.push(
            currentUser.id,
            currentUser.organization_id
        )
    }

    else {

        throw createError({
            statusCode: 403,
            statusMessage: 'Invalid user role.'
        })
    }

    /*
     * SEARCH
     *
     * Search concern number, title, or description.
     */
    if (search) {

        const searchValue = `%${search}%`

        conditions.push(`
            (
                c.concern_number LIKE ?
                OR c.title LIKE ?
                OR c.description LIKE ?
            )
        `)

        params.push(
            searchValue,
            searchValue,
            searchValue
        )
    }

    /*
     * STATUS FILTER
     */
    if (status) {

        conditions.push(`
            c.status = ?
        `)

        params.push(status)
    }

    /*
     * PRIORITY FILTER
     */
    if (priority) {

        conditions.push(`
            c.priority = ?
        `)

        params.push(priority)
    }

    /*
     * BUILD WHERE CLAUSE
     */
    const whereClause = conditions.length
        ? `WHERE ${conditions.join(' AND ')}`
        : ''

    /*
     * GET TOTAL MATCHING CONCERNS
     *
     * This count is calculated AFTER:
     *
     * - Role permissions
     * - Search
     * - Status filter
     * - Priority filter
     */
    const countQuery = `
        SELECT COUNT(*) AS total

        FROM concerns c

        INNER JOIN users u
            ON u.id = c.created_by

        ${whereClause}
    `

    const [countRows] = await db.query(
        countQuery,
        params
    )

    const total = Number(
        countRows[0]?.total || 0
    )

    const totalPages = Math.ceil(
        total / limit
    )

    /*
     * If there are no results, keep page at 1.
     */
    if (total === 0) {

        page = 1
    }

    /*
     * If the requested page is greater than
     * the available pages, use the last page.
     */
    else if (page > totalPages) {

        page = totalPages
    }

    const offset = (page - 1) * limit

    /*
     * GET CONCERNS FOR CURRENT PAGE
     */
    const query = `
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

            u.organization_id AS creator_organization_id,

            creator_org.name AS creator_organization_name,

            c.assigned_organization_id,

            assigned_org.name AS organization_name,

            c.status,

            c.priority,

            c.created_at,

            c.acknowledged_at,

            c.updated_at,

            c.resolved_at,

            c.closed_at

        FROM concerns c

        LEFT JOIN concern_types ct
            ON ct.id = c.concern_type_id

        INNER JOIN users u
            ON u.id = c.created_by

        LEFT JOIN organizations creator_org
            ON creator_org.id = u.organization_id

        LEFT JOIN organizations assigned_org
            ON assigned_org.id = c.assigned_organization_id

        ${whereClause}

        ORDER BY c.created_at DESC

        LIMIT ? OFFSET ?
    `

    const finalParams = [
        ...params,
        limit,
        offset
    ]

    const [rows] = await db.query(
        query,
        finalParams
    )

    return {
        success: true,

        concerns: rows,

        pagination: {
            page,
            limit,
            total,
            totalPages
        }
    }
})