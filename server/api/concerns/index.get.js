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

    const department = Number(
        queryParams.department || 0
    )

    const date = String(
        queryParams.date || ''
    ).trim()

    const trashView = String(
        queryParams.view || ''
    ).trim() === 'trash'

    const sortColumns = {
        title: 'c.title',
        assigned_to: 'assigned_org.name',
        priority: `CASE c.priority
            WHEN 'low' THEN 1
            WHEN 'medium' THEN 2
            WHEN 'high' THEN 3
            WHEN 'urgent' THEN 4
            ELSE 0
        END`,
        status: `CASE c.status
            WHEN 'pending' THEN 1
            WHEN 'in_progress' THEN 2
            WHEN 'on_hold' THEN 3
            WHEN 'resolved' THEN 4
            WHEN 'closed' THEN 5
            WHEN 'cancelled' THEN 6
            ELSE 0
        END`,
        target_commitment_at: 'c.target_commitment_at',
        created_at: 'c.created_at'
    }

    const requestedSort = String(
        queryParams.sortBy || 'created_at'
    ).trim()

    const sortColumn = sortColumns[requestedSort]
        ? requestedSort
        : 'created_at'

    const sortDirection = String(
        queryParams.sortDirection || 'desc'
    ).toLowerCase() === 'asc'
        ? 'ASC'
        : 'DESC'

    /*
     * WHERE CONDITIONS
     */

    const conditions = []
    const params = []

    /*
     * ROLE-BASED VISIBILITY
     *
     * SUPERADMIN
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
     * 2. Concerns created by someone in their organization
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
     * 2. Concerns created by someone in their organization
     * 3. Concerns assigned to their organization
     *
     * Regular users can VIEW concerns assigned to their
     * organization, but they cannot manage their status.
     */

    else if (currentUser.role_name === 'user') {

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

    else {

        throw createError({
            statusCode: 403,
            statusMessage: 'Invalid user role.'
        })
    }

    if (trashView) {
        if (currentUser.role_name === 'admin') {
            conditions.push('u.organization_id = ?')
            params.push(currentUser.organization_id)
            conditions.push("c.status = 'pending'")
        } else if (currentUser.role_name === 'user') {
            conditions.push('c.created_by = ?')
            params.push(currentUser.id)
            conditions.push("c.status = 'pending'")
        }
    }

    conditions.push(
        trashView
            ? 'c.deleted_at IS NOT NULL'
            : 'c.deleted_at IS NULL'
    )

    if (!trashView) {
        conditions.push(`
            (
                u.organization_id IS NULL
                OR (
                    creator_org.id IS NOT NULL
                    AND creator_org.deleted_at IS NULL
                )
            )
            AND (
                c.assigned_organization_id IS NULL
                OR (
                    assigned_org.id IS NOT NULL
                    AND assigned_org.deleted_at IS NULL
                )
            )
        `)
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

    if (Number.isInteger(department) && department > 0) {
        conditions.push('c.assigned_organization_id = ?')
        params.push(department)
    }

    /*
     * DATE FILTER
     *
     * This filter affects:
     *
     * 1. The concerns table
     * 2. The Excel export
     *
     * The selected date range is based on
     * the concern created_at value.
     */

    if (date === 'today') {

        conditions.push(`
            c.created_at >= CURDATE()
            AND c.created_at < DATE_ADD(
                CURDATE(),
                INTERVAL 1 DAY
            )
        `)

    }
    else if (date === 'week') {

        conditions.push(`
            c.created_at >= DATE_SUB(
                CURDATE(),
                INTERVAL WEEKDAY(CURDATE()) DAY
            )
            AND c.created_at < DATE_ADD(
                DATE_SUB(
                    CURDATE(),
                    INTERVAL WEEKDAY(CURDATE()) DAY
                ),
                INTERVAL 7 DAY
            )
        `)

    }
    else if (date === 'month') {

        conditions.push(`
            c.created_at >= DATE_FORMAT(
                CURDATE(),
                '%Y-%m-01'
            )
            AND c.created_at < DATE_ADD(
                DATE_FORMAT(
                    CURDATE(),
                    '%Y-%m-01'
                ),
                INTERVAL 1 MONTH
            )
        `)

    }
    else if (date === 'year') {

        conditions.push(`
            c.created_at >= DATE_FORMAT(
                CURDATE(),
                '%Y-01-01'
            )
            AND c.created_at < DATE_ADD(
                DATE_FORMAT(
                    CURDATE(),
                    '%Y-01-01'
                ),
                INTERVAL 1 YEAR
            )
        `)

    }

    /*
     * BUILD WHERE CLAUSE
     */

    const whereClause = conditions.length
        ? `WHERE ${conditions.join(' AND ')}`
        : ''

    /*
     * GET TOTAL MATCHING CONCERNS
     */

    const countQuery = `
        SELECT COUNT(*) AS total
        FROM concerns c
        INNER JOIN users u
            ON u.id = c.created_by
        LEFT JOIN organizations creator_org
            ON creator_org.id = u.organization_id
        LEFT JOIN organizations assigned_org
            ON assigned_org.id = c.assigned_organization_id
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

    if (total === 0) {

        page = 1

    }
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
            c.target_commitment_at,
            c.updated_at,
            c.resolved_at,
            c.closed_at,
            c.deleted_at,
            c.deleted_by,
            CONCAT(deleted_user.first_name, ' ', deleted_user.last_name) AS deleted_by_name

        FROM concerns c

        LEFT JOIN concern_types ct
            ON ct.id = c.concern_type_id

        INNER JOIN users u
            ON u.id = c.created_by

        LEFT JOIN organizations creator_org
            ON creator_org.id = u.organization_id

        LEFT JOIN organizations assigned_org
            ON assigned_org.id = c.assigned_organization_id

        LEFT JOIN users deleted_user
            ON deleted_user.id = c.deleted_by

        ${whereClause}

        ORDER BY ${sortColumns[sortColumn]} ${sortDirection}, c.created_at DESC

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

    if (rows.length > 0) {
        const concernIds = rows.map((concern) => concern.id)
        const placeholders = concernIds.map(() => '?').join(', ')

        const [historyRows] = await db.query(
            `
                SELECT
                    concern_id,
                    old_status,
                    new_status,
                    remarks,
                    created_at
                FROM concern_status_history
                WHERE concern_id IN (${placeholders})
                ORDER BY created_at ASC
            `,
            concernIds
        )

        for (const concern of rows) {
            concern.statusHistory = historyRows.filter(
                (history) => Number(history.concern_id) === Number(concern.id)
            )
        }
    }

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