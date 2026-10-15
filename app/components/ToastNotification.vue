<script setup>
import { computed, watch } from 'vue'

const { toast, dismissToast } = useToast()
let dismissTimeout = null

const variants = {
    success: {
        title: 'Success!',
        classes: 'border-green-200 border-l-green-700 bg-green-50',
        iconClasses: 'fill-green-700'
    },
    warning: {
        title: 'Please note',
        classes: 'border-yellow-200 border-l-yellow-700 bg-yellow-50',
        iconClasses: 'fill-yellow-700'
    },
    error: {
        title: 'Something went wrong',
        classes: 'border-red-200 border-l-red-700 bg-red-50',
        iconClasses: 'fill-red-700'
    },
    info: {
        title: 'Information',
        classes: 'border-blue-200 border-l-blue-700 bg-blue-50',
        iconClasses: 'fill-blue-700'
    }
}

const activeVariant = computed(() =>
    variants[toast.value.type] || variants.info
)

watch(
    () => toast.value.id,
    () => {
        if (dismissTimeout) {
            clearTimeout(dismissTimeout)
        }

        if (!toast.value.message) {
            return
        }

        const toastId = toast.value.id
        dismissTimeout = setTimeout(() => {
            dismissToast(toastId)
            dismissTimeout = null
        }, ['error', 'warning'].includes(toast.value.type) ? 6000 : 4000)
    },
    { immediate: true }
)

onBeforeUnmount(() => {
    if (dismissTimeout) {
        clearTimeout(dismissTimeout)
    }
})
</script>

<template>
    <Teleport to="body">
    <div class="pointer-events-none fixed inset-x-0 top-4 z-200 flex justify-center px-4 sm:justify-end sm:px-6 sm:pt-2">
        <Transition
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="-translate-y-2 opacity-0"
            enter-to-class="translate-y-0 opacity-100"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="translate-y-0 opacity-100"
            leave-to-class="-translate-y-2 opacity-0"
        >
            <div
                v-if="toast.message"
                class="pointer-events-auto relative flex w-full max-w-sm items-start gap-2.5 rounded-md border border-l-4 p-4 shadow-lg"
                :class="activeVariant.classes"
                :role="['error', 'warning'].includes(toast.type) ? 'alert' : 'status'"
                :aria-live="['error', 'warning'].includes(toast.type) ? 'assertive' : 'polite'"
            >
                <svg v-if="toast.type === 'success'" xmlns="http://www.w3.org/2000/svg" class="mt-0.5 size-4.5 shrink-0 overflow-visible" :class="activeVariant.iconClasses" viewBox="0 0 330 330" aria-hidden="true">
                    <path d="M165 0C74.019 0 0 74.019 0 165s74.019 165 165 165 165-74.019 165-165S255.981 0 165 0m0 300c-74.44 0-135-60.561-135-135S90.56 30 165 30s135 60.561 135 135-60.561 135-135 135" />
                    <path d="m226.872 106.664-84.854 84.853-38.89-38.891c-5.857-5.857-15.355-5.858-21.213-.001-5.858 5.858-5.858 15.355 0 21.213l49.496 49.498a15 15 0 0 0 10.606 4.394h.001c3.978 0 7.793-1.581 10.606-4.393l95.461-95.459c5.858-5.858 5.858-15.355 0-21.213s-15.355-5.859-21.213-.001" />
                </svg>
                <svg v-else-if="toast.type === 'warning'" xmlns="http://www.w3.org/2000/svg" class="mt-0.5 size-4.5 shrink-0 overflow-visible" :class="activeVariant.iconClasses" viewBox="0 0 486.463 486.463" aria-hidden="true">
                    <path d="M243.225 333.382c-13.6 0-25 11.4-25 25s11.4 25 25 25c13.1 0 25-11.4 24.4-24.4.6-14.3-10.7-25.6-24.4-25.6" />
                    <path d="M474.625 421.982c15.7-27.1 15.8-59.4.2-86.4l-156.6-271.2c-15.5-27.3-43.5-43.5-74.9-43.5s-59.4 16.3-74.9 43.4l-156.8 271.5c-15.6 27.3-15.5 59.8.3 86.9 15.6 26.8 43.5 42.9 74.7 42.9h312.8c31.3 0 59.4-16.3 75.2-43.6m-34-19.6c-8.7 15-24.1 23.9-41.3 23.9h-312.8c-17 0-32.3-8.7-40.8-23.4-8.6-14.9-8.7-32.7-.1-47.7l156.8-271.4c8.5-14.9 23.7-23.7 40.9-23.7 17.1 0 32.4 8.9 40.9 23.8l156.7 271.4c8.4 14.6 8.3 32.2-.3 47.1" />
                    <path d="M237.025 157.882c-11.9 3.4-19.3 14.2-19.3 27.3.6 7.9 1.1 15.9 1.7 23.8 1.7 30.1 3.4 59.6 5.1 89.7.6 10.2 8.5 17.6 18.7 17.6s18.2-7.9 18.7-18.2c0-6.2 0-11.9.6-18.2 1.1-19.3 2.3-38.6 3.4-57.9.6-12.5 1.7-25 2.3-37.5 0-4.5-.6-8.5-2.3-12.5-5.1-11.2-17-16.9-28.9-14.1" />
                </svg>
                <svg v-else-if="toast.type === 'error'" xmlns="http://www.w3.org/2000/svg" class="mt-0.5 size-4.5 shrink-0 overflow-visible" :class="activeVariant.iconClasses" viewBox="0 0 512 512" aria-hidden="true">
                    <path d="M256 0C114.508 0 0 114.497 0 256c0 141.493 114.497 256 256 256 141.492 0 256-114.497 256-256C512 114.507 397.503 0 256 0m0 472c-119.384 0-216-96.607-216-216 0-119.385 96.607-216 216-216 119.384 0 216 96.607 216 216 0 119.384-96.607 216-216 216" />
                    <path d="M343.586 315.302 284.284 256l59.302-59.302c7.81-7.81 7.811-20.473.001-28.284-7.812-7.811-20.475-7.81-28.284 0L256 227.716l-59.303-59.302c-7.809-7.811-20.474-7.811-28.284 0s-7.81 20.474.001 28.284L227.716 256l-59.302 59.302c-7.811 7.811-7.812 20.474-.001 28.284 7.813 7.812 20.476 7.809 28.284 0L256 284.284l59.303 59.302c7.808 7.81 20.473 7.811 28.284 0s7.81-20.474-.001-28.284" />
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" class="mt-0.5 size-4.5 shrink-0 overflow-visible" :class="activeVariant.iconClasses" viewBox="0 0 330 330" aria-hidden="true">
                    <path d="M165 0C74.019 0 0 74.02 0 165.001S74.019 330 165 330s165-74.018 165-164.999S255.981 0 165 0m0 300c-74.44 0-135-60.56-135-134.999S90.56 30 165 30s135 60.562 135 135.001S239.439 300 165 300" />
                    <path d="M164.998 70c-11.026 0-19.996 8.976-19.996 20.009 0 11.023 8.97 19.991 19.996 19.991s19.996-8.968 19.996-19.991c0-11.033-8.97-20.009-19.996-20.009m.002 70c-8.284 0-15 6.716-15 15v90c0 8.284 6.716 15 15 15s15-6.716 15-15v-90c0-8.284-6.716-15-15-15" />
                </svg>

                <div class="min-w-0 flex-1">
                    <p class="text-sm font-medium leading-tight text-slate-900">
                        {{ activeVariant.title }}
                    </p>
                    <p class="mt-1 text-xs leading-5 text-slate-600">
                        {{ toast.message }}
                    </p>
                </div>

                <button
                    type="button"
                    class="ml-auto flex shrink-0 items-center rounded opacity-70 transition hover:opacity-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500"
                    aria-label="Dismiss alert"
                    @click="dismissToast(toast.id)"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" class="size-2.5 fill-slate-500" aria-hidden="true" viewBox="0 0 329.269 329">
                        <path d="M194.8 164.77 323.013 36.555c8.343-8.34 8.343-21.825 0-30.164-8.34-8.34-21.825-8.34-30.164 0L164.633 134.605 36.422 6.391c-8.344-8.34-21.824-8.34-30.164 0-8.344 8.34-8.344 21.824 0 30.164l128.21 128.215L6.259 292.984c-8.344 8.34-8.344 21.825 0 30.164a21.27 21.27 0 0 0 15.082 6.25c5.46 0 10.922-2.09 15.082-6.25l128.21-128.214 128.216 128.214a21.27 21.27 0 0 0 15.082 6.25c5.46 0 10.922-2.09 15.082-6.25 8.343-8.34 8.343-21.824 0-30.164z" />
                    </svg>
                </button>
            </div>
        </Transition>
    </div>
    </Teleport>
</template>
