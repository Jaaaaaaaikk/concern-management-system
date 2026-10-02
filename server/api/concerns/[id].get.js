import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
    const currentUser = await requireAuth(event)

    const concernId = Number(
        getRouterParam(event, 'id')
    )

    if (!concernId || Number.isNaN(concernId)) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Invalid concern ID.'
        })
    }

    /*
     * Get concern information.
     *
     * creator_organization_id is the organization
     * of the person who CREATED the concern.
     *
     * This is what we use for visibility.
     *
     * assigned_organization_id is only the organization
     * assigned to handle the concern.
     */
    const [concernRows] = await db.query(
        `
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

        WHERE c.id = ?

        LIMIT 1
        `,
        [concernId]
    )

    if (concernRows.length === 0) {
        throw createError({
            statusCode: 404,
            statusMessage: 'Concern not found.'
        })
    }

    const concern = concernRows[0]

    /*
     * Check whether the current user is allowed
     * to view this concern.
     *
     * --------------------------------------------
     * SUPERADMIN
     * --------------------------------------------
     * Can view every concern.
     *
     * --------------------------------------------
     * ADMIN / USER
     * --------------------------------------------
     * Can view the concern if:
     *
     * 1. They created the concern themselves
     *
     * OR
     *
     * 2. The person who created the concern
     *    belongs to the same organization/department.
     *
     * IMPORTANT:
     *
     * The creator can be either:
     *
     * - Admin
     * - User
     *
     * We DO NOT check the creator's role.
     *
     * We also DO NOT use assigned_organization_id
     * for visibility.
     */

    if (
        currentUser.role_name === 'admin' ||
        currentUser.role_name === 'user'
    ) {
        const createdByCurrentUser =
            Number(concern.created_by) ===
            Number(currentUser.id)

        const creatorSameOrganization =
            Number(concern.creator_organization_id) ===
            Number(currentUser.organization_id)

        if (
            !createdByCurrentUser &&
            !creatorSameOrganization
        ) {
            throw createError({
                statusCode: 403,
                statusMessage:
                    'You do not have permission to view this concern.'
            })
        }
    }

    /*
     * Reject unknown roles.
     *
     * Superadmin is already allowed above.
     */
    else if (
        currentUser.role_name !== 'superadmin'
    ) {
        throw createError({
            statusCode: 403,
            statusMessage:
                'Invalid user role.'
        })
    }

    /*
     * Get attachments.
     */
    const [attachments] = await db.query(
        `
        SELECT
            ca.id,
            ca.file_name,
            ca.file_path,
            ca.file_type,
            ca.file_size,
            ca.created_at,

            ca.uploaded_by,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS uploaded_by_name

        FROM concern_attachments ca

        INNER JOIN users u
            ON u.id = ca.uploaded_by

        WHERE ca.concern_id = ?

        ORDER BY ca.created_at ASC
        `,
        [concernId]
    )

    /*
     * Get comments.
     */
    const [comments] = await db.query(
        `
        SELECT
            cc.id,
            cc.comment,
            cc.created_at,
            cc.updated_at,

            cc.user_id,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS user_name,

            r.name AS role_name

        FROM concern_comments cc

        INNER JOIN users u
            ON u.id = cc.user_id

        LEFT JOIN roles r
            ON r.id = u.role_id

        WHERE cc.concern_id = ?

        ORDER BY cc.created_at ASC
        `,
        [concernId]
    )

    /*
     * Get status history.
     */
    const [statusHistory] = await db.query(
        `
        SELECT
            csh.id,
            csh.old_status,
            csh.new_status,
            csh.remarks,
            csh.created_at,

            csh.changed_by,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS changed_by_name

        FROM concern_status_history csh

        INNER JOIN users u
            ON u.id = csh.changed_by

        WHERE csh.concern_id = ?

        ORDER BY csh.created_at ASC
        `,
        [concernId]
    )

    return {
        success: true,
        concern,
        attachments,
        comments,
        statusHistory
    }
})