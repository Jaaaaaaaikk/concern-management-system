import { readFile } from 'node:fs/promises'
import { send, setHeader } from 'h3'
import db from '../../../../utils/db.js'
import { canReadConcernFile } from '../../../../utils/concern-file-access.js'
import { getConcernUploadPath } from '../../../../utils/concern-uploads.js'
import { requireAuth } from '../../../../utils/require-auth.js'

const allowedImageTypes = new Set(['image/jpeg', 'image/png', 'image/gif', 'image/webp'])

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event)
  const concernId = Number(getRouterParam(event, 'id'))
  const attachmentId = Number(getRouterParam(event, 'attachmentId'))

  if (!Number.isInteger(concernId) || concernId < 1 || !Number.isInteger(attachmentId) || attachmentId < 1) {
    throw createError({ statusCode: 404, statusMessage: 'Attachment not found.' })
  }

  const [rows] = await db.query(
    `
      SELECT
        ca.file_path,
        ca.file_name,
        ca.file_type,
        c.id AS concern_id,
        c.created_by,
        c.assigned_organization_id,
        c.deleted_at,
        creator.organization_id AS creator_organization_id,
        creator_org.deleted_at AS creator_organization_deleted_at,
        assigned_org.deleted_at AS assigned_organization_deleted_at
      FROM concern_attachments ca
      INNER JOIN concerns c ON c.id = ca.concern_id
      INNER JOIN users creator ON creator.id = c.created_by
      LEFT JOIN organizations creator_org ON creator_org.id = creator.organization_id
      LEFT JOIN organizations assigned_org ON assigned_org.id = c.assigned_organization_id
      WHERE ca.id = ?
        AND ca.concern_id = ?
        AND ca.deleted_at IS NULL
      LIMIT 1
    `,
    [attachmentId, concernId]
  )

  const attachment = rows[0]

  if (!attachment || !canReadConcernFile(currentUser, attachment)) {
    throw createError({ statusCode: 404, statusMessage: 'Attachment not found.' })
  }

  if (!allowedImageTypes.has(attachment.file_type)) {
    throw createError({ statusCode: 415, statusMessage: 'Unsupported attachment type.' })
  }

  let data
  try {
    data = await readFile(getConcernUploadPath(attachment.file_path))
  } catch (error) {
    if (error?.code === 'ENOENT') {
      throw createError({ statusCode: 404, statusMessage: 'Attachment file not found.' })
    }
    throw error
  }

  const filename = String(attachment.file_name || 'attachment').replace(/[\r\n"\\]/g, '_')
  setHeader(event, 'Content-Type', attachment.file_type)
  setHeader(event, 'Content-Disposition', `inline; filename="${filename}"`)
  setHeader(event, 'Cache-Control', 'private, no-store')
  setHeader(event, 'X-Content-Type-Options', 'nosniff')

  return send(event, data, attachment.file_type)
})
