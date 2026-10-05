import bcrypt from 'bcryptjs'

export async function hashPassword(password) {
  return await bcrypt.hash(password, 12)
}

export async function verifyPassword(password, passwordHash) {
  return await bcrypt.compare(password, passwordHash)
}