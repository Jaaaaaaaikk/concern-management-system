import { watch, onBeforeUnmount } from 'vue'

export function useBodyScrollLock(shouldLock) {
    let previousOverflow = null

    function lock() {
        if (typeof document === 'undefined' || previousOverflow !== null) {
            return
        }

        previousOverflow = document.body.style.overflow
        document.body.style.overflow = 'hidden'
    }

    function unlock() {
        if (typeof document === 'undefined' || previousOverflow === null) {
            return
        }

        document.body.style.overflow = previousOverflow
        previousOverflow = null
    }

    watch(shouldLock, (isLocked) => {
        if (isLocked) {
            lock()
        } else {
            unlock()
        }
    }, { immediate: true })

    onBeforeUnmount(unlock)
}
