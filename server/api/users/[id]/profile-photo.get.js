import { readFile } from 'node:fs/promises'
import { send, setHeader } from 'h3'
import db from '../../../utils/db.js'
import { getProfilePhotoPath } from '../../../utils/profile-photos.js'
import { requireAuth } from '../../../utils/require-auth.js'

const allowedImageTypes = new Set(['image/jpeg', 'image/png', 'image/gif', 'image/webp'])

export default defineEventHandler(async (event) => {
  await requireAuth(event)

  const userId = Number(getRouterParam(event, 'id'))
  if (!Number.isSafeInteger(userId) || userId <= 0) {
    throw createError({ statusCode: 404, statusMessage: 'Profile photo not found.' })
  }

  const [rows] = await db.query(
    `
      SELECT profile_photo
      FROM users
      WHERE id = ?
        AND deleted_at IS NULL
        AND status = 'active'
      LIMIT 1
    `,
    [userId]
  )

  const photoPath = rows[0]?.profile_photo
  if (!photoPath) {
    throw createError({ statusCode: 404, statusMessage: 'Profile photo not found.' })
  }

  const extension = String(photoPath).toLowerCase().split('.').pop()
  const contentType = {
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    png: 'image/png',
    gif: 'image/gif',
    webp: 'image/webp'
  }[extension]

  if (!allowedImageTypes.has(contentType)) {
    throw createError({ statusCode: 415, statusMessage: 'Unsupported profile photo type.' })
  }

  let data
  try {
    data = await readFile(getProfilePhotoPath(photoPath))
  } catch (error) {
    if (error?.code === 'ENOENT') {
      throw createError({ statusCode: 404, statusMessage: 'Profile photo not found.' })
    }
    throw error
  }

  setHeader(event, 'Content-Type', contentType)
  setHeader(event, 'Content-Disposition', 'inline')
  setHeader(event, 'Cache-Control', 'private, no-store')
  setHeader(event, 'X-Content-Type-Options', 'nosniff')

  return send(event, data, contentType)
})
