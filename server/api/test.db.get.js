import db from '../utils/db.js'

export default defineEventHandler(async () => {
  try {
    const [rows] = await db.query('SELECT 1 AS connected')

    return {
      success: true,
      message: 'MySQL connection successful',
      data: rows
    }
  } catch (error) {
    console.error('Database connection error:', error)

    return {
      success: false,
      message: 'MySQL connection failed',
      error: error.message
    }
  }
})