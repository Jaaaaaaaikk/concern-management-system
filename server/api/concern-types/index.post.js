import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const body = await readBody(event)

  const name = body?.name?.trim()
  const description = body?.description?.trim() || null
  const organizationIds = body?.organization_ids ?? []

  if (!Array.isArray(organizationIds)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Organization assignments must be a list.'
    })
  }

  const normalizedOrganizationIds = [...new Set(organizationIds.map(Number))]

  if (normalizedOrganizationIds.some(id => !Number.isInteger(id) || id <= 0)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'One or more organization assignments are invalid.'
    })
  }

  if (!name) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Concern type name is required.'
    })
  }

  const connection = await db.getConnection()

  try {
    await connection.beginTransaction()

    if (normalizedOrganizationIds.length) {
      const [organizationRows] = await connection.query(
        `
          SELECT id
          FROM organizations
          WHERE id IN (?)
            AND status = 'active'
            AND deleted_at IS NULL
        `,
        [normalizedOrganizationIds]
      )

      if (organizationRows.length !== normalizedOrganizationIds.length) {
        throw createError({
          statusCode: 400,
          statusMessage: 'Select only active organizations.'
        })
      }
    }

    const [result] = await connection.query(
      `
      INSERT INTO concern_types (
        name,
        description,
        status
      )
      VALUES (?, ?, 'active')
      `,
      [
        name,
        description
      ]
    )

    if (normalizedOrganizationIds.length) {
      const values = normalizedOrganizationIds.map(() => '(?, ?)').join(', ')
      const parameters = normalizedOrganizationIds.flatMap(organizationId => [
        organizationId,
        result.insertId
      ])

      await connection.query(
        `INSERT INTO organization_concern_types (organization_id, concern_type_id) VALUES ${values}`,
        parameters
      )
    }

    await connection.commit()

    return {
      success: true,
      message: 'Concern type created successfully.',
      concernTypeId: result.insertId
    }
  } catch (error) {
    await connection.rollback()

    if (error?.statusCode) {
      throw error
    }

    if (error.code === 'ER_DUP_ENTRY') {
      throw createError({
        statusCode: 409,
        statusMessage: 'This concern type already exists.'
      })
    }

    console.error(
      'Concern type creation error:',
      error
    )

    throw createError({
      statusCode: 500,
      statusMessage: 'Failed to create concern type.'
    })
  } finally {
    connection.release()
  }
})