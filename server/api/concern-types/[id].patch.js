import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const id = Number(getRouterParam(event, 'id'))
  const body = await readBody(event)

  if (!Number.isInteger(id) || id < 1) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid concern category.'
    })
  }

  const hasFieldsToUpdate =
    Object.prototype.hasOwnProperty.call(body, 'name') ||
    Object.prototype.hasOwnProperty.call(body, 'description') ||
    Object.prototype.hasOwnProperty.call(body, 'organization_id') ||
    Object.prototype.hasOwnProperty.call(body, 'status')

  if (!hasFieldsToUpdate) {
    throw createError({
      statusCode: 400,
      statusMessage: 'No category changes were provided.'
    })
  }

  const connection = await db.getConnection()

  try {
    await connection.beginTransaction()

    const [categoryRows] = await connection.query(
      'SELECT id FROM concern_types WHERE id = ? LIMIT 1 FOR UPDATE',
      [id]
    )

    if (categoryRows.length === 0) {
      throw createError({
        statusCode: 404,
        statusMessage: 'Concern category not found.'
      })
    }

    const updates = []
    const parameters = []

    if (Object.prototype.hasOwnProperty.call(body, 'name')) {
      const name = body.name?.trim()

      if (!name) {
        throw createError({
          statusCode: 400,
          statusMessage: 'Concern category name is required.'
        })
      }

      updates.push('name = ?')
      parameters.push(name)
    }

    if (Object.prototype.hasOwnProperty.call(body, 'description')) {
      updates.push('description = ?')
      parameters.push(body.description?.trim() || null)
    }

    if (Object.prototype.hasOwnProperty.call(body, 'organization_id')) {
      const organizationId = Number(body.organization_id)

      if (!Number.isInteger(organizationId) || organizationId <= 0) {
        throw createError({
          statusCode: 400,
          statusMessage: 'Select one organization to handle this category.'
        })
      }

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

      updates.push('assigned_organization_id = ?')
      parameters.push(organizationId)
    }

    if (Object.prototype.hasOwnProperty.call(body, 'status')) {
      if (!['active', 'inactive'].includes(body.status)) {
        throw createError({
          statusCode: 400,
          statusMessage: 'Status must be active or inactive.'
        })
      }

      updates.push('status = ?')
      parameters.push(body.status)
    }

    if (updates.length) {
      await connection.query(
        `UPDATE concern_types SET ${updates.join(', ')} WHERE id = ?`,
        [...parameters, id]
      )
    }

    if (Object.prototype.hasOwnProperty.call(body, 'organization_id')) {
      await connection.query(
        'DELETE FROM organization_concern_types WHERE concern_type_id = ?',
        [id]
      )
    }

    await connection.commit()

    return {
      success: true,
      message: Object.prototype.hasOwnProperty.call(body, 'status') && !Object.prototype.hasOwnProperty.call(body, 'name')
        ? body.status === 'active'
          ? 'Concern category restored successfully.'
          : 'Concern category removed from active use.'
        : 'Concern category updated successfully.'
    }
  } catch (error) {
    await connection.rollback()

    if (error?.statusCode) throw error

    if (error.code === 'ER_DUP_ENTRY') {
      throw createError({
        statusCode: 409,
        statusMessage: 'This concern category already exists.'
      })
    }

    console.error('Concern category update error:', error)

    throw createError({
      statusCode: 500,
      statusMessage: 'Failed to update concern category.'
    })
  } finally {
    connection.release()
  }
})