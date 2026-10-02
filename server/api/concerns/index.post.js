import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'
import fs from 'fs/promises'
import path from 'path'
import crypto from 'crypto'

export default defineEventHandler(async (event) => {
    const currentUser = await requireRole(event, ['admin', 'user'])

    /*
     * Read multipart form data.
     *
     * The frontend now sends FormData because it can contain
     * both normal fields and an uploaded image.
     */
    const parts = await readMultipartFormData(event)

    if (!parts) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Invalid form data.'
        })
    }

    /*
     * Convert multipart fields into an object.
     */
    const fields = {}

    let imageFile = null

    for (const part of parts) {
        if (part.name === 'image' && part.filename) {
            imageFile = part
        } else if (part.name) {
            fields[part.name] = part.data?.toString() || ''
        }
    }

    const title = fields.title?.trim()
    const description = fields.description?.trim()
    const concernTypeId = fields.concern_type_id
    const assignedOrganizationId = fields.assigned_organization_id
    const priority = fields.priority || 'medium'

    /*
     * Validate title.
     */
    if (!title) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Concern title is required.'
        })
    }

    /*
     * Validate description.
     */
    if (!description) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Concern description is required.'
        })
    }

    /*
     * Validate concern type.
     */
    if (
        !concernTypeId ||
        Number.isNaN(Number(concernTypeId))
    ) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Concern type is required.'
        })
    }

    /*
     * Validate priority.
     */
    const validPriorities = [
        'low',
        'medium',
        'high',
        'urgent'
    ]

    if (!validPriorities.includes(priority)) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Invalid priority.'
        })
    }

    /*
     * Validate assigned organization.
     */
    if (
        !assignedOrganizationId ||
        Number.isNaN(Number(assignedOrganizationId))
    ) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Assigned organization is required.'
        })
    }

    /*
     * Validate uploaded image.
     *
     * Image is optional.
     */
    if (imageFile) {
        const validImageTypes = [
            'image/jpeg',
            'image/png',
            'image/gif',
            'image/webp'
        ]

        if (!validImageTypes.includes(imageFile.type)) {
            throw createError({
                statusCode: 400,
                statusMessage:
                    'Invalid image format. Please upload JPG, PNG, GIF, or WEBP.'
            })
        }

        /*
         * Maximum image size: 5 MB
         */
        const maxImageSize = 5 * 1024 * 1024

        if (imageFile.data.length > maxImageSize) {
            throw createError({
                statusCode: 400,
                statusMessage:
                    'Image size must not exceed 5 MB.'
            })
        }
    }

    /*
     * Verify concern type exists and is active.
     */
    const [concernTypeRows] = await db.query(
        `
        SELECT
            id
        FROM concern_types
        WHERE id = ?
          AND status = 'active'
        LIMIT 1
        `,
        [Number(concernTypeId)]
    )

    if (concernTypeRows.length === 0) {
        throw createError({
            statusCode: 400,
            statusMessage:
                'Invalid or inactive concern type.'
        })
    }

    /*
     * Verify organization exists and is active.
     */
    const [organizationRows] = await db.query(
        `
        SELECT
            id
        FROM organizations
        WHERE id = ?
          AND status = 'active'
          AND deleted_at IS NULL
        LIMIT 1
        `,
        [Number(assignedOrganizationId)]
    )

    if (organizationRows.length === 0) {
        throw createError({
            statusCode: 400,
            statusMessage:
                'Invalid or inactive organization.'
        })
    }

    /*
     * Generate concern number.
     *
     * Example:
     * CON-2026-00001
     */
    const currentYear = new Date().getFullYear()

    const [latestRows] = await db.query(
        `
        SELECT
            concern_number
        FROM concerns
        WHERE concern_number LIKE ?
        ORDER BY id DESC
        LIMIT 1
        `,
        [`CON-${currentYear}-%`]
    )

    let nextNumber = 1

    if (latestRows.length > 0) {
        const latestNumber =
            latestRows[0].concern_number
                .split('-')
                .pop()

        const parsedNumber = Number(latestNumber)

        if (!Number.isNaN(parsedNumber)) {
            nextNumber = parsedNumber + 1
        }
    }

    const concernNumber =
        `CON-${currentYear}-${String(nextNumber).padStart(5, '0')}`

    /*
     * File information used for cleanup if something fails.
     */
    let savedFilePath = null

    /*
     * Start database transaction.
     */
    const connection = await db.getConnection()

    try {
        await connection.beginTransaction()

        /*
         * Create concern.
         */
        const [result] = await connection.query(
            `
            INSERT INTO concerns (
                concern_number,
                title,
                description,
                concern_type_id,
                created_by,
                assigned_organization_id,
                status,
                priority
            )
            VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
            `,
            [
                concernNumber,
                title,
                description,
                Number(concernTypeId),
                currentUser.id,
                Number(assignedOrganizationId),
                priority
            ]
        )

        const concernId = result.insertId

        /*
         * Save image if one was uploaded.
         */
        if (imageFile) {
            /*
             * Create upload directory:
             *
             * public/uploads/concerns
             */
            const uploadDirectory = path.join(
                process.cwd(),
                'public',
                'uploads',
                'concerns'
            )

            await fs.mkdir(uploadDirectory, {
                recursive: true
            })

            /*
             * Determine extension based on MIME type.
             */
            const extensionMap = {
                'image/jpeg': '.jpg',
                'image/png': '.png',
                'image/gif': '.gif',
                'image/webp': '.webp'
            }

            const extension =
                extensionMap[imageFile.type] || '.jpg'

            /*
             * Generate a unique filename.
             *
             * Example:
             * concern-15-a8f3c9....jpg
             */
            const randomName =
                crypto.randomBytes(16).toString('hex')

            const fileName =
                `concern-${concernId}-${randomName}${extension}`

            savedFilePath = path.join(
                uploadDirectory,
                fileName
            )

            /*
             * Write the image to disk.
             */
            await fs.writeFile(
                savedFilePath,
                imageFile.data
            )

            /*
             * Public path used by the browser.
             */
            const filePath =
                `/uploads/concerns/${fileName}`

            /*
             * Save attachment information.
             */
            await connection.query(
                `
                INSERT INTO concern_attachments (
                    concern_id,
                    uploaded_by,
                    file_name,
                    file_path,
                    file_type,
                    file_size
                )
                VALUES (?, ?, ?, ?, ?, ?)
                `,
                [
                    concernId,
                    currentUser.id,
                    imageFile.filename || fileName,
                    filePath,
                    imageFile.type,
                    imageFile.data.length
                ]
            )
        }

        /*
         * Everything succeeded.
         */
        await connection.commit()

        return {
            success: true,
            message: 'Concern created successfully.',
            concernId,
            concernNumber
        }

    } catch (error) {
        /*
         * Roll back database changes.
         */
        await connection.rollback()

        /*
         * If an image was already saved but something failed,
         * delete the image from the server.
         */
        if (savedFilePath) {
            try {
                await fs.unlink(savedFilePath)
            } catch (fileError) {
                console.error(
                    'Failed to remove uploaded image:',
                    fileError
                )
            }
        }

        console.error(
            'Concern creation error:',
            error
        )

        throw createError({
            statusCode: 500,
            statusMessage:
                'Failed to create concern.'
        })

    } finally {
        connection.release()
    }
})
