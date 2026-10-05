import db from '../../../utils/db.js'

import { requireAuth } from '../../../utils/require-auth.js'

import { mkdir, writeFile, unlink } from 'node:fs/promises'
import path from 'node:path'
import crypto from 'node:crypto'

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
     * Get concern.
     */
    const [concernRows] = await db.query(
        `
        SELECT
            id,
            created_by,
            assigned_organization_id,
            status,
            acknowledged_at,
            resolved_at,
            closed_at
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
     * Determine permissions.
     */
    const isSuperadmin =
        currentUser.role_name === 'superadmin'

    const isCreator =
        Number(concern.created_by) ===
        Number(currentUser.id)

    /*
     * A creator who happens to be an admin must still
     * be treated as the creator, not as the assigned
     * recipient/admin for this concern.
     */
    const isAssignedAdmin =
        currentUser.role_name === 'admin' &&
        !isCreator &&
        Number(concern.assigned_organization_id) ===
            Number(currentUser.organization_id)

    /*
     * CLOSED concerns cannot be changed anymore.
     */
    if (concern.status === 'closed') {
        throw createError({
            statusCode: 403,
            statusMessage:
                'This concern is already closed and cannot be changed.'
        })
    }

    /*
     * Read multipart/form-data.
     *
     * The frontend sends:
     * - status
     * - remarks
     * - images (multiple)
     */
    const parts = await readMultipartFormData(event)

    if (!parts) {
        throw createError({
            statusCode: 400,
            statusMessage:
                'Invalid request. Please submit the status update as multipart form data.'
        })
    }

    let newStatus = ''
    let remarks = null
    const evidenceImages = []

    for (const part of parts) {
        if (!part?.name) {
            continue
        }

        /*
         * Normal form fields.
         */
        if (part.name === 'status') {
            newStatus = Buffer.isBuffer(part.data)
                ? part.data.toString('utf8').trim()
                : String(part.data || '').trim()

            continue
        }

        if (part.name === 'remarks') {
            const value = Buffer.isBuffer(part.data)
                ? part.data.toString('utf8').trim()
                : String(part.data || '').trim()

            remarks = value || null

            continue
        }

        /*
         * Evidence images.
         *
         * The frontend sends every evidence image
         * using the field name "images".
         */
        if (part.name === 'images' && part.filename) {
            evidenceImages.push(part)
        }
    }

    const validStatuses = [
        'pending',
        'in_progress',
        'on_hold',
        'resolved',
        'closed'
    ]

    if (!validStatuses.includes(newStatus)) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Invalid concern status.'
        })
    }

    /*
     * Validate image files.
     */
    const allowedImageTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    const maxFileSize = 5 * 1024 * 1024

    for (const image of evidenceImages) {
        if (!allowedImageTypes.includes(image.type)) {
            throw createError({
                statusCode: 400,
                statusMessage:
                    `${image.filename || 'Evidence image'} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`
            })
        }

        if (!image.data || image.data.length === 0) {
            throw createError({
                statusCode: 400,
                statusMessage:
                    `${image.filename || 'Evidence image'} is empty.`
            })
        }

        if (image.data.length > maxFileSize) {
            throw createError({
                statusCode: 400,
                statusMessage:
                    `${image.filename || 'Evidence image'} exceeds the 5 MB limit.`
            })
        }
    }

    /*
     * Only the creator can close a concern.
     *
     * Superadmin uses the general Update Status control
     * and is allowed to override the status, including
     * closing it.
     */
    if (newStatus === 'closed') {
        if (!isCreator && !isSuperadmin) {
            throw createError({
                statusCode: 403,
                statusMessage:
                    'Only the creator or superadmin can close this concern.'
            })
        }

        if (concern.status !== 'resolved') {
            throw createError({
                statusCode: 400,
                statusMessage:
                    'Only a resolved concern can be closed.'
            })
        }
    }

    /*
     * Creator cannot control recipient work status.
     *
     * Creator may only close a resolved concern.
     */
    if (
        isCreator &&
        !isSuperadmin &&
        !isAssignedAdmin &&
        newStatus !== 'closed'
    ) {
        throw createError({
            statusCode: 403,
            statusMessage:
                'The concern creator cannot change the recipient work status.'
        })
    }

    /*
     * Assigned organization admin or superadmin
     * can manage recipient work status.
     */
    if (
        !isSuperadmin &&
        !isAssignedAdmin &&
        !isCreator
    ) {
        throw createError({
            statusCode: 403,
            statusMessage:
                'You do not have permission to change this concern status.'
        })
    }

    /*
     * Allowed status transitions.
     *
     * Assigned admin UI uses:
     *
     * pending → in_progress
     * in_progress → resolved
     *
     * Superadmin can use the general status override,
     * but transitions still remain controlled here.
     */
    const allowedTransitions = {
        pending: [
            'in_progress'
        ],

        in_progress: [
            'on_hold',
            'resolved'
        ],

        on_hold: [
            'in_progress',
            'resolved'
        ],

        resolved: [
            'closed'
        ],

        closed: [],

    }

    const allowedNextStatuses =
        allowedTransitions[concern.status] || []

    if (!allowedNextStatuses.includes(newStatus)) {
        throw createError({
            statusCode: 400,
            statusMessage:
                `Cannot change concern status from "${concern.status}" to "${newStatus}".`
        })
    }

    /*
     * Only the assigned organization admin or
     * superadmin can change recipient work status.
     */
    const recipientWorkStatuses = [
        'in_progress',
        'on_hold',
        'resolved'
    ]

    if (
        recipientWorkStatuses.includes(newStatus) &&
        !isSuperadmin &&
        !isAssignedAdmin
    ) {
        throw createError({
            statusCode: 403,
            statusMessage:
                'Only the assigned organization can update the work status of this concern.'
        })
    }

    /*
     * Resolution requirements.
     *
     * Assigned admin resolving:
     *
     * in_progress → resolved
     *
     * requires:
     * - remarks
     * - at least one evidence image
     */
    const resolvingByAssignedAdmin =
        isAssignedAdmin &&
        concern.status === 'in_progress' &&
        newStatus === 'resolved'

    if (resolvingByAssignedAdmin) {
        if (!remarks) {
            throw createError({
                statusCode: 400,
                statusMessage:
                    'Resolution remarks are required before marking the concern as resolved.'
            })
        }

        if (evidenceImages.length === 0) {
            throw createError({
                statusCode: 400,
                statusMessage:
                    'At least one resolution evidence image is required before marking the concern as resolved.'
            })
        }
    }

    /*
     * If status is unchanged, do nothing.
     */
    if (concern.status === newStatus) {
        return {
            success: true,
            message:
                'Concern status is already set to this status.'
        }
    }

    const connection = await db.getConnection()

    const savedFilePaths = []

    try {
        await connection.beginTransaction()

        /*
         * Update concern timing fields.
         *
         * acknowledged_at:
         * Set only the first time the concern becomes
         * in_progress.
         *
         * resolved_at:
         * Set when concern becomes resolved.
         *
         * closed_at:
         * Set when concern becomes closed.
         */
        await connection.query(
            `
            UPDATE concerns
            SET
                status = ?,

                acknowledged_at = CASE
                    WHEN ? = 'in_progress'
                        AND acknowledged_at IS NULL
                    THEN NOW()
                    ELSE acknowledged_at
                END,

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
                newStatus,
                concernId
            ]
        )

        /*
         * Save status history.
         *
         * We need the inserted history ID because
         * resolution evidence belongs to this exact
         * status history record.
         */
        const [historyResult] = await connection.query(
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

        const statusHistoryId =
            historyResult.insertId

        /*
         * Save resolution evidence images.
         *
         * Evidence is stored separately from:
         * - original concern attachments
         * - comment attachments
         *
         * It is linked to the exact status history
         * record that changed the concern to Resolved.
         */
        if (
            resolvingByAssignedAdmin &&
            evidenceImages.length > 0
        ) {
            const uploadDirectory = path.join(
                process.cwd(),
                'public',
                'uploads',
                'concerns'
            )

            await mkdir(uploadDirectory, {
                recursive: true
            })

            for (const image of evidenceImages) {
                const originalName =
                    image.filename || 'evidence'

                const extension =
                    path.extname(originalName).toLowerCase() ||
                    (
                        image.type === 'image/jpeg'
                            ? '.jpg'
                            : image.type === 'image/png'
                                ? '.png'
                                : image.type === 'image/gif'
                                    ? '.gif'
                                    : '.webp'
                    )

                const randomPart =
                    crypto.randomBytes(16).toString('hex')

                const fileName =
                    `status-${concernId}-${randomPart}${extension}`

                const fileSystemPath =
                    path.join(
                        uploadDirectory,
                        fileName
                    )

                const browserPath =
                    `/uploads/concerns/${fileName}`

                await writeFile(
                    fileSystemPath,
                    image.data
                )

                savedFilePaths.push(fileSystemPath)

                await connection.query(
                    `
                    INSERT INTO concern_status_attachments (
                        status_history_id,
                        concern_id,
                        uploaded_by,
                        file_name,
                        file_path,
                        file_type,
                        file_size
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    `,
                    [
                        statusHistoryId,
                        concernId,
                        currentUser.id,
                        originalName,
                        browserPath,
                        image.type,
                        image.data.length
                    ]
                )
            }
        }

        await connection.commit()

        return {
            success: true,
            message:
                newStatus === 'resolved'
                    ? 'Concern resolved successfully with evidence.'
                    : 'Concern status updated successfully.'
        }
    } catch (error) {
        await connection.rollback()

        /*
         * Delete files that were successfully written
         * before the transaction failed.
         */
        for (const filePath of savedFilePaths) {
            try {
                await unlink(filePath)
            } catch (cleanupError) {
                console.error(
                    'Failed to remove uploaded status evidence:',
                    cleanupError
                )
            }
        }

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