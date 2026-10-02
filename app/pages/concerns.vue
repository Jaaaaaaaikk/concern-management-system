<script setup>
definePageMeta({
    middleware: 'auth'
})

const concerns = ref([])
const concernTypes = ref([])
const organizations = ref([])
const currentUser = ref(null)

const loading = ref(true)
const saving = ref(false)

const errorMessage = ref('')
const successMessage = ref('')

const showModal = ref(false)

const search = ref('')
const statusFilter = ref('')
const priorityFilter = ref('')

const selectedImage = ref(null)
const imagePreview = ref('')

const showViewModal = ref(false)
const selectedConcern = ref(null)

const concernComments = ref([])
const concernAttachments = ref([])
const concernStatusHistory = ref([])

const loadingConcernDetails = ref(false)
const savingComment = ref(false)
const updatingStatus = ref(false)

const newComment = ref('')
const selectedStatus = ref('')
const statusRemarks = ref('')

/*
 * Current time used for the live concern duration.
 *
 * This is updated every minute.
 */
const currentTime = ref(new Date())

let durationTimer = null

const form = ref({
    title: '',
    description: '',
    concern_type_id: '',
    assigned_organization_id: '',
    priority: 'medium'
})

const filteredConcerns = computed(() => {
    const searchText = search.value.trim().toLowerCase()

    return concerns.value.filter((concern) => {
        const matchesSearch =
            !searchText ||
            concern.concern_number?.toLowerCase().includes(searchText) ||
            concern.title?.toLowerCase().includes(searchText) ||
            concern.description?.toLowerCase().includes(searchText)

        const matchesStatus =
            !statusFilter.value ||
            concern.status === statusFilter.value

        const matchesPriority =
            !priorityFilter.value ||
            concern.priority === priorityFilter.value

        return (
            matchesSearch &&
            matchesStatus &&
            matchesPriority
        )
    })
})

async function viewConcern(concern) {
    showViewModal.value = true
    loadingConcernDetails.value = true
    errorMessage.value = ''

    selectedConcern.value = null
    concernComments.value = []
    concernAttachments.value = []
    concernStatusHistory.value = []

    newComment.value = ''
    selectedStatus.value = ''
    statusRemarks.value = ''

    try {
        const response = await $fetch(
            `/api/concerns/${concern.id}`,
            {
                cache: 'no-store'
            }
        )

        selectedConcern.value = response.concern
        concernComments.value = response.comments || []
        concernAttachments.value = response.attachments || []
        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern.status

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load concern details.'

        showViewModal.value = false
    } finally {
        loadingConcernDetails.value = false
    }
}

function closeViewModal() {
    if (
        savingComment.value ||
        updatingStatus.value
    ) {
        return
    }

    showViewModal.value = false

    selectedConcern.value = null
    concernComments.value = []
    concernAttachments.value = []
    concernStatusHistory.value = []

    newComment.value = ''
    selectedStatus.value = ''
    statusRemarks.value = ''
}

async function refreshConcernDetails() {
    if (!selectedConcern.value) return

    const response = await $fetch(
        `/api/concerns/${selectedConcern.value.id}`,
        {
            cache: 'no-store'
        }
    )

    selectedConcern.value = response.concern
    concernComments.value = response.comments || []
    concernAttachments.value = response.attachments || []
    concernStatusHistory.value =
        response.statusHistory || []

    selectedStatus.value =
        response.concern.status
}

async function addComment() {
    if (!selectedConcern.value) return

    const comment = newComment.value.trim()

    if (!comment) {
        errorMessage.value =
            'Please enter a comment.'

        return
    }

    savingComment.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/comments`,
            {
                method: 'POST',
                body: {
                    comment
                }
            }
        )

        newComment.value = ''

        await refreshConcernDetails()

        successMessage.value =
            'Comment added successfully.'

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to add comment.'
    } finally {
        savingComment.value = false
    }
}

async function updateConcernStatus() {
    if (!selectedConcern.value) return

    if (
        selectedStatus.value ===
        selectedConcern.value.status
    ) {
        return
    }

    /*
     * Extra frontend protection.
     *
     * Only the creator can close a concern,
     * and the concern must already be resolved.
     */
    if (
        selectedStatus.value === 'closed' &&
        !canCloseConcern()
    ) {
        errorMessage.value =
            'Only the creator can close a resolved concern.'

        return
    }

    updatingStatus.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/status`,
            {
                method: 'PUT',
                body: {
                    status: selectedStatus.value,
                    remarks: statusRemarks.value
                }
            }
        )

        statusRemarks.value = ''

        await refreshConcernDetails()
        await loadConcerns()

        successMessage.value =
            'Concern status updated successfully.'

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to update concern status.'
    } finally {
        updatingStatus.value = false
    }
}

async function loadCurrentUser() {
    try {
        const response = await $fetch(
            '/api/auth/me',
            {
                cache: 'no-store'
            }
        )

        currentUser.value = response.user

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load current user.'
    }
}

/*
 * Load concerns.
 *
 * The backend determines which concerns
 * the current user is allowed to see.
 *
 * cache: 'no-store' makes sure the latest
 * concern records are requested.
 */
async function loadConcerns() {
    try {
        const response = await $fetch(
            '/api/concerns',
            {
                method: 'GET',
                cache: 'no-store'
            }
        )

        concerns.value =
            response.concerns || []

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load concerns.'
    }
}

async function loadConcernTypes() {
    try {
        const response = await $fetch(
            '/api/concern-types',
            {
                cache: 'no-store'
            }
        )

        concernTypes.value =
            response.concernTypes || []

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load concern types.'
    }
}

async function loadOrganizations() {
    try {
        const response = await $fetch(
            '/api/organizations',
            {
                cache: 'no-store'
            }
        )

        organizations.value =
            response.organizations || []

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load organizations.'
    }
}

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    await Promise.all([
        loadCurrentUser(),
        loadConcerns(),
        loadConcernTypes(),
        loadOrganizations()
    ])

    loading.value = false
}

function openCreateModal() {
    errorMessage.value = ''
    successMessage.value = ''

    selectedImage.value = null
    imagePreview.value = ''

    form.value = {
        title: '',
        description: '',
        concern_type_id: '',
        assigned_organization_id: '',
        priority: 'medium'
    }

    showModal.value = true
}

function closeModal() {
    if (saving.value) return

    showModal.value = false

    selectedImage.value = null

    if (imagePreview.value) {
        URL.revokeObjectURL(imagePreview.value)
    }

    imagePreview.value = ''
}

function handleImageChange(event) {
    const file = event.target.files?.[0]

    if (!file) {
        selectedImage.value = null
        imagePreview.value = ''
        return
    }

    const validImageTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    if (!validImageTypes.includes(file.type)) {
        errorMessage.value =
            'Invalid image format. Please upload JPG, PNG, GIF, or WEBP.'

        event.target.value = ''
        selectedImage.value = null
        imagePreview.value = ''

        return
    }

    const maxSize = 5 * 1024 * 1024

    if (file.size > maxSize) {
        errorMessage.value =
            'Image size must not exceed 5 MB.'

        event.target.value = ''
        selectedImage.value = null
        imagePreview.value = ''

        return
    }

    errorMessage.value = ''

    selectedImage.value = file

    if (imagePreview.value) {
        URL.revokeObjectURL(imagePreview.value)
    }

    imagePreview.value =
        URL.createObjectURL(file)
}

function removeImage() {
    if (imagePreview.value) {
        URL.revokeObjectURL(imagePreview.value)
    }

    selectedImage.value = null
    imagePreview.value = ''

    const imageInput =
        document.getElementById('concern-image')

    if (imageInput) {
        imageInput.value = ''
    }
}

async function createConcern() {
    if (saving.value) return

    saving.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        const formData = new FormData()

        formData.append(
            'title',
            form.value.title
        )

        formData.append(
            'description',
            form.value.description
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

        if (selectedImage.value) {
            formData.append(
                'image',
                selectedImage.value
            )
        }

        const response = await $fetch(
            '/api/concerns',
            {
                method: 'POST',
                body: formData
            }
        )

        showModal.value = false

        selectedImage.value = null

        if (imagePreview.value) {
            URL.revokeObjectURL(imagePreview.value)
        }

        imagePreview.value = ''

        form.value = {
            title: '',
            description: '',
            concern_type_id: '',
            assigned_organization_id: '',
            priority: 'medium'
        }

        /*
         * Reload the concern list so the newly
         * created concern appears immediately.
         */
        await loadConcerns()

        /*
         * Reset current time so the new concern
         * starts counting from the current moment.
         */
        currentTime.value = new Date()

        successMessage.value =
            response?.message ||
            'Concern created successfully.'

    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to create concern.'
    } finally {
        saving.value = false
    }
}

function formatStatus(status) {
    if (!status) return '-'

    return status
        .replaceAll('_', ' ')
        .replace(/\b\w/g, letter =>
            letter.toUpperCase()
        )
}

function formatPriority(priority) {
    if (!priority) return '-'

    return priority.charAt(0).toUpperCase() +
        priority.slice(1)
}

function statusClass(status) {
    switch (status) {
        case 'pending':
            return 'bg-yellow-100 text-yellow-700'

        case 'in_progress':
            return 'bg-blue-100 text-blue-700'

        case 'on_hold':
            return 'bg-orange-100 text-orange-700'

        case 'resolved':
            return 'bg-green-100 text-green-700'

        case 'closed':
            return 'bg-slate-200 text-slate-700'

        case 'cancelled':
            return 'bg-red-100 text-red-700'

        default:
            return 'bg-slate-100 text-slate-700'
    }
}

function priorityClass(priority) {
    switch (priority) {
        case 'low':
            return 'bg-slate-100 text-slate-700'

        case 'medium':
            return 'bg-blue-100 text-blue-700'

        case 'high':
            return 'bg-orange-100 text-orange-700'

        case 'urgent':
            return 'bg-red-100 text-red-700'

        default:
            return 'bg-slate-100 text-slate-700'
    }
}

function formatDate(date) {
    if (!date) return '-'

    const parsedDate = parseDate(date)

    if (!parsedDate) {
        return '-'
    }

    return parsedDate.toLocaleString()
}

/*
 * Convert a MySQL DATETIME value into a JavaScript Date.
 *
 * MySQL normally returns:
 *
 * 2026-10-01 13:30:00
 *
 * JavaScript handles the ISO-style separator more
 * consistently when the space is changed to T.
 */
function parseDate(date) {
    if (!date) return null

    const normalizedDate =
        String(date).replace(' ', 'T')

    const parsedDate =
        new Date(normalizedDate)

    return Number.isNaN(parsedDate.getTime())
        ? null
        : parsedDate
}

/*
 * Calculate how long the concern has existed.
 *
 * Non-closed concern:
 * created_at -> current time
 *
 * Closed concern:
 * created_at -> closed_at
 *
 * Therefore, only a CLOSED concern stops counting.
 */
function getConcernDuration(concern) {
    if (!concern?.created_at) {
        return '-'
    }

    const startDate =
        parseDate(concern.created_at)

    if (!startDate) {
        return '-'
    }

    let endDate

    if (
        concern.status === 'closed' &&
        concern.closed_at
    ) {
        endDate =
            parseDate(concern.closed_at)
    } else {
        endDate = currentTime.value
    }

    if (!endDate) {
        return '-'
    }

    const difference =
        Math.max(
            0,
            endDate.getTime() -
            startDate.getTime()
        )

    const totalMinutes =
        Math.floor(
            difference / 60000
        )

    const days =
        Math.floor(
            totalMinutes / 1440
        )

    const hours =
        Math.floor(
            (totalMinutes % 1440) / 60
        )

    const minutes =
        totalMinutes % 60

    const parts = []

    if (days > 0) {
        parts.push(`${days}d`)
    }

    if (hours > 0) {
        parts.push(`${hours}h`)
    }

    if (
        minutes > 0 ||
        parts.length === 0
    ) {
        parts.push(`${minutes}m`)
    }

    return parts.join(' ')
}

/*
 * Check if the current user is the creator
 * of the selected concern.
 */
function isConcernCreator() {
    if (
        !currentUser.value ||
        !selectedConcern.value
    ) {
        return false
    }

    return (
        Number(
            selectedConcern.value.created_by
        ) ===
        Number(
            currentUser.value.id
        )
    )
}

/*
 * Permission to update the concern status.
 *
 * Superadmin:
 * - Can update concerns that are not already
 *   resolved/closed/cancelled.
 *
 * Admin/User:
 * - Can update their own concern.
 * - Can also update concerns created by someone
 *   from the same organization/department.
 *
 * Once a concern is RESOLVED, only its CREATOR
 * can make another status change.
 *
 * This gives the workflow:
 *
 * Recipient:
 *   Work on concern -> Resolved
 *
 * Creator:
 *   Review completed concern -> Closed
 */
function canUpdateStatus() {
    if (
        !currentUser.value ||
        !selectedConcern.value
    ) {
        return false
    }

    const role =
        currentUser.value.role_name

    const currentStatus =
        selectedConcern.value.status

    /*
     * Closed and cancelled concerns are treated
     * as final from the frontend.
     */
    if (
        currentStatus === 'closed' ||
        currentStatus === 'cancelled'
    ) {
        return false
    }

    /*
     * Once resolved, only the creator can
     * continue the workflow.
     */
    if (currentStatus === 'resolved') {
        return isConcernCreator()
    }

    if (role === 'superadmin') {
        return true
    }

    if (
        role === 'admin' ||
        role === 'user'
    ) {
        const createdByCurrentUser =
            Number(
                selectedConcern.value.created_by
            ) ===
            Number(
                currentUser.value.id
            )

        const creatorSameOrganization =
            Number(
                selectedConcern.value
                    .creator_organization_id
            ) ===
            Number(
                currentUser.value
                    .organization_id
            )

        return (
            createdByCurrentUser ||
            creatorSameOrganization
        )
    }

    return false
}

/*
 * Permission to CLOSE a concern.
 *
 * IMPORTANT:
 *
 * Only the creator can close the concern.
 *
 * The concern must already be RESOLVED.
 *
 * This means:
 *
 * Recipient -> Resolved / Completed
 * Creator   -> Closed
 */
function canCloseConcern() {
    if (
        !currentUser.value ||
        !selectedConcern.value
    ) {
        return false
    }

    return (
        selectedConcern.value.status ===
            'resolved' &&
        Number(
            selectedConcern.value.created_by
        ) ===
        Number(
            currentUser.value.id
        )
    )
}

/*
 * Permission to CANCEL a concern.
 *
 * Superadmin:
 * - Can cancel active concerns.
 *
 * Admin:
 * - Can cancel their own concern.
 * - Can cancel concerns created by someone
 *   in the same organization.
 *
 * User:
 * - Cannot cancel concerns.
 */
function canCancelConcern() {
    if (
        !currentUser.value ||
        !selectedConcern.value
    ) {
        return false
    }

    const role =
        currentUser.value.role_name

    const currentStatus =
        selectedConcern.value.status

    if (
        currentStatus === 'closed' ||
        currentStatus === 'cancelled' ||
        currentStatus === 'resolved'
    ) {
        return false
    }

    if (role === 'superadmin') {
        return true
    }

    if (role === 'admin') {
        const createdByCurrentUser =
            Number(
                selectedConcern.value.created_by
            ) ===
            Number(
                currentUser.value.id
            )

        const creatorSameOrganization =
            Number(
                selectedConcern.value
                    .creator_organization_id
            ) ===
            Number(
                currentUser.value
                    .organization_id
            )

        return (
            createdByCurrentUser ||
            creatorSameOrganization
        )
    }

    return false
}

/*
 * Permission to add comments.
 *
 * Superadmin:
 * - Can comment on any concern.
 *
 * Admin/User:
 * - Can comment on their own concern.
 * - Can comment on concerns created by
 *   someone in the same organization.
 *
 * The creator can be either an admin or a user.
 */
function canComment() {
    if (
        !currentUser.value ||
        !selectedConcern.value
    ) {
        return false
    }

    const role =
        currentUser.value.role_name

    if (role === 'superadmin') {
        return true
    }

    if (
        role === 'admin' ||
        role === 'user'
    ) {
        const createdByCurrentUser =
            Number(
                selectedConcern.value.created_by
            ) ===
            Number(
                currentUser.value.id
            )

        const creatorSameOrganization =
            Number(
                selectedConcern.value
                    .creator_organization_id
            ) ===
            Number(
                currentUser.value
                    .organization_id
            )

        return (
            createdByCurrentUser ||
            creatorSameOrganization
        )
    }

    return false
}

function attachmentUrl(path) {
    if (!path) return ''

    if (
        path.startsWith('http://') ||
        path.startsWith('https://')
    ) {
        return path
    }

    return path
}

async function logout() {
    try {
        await $fetch(
            '/api/auth/logout',
            {
                method: 'POST'
            }
        )
    } finally {
        await navigateTo('/login')
    }
}

onMounted(() => {
    loadData()

    /*
     * Update the current time every minute.
     *
     * This does NOT make an API/database request.
     * It only updates the browser's local timer.
     */
    durationTimer = setInterval(() => {
        currentTime.value = new Date()
    }, 60000)
})

onUnmounted(() => {
    /*
     * Stop the timer when leaving the page.
     */
    if (durationTimer) {
        clearInterval(durationTimer)
        durationTimer = null
    }
})
</script>

<template>
    <div class="min-h-screen bg-slate-100">

        <!-- Sidebar -->
        <aside
            class="fixed inset-y-0 left-0 z-30 w-64 bg-slate-900 text-white"
        >

            <!-- Logo -->
            <div
                class="flex h-16 items-center border-b border-slate-700 px-6"
            >
                <h1 class="text-lg font-bold">
                    Concern Management
                </h1>
            </div>

            <!-- Navigation -->
            <nav class="space-y-2 p-4">

                <NuxtLink
                    to="/dashboard"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Dashboard
                </NuxtLink>

                <NuxtLink
                    v-if="
                        currentUser?.role_name ===
                        'superadmin'
                    "
                    to="/organizations"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Organizations
                </NuxtLink>

                <NuxtLink
                    v-if="
                        currentUser?.role_name ===
                        'superadmin'
                    "
                    to="/users"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Users
                </NuxtLink>

                <NuxtLink
                    to="/concerns"
                    class="block rounded-lg bg-slate-700 px-4 py-3 text-sm font-medium text-white"
                >
                    Concerns
                </NuxtLink>

                <NuxtLink
                    v-if="
                        currentUser?.role_name ===
                            'superadmin' ||
                        currentUser?.role_name ===
                            'admin'
                    "
                    to="/reports"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Reports
                </NuxtLink>

            </nav>

            <!-- Logged-in user -->
            <div
                class="absolute bottom-0 w-full border-t border-slate-700 p-4"
            >

                <div class="mb-3">

                    <p
                        class="truncate text-sm font-medium"
                    >
                        {{ currentUser?.first_name }}
                        {{ currentUser?.last_name }}
                    </p>

                    <p
                        class="truncate text-xs text-slate-400"
                    >
                        {{ currentUser?.role_name }}
                    </p>

                </div>

                <button
                    type="button"
                    @click="logout"
                    class="w-full rounded-lg bg-slate-800 px-4 py-2 text-sm text-slate-300 hover:bg-slate-700"
                >
                    Logout
                </button>

            </div>

        </aside>

        <!-- Main Content -->
        <main class="ml-64 min-h-screen">

            <!-- Header -->
            <header
                class="sticky top-0 z-20 flex h-16 items-center justify-between border-b bg-white px-8"
            >

                <div>

                    <h2
                        class="text-xl font-semibold text-gray-900"
                    >
                        Concerns
                    </h2>

                    <p
                        class="mt-1 text-sm text-slate-500"
                    >
                        View and manage concerns.
                    </p>

                </div>

                <button
                    v-if="
                        currentUser?.role_name ===
                            'admin' ||
                        currentUser?.role_name ===
                            'user'
                    "
                    type="button"
                    @click="openCreateModal"
                    class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800"
                >
                    + Create Concern
                </button>

            </header>

            <!-- Page Body -->
            <div class="p-8">

                <!-- Success -->
                <div
                    v-if="successMessage"
                    class="mb-6 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700"
                >
                    {{ successMessage }}
                </div>

                <!-- Error -->
                <div
                    v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
                >
                    {{ errorMessage }}
                </div>

                <!-- Filters -->
                <div
                    class="mb-6 rounded-xl bg-white p-5 shadow-sm"
                >

                    <div
                        class="grid gap-4 md:grid-cols-3"
                    >

                        <!-- Search -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Search
                            </label>

                            <input
                                v-model="search"
                                type="text"
                                placeholder="Search concern number, title, or description..."
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                        <!-- Status -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Status
                            </label>

                            <select
                                v-model="statusFilter"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500"
                            >

                                <option value="">
                                    All Statuses
                                </option>

                                <option value="pending">
                                    Pending
                                </option>

                                <option value="in_progress">
                                    In Progress
                                </option>

                                <option value="on_hold">
                                    On Hold
                                </option>

                                <option value="resolved">
                                    Resolved
                                </option>

                                <option value="closed">
                                    Closed
                                </option>

                                <option value="cancelled">
                                    Cancelled
                                </option>

                            </select>

                        </div>

                        <!-- Priority -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Priority
                            </label>

                            <select
                                v-model="priorityFilter"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500"
                            >

                                <option value="">
                                    All Priorities
                                </option>

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

                    </div>

                </div>

                <!-- Loading -->
                <div
                    v-if="loading"
                    class="rounded-xl bg-white p-8 text-center text-sm text-slate-500 shadow-sm"
                >
                    Loading concerns...
                </div>

                <!-- Concerns -->
                <div
                    v-else
                    class="overflow-hidden rounded-xl bg-white shadow-sm"
                >

                    <!-- Header -->
                    <div
                        class="flex flex-col gap-2 border-b border-slate-200 px-6 py-5 sm:flex-row sm:items-center sm:justify-between"
                    >

                        <div>

                            <h3
                                class="text-lg font-semibold text-slate-800"
                            >
                                Recent Concerns
                            </h3>

                            <p
                                class="mt-1 text-sm text-slate-500"
                            >
                                View and manage the latest concern records.
                            </p>

                        </div>

                        <div
                            class="rounded-lg bg-slate-50 px-3 py-2 text-sm text-slate-600"
                        >

                            Showing

                            <span
                                class="font-semibold text-slate-800"
                            >
                                {{ filteredConcerns.length }}
                            </span>

                            concern<span
                                v-if="
                                    filteredConcerns.length !==
                                    1
                                "
                            >
                                s
                            </span>

                        </div>

                    </div>

                    <!-- Completed Legend -->
                    <div
                        class="flex items-center gap-2 border-b border-green-100 bg-green-50 px-6 py-3 text-sm text-green-700"
                    >

                        <span
                            class="flex h-6 w-6 items-center justify-center rounded-full bg-green-100 font-bold text-green-700"
                            aria-hidden="true"
                        >
                            ✓
                        </span>

                        <span>
                            <span class="font-semibold">
                                Completed
                            </span>
                            means the concern has been marked as resolved.
                            The creator can review it and close the concern.
                        </span>

                    </div>

                    <!-- Table -->
                    <div class="overflow-x-auto">

                        <table
                            class="min-w-full divide-y divide-slate-200"
                        >

                            <thead
                                class="bg-slate-50"
                            >

                                <tr>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Concern No.
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Title
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Type
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Assigned To
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Priority
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Status
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Created By
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Date
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Duration
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Action
                                    </th>

                                </tr>

                            </thead>

                            <tbody
                                class="divide-y divide-slate-100"
                            >

                                <tr
                                    v-if="
                                        filteredConcerns.length ===
                                        0
                                    "
                                >

                                    <td
                                        colspan="10"
                                        class="px-6 py-10 text-center text-sm text-slate-500"
                                    >
                                        No concerns found.
                                    </td>

                                </tr>

                                <tr
                                    v-for="
                                        concern in filteredConcerns
                                    "
                                    :key="concern.id"
                                    :class="
                                        concern.status === 'resolved'
                                            ? 'border-l-4 border-green-500 bg-green-50 hover:bg-green-100'
                                            : 'hover:bg-slate-50'
                                    "
                                >

                                    <!-- Concern Number -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm font-medium text-slate-800"
                                    >
                                        {{
                                            concern.concern_number
                                        }}
                                    </td>

                                    <!-- Title -->
                                    <td
                                        class="max-w-xs px-6 py-4"
                                    >

                                        <div
                                            class="truncate text-sm font-medium text-slate-800"
                                        >
                                            {{ concern.title }}
                                        </div>

                                        <div
                                            class="mt-1 truncate text-xs text-slate-500"
                                        >
                                            {{
                                                concern.description
                                            }}
                                        </div>

                                    </td>

                                    <!-- Type -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm text-slate-700"
                                    >
                                        {{
                                            concern.concern_type_name ||
                                            '-'
                                        }}
                                    </td>

                                    <!-- Assigned To -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm text-slate-700"
                                    >
                                        {{
                                            concern.organization_name ||
                                            '-'
                                        }}
                                    </td>

                                    <!-- Priority -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4"
                                    >

                                        <span
                                            class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="
                                                priorityClass(
                                                    concern.priority
                                                )
                                            "
                                        >
                                            {{
                                                formatPriority(
                                                    concern.priority
                                                )
                                            }}
                                        </span>

                                    </td>

                                    <!-- Status -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4"
                                    >

                                        <div
                                            class="flex flex-col items-start gap-2"
                                        >

                                            <span
                                                class="rounded-full px-3 py-1 text-xs font-medium"
                                                :class="
                                                    statusClass(
                                                        concern.status
                                                    )
                                                "
                                            >
                                                {{
                                                    formatStatus(
                                                        concern.status
                                                    )
                                                }}
                                            </span>

                                            <!-- Completed Mark -->
                                            <span
                                                v-if="
                                                    concern.status ===
                                                    'resolved'
                                                "
                                                class="inline-flex items-center gap-1 rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700"
                                            >

                                                <span
                                                    aria-hidden="true"
                                                >
                                                    ✓
                                                </span>

                                                Completed

                                            </span>

                                        </div>

                                    </td>

                                    <!-- Created By -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm text-slate-700"
                                    >
                                        {{
                                            concern.created_by_name ||
                                            '-'
                                        }}
                                    </td>

                                    <!-- Date -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm text-slate-500"
                                    >
                                        {{
                                            formatDate(
                                                concern.created_at
                                            )
                                        }}
                                    </td>

                                    <!-- Duration -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm font-semibold text-slate-700"
                                    >
                                        {{
                                            getConcernDuration(
                                                concern
                                            )
                                        }}
                                    </td>

                                    <!-- Action -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4"
                                    >

                                        <button
                                            type="button"
                                            @click="
                                                viewConcern(
                                                    concern
                                                )
                                            "
                                            class="rounded-lg bg-slate-100 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-200"
                                        >
                                            View
                                        </button>

                                    </td>

                                </tr>

                            </tbody>

                        </table>

                    </div>

                </div>

            </div>

        </main>

        <!-- Create Concern Modal -->
        <div
            v-if="showModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4"
        >

            <div
                class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white shadow-xl"
            >

                <!-- Header -->
                <div
                    class="flex items-center justify-between border-b border-slate-200 px-6 py-5"
                >

                    <div>

                        <h3
                            class="text-lg font-bold text-slate-800"
                        >
                            Create Concern
                        </h3>

                        <p
                            class="mt-1 text-sm text-slate-500"
                        >
                            Submit a new concern.
                        </p>

                    </div>

                    <button
                        type="button"
                        @click="closeModal"
                        class="text-2xl text-slate-400 hover:text-slate-700"
                    >
                        ×
                    </button>

                </div>

                <!-- Form -->
                <form
                    @submit.prevent="createConcern"
                    class="space-y-5 p-6"
                >

                    <!-- Title -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Concern Title
                        </label>

                        <input
                            v-model="form.title"
                            type="text"
                            required
                            placeholder="Enter concern title"
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                        />

                    </div>

                    <!-- Description -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Description
                        </label>

                        <textarea
                            v-model="form.description"
                            required
                            rows="5"
                            placeholder="Describe the concern..."
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                        ></textarea>

                    </div>

                    <!-- Image -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Attached Image

                            <span
                                class="font-normal text-slate-400"
                            >
                                (Optional)
                            </span>

                        </label>

                        <input
                            id="concern-image"
                            type="file"
                            accept="image/jpeg,image/png,image/gif,image/webp"
                            @change="handleImageChange"
                            class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none file:mr-4 file:rounded-md file:border-0 file:bg-slate-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:file:bg-slate-200 focus:border-slate-500"
                        />

                        <p
                            class="mt-1 text-xs text-slate-500"
                        >
                            Upload an image related to the concern.
                            Maximum size: 5 MB.
                        </p>

                        <!-- Preview -->
                        <div
                            v-if="imagePreview"
                            class="mt-4 rounded-lg border border-slate-200 bg-slate-50 p-3"
                        >

                            <div
                                class="mb-3 flex items-center justify-between"
                            >

                                <div>

                                    <p
                                        class="text-sm font-medium text-slate-700"
                                    >
                                        Image Preview
                                    </p>

                                    <p
                                        v-if="selectedImage"
                                        class="mt-1 text-xs text-slate-500"
                                    >
                                        {{
                                            selectedImage.name
                                        }}
                                    </p>

                                </div>

                                <button
                                    type="button"
                                    @click="removeImage"
                                    class="text-sm font-medium text-red-600 hover:text-red-700"
                                >
                                    Remove
                                </button>

                            </div>

                            <img
                                :src="imagePreview"
                                alt="Concern attachment preview"
                                class="max-h-64 w-full rounded-lg object-contain"
                            />

                        </div>

                    </div>

                    <!-- Type / Assigned To -->
                    <div
                        class="grid gap-5 md:grid-cols-2"
                    >

                        <!-- Type -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Concern Type
                            </label>

                            <select
                                v-model="form.concern_type_id"
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500"
                            >

                                <option
                                    value=""
                                    disabled
                                >
                                    Select concern type
                                </option>

                                <option
                                    v-for="
                                        type in concernTypes
                                    "
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
                            </label>

                            <select
                                v-model="
                                    form.assigned_organization_id
                                "
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500"
                            >

                                <option
                                    value=""
                                    disabled
                                >
                                    Select organization
                                </option>

                                <option
                                    v-for="
                                        organization in organizations
                                    "
                                    :key="
                                        organization.id
                                    "
                                    :value="
                                        organization.id
                                    "
                                >
                                    {{
                                        organization.name
                                    }}
                                </option>

                            </select>

                            <p
                                v-if="
                                    organizations.length ===
                                    0
                                "
                                class="mt-1 text-xs text-red-500"
                            >
                                No active organizations available.
                            </p>

                        </div>

                    </div>

                    <!-- Priority -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Priority
                        </label>

                        <select
                            v-model="form.priority"
                            required
                            class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500"
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
                        class="flex justify-end gap-3 border-t border-slate-200 pt-5"
                    >

                        <button
                            type="button"
                            @click="closeModal"
                            class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100"
                        >
                            Cancel
                        </button>

                        <button
                            type="submit"
                            :disabled="saving"
                            class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{
                                saving
                                    ? 'Submitting...'
                                    : 'Submit Concern'
                            }}
                        </button>

                    </div>

                </form>

            </div>

        </div>

        <!-- View Concern Modal -->
        <div
            v-if="showViewModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4 py-6"
        >

            <div
                class="flex max-h-[90vh] w-full max-w-4xl flex-col overflow-hidden rounded-xl bg-white shadow-xl"
            >

                <!-- Header -->
                <div
                    class="flex items-center justify-between border-b border-slate-200 px-6 py-5"
                >

                    <div class="min-w-0">

                        <h3
                            class="text-lg font-bold text-slate-800"
                        >
                            View Concern
                        </h3>

                        <p
                            v-if="selectedConcern"
                            class="mt-1 text-sm text-slate-500"
                        >
                            {{
                                selectedConcern.concern_number
                            }}
                        </p>

                    </div>

                    <button
                        type="button"
                        @click="closeViewModal"
                        :disabled="
                            savingComment ||
                            updatingStatus
                        "
                        class="text-2xl text-slate-400 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        ×
                    </button>

                </div>

                <!-- Loading -->
                <div
                    v-if="loadingConcernDetails"
                    class="flex-1 overflow-y-auto p-8 text-center"
                >

                    <p
                        class="text-sm text-slate-500"
                    >
                        Loading concern details...
                    </p>

                </div>

                <!-- Details -->
                <div
                    v-else-if="selectedConcern"
                    class="flex-1 overflow-y-auto"
                >

                    <div class="space-y-6 p-6">

                        <!-- Completed Notice -->
                        <div
                            v-if="
                                selectedConcern.status ===
                                'resolved'
                            "
                            class="flex items-start gap-3 rounded-xl border border-green-200 bg-green-50 p-5"
                        >

                            <div
                                class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-green-100 text-lg font-bold text-green-700"
                            >
                                ✓
                            </div>

                            <div>

                                <p
                                    class="font-semibold text-green-800"
                                >
                                    Concern Completed
                                </p>

                                <p
                                    class="mt-1 text-sm leading-6 text-green-700"
                                >
                                    The concern has been marked as resolved.
                                    The creator can review the result and
                                    close the concern.
                                </p>

                                <p
                                    v-if="!canCloseConcern()"
                                    class="mt-1 text-sm font-medium text-green-700"
                                >
                                    Only the creator of this concern can
                                    close it.
                                </p>

                            </div>

                        </div>

                        <!-- Main Information -->
                        <div
                            class="rounded-xl border border-slate-200 bg-slate-50 p-5"
                        >

                            <div class="mb-5">

                                <div
                                    class="flex flex-wrap items-start justify-between gap-3"
                                >

                                    <div
                                        class="min-w-0 flex-1"
                                    >

                                        <p
                                            class="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500"
                                        >
                                            Concern Title
                                        </p>

                                        <h4
                                            class="break-words text-xl font-bold text-slate-800"
                                        >
                                            {{
                                                selectedConcern.title
                                            }}
                                        </h4>

                                    </div>

                                    <div
                                        class="flex flex-wrap gap-2"
                                    >

                                        <span
                                            class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="
                                                priorityClass(
                                                    selectedConcern.priority
                                                )
                                            "
                                        >
                                            {{
                                                formatPriority(
                                                    selectedConcern.priority
                                                )
                                            }}
                                        </span>

                                        <span
                                            class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="
                                                statusClass(
                                                    selectedConcern.status
                                                )
                                            "
                                        >
                                            {{
                                                formatStatus(
                                                    selectedConcern.status
                                                )
                                            }}
                                        </span>

                                        <!-- Completed Badge -->
                                        <span
                                            v-if="
                                                selectedConcern.status ===
                                                'resolved'
                                            "
                                            class="inline-flex items-center gap-1 rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700"
                                        >

                                            <span
                                                aria-hidden="true"
                                            >
                                                ✓
                                            </span>

                                            Completed

                                        </span>

                                    </div>

                                </div>

                            </div>

                            <!-- Description -->
                            <div class="mb-6">

                                <p
                                    class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500"
                                >
                                    Description
                                </p>

                                <div
                                    class="whitespace-pre-wrap break-words rounded-lg bg-white p-4 text-sm leading-6 text-slate-700"
                                >
                                    {{
                                        selectedConcern.description
                                    }}
                                </div>

                            </div>

                            <!-- Information -->
                            <div
                                class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3"
                            >

                                <div>

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Concern Number
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-medium text-slate-800"
                                    >
                                        {{
                                            selectedConcern.concern_number
                                        }}
                                    </p>

                                </div>

                                <div>

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Concern Type
                                    </p>

                                    <p
                                        class="mt-1 text-sm text-slate-700"
                                    >
                                        {{
                                            selectedConcern.concern_type_name ||
                                            '-'
                                        }}
                                    </p>

                                </div>

                                <!-- Assigned To -->
                                <div>

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Assigned To
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-medium text-slate-700"
                                    >
                                        {{
                                            selectedConcern.organization_name ||
                                            '-'
                                        }}
                                    </p>

                                </div>

                                <div>

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Created By
                                    </p>

                                    <p
                                        class="mt-1 text-sm text-slate-700"
                                    >
                                        {{
                                            selectedConcern.created_by_name ||
                                            '-'
                                        }}
                                    </p>

                                </div>

                                <div>

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Created At
                                    </p>

                                    <p
                                        class="mt-1 text-sm text-slate-700"
                                    >
                                        {{
                                            formatDate(
                                                selectedConcern.created_at
                                            )
                                        }}
                                    </p>

                                </div>

                                <!-- Duration -->
                                <div>

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Duration
                                    </p>

                                    <p
                                        class="mt-1 text-sm font-semibold text-slate-800"
                                    >
                                        {{
                                            getConcernDuration(
                                                selectedConcern
                                            )
                                        }}
                                    </p>

                                </div>

                                <div>

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Updated At
                                    </p>

                                    <p
                                        class="mt-1 text-sm text-slate-700"
                                    >
                                        {{
                                            formatDate(
                                                selectedConcern.updated_at
                                            )
                                        }}
                                    </p>

                                </div>

                                <div
                                    v-if="
                                        selectedConcern.resolved_at
                                    "
                                >

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Resolved At
                                    </p>

                                    <p
                                        class="mt-1 text-sm text-slate-700"
                                    >
                                        {{
                                            formatDate(
                                                selectedConcern.resolved_at
                                            )
                                        }}
                                    </p>

                                </div>

                                <div
                                    v-if="
                                        selectedConcern.closed_at
                                    "
                                >

                                    <p
                                        class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                                    >
                                        Closed At
                                    </p>

                                    <p
                                        class="mt-1 text-sm text-slate-700"
                                    >
                                        {{
                                            formatDate(
                                                selectedConcern.closed_at
                                            )
                                        }}
                                    </p>

                                </div>

                            </div>

                        </div>

                        <!-- Status Update -->
                        <div
                            v-if="canUpdateStatus()"
                            class="rounded-xl border border-slate-200 bg-white p-5"
                        >

                            <div class="mb-4">

                                <h4
                                    class="text-base font-semibold text-slate-800"
                                >
                                    Update Status
                                </h4>

                                <p
                                    class="mt-1 text-sm text-slate-500"
                                >
                                    Change the current status of this concern.
                                </p>

                            </div>

                            <div
                                class="grid gap-4 md:grid-cols-2"
                            >

                                <div>

                                    <label
                                        class="mb-2 block text-sm font-medium text-slate-700"
                                    >
                                        Status
                                    </label>

                                    <select
                                        v-model="selectedStatus"
                                        :disabled="
                                            updatingStatus
                                        "
                                        class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100"
                                    >

                                        <option value="pending">
                                            Pending
                                        </option>

                                        <option value="in_progress">
                                            In Progress
                                        </option>

                                        <option value="on_hold">
                                            On Hold
                                        </option>

                                        <option value="resolved">
                                            Resolved
                                        </option>

                                        <!--
                                         * CLOSED is only visible
                                         * to the creator after the
                                         * concern is resolved.
                                         -->
                                        <option
                                            v-if="
                                                canCloseConcern()
                                            "
                                            value="closed"
                                        >
                                            Closed
                                        </option>

                                        <!--
                                         * Cancelled has its own
                                         * permission.
                                         -->
                                        <option
                                            v-if="
                                                canCancelConcern()
                                            "
                                            value="cancelled"
                                        >
                                            Cancelled
                                        </option>

                                    </select>

                                </div>

                                <div>

                                    <label
                                        class="mb-2 block text-sm font-medium text-slate-700"
                                    >
                                        Remarks

                                        <span
                                            class="font-normal text-slate-400"
                                        >
                                            (Optional)
                                        </span>

                                    </label>

                                    <textarea
                                        v-model="statusRemarks"
                                        :disabled="
                                            updatingStatus
                                        "
                                        rows="3"
                                        placeholder="Add remarks about this status change..."
                                        class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100"
                                    ></textarea>

                                </div>

                            </div>

                            <!-- Creator Close Section -->
                            <div
                                v-if="
                                    selectedConcern.status ===
                                        'resolved' &&
                                    canCloseConcern()
                                "
                                class="mt-5 flex flex-col gap-3 rounded-lg border border-green-200 bg-green-50 p-4 sm:flex-row sm:items-center sm:justify-between"
                            >

                                <div>

                                    <p
                                        class="text-sm font-semibold text-green-800"
                                    >
                                        This concern is completed.
                                    </p>

                                    <p
                                        class="mt-1 text-xs text-green-700"
                                    >
                                        You created this concern, so you can
                                        now close it.
                                    </p>

                                </div>

                                <button
                                    type="button"
                                    @click="
                                        selectedStatus = 'closed';
                                        statusRemarks = '';
                                        updateConcernStatus()
                                    "
                                    :disabled="
                                        updatingStatus
                                    "
                                    class="inline-flex items-center justify-center gap-2 rounded-lg bg-green-600 px-5 py-3 text-sm font-semibold text-white hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-50"
                                >

                                    <span
                                        aria-hidden="true"
                                    >
                                        ✓
                                    </span>

                                    {{
                                        updatingStatus
                                            ? 'Closing...'
                                            : 'Close Concern'
                                    }}

                                </button>

                            </div>

                            <div
                                class="mt-4 flex justify-end"
                            >

                                <button
                                    type="button"
                                    @click="
                                        updateConcernStatus
                                    "
                                    :disabled="
                                        updatingStatus ||
                                        selectedStatus ===
                                            selectedConcern.status
                                    "
                                    class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    {{
                                        updatingStatus
                                            ? 'Updating...'
                                            : 'Update Status'
                                    }}
                                </button>

                            </div>

                        </div>

                        <!-- Attachments -->
                        <div
                            class="rounded-xl border border-slate-200 bg-white p-5"
                        >

                            <div class="mb-4">

                                <h4
                                    class="text-base font-semibold text-slate-800"
                                >
                                    Attachments
                                </h4>

                                <p
                                    class="mt-1 text-sm text-slate-500"
                                >
                                    Images attached to this concern.
                                </p>

                            </div>

                            <div
                                v-if="
                                    concernAttachments.length ===
                                    0
                                "
                                class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500"
                            >
                                No attachments.
                            </div>

                            <div
                                v-else
                                class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3"
                            >

                                <div
                                    v-for="
                                        attachment in concernAttachments
                                    "
                                    :key="attachment.id"
                                    class="overflow-hidden rounded-lg border border-slate-200 bg-slate-50"
                                >

                                    <a
                                        :href="
                                            attachmentUrl(
                                                attachment.file_path
                                            )
                                        "
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="block"
                                    >

                                        <img
                                            v-if="
                                                attachment.file_type?.startsWith(
                                                    'image/'
                                                )
                                            "
                                            :src="
                                                attachmentUrl(
                                                    attachment.file_path
                                                )
                                            "
                                            :alt="
                                                attachment.file_name
                                            "
                                            class="h-48 w-full bg-white object-contain"
                                        />

                                        <div
                                            v-else
                                            class="flex h-48 items-center justify-center text-sm text-slate-500"
                                        >
                                            File attachment
                                        </div>

                                    </a>

                                    <div
                                        class="border-t border-slate-200 p-3"
                                    >

                                        <p
                                            class="truncate text-sm font-medium text-slate-700"
                                            :title="
                                                attachment.file_name
                                            "
                                        >
                                            {{
                                                attachment.file_name
                                            }}
                                        </p>

                                        <p
                                            class="mt-1 text-xs text-slate-500"
                                        >
                                            Uploaded by
                                            {{
                                                attachment.uploaded_by_name ||
                                                '-'
                                            }}
                                        </p>

                                        <p
                                            class="mt-1 text-xs text-slate-400"
                                        >
                                            {{
                                                formatDate(
                                                    attachment.created_at
                                                )
                                            }}
                                        </p>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!-- Status History -->
                        <div
                            class="rounded-xl border border-slate-200 bg-white p-5"
                        >

                            <div class="mb-4">

                                <h4
                                    class="text-base font-semibold text-slate-800"
                                >
                                    Status History
                                </h4>

                                <p
                                    class="mt-1 text-sm text-slate-500"
                                >
                                    Record of status changes.
                                </p>

                            </div>

                            <div
                                v-if="
                                    concernStatusHistory.length ===
                                    0
                                "
                                class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500"
                            >
                                No status history available.
                            </div>

                            <div
                                v-else
                                class="space-y-4"
                            >

                                <div
                                    v-for="
                                        history in concernStatusHistory
                                    "
                                    :key="history.id"
                                    class="rounded-lg border border-slate-200 bg-slate-50 p-4"
                                >

                                    <div
                                        class="flex flex-wrap items-center justify-between gap-3"
                                    >

                                        <div
                                            class="flex flex-wrap items-center gap-2"
                                        >

                                            <span
                                                v-if="
                                                    history.old_status
                                                "
                                                class="rounded-full bg-slate-200 px-3 py-1 text-xs font-medium text-slate-700"
                                            >
                                                {{
                                                    formatStatus(
                                                        history.old_status
                                                    )
                                                }}
                                            </span>

                                            <span
                                                v-if="
                                                    history.old_status
                                                "
                                                class="text-slate-400"
                                            >
                                                →
                                            </span>

                                            <span
                                                class="rounded-full px-3 py-1 text-xs font-medium"
                                                :class="
                                                    statusClass(
                                                        history.new_status
                                                    )
                                                "
                                            >
                                                {{
                                                    formatStatus(
                                                        history.new_status
                                                    )
                                                }}
                                            </span>

                                            <!-- Completed History Mark -->
                                            <span
                                                v-if="
                                                    history.new_status ===
                                                    'resolved'
                                                "
                                                class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-xs font-semibold text-green-700"
                                            >
                                                ✓ Completed
                                            </span>

                                        </div>

                                        <span
                                            class="text-xs text-slate-400"
                                        >
                                            {{
                                                formatDate(
                                                    history.created_at
                                                )
                                            }}
                                        </span>

                                    </div>

                                    <p
                                        class="mt-3 text-xs text-slate-500"
                                    >
                                        Changed by

                                        <span
                                            class="font-medium text-slate-700"
                                        >
                                            {{
                                                history.changed_by_name ||
                                                '-'
                                            }}
                                        </span>
                                    </p>

                                    <p
                                        v-if="history.remarks"
                                        class="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700"
                                    >
                                        {{ history.remarks }}
                                    </p>

                                </div>

                            </div>

                        </div>

                        <!-- Comments -->
                        <div
                            class="rounded-xl border border-slate-200 bg-white p-5"
                        >

                            <div class="mb-4">

                                <h4
                                    class="text-base font-semibold text-slate-800"
                                >
                                    Comments
                                </h4>

                                <p
                                    class="mt-1 text-sm text-slate-500"
                                >
                                    Discussion related to this concern.
                                </p>

                            </div>

                            <!-- Existing Comments -->
                            <div
                                v-if="
                                    concernComments.length ===
                                    0
                                "
                                class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500"
                            >
                                No comments yet.
                            </div>

                            <div
                                v-else
                                class="space-y-4"
                            >

                                <div
                                    v-for="
                                        comment in concernComments
                                    "
                                    :key="comment.id"
                                    class="rounded-lg border border-slate-200 bg-slate-50 p-4"
                                >

                                    <div
                                        class="flex flex-wrap items-start justify-between gap-3"
                                    >

                                        <div>

                                            <p
                                                class="text-sm font-semibold text-slate-800"
                                            >
                                                {{
                                                    comment.user_name ||
                                                    '-'
                                                }}
                                            </p>

                                            <p
                                                class="mt-1 text-xs text-slate-500"
                                            >
                                                {{
                                                    comment.role_name ||
                                                    '-'
                                                }}
                                            </p>

                                        </div>

                                        <p
                                            class="text-xs text-slate-400"
                                        >
                                            {{
                                                formatDate(
                                                    comment.created_at
                                                )
                                            }}
                                        </p>

                                    </div>

                                    <p
                                        class="mt-3 whitespace-pre-wrap break-words text-sm leading-6 text-slate-700"
                                    >
                                        {{
                                            comment.comment
                                        }}
                                    </p>

                                </div>

                            </div>

                            <!-- Add Comment -->
                            <div
                                v-if="canComment()"
                                class="mt-5 border-t border-slate-200 pt-5"
                            >

                                <label
                                    class="mb-2 block text-sm font-medium text-slate-700"
                                >
                                    Add Comment
                                </label>

                                <textarea
                                    v-model="newComment"
                                    :disabled="
                                        savingComment
                                    "
                                    rows="4"
                                    placeholder="Write a comment..."
                                    class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100"
                                ></textarea>

                                <div
                                    class="mt-3 flex justify-end"
                                >

                                    <button
                                        type="button"
                                        @click="addComment"
                                        :disabled="
                                            savingComment ||
                                            !newComment.trim()
                                        "
                                        class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                                    >
                                        {{
                                            savingComment
                                                ? 'Adding...'
                                                : 'Add Comment'
                                        }}
                                    </button>

                                </div>

                            </div>

                        </div>

                    </div>

                </div>

                <!-- Footer -->
                <div
                    class="flex justify-end border-t border-slate-200 bg-white px-6 py-4"
                >

                    <button
                        type="button"
                        @click="closeViewModal"
                        :disabled="
                            savingComment ||
                            updatingStatus
                        "
                        class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        Close
                    </button>

                </div>

            </div>

        </div>

    </div>
</template>
