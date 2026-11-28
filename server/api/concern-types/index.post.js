import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const body = await readBody(event)

  const name = body?.name?.trim()
  const description = body?.description?.trim() || null
  const organizationId = Number(body?.organization_id)

  if (!Number.isInteger(organizationId) || organizationId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Select one organization to handle this category.'
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

    const [organizationRows] = await connection.query(
      `
        SELECT id
        FROM organizations
        WHERE id = ?
          AND status = 'active'
          AND deleted_at IS NULL
        LIMIT 1
      `,
      [organizationId]
    )

    if (organizationRows.length === 0) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Select one active organization.'
      })
    }

    const [result] = await connection.query(
      `
      INSERT INTO concern_types (
        name,
        description,
        assigned_organization_id,
        status
      )
      VALUES (?, ?, ?, 'active')
      `,
      [
        name,
        description,
        organizationId
      ]
    )

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