<script setup>

import ConfirmActionModal from '~/components/ConfirmActionModal.vue'
import AppSelect from '~/components/AppSelect.vue'
import { useBodyScrollLock } from '~/composables/useBodyScrollLock'

const props = defineProps({

    show: {
        type: Boolean,
        default: false
    },

    currentUser: {
        type: Object,
        default: null
    },

    concernTypes: {
        type: Array,
        default: () => []
    },

    organizations: {
        type: Array,
        default: () => []
    }

})

const emit = defineEmits([
    'close',
    'created'
])

const { showToast } = useToast()

const saving = ref(false)
const showSaveConfirmation = ref(false)

const selectedImages = ref([])

const imagePreviews = ref([])
useBodyScrollLock(() => props.show)

const form = ref({

    title: '',

    description: '',

    concern_type_id: '',

    assigned_organization_id: '',

    priority: 'medium'

})

const availableOrganizations = computed(() => {

    if (!props.currentUser || !form.value.concern_type_id) {
        return []
    }

    const concernTypeId = Number(form.value.concern_type_id)
    let eligibleOrganizations = []

    if (
        props.currentUser.role_name === 'superadmin'
    ) {
        eligibleOrganizations = props.organizations
    } else {
        const ownOrganizationId = Number(props.currentUser.organization_id)
        const ownOrganization = props.organizations.find(
            organization => Number(organization.id) === ownOrganizationId
        )
        const isAdminFacilitiesOrganization =
            ownOrganization?.organization_type === 'admin_facilities'

        eligibleOrganizations = !isAdminFacilitiesOrganization
            ? props.organizations.filter(
                organization => organization.organization_type === 'admin_facilities'
            )
            : props.organizations.filter(
                organization => Number(organization.id) !== ownOrganizationId
            )
    }

    return eligibleOrganizations.filter(organization =>
        organization.status === 'active' &&
        (organization.concern_type_ids || []).some(
            assignedTypeId => Number(assignedTypeId) === concernTypeId
        )
    )

})

const organizationPlaceholder = computed(() => {
    if (!form.value.concern_type_id) return 'Select concern type first'
    return availableOrganizations.value.length
        ? 'Select organization'
        : 'No organization handles this concern type'
})

function resetForm() {

    form.value = {

        title: '',

        description: '',

        concern_type_id: '',

        assigned_organization_id: '',

        priority: 'medium'

    }

}

function resetOriginalImages() {

    for (const preview of imagePreviews.value) {

        if (preview?.url) {

            URL.revokeObjectURL(preview.url)

        }

    }

    selectedImages.value = []

    imagePreviews.value = []

}

function handleImageChange(event) {

    const files = Array.from(
        event.target.files || []
    )

    if (!files.length) {
        return
    }

    const allowedTypes = [

        'image/jpeg',

        'image/png',

        'image/gif',

        'image/webp'

    ]

    for (const file of files) {

        if (!allowedTypes.includes(file.type)) {

            showToast(
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`,
                'error'
            )

            continue

        }

        if (file.size > 5 * 1024 * 1024) {

            showToast(
                `${file.name} is larger than 5MB.`,
                'error'
            )

            continue

        }

        selectedImages.value.push(file)

        const previewUrl = URL.createObjectURL(file)

        imagePreviews.value.push({

            file,

            url: previewUrl

        })

    }

    event.target.value = ''

}

function removeImage(index) {

    const preview = imagePreviews.value[index]

    if (preview?.url) {

        URL.revokeObjectURL(preview.url)

    }

    selectedImages.value.splice(index, 1)

    imagePreviews.value.splice(index, 1)

}

function closeModal() {

    if (saving.value) {
        return
    }

    resetOriginalImages()

    resetForm()

    emit('close')

}

async function createConcern(confirmed = false) {

    if (!form.value.title.trim()) {

        showToast(
            'Please enter a concern title.',
            'error'
        )

        return

    }

    if (!form.value.description.trim()) {

        showToast(
            'Please enter a concern description.',
            'error'
        )

        return

    }

    if (!form.value.concern_type_id) {

        showToast(
            'Please select a concern type.',
            'error'
        )

        return

    }

    if (!form.value.assigned_organization_id) {

        showToast(
            'Please select an organization.',
            'error'
        )

        return

    }

    if (!availableOrganizations.value.some(
        organization => Number(organization.id) === Number(form.value.assigned_organization_id)
    )) {
        showToast(
            'Please select an organization allowed for your department.',
            'error'
        )

        return
    }

    /*
     * Frontend protection:
     * Admin cannot assign a concern to
     * their own organization.
     */

    if (

        props.currentUser?.role_name !== 'superadmin' &&

        Number(
            form.value.assigned_organization_id
        ) ===

        Number(
            props.currentUser.organization_id
        )

    ) {

        showToast(
            'You cannot assign a concern to your own organization.',
            'error'
        )

        return

    }

    if (!confirmed) {
        showSaveConfirmation.value = true
        return
    }

    showSaveConfirmation.value = false
    saving.value = true

    try {

        const formData = new FormData()

        formData.append(
            'title',
            form.value.title.trim()
        )

        formData.append(
            'description',
            form.value.description.trim()
        )

        formData.append(
            'concern_type_id',
            form.value.concern_type_id
        )

        formData.append(
            'assigned_organization_id',
            form.value.assigned_organization_id
        )

        formData.append(
            'priority',
            form.value.priority
        )

        for (const file of selectedImages.value) {

            formData.append(
                'image',
                file
            )

        }

        await $fetch(
            '/api/concerns',
            {
                method: 'POST',
                body: formData
            }
        )

        resetOriginalImages()

        resetForm()

        emit('created')

        showToast(
            'Concern submitted successfully.',
            'success'
        )

        emit('close')

    } catch (error) {

        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to submit concern.',
            'error'
        )

    } finally {

        saving.value = false

    }

}

watch(
    () => form.value.concern_type_id,
    () => {
        if (!availableOrganizations.value.some(
            organization => Number(organization.id) === Number(form.value.assigned_organization_id)
        )) {
            form.value.assigned_organization_id = ''
        }
    }
)

watch(

    () => props.show,

    value => {

        if (value) {

            resetForm()

            resetOriginalImages()

            showSaveConfirmation.value = false

        } else {

            showSaveConfirmation.value = false

        }

    }

)

onUnmounted(() => {

    resetOriginalImages()

})

</script>

<template>

    <div v-if="show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 px-2 py-3 backdrop-blur-[2px] sm:items-center sm:px-4 sm:py-6">

        <div
            class="create-concern-modal modal-height-adaptive my-auto flex max-h-[calc(100dvh-1.5rem)] w-full max-w-5xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-3rem)]">

            <!-- Header -->
            <div class="modal-header-adaptive flex items-center justify-between gap-3 border-b border-slate-200 bg-white px-4 py-5 sm:px-6 sm:py-6">

                <div class="flex items-center gap-3">

                    <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-blue-100 bg-blue-50 text-blue-800">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke-width="1.8" stroke="currentColor" class="h-6 w-6" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M12 4.5v15m7.5-7.5h-15M3.75 3.75h16.5v16.5H3.75V3.75Z" />
                        </svg>
                    </span>

                    <div>

                    <h3 class="text-xl font-semibold text-slate-900">
                        Create Concern
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        Submit a new concern for the assigned organization.
                    </p>

                    </div>

                </div>

                <button type="button" @click="closeModal" :disabled="saving"
                    aria-label="Close modal"
                    class="group relative flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center text-3xl leading-none text-red-700 transition-colors duration-200 hover:text-red-800 disabled:cursor-not-allowed disabled:opacity-50">
                    <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                        stroke="currentColor" aria-hidden="true"
                        class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                    </svg>
                </button>

            </div>

            <form @submit.prevent="createConcern(false)" class="min-h-0 flex-1 overflow-y-auto">

                <div class="modal-form-content-adaptive modal-form-stack-adaptive create-concern-form space-y-5 p-4 sm:p-6">

                    <!-- Concern Title -->
                    <div>

                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Concern Title
                            <span class="text-red-500">*</span>
                        </label>

                        <input data-tour="create-title" v-model="form.title" type="text" required placeholder="Enter concern title"
                            class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100" />

                    </div>

                    <!-- Description -->
                    <div>

                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Description
                            <span class="text-red-500">*</span>
                        </label>

                        <textarea data-tour="create-description" v-model="form.description" required rows="6" placeholder="Describe the concern..."
                            class="w-full resize-y rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm leading-6 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"></textarea>

                    </div>

                    <!-- Multiple Original Images -->
                    <div data-tour="create-images">

                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Attach Images

                            <span class="font-normal text-slate-400">
                                (Optional)
                            </span>

                        </label>

                        <input id="concern-image" type="file" multiple
                            accept="image/jpeg,image/png,image/gif,image/webp" @change="handleImageChange"
                            class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-slate-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:border-slate-400 hover:file:bg-slate-200" />

                        <p class="mt-1 text-xs text-slate-500">
                            You can select multiple images. Maximum size: 5 MB per image.
                        </p>

                        <div v-if="imagePreviews.length > 0" class="mt-4">

                            <div class="mb-2 flex items-center justify-between">

                                <p class="text-sm font-medium text-slate-700">
                                    Selected Images
                                </p>

                                <button type="button" @click="resetOriginalImages" :disabled="saving"
                                    class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                    Remove All
                                </button>

                            </div>

                            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">

                                <div v-for="(preview, index) in imagePreviews" :key="preview.url"
                                    class="group relative overflow-hidden rounded-lg border border-slate-200 bg-slate-50">

                                    <img :src="preview.url" :alt="preview.file.name"
                                        class="h-28 w-full bg-white object-cover transition duration-200 group-hover:scale-105" />

                                    <button type="button" @click="removeImage(index)" :disabled="saving"
                                        class="absolute right-2 top-2 cursor-pointer rounded-md bg-black/70 px-2 py-1 text-xs font-medium text-white opacity-90 transition hover:bg-red-600 hover:opacity-100 disabled:cursor-not-allowed disabled:opacity-50">
                                        Remove
                                    </button>

                                    <div class="border-t border-slate-200 bg-white px-2 py-2">

                                        <p class="truncate text-xs text-slate-500" :title="preview.file.name">
                                            {{ preview.file.name }}
                                        </p>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                    <!-- Concern Type / Assigned To -->
                    <div data-tour="create-routing" class="rounded-xl border border-blue-100 bg-blue-50/50 p-4 sm:p-5">

                        <div class="mb-4">
                            <h4 class="text-sm font-semibold text-slate-800">Request routing</h4>
                            <p class="mt-1 text-xs text-slate-500">Choose a category and the organization responsible for handling this concern.</p>
                        </div>

                        <div class="grid gap-5 sm:grid-cols-2">

                        <!-- Concern Type -->
                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Concern Type
                                <span class="text-red-500">*</span>
                            </label>

                            <AppSelect
                                v-model="form.concern_type_id"
                                aria-label="Concern type"
                                name="concern_type_id"
                                placeholder="Select concern type"
                                :required="true"
                                :searchable="true"
                                :options="[
                                    { label: 'Select concern type', value: '', disabled: true },
                                    ...concernTypes.map(type => ({ label: type.name, value: type.id }))
                                ]"
                            />

                        </div>

                        <!-- Assigned To -->
                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Assigned To
                                <span class="text-red-500">*</span>
                            </label>

                            <AppSelect
                                v-model="form.assigned_organization_id"
                                aria-label="Assigned organization"
                                name="assigned_organization_id"
                                :placeholder="organizationPlaceholder"
                                :required="true"
                                :disabled="!form.concern_type_id || availableOrganizations.length === 0"
                                :searchable="true"
                                :options="[
                                    { label: organizationPlaceholder, value: '', disabled: true },
                                    ...availableOrganizations.map(organization => ({ label: organization.name, value: organization.id }))
                                ]"
                            />

                            <p v-if="form.concern_type_id && !availableOrganizations.length" class="mt-1 text-xs text-amber-700">
                                Ask a Superadmin to assign this concern type to an eligible organization.
                            </p>

                        </div>

                        </div>

                    </div>

                    <!-- Priority -->
                    <div class="rounded-xl border border-amber-100 bg-amber-50/60 p-4">

                        <label class="mb-2 block text-sm font-semibold text-amber-950">
                            Priority
                            <span class="text-red-500">*</span>
                        </label>

                        <AppSelect
                            v-model="form.priority"
                            aria-label="Priority"
                            name="priority"
                            :required="true"
                            :options="[
                                { label: 'Low', value: 'low' },
                                { label: 'Medium', value: 'medium' },
                                { label: 'High', value: 'high' },
                                { label: 'Urgent', value: 'urgent' }
                            ]"
                        />

                    </div>

                    <!-- Buttons -->
                    <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end">

                        <button type="button" @click="closeModal" :disabled="saving"
                            class="secondary-hover-button w-full cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto">
                            Cancel
                        </button>

                        <button data-tour="create-submit" type="submit" :disabled="saving"
                            class="primary-action-button w-full cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto">

                            {{
                                saving
                                    ? 'Submitting...'
                                    : 'Submit Concern'
                            }}

                        </button>

                    </div>

                </div>

            </form>

        </div>

    </div>

    <ConfirmActionModal
        :show="show && showSaveConfirmation"
        title="Submit this concern?"
        :message="`Submit “${form.title.trim()}” to ${availableOrganizations.find(organization => Number(organization.id) === Number(form.assigned_organization_id))?.name || 'the selected organization'}?`"
        confirm-label="Submit concern"
        :loading="saving"
        @cancel="showSaveConfirmation = false"
        @confirm="createConcern(true)"
    />

</template>