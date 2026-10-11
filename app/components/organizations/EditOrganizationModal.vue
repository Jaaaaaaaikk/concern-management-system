<script setup>

import { useBodyScrollLock } from '~/composables/useBodyScrollLock'

const props = defineProps({

    show: {
        type: Boolean,
        default: false
    },

    form: {
        type: Object,
        required: true
    },

    updating: {
        type: Boolean,
        default: false
    }

})

const emit = defineEmits([
    'close',
    'submit'
])

useBodyScrollLock(() => props.show)

</script>

<template>

    <div
        v-if="props.show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 p-2 backdrop-blur-[2px] sm:items-center sm:p-4"
    >

        <div
            class="my-auto max-h-[calc(100dvh-1rem)] w-full max-w-lg overflow-y-auto rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-2rem)]"
        >

            <!-- Header -->
            <div
                class="flex items-center justify-between border-b border-blue-800 bg-linear-to-r from-blue-950 via-blue-900 to-indigo-800 px-4 py-5 text-white sm:px-6 sm:py-6"
            >

                <div class="flex items-center gap-3">

                    <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-white/15 bg-white/10 text-blue-100 shadow-inner">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke-width="1.8" stroke="currentColor" class="h-6 w-6" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652l-9.193 9.193a4.5 4.5 0 0 1-1.897 1.13l-3.24.928.928-3.24a4.5 4.5 0 0 1 1.13-1.897l7.933-7.078ZM19.5 13.5V19.5A1.5 1.5 0 0 1 18 21H5.25A2.25 2.25 0 0 1 3 18.75V6A2.25 2.25 0 0 1 5.25 3.75H12" />
                        </svg>
                    </span>

                    <div>

                    <h3 class="text-lg font-bold tracking-tight text-white">
                        Edit Organization
                    </h3>

                    <p class="mt-1 text-sm text-blue-100/80">
                        Update the selected organization's information.
                    </p>

                    </div>

                </div>

                <button
                    type="button"
                    @click="emit('close')"
                    class="cursor-pointer rounded-lg p-1 text-2xl leading-none text-blue-100 transition hover:bg-white/10 hover:text-white"
                >
                    ×
                </button>

            </div>

            <!-- Form -->
            <form
                @submit.prevent="emit('submit')"
                class="space-y-5 px-4 py-5 sm:px-6 sm:py-6"
            >

                <!-- Name -->
                <div>

                    <label
                        class="mb-2 block text-sm font-medium text-slate-700"
                    >
                        Name
                        <span class="text-red-500">*</span>
                    </label>

                    <input
                        v-model="props.form.name"
                        type="text"
                        placeholder="Enter organization name"
                        required
                        class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-blue-700 focus:ring-2 focus:ring-blue-100"
                    />

                </div>

                <!-- Address -->
                <div>

                    <label
                        class="mb-2 block text-sm font-medium text-slate-700"
                    >
                        Address
                    </label>

                    <textarea
                        v-model="props.form.address"
                        rows="3"
                        placeholder="Enter organization address/location"
                        class="w-full resize-none rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                    ></textarea>

                </div>

                <!-- Description -->
                <div>

                    <label
                        class="mb-2 block text-sm font-medium text-slate-700"
                    >
                        Description
                    </label>

                    <textarea
                        v-model="props.form.description"
                        rows="4"
                        placeholder="Enter organization description"
                        class="w-full resize-none rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                    ></textarea>

                </div>

                <!-- Footer -->
                <div
                    class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end"
                >

                    <button
                        type="button"
                        @click="emit('close')"
                        :disabled="props.updating"
                        class="w-full cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                    >
                        Cancel
                    </button>

                    <button
                        type="submit"
                        :disabled="props.updating"
                        class="w-full cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                    >

                        {{
                            props.updating
                                ? 'Saving...'
                                : 'Save Changes'
                        }}

                    </button>

                </div>

            </form>

        </div>

    </div>

</template>
