export function useStickyHeader(threshold = 96) {
    const isSticky = ref(false)

    function updateStickyState() {
        const scrollY = window.scrollY

        if (!isSticky.value && scrollY > threshold) {
            isSticky.value = true
        } else if (isSticky.value && scrollY <= 24) {
            isSticky.value = false
        }
    }

    onMounted(() => {
        updateStickyState()
        window.addEventListener('scroll', updateStickyState, { passive: true })
    })

    onBeforeUnmount(() => {
        window.removeEventListener('scroll', updateStickyState)
    })

    return isSticky
}
