import { autoCloseResolvedConcerns } from "../utils/auto-close-resolved-concerns.js";

const AUTO_CLOSE_INTERVAL_MS = 60 * 60 * 1000;
let autoCloseTimer;

export default defineNitroPlugin((nitroApp) => {
  if (autoCloseTimer) {
    return;
  }

  let cleanupInProgress = false;

  const runAutoClose = async () => {
    if (cleanupInProgress) {
      return;
    }

    cleanupInProgress = true;

    try {
      const closedCount = await autoCloseResolvedConcerns();

      if (closedCount > 0) {
        console.info(
          `Automatically closed ${closedCount} concern(s) that remained resolved for seven days.`,
        );
      }
    } catch (error) {
      console.error("Automatic resolved-concern closure failed:", error);
    } finally {
      cleanupInProgress = false;
    }
  };

  // Catch up after restarts, then check hourly.
  void runAutoClose();

  autoCloseTimer = setInterval(() => {
    void runAutoClose();
  }, AUTO_CLOSE_INTERVAL_MS);

  autoCloseTimer.unref?.();

  nitroApp.hooks.hook("close", () => {
    clearInterval(autoCloseTimer);
    autoCloseTimer = undefined;
  });
});
