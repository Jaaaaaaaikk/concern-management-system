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
    `

    const params = []

    /*
     * SUPERADMIN
     *
     * Can see all concerns.
     */
    if (currentUser.role_name === 'superadmin') {

        // No filter.

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
     *
     * The third condition is important because
     * the assigned organization's admin is the recipient
     * responsible for handling the concern.
     */
    else if (currentUser.role_name === 'admin') {

        query += `
            WHERE
                c.created_by = ?
                OR u.organization_id = ?
                OR c.assigned_organization_id = ?
        `

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
     * The organization's admin handles assigned concerns.
     */
    else if (currentUser.role_name === 'user') {

        query += `
            WHERE
                c.created_by = ?
                OR u.organization_id = ?
        `

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

    query += `
        ORDER BY c.created_at DESC
    `

    const [rows] = await db.query(
        query,
        params
    )

    return {
        success: true,
        concerns: rows
    }

})
