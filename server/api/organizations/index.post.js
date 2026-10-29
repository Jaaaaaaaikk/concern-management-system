
import db from '../../utils/db.js'
import { requireRole, SYSTEM_MANAGEMENT_ROLES } from '../../utils/require-auth.js'
import {
    assertConcernTypesExist,
    normalizeConcernTypeIds,
    replaceOrganizationConcernTypes
} from '../../utils/organization-concern-types.js'

export default defineEventHandler(async (event) => {
    const currentUser = await requireRole(event, SYSTEM_MANAGEMENT_ROLES)

    const body = await readBody(event)

    const name = body?.name?.trim()
    const organizationType = body?.organization_type
    const description = body?.description?.trim() || null
    const address = body?.address?.trim() || null
    const allowedOrganizationTypes = ['bpo', 'tenant', 'admin_facilities']
    const hasConcernTypeAssignments = Object.hasOwn(body || {}, 'concern_type_ids')

    if (hasConcernTypeAssignments && currentUser.role_name !== 'superadmin') {
        throw createError({
            statusCode: 403,
            statusMessage: 'Only superadmins can assign concern types to organizations.'
        })
    }

    const concernTypeIds = hasConcernTypeAssignments
        ? normalizeConcernTypeIds(body.concern_type_ids)
        : []

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

    const connection = await db.getConnection()

    try {
        await connection.beginTransaction()
        await assertConcernTypesExist(connection, concernTypeIds)

        const [result] = await connection.query(
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

        if (hasConcernTypeAssignments) {
            await replaceOrganizationConcernTypes(
                connection,
                result.insertId,
                concernTypeIds
            )
        }

        await connection.commit()

        return {
            success: true,
            message: 'Organization created successfully.',
            organizationId: result.insertId
        }
    } catch (error) {
        await connection.rollback()

        if (error?.statusCode) {
            throw error
        }

        console.error('Organization creation error:', error)

        throw createError({
            statusCode: 500,
            statusMessage: 'Failed to create organization.'
        })
    } finally {
        connection.release()
    }
})

