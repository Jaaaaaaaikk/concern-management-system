<script setup>
const isNavigating = ref(false)
let showTimer
let hideTimer
let removeBeforeEach
let removeAfterEach
let removeOnError

function finishNavigation() {
  clearTimeout(showTimer)

  if (isNavigating.value) {
    hideTimer = setTimeout(() => {
      isNavigating.value = false
    }, 260)
  }
}

onMounted(() => {
  const router = useRouter()

  removeBeforeEach = router.beforeEach(() => {
    clearTimeout(showTimer)
    clearTimeout(hideTimer)
    showTimer = setTimeout(() => {
      isNavigating.value = true
    }, 120)
  })
  removeAfterEach = router.afterEach(finishNavigation)
  removeOnError = router.onError(finishNavigation)
})

onBeforeUnmount(() => {
  clearTimeout(showTimer)
  clearTimeout(hideTimer)
  removeBeforeEach?.()
  removeAfterEach?.()
  removeOnError?.()
})
</script>

<template>
  <NuxtPage />
  <Transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="-translate-y-2 opacity-0"
    enter-to-class="translate-y-0 opacity-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="translate-y-0 opacity-100"
    leave-to-class="-translate-y-2 opacity-0"
  >
    <div
      v-if="isNavigating"
      class="fixed right-4 top-4 z-[100] flex items-center gap-3 rounded-2xl border border-emerald-900/15 bg-white px-4 py-3 shadow-xl shadow-emerald-950/15"
      role="status"
      aria-live="polite"
      aria-label="Loading the next page"
    >
      <span class="relative flex h-8 w-8 items-center justify-center rounded-xl bg-emerald-900 text-white">
        <svg
          class="h-4 w-4 motion-safe:animate-pulse"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          aria-hidden="true"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 21h18M5 21V7l7-4 7 4v14M9 21v-6h6v6M9 9h.01M15 9h.01" />
        </svg>
        <span class="absolute -right-1 -top-1 h-2.5 w-2.5 animate-ping rounded-full bg-emerald-400 motion-reduce:animate-none" />
      </span>
      <span>
        <span class="block text-sm font-semibold text-emerald-950">One moment</span>
        <span class="block text-xs text-slate-500">Getting things ready…</span>
      </span>
    </div>
  </Transition>
  <ToastNotification />
</template>
