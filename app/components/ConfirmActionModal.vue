<script setup>
const props = defineProps({
    show: { type: Boolean, default: false },
    title: { type: String, default: 'Confirm action' },
    message: { type: String, default: 'Are you sure you want to continue?' },
    confirmLabel: { type: String, default: 'Confirm' },
    cancelLabel: { type: String, default: 'Go back' },
    loading: { type: Boolean, default: false },
    tone: { type: String, default: 'primary' }
})

const emit = defineEmits(['confirm', 'cancel'])
</script>

<template>
    <Transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
    >
        <div
            v-if="props.show"
            class="fixed inset-0 z-70 flex items-center justify-center bg-slate-950/55 p-4 backdrop-blur-sm"
            @click.self="!props.loading && emit('cancel')"
        >
            <section
                class="w-full max-w-md rounded-2xl border border-white/60 bg-white p-6 shadow-2xl sm:p-7"
                role="dialog"
                aria-modal="true"
                :aria-label="props.title"
            >
                <div class="flex items-start gap-4">
                    <span
                        class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl"
                        :class="props.tone === 'danger' ? 'bg-red-50 text-red-700' : 'bg-blue-50 text-blue-800'"
                        aria-hidden="true"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75m6 .75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                        </svg>
                    </span>
                    <div class="min-w-0">
                        <h3 class="text-lg font-semibold text-slate-900">{{ props.title }}</h3>
                        <p class="mt-2 whitespace-pre-line text-sm leading-6 text-slate-600">{{ props.message }}</p>
                    </div>
                </div>
                <div class="mt-7 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                    <button
                        type="button"
                        class="cursor-pointer rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                        :disabled="props.loading"
                        @click="emit('cancel')"
                    >
                        {{ props.cancelLabel }}
                    </button>
                    <button
                        type="button"
                        class="cursor-pointer rounded-lg px-5 py-2.5 text-sm font-semibold text-white transition disabled:cursor-not-allowed disabled:opacity-60"
                        :class="props.tone === 'danger' ? 'bg-red-700 hover:bg-red-800' : 'bg-blue-900 hover:bg-blue-800'"
                        :disabled="props.loading"
                        @click="emit('confirm')"
                    >
                        {{ props.loading ? 'Saving…' : props.confirmLabel }}
                    </button>
                </div>
            </section>
        </div>
    </Transition>
</template>
