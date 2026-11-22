import db from '../../../utils/db.js'
import { requireRole } from '../../../utils/require-auth.js'

function parseDate(value, fieldName) {
  if (!value) return null

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    throw createError({
      statusCode: 400,
      statusMessage: `Invalid ${fieldName}.`
    })
  }

  return date
}

export default defineEventHandler(async (event) => {
  await requireRole(event, ['superadmin'])
  const body = await readBody(event)
  const mode = ['range', 'all'].includes(body?.mode) ? body.mode : 'selected'

  const selectedIds = Array.isArray(body?.session_ids)
    ? [...new Set(body.session_ids.map(Number).filter((id) => Number.isInteger(id) && id > 0))]
    : []
  const dateFrom = parseDate(body?.date_from, 'start date')
  const dateTo = parseDate(body?.date_to, 'end date')

  if (mode === 'selected' && selectedIds.length === 0) {
    throw createError({ statusCode: 400, statusMessage: 'Select at least one login-history record.' })
  }

  if (mode === 'range') {
    if (!dateFrom || !dateTo) {
      throw createError({ statusCode: 400, statusMessage: 'A start date and end date are required.' })
    }
    if (dateFrom > dateTo) {
      throw createError({ statusCode: 400, statusMessage: 'The start date cannot be after the end date.' })
    }
  }

  const connection = await db.getConnection()

  try {
    await connection.beginTransaction()

    let sql
    let params

    if (mode === 'selected') {
      const placeholders = selectedIds.map(() => '?').join(',')
      sql = `
        DELETE FROM user_sessions
        WHERE id IN (${placeholders})
          AND (revoked_at IS NOT NULL OR expires_at <= NOW())
      `
      params = selectedIds
    } else if (mode === 'range') {
      sql = `
        DELETE FROM user_sessions
        WHERE created_at >= ?
          AND created_at <= ?
          AND (revoked_at IS NOT NULL OR expires_at <= NOW())
      `
      params = [dateFrom, dateTo]
    } else {
      sql = `
        DELETE FROM user_sessions
        WHERE revoked_at IS NOT NULL OR expires_at <= NOW()
      `
      params = []
    }

    const [result] = await connection.query(sql, params)
    const deletedCount = Number(result.affectedRows || 0)

    await connection.query(
      `
        INSERT INTO login_history_deletion_audit
          (deletion_mode, deleted_count, date_from, date_to)
        VALUES (?, ?, ?, ?)
      `,
      [
        mode,
        deletedCount,
        mode === 'range' ? dateFrom : null,
        mode === 'range' ? dateTo : null
      ]
    )

    await connection.commit()

    return {
      success: true,
      deletedCount,
      message: `${deletedCount} login history record${deletedCount === 1 ? '' : 's'} cleared successfully.`
    }
  } catch (error) {
    await connection.rollback()
    throw error
  } finally {
    connection.release()
  }
})
