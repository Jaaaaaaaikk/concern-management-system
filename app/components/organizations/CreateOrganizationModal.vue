<script setup>

import { useBodyScrollLock } from '~/composables/useBodyScrollLock'
import AppSelect from '~/components/AppSelect.vue'

const props = defineProps({

    show: {
        type: Boolean,
        default: false
    },

    form: {
        type: Object,
        required: true
    },

    saving: {
        type: Boolean,
        default: false
    },

    concernTypes: {
        type: Array,
        default: () => []
    },

    canAssignConcernTypes: {
        type: Boolean,
        default: false
    }

})

const emit = defineEmits([
    'close',
    'submit'
])

useBodyScrollLock(() => props.show)
const showSaveConfirmation = ref(false)

function requestSubmit() {
    if (!props.saving) showSaveConfirmation.value = true
}

function organizationTypeLabel(type) {
    return {
        bpo: 'BPO',
        tenant: 'Tenant',
        admin_facilities: 'Admin Facilities'
    }[type] || 'organization'
}

function toggleConcernType(concernTypeId) {
    const assignedIds = props.form.concern_type_ids || []
    const id = Number(concernTypeId)

    props.form.concern_type_ids = assignedIds.some(value => Number(value) === id)
        ? assignedIds.filter(value => Number(value) !== id)
        : [...assignedIds, id]
}

function confirmSubmit() {
    if (props.saving) return
    showSaveConfirmation.value = false
    emit('submit')
}

watch(() => props.show, (isShown) => {
    if (!isShown) showSaveConfirmation.value = false
})

</script>

<template>

    <div
        v-if="props.show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 p-2 backdrop-blur-[2px] sm:items-center sm:p-4"
    >

        <div
            class="modal-height-adaptive my-auto max-h-[calc(100dvh-1rem)] w-full max-w-lg overflow-y-auto rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-2rem)]"
        >

            <!-- Header -->
            <div
                class="modal-header-adaptive flex items-center justify-between gap-3 border-b border-slate-200 bg-white px-4 py-5 sm:px-6 sm:py-6"
            >

                <div class="flex items-center gap-3">

                    <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-blue-100 bg-blue-50 text-blue-800">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke-width="1.8" stroke="currentColor" class="h-6 w-6" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M3.75 21h16.5M4.5 21V7.5L12 3l7.5 4.5V21M9 21v-6h6v6M8 9h.008v.008H8V9Zm4 0h.008v.008H12V9Zm4 0h.008v.008H16V9Z" />
                        </svg>
                    </span>

                    <div>

                    <h3 class="text-xl font-semibold text-slate-900">
                        Add Organization
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        Create a new organization.
                    </p>

                    </div>

                </div>

                <button
                    type="button"
                    @click="emit('close')"
                    aria-label="Close modal"
                    class="group relative flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center text-3xl leading-none text-red-700 transition-colors duration-200 hover:text-red-800"
                >
                    <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                        stroke="currentColor" aria-hidden="true"
                        class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                    </svg>
                </button>

            </div>

            <!-- Form -->
            <form
                @submit.prevent="requestSubmit"
                class="modal-form-content-adaptive modal-form-stack-adaptive modal-compact-fields space-y-5 px-4 py-5 sm:px-6 sm:py-6"
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

                <!-- Organization Type -->
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700">
                        Organization type <span class="text-red-500">*</span>
                    </label>
                    <AppSelect
                        v-model="props.form.organization_type"
                        aria-label="Organization type"
                        name="organization_type"
                        placeholder="Select organization type"
                        :required="true"
                        :options="[
                            { label: 'Select organization type', value: '', disabled: true },
                            { label: 'BPO', value: 'bpo' },
                            { label: 'Tenant', value: 'tenant' },
                            { label: 'Admin Facilities', value: 'admin_facilities' }
                        ]"
                    />
                    <p class="mt-1 text-xs leading-5 text-slate-500">This determines which organizations its users can route concerns to.</p>
                </div>

                <fieldset v-if="props.canAssignConcernTypes" class="rounded-xl border border-slate-200 p-4">
                    <legend class="px-1 text-sm font-medium text-slate-700">Concern types this organization handles</legend>
                    <p class="mb-3 text-xs leading-5 text-slate-500">Users will only be able to route matching concern types to this organization.</p>
                    <div v-if="props.concernTypes.length" class="grid gap-2 sm:grid-cols-2">
                        <label
                            v-for="concernType in props.concernTypes"
                            :key="concernType.id"
                            class="flex cursor-pointer items-start gap-2 rounded-lg border border-slate-100 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
                        >
                            <input
                                type="checkbox"
                                :checked="(props.form.concern_type_ids || []).some(value => Number(value) === Number(concernType.id))"
                                class="mt-0.5 rounded border-slate-300 text-blue-700 focus:ring-blue-600"
                                @change="toggleConcernType(concernType.id)"
                            >
                            <span>{{ concernType.name }}<span v-if="concernType.status !== 'active'" class="ml-1 text-xs text-slate-400">(inactive)</span></span>
                        </label>
                    </div>
                    <p v-else class="text-sm text-slate-500">No concern types are available.</p>
                    <p class="mt-3 text-xs text-amber-700">No assigned types means this organization will not appear as a routing option.</p>
                </fieldset>

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
                        placeholder="Enter organization address"
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
                    class="flex justify-end border-t border-slate-200 pt-5"
                >

                    <button
                        type="submit"
                        :disabled="props.saving"
                        class="primary-action-button w-full cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                    >

                        {{
                            props.saving
                                ? 'Creating...'
                                : 'Create Organization'
                        }}

                    </button>

                </div>

            </form>

        </div>

        <ConfirmActionModal
            :show="showSaveConfirmation"
            title="Create organization?"
            :message="`Create “${props.form.name?.trim() || 'this organization'}” as ${organizationTypeLabel(props.form.organization_type)} with the entered details?`"
            confirm-label="Create organization"
            :loading="props.saving"
            @cancel="showSaveConfirmation = false"
            @confirm="confirmSubmit"
        />

    </div>

</template>
