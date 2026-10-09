import db from '../../utils/db.js'

import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {

    await requireRole(event, ['superadmin'])

    const organizationId = Number(
        getRouterParam(event, 'id')
    )

    if (!Number.isInteger(organizationId) || organizationId <= 0) {

        throw createError({
            statusCode: 400,
            statusMessage: 'Invalid organization ID.'
        })

    }

    const body = await readBody(event)

    const name = body?.name?.trim()

    const description =
        body?.description?.trim() || null

    const address =
        body?.address?.trim() || null

    if (!name) {

        throw createError({
            statusCode: 400,
            statusMessage: 'Organization name is required.'
        })

    }

    try {

        const [existingRows] = await db.query(
            `
            SELECT id
            FROM organizations
            WHERE id = ?
              AND deleted_at IS NULL
            LIMIT 1
            `,
            [
                organizationId
            ]
        )

        if (existingRows.length === 0) {

            throw createError({
                statusCode: 404,
                statusMessage: 'Organization not found.'
            })

        }

        await db.query(
            `
            UPDATE organizations
            SET
                name = ?,
                description = ?,
                address = ?
            WHERE id = ?
              AND deleted_at IS NULL
            `,
            [
                name,
                description,
                address,
                organizationId
            ]
        )

        return {

            success: true,

            message: 'Organization updated successfully.'

        }

    } catch (error) {

        if (error?.statusCode) {
            throw error
        }

        console.error(
            'Organization update error:',
            error
        )

        throw createError({
            statusCode: 500,
            statusMessage: 'Failed to update organization.'
        })

    }

})
