import { mkdir, unlink, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { randomUUID } from 'node:crypto'
import { readMultipartFormData } from 'h3'
import db from '../../../utils/db.js'
import { requireAuth } from '../../../utils/require-auth.js'

const uploadDirectory = path.resolve(process.cwd(), 'public', 'uploads', 'users')
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

async function removeStoredPhoto(photoPath) {
  if (typeof photoPath !== 'string' || !photoPath.startsWith('/uploads/users/')) {
    return
  }

  const filename = photoPath.slice('/uploads/users/'.length)

  if (!filename || path.basename(filename) !== filename) {
    return
  }

  const filePath = path.resolve(uploadDirectory, filename)

  if (!filePath.startsWith(`${uploadDirectory}${path.sep}`)) {
    return
  }

  try {
    await unlink(filePath)
  } catch (error) {
    if (error?.code !== 'ENOENT') {
      throw error
    }
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
    currentUser.role_name !== 'superadmin' &&
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

  const previousPhoto = users[0].profile_photo
  let newPhoto = null
  let newFilePath = null

  if (photo) {
    const filename = `${randomUUID()}${imageType.extension}`
    newPhoto = `/uploads/users/${filename}`
    newFilePath = path.resolve(uploadDirectory, filename)

    await mkdir(uploadDirectory, { recursive: true })
    await writeFile(newFilePath, photo.data, { flag: 'wx' })
  }

  try {
    await db.query(
      `
      UPDATE users
      SET profile_photo = ?
      WHERE id = ?
        AND deleted_at IS NULL
      `,
      [newPhoto, userId]
    )
  } catch (error) {
    if (newFilePath) {
      try {
        await unlink(newFilePath)
      } catch (cleanupError) {
        if (cleanupError?.code !== 'ENOENT') {
          console.error('Failed to clean up an unlinked profile photo:', cleanupError)
        }
      }
    }

    throw error
  }

  try {
    await removeStoredPhoto(previousPhoto)
  } catch (error) {
    console.error('Failed to remove the replaced profile photo:', error)
  }

  return {
    success: true,
    message: removePhoto
      ? 'Profile photo removed successfully.'
      : 'Profile photo updated successfully.',
    profile_photo: newPhoto
  }
})
