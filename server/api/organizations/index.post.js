import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const body = await readBody(event)

  const name = body?.name?.trim()
  const code = body?.code?.trim() || null
  const description = body?.description?.trim() || null
  const contactEmail = body?.contact_email?.trim() || null
  const contactNumber = body?.contact_number?.trim() || null
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
        code,
        description,
        contact_email,
        contact_number,
        address,
        status
      )
      VALUES (?, ?, ?, ?, ?, ?, 'active')
      `,
      [
        name,
        code,
        description,
        contactEmail,
        contactNumber,
        address
      ]
    )

    return {
      success: true,
      message: 'Organization created successfully.',
      organizationId: result.insertId
    }
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      throw createError({
        statusCode: 409,
        statusMessage: 'The organization code already exists.'
      })
    }

    console.error('Organization creation error:', error)

    throw createError({
      statusCode: 500,
      statusMessage: 'Failed to create organization.'
    })
  }
})