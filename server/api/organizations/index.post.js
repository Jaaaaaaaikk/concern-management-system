
import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
    await requireRole(event, ['superadmin'])

    const body = await readBody(event)

    const name = body?.name?.trim()
    const description = body?.description?.trim() || null
    const address = body?.address?.trim() || null

    if (!name) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Organization name is required.'
        })
    }

    try {
        const [result] = await db.query(
            `
            INSERT INTO organizations (
                name,
                description,
                address,
                status
            )
            VALUES (?, ?, ?, 'active')
            `,
            [
                name,
                description,
                address
            ]
        )

        return {
            success: true,
            message: 'Organization created successfully.',
            organizationId: result.insertId
        }
    } catch (error) {
        console.error('Organization creation error:', error)

        throw createError({
            statusCode: 500,
            statusMessage: 'Failed to create organization.'
        })
    }
})

