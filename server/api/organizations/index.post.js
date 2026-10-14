
import db from '../../utils/db.js'
import { requireRole, SYSTEM_MANAGEMENT_ROLES } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
    const currentUser = await requireRole(event, SYSTEM_MANAGEMENT_ROLES)

    const body = await readBody(event)

    const name = body?.name?.trim()
    const organizationType = body?.organization_type
    const description = body?.description?.trim() || null
    const address = body?.address?.trim() || null
    const allowedOrganizationTypes = ['bpo', 'tenant', 'admin_facilities']

    if (!name) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Organization name is required.'
        })
    }

    if (!allowedOrganizationTypes.includes(organizationType)) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Select a valid organization type.'
        })
    }

    try {
        const [result] = await db.query(
            `
            INSERT INTO organizations (
                name,
                organization_type,
                description,
                address,
                status,
                created_by,
                updated_by
            )
            VALUES (?, ?, ?, ?, 'active', ?, ?)
            `,
            [
                name,
                organizationType,
                description,
                address,
                currentUser.id,
                currentUser.id
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

