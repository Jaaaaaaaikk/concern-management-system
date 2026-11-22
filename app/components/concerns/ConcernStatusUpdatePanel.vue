<script setup>
import { toRefs } from 'vue'
import { VueDatePicker } from '@vuepic/vue-datepicker'
import '@vuepic/vue-datepicker/dist/main.css'
import AppSelect from '~/components/AppSelect.vue'

const props = defineProps({
    selectedStatus: {
        type: String,
        default: ''
    },
    currentStatus: {
        type: String,
        default: ''
    },
    currentStatusLabel: {
        type: String,
        default: ''
    },
    availableStatusOptions: {
        type: Array,
        default: () => []
    },
    assignedAdmin: {
        type: Boolean,
        default: false
    },
    creatorOrganizationAdmin: {
        type: Boolean,
        default: false
    },
    commitmentDateRequired: {
        type: Boolean,
        default: false
    },
    targetCommitmentAt: {
        type: [Date, String],
        default: null
    },
    minimumCommitmentDate: {
        type: Function,
        required: true
    },
    updatingStatus: {
        type: Boolean,
        default: false
    },
    statusRemarks: {
        type: String,
        default: ''
    },
    remarksRequired: {
        type: Boolean,
        default: false
    },
    statusRemarksPlaceholder: {
        type: String,
        default: 'Add notes about this status change...'
    },
    statusEvidenceRequired: {
        type: Boolean,
        default: false
    },
    statusImagePreviews: {
        type: Array,
        default: () => []
    },
    setStatusImageInput: {
        type: Function,
        required: true
    },
    setStatusSelectorSection: {
        type: Function,
        required: true
    }
})

const {
    selectedStatus,
    currentStatus,
    currentStatusLabel,
    availableStatusOptions,
    assignedAdmin,
    creatorOrganizationAdmin,
    commitmentDateRequired,
    targetCommitmentAt,
    minimumCommitmentDate,
    updatingStatus,
    statusRemarks,
    remarksRequired,
    statusRemarksPlaceholder,
    statusEvidenceRequired,
    statusImagePreviews,
    setStatusImageInput,
    setStatusSelectorSection
} = toRefs(props)

const emit = defineEmits([
    'update:selectedStatus',
    'update:targetCommitmentAt',
    'update:statusRemarks',
    'status-images-change',
    'clear-status-images',
    'remove-status-image',
    'update-status'
])
</script>

<template>
    <div :ref="setStatusSelectorSection" data-tour="view-status" class="view-concern-status scroll-mt-8 overflow-hidden rounded-xl border border-blue-200 bg-white shadow-md">
        <div class="border-b border-blue-100 bg-blue-50/70 px-5 py-4">
            <div class="flex items-start gap-3">
                <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-blue-100 text-blue-800">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                        stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M12 6v6l4 2m6-2a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z" />
                    </svg>
                </span>
                <div>
                    <h4 class="text-base font-semibold text-slate-900">
                        Update Status
                    </h4>
                    <p class="mt-1 text-sm leading-5 text-slate-600">
                        <span v-if="assignedAdmin">
                            Manage this concern on behalf of the assigned organization.
                        </span>
                        <span v-else>
                            Review the resolution and close the concern for the creator organization.
                        </span>
                    </p>
                </div>
            </div>
        </div>

        <div class="space-y-5 p-5">
            <div class="grid gap-4 md:grid-cols-2">
                <div>
                    <label for="concern-status" class="mb-2 block text-sm font-semibold text-slate-700">
                        New status
                    </label>
                    <AppSelect
                        id="concern-status"
                        :model-value="selectedStatus"
                        :placeholder="currentStatusLabel"
                        :disabled="updatingStatus || availableStatusOptions.length === 0"
                        :options="[
                            { label: currentStatusLabel, value: currentStatus },
                            ...availableStatusOptions
                        ]"
                        @update:model-value="emit('update:selectedStatus', $event)"
                    />
                    <p class="mt-2 text-xs text-slate-500">
                        Choose the next status allowed for your organization.
                    </p>
                    <p v-if="creatorOrganizationAdmin && currentStatus === 'resolved'" class="mt-2 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs leading-5 text-amber-900">
                        Review the reported resolution. If work is incomplete, reopen it as In Progress and explain what remains. The original commitment date is retained; no new commitment date is required.
                    </p>
                </div>

                <div v-if="commitmentDateRequired" class="rounded-lg border border-blue-200 bg-blue-50/70 p-4">
                    <label for="target-commitment-at" class="mb-2 block text-sm font-semibold text-blue-900">
                        Committed start date <span class="text-red-500">*</span>
                    </label>
                    <VueDatePicker
                        id="target-commitment-at"
                        :model-value="targetCommitmentAt"
                        :min-date="minimumCommitmentDate()"
                        :time-config="{ enableTimePicker: false }"
                        :disabled="updatingStatus"
                        :auto-apply="true"
                        format="MMM d, yyyy"
                        placeholder="Choose your committed start date"
                        input-class-name="!rounded-lg !border-blue-300 !py-3 !text-sm focus:!border-blue-500"
                        menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                        class="w-full"
                        @update:model-value="emit('update:targetCommitmentAt', $event)"
                    />
                    <p class="mt-2 text-xs leading-5 text-blue-800">
                        This is the date your organization commits to begin handling the concern, not a due date. Choose today or a future date.
                    </p>
                </div>
            </div>

            <div>
                <label for="status-remarks" class="mb-2 block text-sm font-semibold text-slate-700">
                    Update notes
                    <span v-if="remarksRequired" class="text-red-500">*</span>
                    <span v-else class="font-normal text-slate-400">(Optional)</span>
                </label>
                <textarea
                    id="status-remarks"
                    :value="statusRemarks"
                    :disabled="updatingStatus"
                    rows="3"
                    :placeholder="statusRemarksPlaceholder"
                    class="w-full resize-y rounded-lg border border-slate-300 px-4 py-3 text-sm leading-6 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 disabled:cursor-not-allowed disabled:bg-slate-100"
                    @input="emit('update:statusRemarks', $event.target.value)"
                ></textarea>
            </div>

            <div v-if="statusEvidenceRequired" class="mt-5 rounded-lg border border-green-200 bg-green-50 p-4">
                <div class="mb-3">
                    <p class="text-sm font-semibold text-green-800">
                        Resolution Evidence <span class="text-red-500">*</span>
                    </p>
                    <p class="mt-1 text-xs leading-5 text-green-700">
                        Attach one or more images showing the completed work,
                        repaired issue, or other evidence that the concern has
                        been resolved.
                    </p>
                </div>

                <input :ref="setStatusImageInput" type="file" multiple
                    accept="image/jpeg,image/png,image/gif,image/webp" :disabled="updatingStatus"
                    @change="emit('status-images-change', $event)"
                    class="w-full cursor-pointer rounded-lg border border-green-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-green-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-green-700 hover:border-green-400 hover:file:bg-green-200 disabled:cursor-not-allowed disabled:bg-slate-100" />
                <p class="mt-1 text-xs text-slate-500">
                    Multiple images are allowed. Maximum size: 5 MB per image.
                </p>

                <div v-if="statusImagePreviews.length > 0" class="mt-4">
                    <div class="mb-2 flex items-center justify-between">
                        <p class="text-sm font-medium text-slate-700">
                            Selected Evidence ({{ statusImagePreviews.length }})
                        </p>
                        <button type="button" @click="emit('clear-status-images')" :disabled="updatingStatus"
                            class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                            Remove All
                        </button>
                    </div>

                    <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
                        <div v-for="(preview, index) in statusImagePreviews" :key="preview.url"
                            class="group relative overflow-hidden rounded-lg border border-green-200 bg-white">
                            <img :src="preview.url" :alt="preview.file.name"
                                class="h-28 w-full object-cover transition duration-200 group-hover:scale-105" />
                            <button type="button" @click="emit('remove-status-image', index)" :disabled="updatingStatus"
                                class="absolute right-2 top-2 cursor-pointer rounded-md bg-black/70 px-2 py-1 text-xs font-medium text-white transition hover:bg-red-600 disabled:cursor-not-allowed disabled:opacity-50">
                                Remove
                            </button>
                            <div class="border-t border-slate-200 px-2 py-2">
                                <p class="truncate text-xs text-slate-500" :title="preview.file.name">
                                    {{ preview.file.name }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="flex justify-end border-t border-slate-100 pt-4">
                <button type="button" @click="emit('update-status')"
                    :disabled="updatingStatus || selectedStatus === currentStatus"
                    class="primary-action-button cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50">
                    {{ updatingStatus ? 'Updating...' : 'Update Status' }}
                </button>
            </div>
        </div>
    </div>
</template>
