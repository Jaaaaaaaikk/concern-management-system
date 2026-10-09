import { purgeExpiredTrashedConcerns } from "../utils/purge-concern.js";

const CLEANUP_INTERVAL_MS = 60 * 60 * 1000;
let cleanupTimer;

export default defineNitroPlugin((nitroApp) => {
  if (cleanupTimer) {
    return;
  }

  let cleanupInProgress = false;

  const runCleanup = async () => {
    if (cleanupInProgress) {
      return;
    }

    cleanupInProgress = true;

    try {
      const deletedCount = await purgeExpiredTrashedConcerns();

      if (deletedCount > 0) {
        console.info(
          `Automatically purged ${deletedCount} concern(s) after 30 days in trash.`,
        );
      }
    } catch (error) {
      console.error("Automatic concern trash cleanup failed:", error);
    } finally {
      cleanupInProgress = false;
    }
  };

  // Run once at startup to catch items that expired while the server was down.
  void runCleanup();

  cleanupTimer = setInterval(() => {
    void runCleanup();
  }, CLEANUP_INTERVAL_MS);

  cleanupTimer.unref?.();

  nitroApp.hooks.hook("close", () => {
    clearInterval(cleanupTimer);
    cleanupTimer = undefined;
  });
});
