<script setup>

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
                class="flex items-center justify-between border-b border-slate-200 px-4 py-4 sm:px-6 sm:py-5"
            >

                <div>

                    <h3 class="text-lg font-semibold text-slate-800">
                        Edit Organization
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        Update the selected organization's information.
                    </p>

                </div>

                <button
                    type="button"
                    @click="emit('close')"
                    class="cursor-pointer text-2xl leading-none text-slate-400 hover:text-slate-700"
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
                        class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-emerald-700 focus:ring-2 focus:ring-emerald-100"
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
                        class="w-full cursor-pointer rounded-lg bg-emerald-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-emerald-800 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
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
