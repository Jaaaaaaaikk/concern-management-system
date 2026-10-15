import { randomUUID } from 'node:crypto'
import { readMultipartFormData } from 'h3'
import db from '../../../utils/db.js'
import { removeProfilePhoto, saveProfilePhoto } from '../../../utils/profile-photos.js'
import { requireAuth } from '../../../utils/require-auth.js'

const maxFileSize = 2 * 1024 * 1024

const imageTypes = {
  'image/jpeg': {
    extension: '.jpg',
    matches: (data) =>
      data.length >= 3 &&
      data[0] === 0xff &&
      data[1] === 0xd8 &&
      data[2] === 0xff
  },
  'image/png': {
    extension: '.png',
    matches: (data) =>
      data.length >= 8 &&
      data.subarray(0, 8).equals(
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
      )
  },
  'image/gif': {
    extension: '.gif',
    matches: (data) =>
      data.length >= 6 &&
      ['GIF87a', 'GIF89a'].includes(data.subarray(0, 6).toString('ascii'))
  },
  'image/webp': {
    extension: '.webp',
    matches: (data) =>
      data.length >= 12 &&
      data.subarray(0, 4).toString('ascii') === 'RIFF' &&
      data.subarray(8, 12).toString('ascii') === 'WEBP'
  }
}

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event)

  const userId = Number(getRouterParam(event, 'id'))

  if (!Number.isSafeInteger(userId) || userId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid user ID.'
    })
  }

  if (
    !['superadmin', 'system_admin'].includes(currentUser.role_name) &&
    Number(currentUser.id) !== userId
  ) {
    throw createError({
      statusCode: 403,
      statusMessage: 'You can only update your own profile photo.'
    })
  }

  const formData = await readMultipartFormData(event)

  if (!formData) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid profile photo form data.'
    })
  }

  const photo = formData.find(
    (field) => field.name === 'photo' && field.filename
  )
  const removePhoto = formData.some(
    (field) =>
      field.name === 'remove' &&
      field.data?.toString() === 'true'
  )

  if (Boolean(photo) === removePhoto) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Choose a profile photo or request photo removal.'
    })
  }

  let imageType = null

  if (photo) {
    imageType = imageTypes[photo.type]

    if (!imageType || !imageType.matches(photo.data)) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Upload a valid JPEG, PNG, GIF, or WEBP image.'
      })
    }

    if (photo.data.length > maxFileSize) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Profile photos must be 2 MB or smaller.'
      })
    }
  }

  const [users] = await db.query(
    `
    SELECT profile_photo
    FROM users
    WHERE id = ?
      AND deleted_at IS NULL
    LIMIT 1
    `,
    [userId]
  )

  if (users.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'User not found.'
    })
  }

  if (currentUser.role_name === 'system_admin' && Number(userId) !== Number(currentUser.id)) {
    const [targetRoles] = await db.query(
      `SELECT r.name AS role_name FROM users u INNER JOIN roles r ON r.id = u.role_id WHERE u.id = ? LIMIT 1`,
      [userId]
    )

    if (['superadmin', 'system_admin'].includes(targetRoles[0]?.role_name)) {
      throw createError({
        statusCode: 403,
        statusMessage: 'System Administrators cannot update privileged account photos.'
      })
    }
  }

  const previousPhoto = users[0].profile_photo
  let newPhoto = null
  let newFilePath = null

  if (photo) {
    const filename = `${randomUUID()}${imageType.extension}`
    newPhoto = `/uploads/users/${filename}`
    newFilePath = await saveProfilePhoto(filename, photo.data)
  }

  try {
    await db.query(
      `
      UPDATE users
      SET profile_photo = ?, updated_by = ?
      WHERE id = ?
        AND deleted_at IS NULL
      `,
      [newPhoto, currentUser.id, userId]
    )
  } catch (error) {
    if (newFilePath) {
      try {
        await removeProfilePhoto(newPhoto)
      } catch (cleanupError) {
        if (cleanupError?.code !== 'ENOENT') {
          console.error('Failed to clean up an unlinked profile photo:', cleanupError)
        }
      }
    }

    throw error
  }

  try {
    if (previousPhoto) await removeProfilePhoto(previousPhoto)
  } catch (error) {
    console.error('Failed to remove the replaced profile photo:', error)
  }

  return {
    success: true,
    message: removePhoto
      ? 'Profile photo removed successfully.'
      : 'Profile photo updated successfully.',
    profile_photo: newPhoto ? `/api/users/${userId}/profile-photo` : null
  }
})
