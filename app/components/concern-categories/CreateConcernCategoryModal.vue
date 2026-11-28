<script setup>
import { computed, ref, watch } from 'vue'
import { useBodyScrollLock } from '~/composables/useBodyScrollLock'
import AppSelect from '~/components/AppSelect.vue'

const props = defineProps({
    show: { type: Boolean, default: false },
    form: { type: Object, required: true },
    saving: { type: Boolean, default: false },
    organizations: { type: Array, default: () => [] },
    mode: { type: String, default: 'create' },
    currentOrganizationId: { type: [String, Number], default: '' },
    currentOrganizationName: { type: String, default: '' }
})

const emit = defineEmits(['close', 'submit'])
const showConfirmation = ref(false)
const isEditing = computed(() => props.mode === 'edit')
useBodyScrollLock(() => props.show)

const confirmationTitle = computed(() =>
    isReceiverChanging.value
        ? 'Change receiving organization?'
        : isEditing.value ? 'Update concern category?' : 'Create concern category?'
)

const confirmationMessage = computed(() =>
    isEditing.value && props.currentOrganizationName &&
    Number(props.form.organization_id) !== Number(props.currentOrganizationId)
        ? `Change “${props.form.name?.trim() || 'this category'}” from ${props.currentOrganizationName} to ${props.organizations.find(organization => Number(organization.id) === Number(props.form.organization_id))?.name || 'the selected organization'}? This affects new concerns only. Existing concerns will stay assigned to their current organization.`
        : isEditing.value
            ? `Save changes to “${props.form.name?.trim() || 'this category'}”? The selected receiving organization will handle new concerns; existing concerns will not be reassigned.`
            : `Create “${props.form.name?.trim() || 'this category'}” and route new concerns to ${props.organizations.find(organization => Number(organization.id) === Number(props.form.organization_id))?.name || 'the selected organization'}?`
)

const isReceiverChanging = computed(() =>
    isEditing.value &&
    Boolean(props.currentOrganizationName) &&
    Number(props.form.organization_id) !== Number(props.currentOrganizationId)
)

function requestSubmit() {
    if (!props.saving && props.form.organization_id) showConfirmation.value = true
}

function cancelConfirmation() {
    if (!props.saving) showConfirmation.value = false
}

function confirmSubmit() {
    if (props.saving) return
    showConfirmation.value = false
    emit('submit')
}

watch(() => props.show, (isShown) => {
    if (!isShown) showConfirmation.value = false
})
</script>

<template>
    <div
        v-if="props.show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 p-4 backdrop-blur-sm sm:items-center"
        @click.self="!props.saving && emit('close')"
    >
        <form
            class="my-auto w-full max-w-lg rounded-2xl border border-white/60 bg-white p-6 shadow-2xl sm:p-8"
            @submit.prevent="requestSubmit"
        >
            <div class="mb-6 flex items-start justify-between gap-4">
                <div>
                    <p class="text-xs font-bold uppercase tracking-[0.16em] text-blue-700">Category setup</p>
                    <h3 class="mt-1 text-xl font-semibold text-slate-900">{{ isEditing ? 'Edit concern category' : 'Add concern category' }}</h3>
                    <p class="mt-1 text-sm text-slate-500">{{ isEditing ? 'Update the category details and its one receiving organization.' : 'Create a category and route it to one responsible organization.' }}</p>
                </div>
                <button
                    type="button"
                    class="group relative flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center text-3xl leading-none text-red-700 transition-colors duration-200 hover:text-red-800 disabled:cursor-not-allowed disabled:opacity-50"
                    aria-label="Close"
                    :disabled="props.saving"
                    @click="emit('close')"
                >
                    <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                        stroke="currentColor" aria-hidden="true"
                        class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                    </svg>
                </button>
            </div>

            <label for="category-name" class="mb-1.5 block text-sm font-medium text-slate-700">
                Category name <span class="text-red-500">*</span>
            </label>
            <input
                id="category-name"
                v-model="props.form.name"
                required
                maxlength="100"
                autofocus
                class="mb-4 w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm outline-none transition focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15"
                placeholder="e.g. Facilities"
            >

            <label for="category-description" class="mb-1.5 block text-sm font-medium text-slate-700">
                Description <span class="text-slate-400">(optional)</span>
            </label>
            <textarea
                id="category-description"
                v-model="props.form.description"
                maxlength="255"
                rows="3"
                class="w-full resize-y rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm outline-none transition focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15"
                placeholder="Briefly describe what belongs in this category."
            />

            <div class="mt-5 rounded-xl border border-slate-200 p-4">
                <label for="category-organization" class="mb-2 block text-sm font-medium text-slate-700">
                    Receiving organization <span class="text-red-500">*</span>
                </label>
                <p class="mb-3 text-xs leading-5 text-slate-500">Each category routes to exactly one organization. Selecting this category when creating a concern will fill in its destination automatically.</p>
                <AppSelect
                    id="category-organization"
                    v-model="props.form.organization_id"
                    aria-label="Organization that handles this category"
                    placeholder="Select one organization"
                    :required="true"
                    :searchable="true"
                    :options="[
                        { label: 'Select one organization', value: '', disabled: true },
                        ...props.organizations.map(organization => ({
                            label: `${organization.name} · ${organization.organization_type?.replaceAll('_', ' ') || 'organization'}`,
                            value: organization.id
                        }))
                    ]"
                />
                <p v-if="!props.organizations.length" class="mt-2 text-xs text-amber-700">No active organizations are available. Add or activate an organization first.</p>
            </div>

            <div class="mt-7 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <button
                    type="button"
                    class="secondary-hover-button cursor-pointer rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                    :disabled="props.saving"
                    @click="emit('close')"
                >Cancel</button>
                <button
                    type="submit"
                    class="primary-action-button cursor-pointer rounded-lg bg-blue-900 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 disabled:cursor-wait disabled:opacity-60"
                    :disabled="props.saving || !props.form.organization_id"
                >{{ props.saving ? (isEditing ? 'Saving…' : 'Creating…') : (isEditing ? 'Save changes' : 'Create category') }}</button>
            </div>
        </form>

        <ConfirmActionModal
            :show="showConfirmation"
            :title="confirmationTitle"
            :message="confirmationMessage"
            :confirm-label="isReceiverChanging ? 'Change future routing' : isEditing ? 'Save changes' : 'Create category'"
            :loading="props.saving"
            @cancel="cancelConfirmation"
            @confirm="confirmSubmit"
        />
    </div>
</template>
