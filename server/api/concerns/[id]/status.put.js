import db from '../../../utils/db.js'
import { requireAuth } from '../../../utils/require-auth.js'

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

    const body = await readBody(event)

    const newStatus = body?.status
    const remarks = body?.remarks?.trim() || null

    const validStatuses = [
        'pending',
        'in_progress',
        'on_hold',
        'resolved',
        'closed',
        'cancelled'
    ]

    if (!validStatuses.includes(newStatus)) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Invalid concern status.'
        })
    }

    /*
     * Get concern.
     */
    const [concernRows] = await db.query(
        `
        SELECT
            id,
            created_by,
            assigned_organization_id,
            status
        FROM concerns
        WHERE id = ?
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
     * Determine permission.
     */
    const isSuperadmin =
        currentUser.role_name === 'superadmin'

    const isAssignedAdmin =
        currentUser.role_name === 'admin' &&
        Number(concern.assigned_organization_id) ===
        Number(currentUser.organization_id)

    const isCreator =
        currentUser.role_name === 'user' &&
        Number(concern.created_by) ===
        Number(currentUser.id)

    /*
     * Superadmin can manage all concerns.
     */
    if (isSuperadmin) {
        // Allowed.
    }

    /*
     * Assigned admin can manage their organization's concerns.
     */
    else if (isAssignedAdmin) {
        // Allowed.
    }

    /*
     * Creator can manage their own concern,
     * but cannot close it.
     */
    else if (isCreator) {
        if (newStatus === 'closed') {
            throw createError({
                statusCode: 403,
                statusMessage:
                    'The concern creator cannot close the concern. Only the assigned organization admin can close it.'
            })
        }
    }

    else {
        throw createError({
            statusCode: 403,
            statusMessage:
                'You do not have permission to change this concern status.'
        })
    }

    /*
     * Do not update if status is unchanged.
     */
    if (concern.status === newStatus) {
        return {
            success: true,
            message: 'Concern status is already set to this status.'
        }
    }

    const connection = await db.getConnection()

    try {
        await connection.beginTransaction()

        /*
         * Determine timestamps.
         */
        let resolvedAt = null
        let closedAt = null

        if (newStatus === 'resolved') {
            resolvedAt = new Date()
        }

        if (newStatus === 'closed') {
            closedAt = new Date()
        }

        /*
         * Update concern.
         */
        await connection.query(
            `
            UPDATE concerns
            SET
                status = ?,
                resolved_at = CASE
                    WHEN ? = 'resolved'
                    THEN NOW()
                    ELSE resolved_at
                END,
                closed_at = CASE
                    WHEN ? = 'closed'
                    THEN NOW()
                    ELSE closed_at
                END
            WHERE id = ?
            `,
            [
                newStatus,
                newStatus,
                newStatus,
                concernId
            ]
        )

        /*
         * Save status history.
         */
        await connection.query(
            `
            INSERT INTO concern_status_history (
                concern_id,
                changed_by,
                old_status,
                new_status,
                remarks
            )
            VALUES (?, ?, ?, ?, ?)
            `,
            [
                concernId,
                currentUser.id,
                concern.status,
                newStatus,
                remarks
            ]
        )

        await connection.commit()

        return {
            success: true,
            message: 'Concern status updated successfully.'
        }

    } catch (error) {
        await connection.rollback()

        console.error(
            'Concern status update error:',
            error
        )

        throw createError({
            statusCode: 500,
            statusMessage:
                'Failed to update concern status.'
        })
    } finally {
        connection.release()
    }
})