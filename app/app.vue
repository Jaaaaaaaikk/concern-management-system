<script setup>
const isNavigating = ref(false)
const isSessionRevoked = ref(false)
const revokedProgress = ref(0)
const route = useRoute()
const currentUser = useState('current-user', () => null)
let showTimer
let hideTimer
let removeBeforeEach
let removeAfterEach
let removeOnError
let revokedTimer = null

function finishNavigation() {
  clearTimeout(showTimer)

  if (isNavigating.value) {
    hideTimer = setTimeout(() => {
      isNavigating.value = false
    }, 260)
  }
}

function startRevokedRedirect() {
  if (isSessionRevoked.value) {
    return
  }

  isSessionRevoked.value = true
  revokedProgress.value = 0

  if (route.query.revoked === '1') {
    const query = { ...route.query }
    delete query.revoked
    useRouter().replace({
      path: route.path,
      query,
      hash: route.hash
    })
  }

  revokedTimer = setInterval(() => {
    revokedProgress.value = Math.min(100, revokedProgress.value + 8)

    if (revokedProgress.value >= 100) {
      clearInterval(revokedTimer)
      revokedTimer = null
      navigateTo('/login').finally(() => {
        isSessionRevoked.value = false
        revokedProgress.value = 0
      })
    }
  }, 90)
}

function showRevokedSessionOverlay() {
  if (isSessionRevoked.value) {
    return
  }

  startRevokedRedirect()
}

onMounted(() => {
  const router = useRouter()

  if (route.query.revoked === '1') {
    startRevokedRedirect()
  }

  const nuxtApp = useNuxtApp()
  const originalFetch = nuxtApp.$fetch

  nuxtApp.$fetch = (...args) => {
    return originalFetch(...args).catch((error) => {
      const statusCode = Number(error?.statusCode ?? error?.response?.status ?? 0)

      const statusMessage = error?.data?.statusMessage ?? error?.statusMessage

      if (statusCode === 401 && statusMessage === 'SESSION_REVOKED') {
        showRevokedSessionOverlay()
      }

      throw error
    })
  }

  removeBeforeEach = router.beforeEach(() => {
    clearTimeout(showTimer)
    clearTimeout(hideTimer)
    showTimer = setTimeout(() => {
      isNavigating.value = true
    }, 120)
  })
  removeAfterEach = router.afterEach((to) => {
    if (to.query.revoked === '1') {
      startRevokedRedirect()
    }

    finishNavigation()
  })
  removeOnError = router.onError(finishNavigation)
})

onBeforeUnmount(() => {
  clearTimeout(showTimer)
  clearTimeout(hideTimer)
  if (revokedTimer) {
    clearInterval(revokedTimer)
    revokedTimer = null
  }
  removeBeforeEach?.()
  removeAfterEach?.()
  removeOnError?.()
})
</script>

<template>
  <NuxtPage />
  <HelpGuideModal :current-user="currentUser" />
  <Transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="transition duration-150 ease-in"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div
      v-if="isSessionRevoked"
      class="fixed inset-0 z-[200] flex items-center justify-center bg-slate-950/75 backdrop-blur-sm"
    >
      <div class="flex w-full max-w-sm flex-col items-center rounded-2xl border border-slate-200 bg-white/95 px-7 py-6 shadow-2xl">
        <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-red-100 text-red-700">
          <svg
            class="h-8 w-8 animate-[spin_1s_linear_infinite]"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 0 1 14.9-4.7L18.5 9.5A6 6 0 0 0 6 12h-2Zm2 0a8 8 0 0 1 14.9 4.7L18.5 14.5A6 6 0 0 0 6 12h-2Z"></path>
          </svg>
        </div>

        <p class="text-lg font-semibold text-slate-900">Session revoked</p>
        <p class="mt-1 text-center text-sm text-slate-500">Your session has been terminated. You are being returned to the login screen.</p>

        <div class="mt-5 w-full">
          <div class="mb-2 flex items-center justify-between text-[11px] font-medium uppercase tracking-[0.18em] text-slate-500">
            <span>Redirecting</span>
            <span>{{ revokedProgress }}%</span>
          </div>
          <div class="h-2.5 w-full overflow-hidden rounded-full bg-slate-200">
            <div
              class="h-full rounded-full bg-gradient-to-r from-red-600 via-orange-500 to-amber-400 transition-all duration-75 ease-linear"
              :style="{ width: `${revokedProgress}%` }"
            ></div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
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
      <span class="relative flex h-12 w-14 shrink-0 items-center justify-center text-orange-500">
        <svg
          class="h-10 w-14"
          viewBox="0 0 64 48"
          fill="none"
          aria-hidden="true"
        >
          <g class="loading-cat-body">
            <ellipse cx="31" cy="29" rx="15" ry="9" fill="currentColor" />
            <path d="M37 20L39 10L46 16L53 13L54 24C54 30 50 34 45 34H42C37 34 34 29 37 20Z" fill="currentColor" />
            <circle cx="48" cy="22" r="1.5" fill="white" />
          </g>
          <path class="loading-cat-tail" d="M14 29C9 29 7 25 9 21C11 17 15 18 17 21" stroke="currentColor" stroke-width="4" stroke-linecap="round" />
          <g class="loading-cat-leg loading-cat-leg-back" stroke="currentColor" stroke-width="3.5" stroke-linecap="round">
            <path d="M23 33L20 41M30 34L28 41" />
          </g>
          <g class="loading-cat-leg loading-cat-leg-front" stroke="currentColor" stroke-width="3.5" stroke-linecap="round">
            <path d="M41 33L39 41M47 32L49 40" />
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
