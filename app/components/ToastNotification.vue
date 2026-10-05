<script setup>
import { watch } from 'vue'

const { toast, dismissToast } = useToast()
let dismissTimeout = null

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
        }, toast.value.type === 'error' ? 6000 : 4000)
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
    <div class="pointer-events-none fixed inset-x-0 top-4 z-[200] flex justify-center px-4 sm:justify-end sm:px-6 sm:pt-2">
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
                class="pointer-events-auto flex w-full max-w-md items-start gap-3 overflow-hidden rounded-2xl border bg-white p-4 shadow-[0_18px_50px_-18px_rgba(15,23,42,0.45)]"
                :class="toast.type === 'error' ? 'border-red-200' : 'border-emerald-200'"
                :role="toast.type === 'error' ? 'alert' : 'status'"
                :aria-live="toast.type === 'error' ? 'assertive' : 'polite'"
            >
                <span
                    class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl"
                    :class="toast.type === 'error' ? 'bg-red-50 text-red-600' : 'bg-emerald-50 text-emerald-700'"
                    aria-hidden="true"
                >
                    <svg v-if="toast.type === 'error'" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m0 3.75h.008v.008H12v-.008z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                    </svg>
                    <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                    </svg>
                </span>

                <div class="min-w-0 flex-1 pt-0.5">
                    <p class="text-sm font-semibold text-slate-900">
                        {{ toast.type === 'error' ? 'Something went wrong' : 'Success' }}
                    </p>
                    <p class="mt-1 text-sm leading-5 text-slate-600">
                        {{ toast.message }}
                    </p>
                </div>

                <button
                    type="button"
                    class="rounded-lg p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-700/30"
                    aria-label="Dismiss notification"
                    @click="dismissToast(toast.id)"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="m6 6 12 12M18 6 6 18" />
                    </svg>
                </button>
            </div>
        </Transition>
    </div>
</template>
