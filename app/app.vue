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
    enter-active-class="nav-loader-enter-active"
    leave-active-class="nav-loader-leave-active"
  >
    <div
      v-if="isNavigating"
      class="pointer-events-none fixed inset-x-0 top-4 z-100 flex justify-center"
      role="status"
      aria-live="polite"
      aria-label="Loading the next page"
    >
      <div class="pointer-events-auto flex items-center gap-3 rounded-2xl border border-blue-900/15 bg-white px-4 py-3 shadow-xl shadow-blue-950/15">
      <span class="relative flex h-12 w-14 shrink-0 items-center justify-center text-blue-800">
        <svg
          class="h-10 w-14"
          viewBox="0 0 32 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.7"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <g class="loading-cat-body">
            <path d="M8 12.5c1.2-2 3.1-3 6.2-3h4.2a4.4 4.4 0 0 1 4.2 3.2l.8 2.8H9.2L8 12.5Z" fill="currentColor" stroke="none" />
            <path d="M18.5 10.1 19 6.6l3 2.3a4.1 4.1 0 0 1 2.8 3.9v1.1h-5.3" fill="currentColor" stroke="none" />
            <path d="m19 6.7 2.5-.3-.2 2.8m-1.5 3.2h.01" />
            <path class="loading-cat-tail" d="M8.6 12.5c-2.8-.2-3-3.7-5.4-3.5-1.3.1-1.5 1.4-.8 2" />
            <path class="loading-cat-leg loading-cat-leg-back" d="m11 15.2-.8 3.3 2.2 1.2m1.1-4.5-.4 3.4 2 1.1" />
            <path class="loading-cat-leg loading-cat-leg-front" d="m18 15.2.6 3.3 2.2.8m1.1-4.1 1.1 3.1 2.3.3" />
          </g>
        </svg>
      </span>
      <span>
        <span class="block text-sm font-semibold text-blue-950">One moment</span>
        <span class="block text-xs text-slate-500">Getting things ready…</span>
      </span>
      </div>
    </div>
  </Transition>
  <ToastNotification />
</template>

<style scoped>
.nav-loader-enter-active {
  animation: loader-drop-in 420ms cubic-bezier(0.18, 0.89, 0.32, 1.28) both;
}

.nav-loader-leave-active {
  animation: loader-climb-out 260ms cubic-bezier(0.4, 0, 1, 1) both;
}

@keyframes loader-drop-in {
  0% {
    opacity: 0;
    translate: 0 -140%;
  }

  72% {
    opacity: 1;
    translate: 0 8%;
  }

  100% {
    opacity: 1;
    translate: 0 0;
  }
}

@keyframes loader-climb-out {
  from {
    opacity: 1;
    translate: 0 0;
  }

  to {
    opacity: 0;
    translate: 0 -140%;
  }
}

.loading-cat-body {
  transform-origin: 50% 70%;
  animation: cat-run-bob 280ms ease-in-out infinite alternate;
}

.loading-cat-leg {
  transform-box: fill-box;
  transform-origin: top center;
  animation: cat-run-legs 180ms ease-in-out infinite alternate;
}

.loading-cat-leg-front {
  animation-delay: 90ms;
}

.loading-cat-tail {
  transform-box: fill-box;
  transform-origin: right center;
  animation: cat-run-tail 320ms ease-in-out infinite alternate;
}

@keyframes cat-run-bob {
  from { transform: translateY(0); }
  to { transform: translateY(-1.5px); }
}

@keyframes cat-run-legs {
  from { transform: rotate(-22deg); }
  to { transform: rotate(24deg); }
}

@keyframes cat-run-tail {
  from { transform: rotate(-14deg); }
  to { transform: rotate(18deg); }
}

@media (prefers-reduced-motion: reduce) {
  .nav-loader-enter-active,
  .nav-loader-leave-active,
  .loading-cat-body,
  .loading-cat-leg,
  .loading-cat-tail {
    animation: none;
  }
}
</style>
