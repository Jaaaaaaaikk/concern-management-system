import { purgeExpiredNotifications } from '../utils/purge-expired-notifications.js'

const CLEANUP_INTERVAL_MS = 24 * 60 * 60 * 1000
let cleanupTimer

export default defineNitroPlugin((nitroApp) => {
  if (cleanupTimer) return

  let cleanupInProgress = false

  const runCleanup = async () => {
    if (cleanupInProgress) return

    cleanupInProgress = true

    try {
      const deletedCount = await purgeExpiredNotifications()

      if (deletedCount > 0) {
        console.info(`Automatically purged ${deletedCount} read notification(s) older than 90 days.`)
      }
    } catch (error) {
      console.error('Automatic notification cleanup failed:', error)
    } finally {
      cleanupInProgress = false
    }
  }

  // Catch up after a restart, then check once per day.
  void runCleanup()

  cleanupTimer = setInterval(() => {
    void runCleanup()
  }, CLEANUP_INTERVAL_MS)

  cleanupTimer.unref?.()

  nitroApp.hooks.hook('close', () => {
    clearInterval(cleanupTimer)
    cleanupTimer = undefined
  })
})
