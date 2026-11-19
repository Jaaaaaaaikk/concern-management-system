import { copyFile, mkdir, readFile, readdir, unlink, writeFile } from 'node:fs/promises'
import { constants as fsConstants } from 'node:fs'
import path from 'node:path'

const LEGACY_UPLOAD_DIRECTORIES = [
  path.resolve(process.cwd(), 'public', 'uploads', 'concerns'),
  path.resolve(process.cwd(), '.output', 'public', 'uploads', 'concerns')
]

export function getConcernUploadDirectory() {
  const configuredDirectory = process.env.CONCERN_UPLOAD_DIR?.trim()
  const directory = path.resolve(
    configuredDirectory || path.join(process.cwd(), 'data', 'uploads', 'concerns')
  )

  for (const publicDirectory of [
    path.resolve(process.cwd(), 'public'),
    path.resolve(process.cwd(), '.output', 'public')
  ]) {
    const relativePath = path.relative(publicDirectory, directory)

    if (relativePath === '' || (!relativePath.startsWith('..') && !path.isAbsolute(relativePath))) {
      throw new Error('CONCERN_UPLOAD_DIR must be outside public directories.')
    }
  }

  return directory
}

export function getConcernUploadPath(storedPath) {
  const fileName = path.basename(String(storedPath || ''))

  if (!fileName || fileName === '.' || fileName === '..') {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid attachment path.'
    })
  }

  const directory = getConcernUploadDirectory()
  const filePath = path.resolve(directory, fileName)

  if (path.dirname(filePath) !== directory) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid attachment path.'
    })
  }

  return filePath
}

export async function saveConcernUpload(fileName, data) {
  const filePath = getConcernUploadPath(fileName)
  await mkdir(getConcernUploadDirectory(), { recursive: true })
  await writeFile(filePath, data, { flag: 'wx' })
  return filePath
}

export async function removeConcernUpload(storedPath) {
  const filePath = getConcernUploadPath(storedPath)

  try {
    await unlink(filePath)
  } catch (error) {
    if (error?.code !== 'ENOENT') throw error
  }
}

export async function migratePublicConcernUploads() {
  const targetDirectory = getConcernUploadDirectory()
  await mkdir(targetDirectory, { recursive: true })

  for (const sourceDirectory of LEGACY_UPLOAD_DIRECTORIES) {
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
      const targetPath = getConcernUploadPath(entry.name)

      try {
        await copyFile(sourcePath, targetPath, fsConstants.COPYFILE_EXCL)
        await unlink(sourcePath)
      } catch (error) {
        if (error?.code === 'EEXIST') {
          const [sourceData, targetData] = await Promise.all([
            readFile(sourcePath),
            readFile(targetPath)
          ])

          if (!sourceData.equals(targetData)) {
            throw new Error(`Conflicting public and private concern upload: ${entry.name}`)
          }

          await unlink(sourcePath)
        } else {
          throw error
        }
      }
    }
  }
}
