import db from '../../utils/db.js'
import { requireRole } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])

  const id = Number(getRouterParam(event, 'id'))
  const body = await readBody(event)
  const status = body?.status

  if (!Number.isInteger(id) || id < 1) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid concern category.'
    })
  }

  if (!['active', 'inactive'].includes(status)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Status must be active or inactive.'
    })
  }

  const [result] = await db.query(
    'UPDATE concern_types SET status = ? WHERE id = ?',
    [status, id]
  )

  if (result.affectedRows === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'Concern category not found.'
    })
  }

  return {
    success: true,
    message: status === 'active'
      ? 'Concern category restored successfully.'
      : 'Concern category removed from active use.'
  }
})