import db from '../../utils/db.js'

import { requireRole, SYSTEM_MANAGEMENT_ROLES } from '../../utils/require-auth.js'
import {
    assertConcernTypesExist,
    normalizeConcernTypeIds,
    replaceOrganizationConcernTypes
} from '../../utils/organization-concern-types.js'

export default defineEventHandler(async (event) => {

    const currentUser = await requireRole(event, SYSTEM_MANAGEMENT_ROLES)

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
    const organizationType = body?.organization_type

    const description =
        body?.description?.trim() || null

    const address =
        body?.address?.trim() || null

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

        const [existingRows] = await connection.query(
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

        await connection.query(
            `
            UPDATE organizations
            SET
                name = ?,
                organization_type = ?,
                description = ?,
                address = ?,
                updated_by = ?
            WHERE id = ?
              AND deleted_at IS NULL
            `,
            [
                name,
                organizationType,
                description,
                address,
                currentUser.id,
                organizationId
            ]
        )

        if (hasConcernTypeAssignments) {
            await assertConcernTypesExist(connection, concernTypeIds)
            await replaceOrganizationConcernTypes(
                connection,
                organizationId,
                concernTypeIds
            )
        }

        await connection.commit()

        return {

            success: true,

            message: 'Organization updated successfully.'

        }

    } catch (error) {

        await connection.rollback()

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

    } finally {
        connection.release()
    }

})
