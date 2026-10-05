<script setup>

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
    'success',
    'error',
    'created'
])

const saving = ref(false)

const selectedImages = ref([])

const imagePreviews = ref([])

const form = ref({

    title: '',

    description: '',

    concern_type_id: '',

    assigned_organization_id: '',

    priority: 'medium'

})

const availableOrganizations = computed(() => {

    if (!props.currentUser) {
        return []
    }

    if (props.currentUser.role_name === 'admin') {

        return props.organizations.filter(
            organization =>
                Number(organization.id) !==
                Number(props.currentUser.organization_id)
        )

    }

    return props.organizations

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

            emit(
                'error',
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`
            )

            continue

        }

        if (file.size > 5 * 1024 * 1024) {

            emit(
                'error',
                `${file.name} is larger than 5MB.`
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

async function createConcern() {

    if (!form.value.title.trim()) {

        emit(
            'error',
            'Please enter a concern title.'
        )

        return

    }

    if (!form.value.description.trim()) {

        emit(
            'error',
            'Please enter a concern description.'
        )

        return

    }

    if (!form.value.concern_type_id) {

        emit(
            'error',
            'Please select a concern type.'
        )

        return

    }

    if (!form.value.assigned_organization_id) {

        emit(
            'error',
            'Please select an organization.'
        )

        return

    }

    /*
     * Frontend protection:
     * Admin cannot assign a concern to
     * their own organization.
     */

    if (

        props.currentUser?.role_name === 'admin' &&

        Number(
            form.value.assigned_organization_id
        ) ===

        Number(
            props.currentUser.organization_id
        )

    ) {

        emit(
            'error',
            'You cannot assign a concern to your own organization.'
        )

        return

    }

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

        emit(
            'success',
            'Concern submitted successfully.'
        )

        emit('close')

    } catch (error) {

        emit(
            'error',
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to submit concern.'
        )

    } finally {

        saving.value = false

    }

}

watch(

    () => props.show,

    value => {

        if (value) {

            resetForm()

            resetOriginalImages()

        }

    }

)

onUnmounted(() => {

    resetOriginalImages()

})

</script>

<template>

    <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 px-2 py-3 backdrop-blur-[2px] sm:items-center sm:px-4 sm:py-6"
    >

        <div
            class="my-auto flex max-h-[calc(100dvh-1.5rem)] w-full max-w-2xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-3rem)]"
        >

            <!-- Header -->
            <div
                class="flex items-center justify-between border-b border-slate-200 px-4 py-4 sm:px-6 sm:py-5"
            >

                <div>

                    <h3 class="text-lg font-bold text-slate-800">
                        Create Concern
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        Submit a new concern for the assigned organization.
                    </p>

                </div>

                <button
                    type="button"
                    @click="closeModal"
                    :disabled="saving"
                    class="cursor-pointer rounded-lg p-2 text-2xl leading-none text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-50"
                >
                    ×
                </button>

            </div>

            <form
                @submit.prevent="createConcern"
                class="flex-1 overflow-y-auto"
            >

                <div class="space-y-5 p-4 sm:p-6">

                    <!-- Concern Title -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Concern Title
                            <span class="text-red-500">*</span>
                        </label>

                        <input
                            v-model="form.title"
                            type="text"
                            required
                            placeholder="Enter concern title"
                            class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />

                    </div>

                    <!-- Description -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Description
                            <span class="text-red-500">*</span>
                        </label>

                        <textarea
                            v-model="form.description"
                            required
                            rows="6"
                            placeholder="Describe the concern..."
                            class="w-full resize-y rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm leading-6 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        ></textarea>

                    </div>

                    <!-- Multiple Original Images -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Attach Images

                            <span class="font-normal text-slate-400">
                                (Optional)
                            </span>

                        </label>

                        <input
                            id="concern-image"
                            type="file"
                            multiple
                            accept="image/jpeg,image/png,image/gif,image/webp"
                            @change="handleImageChange"
                            class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-slate-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:border-slate-400 hover:file:bg-slate-200"
                        />

                        <p class="mt-1 text-xs text-slate-500">
                            You can select multiple images. Maximum size: 5 MB per image.
                        </p>

                        <div
                            v-if="imagePreviews.length > 0"
                            class="mt-4"
                        >

                            <div
                                class="mb-2 flex items-center justify-between"
                            >

                                <p class="text-sm font-medium text-slate-700">
                                    Selected Images
                                </p>

                                <button
                                    type="button"
                                    @click="resetOriginalImages"
                                    :disabled="saving"
                                    class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    Remove All
                                </button>

                            </div>

                            <div
                                class="grid grid-cols-2 gap-3 sm:grid-cols-3"
                            >

                                <div
                                    v-for="(preview, index) in imagePreviews"
                                    :key="preview.url"
                                    class="group relative overflow-hidden rounded-lg border border-slate-200 bg-slate-50"
                                >

                                    <img
                                        :src="preview.url"
                                        :alt="preview.file.name"
                                        class="h-28 w-full bg-white object-cover transition duration-200 group-hover:scale-105"
                                    />

                                    <button
                                        type="button"
                                        @click="removeImage(index)"
                                        :disabled="saving"
                                        class="absolute right-2 top-2 cursor-pointer rounded-md bg-black/70 px-2 py-1 text-xs font-medium text-white opacity-90 transition hover:bg-red-600 hover:opacity-100 disabled:cursor-not-allowed disabled:opacity-50"
                                    >
                                        Remove
                                    </button>

                                    <div
                                        class="border-t border-slate-200 bg-white px-2 py-2"
                                    >

                                        <p
                                            class="truncate text-xs text-slate-500"
                                            :title="preview.file.name"
                                        >
                                            {{ preview.file.name }}
                                        </p>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                    <!-- Concern Type / Assigned To -->
                    <div class="grid gap-5 sm:grid-cols-2">

                        <!-- Concern Type -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Concern Type
                                <span class="text-red-500">*</span>
                            </label>

                            <select
                                v-model="form.concern_type_id"
                                required
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                            >

                                <option
                                    value=""
                                    disabled
                                >
                                    Select concern type
                                </option>

                                <option
                                    v-for="type in concernTypes"
                                    :key="type.id"
                                    :value="type.id"
                                >
                                    {{ type.name }}
                                </option>

                            </select>

                        </div>

                        <!-- Assigned To -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Assigned To
                                <span class="text-red-500">*</span>
                            </label>

                            <select
                                v-model="form.assigned_organization_id"
                                required
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                            >

                                <option
                                    value=""
                                    disabled
                                >
                                    Select organization
                                </option>

                                <option
                                    v-for="organization in availableOrganizations"
                                    :key="organization.id"
                                    :value="organization.id"
                                >
                                    {{ organization.name }}
                                </option>

                            </select>

                            <p
                                v-if="currentUser?.role_name === 'admin'"
                                class="mt-1 text-xs text-slate-500"
                            >
                                Your own organization is not available for assignment.
                            </p>

                        </div>

                    </div>

                    <!-- Priority -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Priority
                            <span class="text-red-500">*</span>
                        </label>

                        <select
                            v-model="form.priority"
                            required
                            class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        >

                            <option value="low">
                                Low
                            </option>

                            <option value="medium">
                                Medium
                            </option>

                            <option value="high">
                                High
                            </option>

                            <option value="urgent">
                                Urgent
                            </option>

                        </select>

                    </div>

                    <!-- Buttons -->
                    <div
                        class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end"
                    >

                        <button
                            type="button"
                            @click="closeModal"
                            :disabled="saving"
                            class="w-full cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                        >
                            Cancel
                        </button>

                        <button
                            type="submit"
                            :disabled="saving"
                            class="w-full cursor-pointer rounded-lg bg-emerald-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-emerald-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                        >

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

</template>
