import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const body = await readBody(event)

  const name = body?.name?.trim()
  const description = body?.description?.trim() || null

  if (!name) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Concern type name is required.'
    })
  }

  try {
    const [result] = await db.query(
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

    return {
      success: true,
      message: 'Concern type created successfully.',
      concernTypeId: result.insertId
    }
  } catch (error) {
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
  }
})