import { copyFile, mkdir, readFile, readdir, unlink, writeFile } from 'node:fs/promises'
import { constants as fsConstants } from 'node:fs'
import path from 'node:path'

const LEGACY_PHOTO_DIRECTORIES = [
  path.resolve(process.cwd(), 'public', 'uploads', 'users'),
  path.resolve(process.cwd(), '.output', 'public', 'uploads', 'users')
]

export function getProfilePhotoDirectory() {
  const configuredDirectory = process.env.PROFILE_PHOTO_DIR?.trim()
  const directory = path.resolve(
    configuredDirectory || path.join(process.cwd(), 'data', 'uploads', 'users')
  )

  for (const publicDirectory of [
    path.resolve(process.cwd(), 'public'),
    path.resolve(process.cwd(), '.output', 'public')
  ]) {
    const relativePath = path.relative(publicDirectory, directory)

    if (relativePath === '' || (!relativePath.startsWith('..') && !path.isAbsolute(relativePath))) {
      throw new Error('PROFILE_PHOTO_DIR must be outside public directories.')
    }
  }

  return directory
}

export function getProfilePhotoPath(storedPath) {
  const fileName = path.basename(String(storedPath || ''))

  if (!fileName || fileName === '.' || fileName === '..') {
    throw createError({ statusCode: 400, statusMessage: 'Invalid profile photo path.' })
  }

  const directory = getProfilePhotoDirectory()
  const filePath = path.resolve(directory, fileName)

  if (path.dirname(filePath) !== directory) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid profile photo path.' })
  }

  return filePath
}

export async function saveProfilePhoto(fileName, data) {
  const directory = getProfilePhotoDirectory()
  await mkdir(directory, { recursive: true })
  const filePath = getProfilePhotoPath(fileName)
  await writeFile(filePath, data, { flag: 'wx' })
  return filePath
}

export async function removeProfilePhoto(storedPath) {
  const filePath = getProfilePhotoPath(storedPath)

  try {
    await unlink(filePath)
  } catch (error) {
    if (error?.code !== 'ENOENT') throw error
  }
}

export async function migratePublicProfilePhotos() {
  const targetDirectory = getProfilePhotoDirectory()
  await mkdir(targetDirectory, { recursive: true })

  for (const sourceDirectory of LEGACY_PHOTO_DIRECTORIES) {
    let entries

    try {
      entries = await readdir(sourceDirectory, { withFileTypes: true })
    } catch (error) {
      if (error?.code === 'ENOENT') continue
      throw error
    }

    for (const entry of entries) {
      if (!entry.isFile()) continue

      const sourcePath = path.join(sourceDirectory, entry.name)
      const targetPath = getProfilePhotoPath(entry.name)

      try {
        await copyFile(sourcePath, targetPath, fsConstants.COPYFILE_EXCL)
        await unlink(sourcePath)
      } catch (error) {
        if (error?.code !== 'EEXIST') throw error

        const [sourceData, targetData] = await Promise.all([
          readFile(sourcePath),
          readFile(targetPath)
        ])

        if (!sourceData.equals(targetData)) {
          throw new Error(`Conflicting public and private profile photo: ${entry.name}`)
        }

        await unlink(sourcePath)
      }
    }
  }
}
