```vue
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

async function loadCurrentUser() {
    try {
        const response = await $fetch('/api/auth/me')

        currentUser.value = response.user
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load current user.'
    }
}

async function loadConcerns() {
    try {
        const response = await $fetch('/api/concerns')

        concerns.value = response.concerns || []
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load concerns.'
    }
}

async function loadConcernTypes() {
    try {
        const response = await $fetch('/api/concern-types')

        concernTypes.value = response.concernTypes || []
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load concern types.'
    }
}

async function loadOrganizations() {
    try {
        const response = await $fetch('/api/organizations')

        organizations.value = response.organizations || []
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
}

async function createConcern() {
    saving.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        await $fetch('/api/concerns', {
            method: 'POST',
            body: {
                title: form.value.title,
                description: form.value.description,
                concern_type_id: Number(form.value.concern_type_id),
                assigned_organization_id: Number(
                    form.value.assigned_organization_id
                ),
                priority: form.value.priority
            }
        })

        successMessage.value =
            'Concern created successfully.'

        showModal.value = false

        await loadConcerns()
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
        .replace(/\b\w/g, letter => letter.toUpperCase())
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

    return new Date(date).toLocaleString()
}

async function logout() {
    try {
        await $fetch('/api/auth/logout', {
            method: 'POST'
        })
    } finally {
        await navigateTo('/login')
    }
}

onMounted(() => {
    loadData()
})
</script>

<template>
    <div class="min-h-screen bg-slate-100">

        <!-- Sidebar -->
        <aside class="fixed inset-y-0 left-0 z-30 w-64 bg-slate-900 text-white">

            <!-- Logo -->
            <div class="flex h-16 items-center border-b border-slate-700 px-6">
                <h1 class="text-lg font-bold">
                    Concern Management
                </h1>
            </div>

            <!-- Navigation -->
            <nav class="space-y-2 p-4">

                <!-- Dashboard -->
                <NuxtLink to="/dashboard" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Dashboard
                </NuxtLink>

                <!-- Organizations -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/organizations"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Organizations
                </NuxtLink>

                <!-- Users -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/users"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Users
                </NuxtLink>

                <!-- Concerns -->
                <NuxtLink to="/concerns" class="block rounded-lg bg-slate-700 px-4 py-3 text-sm font-medium text-white">
                    Concerns
                </NuxtLink>

                <!-- Reports -->
                <NuxtLink v-if="
                    currentUser?.role_name === 'superadmin' ||
                    currentUser?.role_name === 'admin'
                " to="/reports" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Reports
                </NuxtLink>

            </nav>

            <!-- Logged-in user -->
            <div class="absolute bottom-0 w-full border-t border-slate-700 p-4">

                <div class="mb-3">
                    <p class="truncate text-sm font-medium">
                        {{ currentUser?.first_name }}
                        {{ currentUser?.last_name }}
                    </p>

                    <p class="truncate text-xs text-slate-400">
                        {{ currentUser?.role_name }}
                    </p>
                </div>

                <button @click="logout"
                    class="w-full rounded-lg bg-slate-800 px-4 py-2 text-sm text-slate-300 hover:bg-slate-700">
                    Logout
                </button>

            </div>

        </aside>

        <!-- Main content -->
        <main class="ml-64 min-h-screen">

            <!-- Header -->
            <header class="sticky top-0 z-20 flex h-16 items-center justify-between border-b bg-white px-8">

                <div class="flex items-center justify-between">

                    <div>
                        <h2 class="text-xl font-semibold text-gray-900">
                            Concerns
                        </h2>

                        <p class="mt-1 text-sm text-slate-500">
                            View and manage concerns.
                        </p>
                    </div>

                    <!-- Create Concern -->
                    <!-- Only Admin and User can create -->
                    <button v-if="
                        currentUser?.role_name === 'admin' ||
                        currentUser?.role_name === 'user'
                    " @click="openCreateModal"
                        class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800">
                        + Create Concern
                    </button>

                </div>

            </header>

            <!-- Page body -->
            <div class="p-8">

                <!-- Success message -->
                <div v-if="successMessage"
                    class="mb-6 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700">
                    {{ successMessage }}
                </div>

                <!-- Error message -->
                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {{ errorMessage }}
                </div>

                <!-- Filters -->
                <div class="mb-6 rounded-xl bg-white p-5 shadow-sm">

                    <div class="grid gap-4 md:grid-cols-3">

                        <!-- Search -->
                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Search
                            </label>

                            <input v-model="search" type="text"
                                placeholder="Search concern number, title, or description..."
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <!-- Status -->
                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Status
                            </label>

                            <select v-model="statusFilter"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">

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
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Priority
                            </label>

                            <select v-model="priorityFilter"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">

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
                <div v-if="loading" class="rounded-xl bg-white p-8 text-center text-sm text-slate-500 shadow-sm">
                    Loading concerns...
                </div>

                <!-- Concerns table -->
                <div v-else class="overflow-hidden rounded-xl bg-white shadow-sm">

                    <div class="overflow-x-auto">

                        <table class="min-w-full divide-y divide-slate-200">

                            <thead class="bg-slate-50">
                                <tr>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Concern No.
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Title
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Type
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Organization
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Priority
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Status
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Created By
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Date
                                    </th>

                                </tr>
                            </thead>

                            <tbody class="divide-y divide-slate-100">

                                <!-- No concerns -->
                                <tr v-if="filteredConcerns.length === 0">
                                    <td colspan="8" class="px-6 py-10 text-center text-sm text-slate-500">
                                        No concerns found.
                                    </td>
                                </tr>

                                <!-- Concern rows -->
                                <tr v-for="concern in filteredConcerns" :key="concern.id" class="hover:bg-slate-50">

                                    <!-- Concern number -->
                                    <td class="whitespace-nowrap px-6 py-4 text-sm font-medium text-slate-800">
                                        {{ concern.concern_number }}
                                    </td>

                                    <!-- Title -->
                                    <td class="max-w-xs px-6 py-4">

                                        <div class="truncate text-sm font-medium text-slate-800">
                                            {{ concern.title }}
                                        </div>

                                        <div class="mt-1 truncate text-xs text-slate-500">
                                            {{ concern.description }}
                                        </div>

                                    </td>

                                    <!-- Concern type -->
                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-700">
                                        {{ concern.concern_type_name || '-' }}
                                    </td>

                                    <!-- Organization -->
                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-700">
                                        {{ concern.organization_name || '-' }}
                                    </td>

                                    <!-- Priority -->
                                    <td class="whitespace-nowrap px-6 py-4">

                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="priorityClass(concern.priority)">
                                            {{ formatPriority(concern.priority) }}
                                        </span>

                                    </td>

                                    <!-- Status -->
                                    <td class="whitespace-nowrap px-6 py-4">

                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(concern.status)">
                                            {{ formatStatus(concern.status) }}
                                        </span>

                                    </td>

                                    <!-- Created by -->
                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-700">
                                        {{ concern.created_by_name || '-' }}
                                    </td>

                                    <!-- Date -->
                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-500">
                                        {{ formatDate(concern.created_at) }}
                                    </td>

                                </tr>

                            </tbody>

                        </table>

                    </div>

                </div>

            </div>

        </main>

        <!-- Create Concern Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">

            <div class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white shadow-xl">

                <!-- Modal header -->
                <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5">

                    <div>

                        <h3 class="text-lg font-bold text-slate-800">
                            Create Concern
                        </h3>

                        <p class="mt-1 text-sm text-slate-500">
                            Submit a new concern.
                        </p>

                    </div>

                    <button @click="closeModal" class="text-2xl text-slate-400 hover:text-slate-700">
                        ×
                    </button>

                </div>

                <!-- Form -->
                <form @submit.prevent="createConcern" class="space-y-5 p-6">

                    <!-- Title -->
                    <div>

                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Concern Title
                        </label>

                        <input v-model="form.title" type="text" required placeholder="Enter concern title"
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />

                    </div>

                    <!-- Description -->
                    <div>

                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Description
                        </label>

                        <textarea v-model="form.description" required rows="5" placeholder="Describe the concern..."
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"></textarea>

                    </div>

                    <!-- Type and Organization -->
                    <div class="grid gap-5 md:grid-cols-2">

                        <!-- Concern Type -->
                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Concern Type
                            </label>

                            <select v-model="form.concern_type_id" required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">

                                <option value="" disabled>
                                    Select concern type
                                </option>

                                <option v-for="type in concernTypes" :key="type.id" :value="type.id">
                                    {{ type.name }}
                                </option>

                            </select>

                        </div>

                        <!-- Organization -->
                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Assigned Organization
                            </label>

                            <select v-model="form.assigned_organization_id" required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">

                                <option value="" disabled>
                                    Select organization
                                </option>

                                <option v-for="organization in organizations" :key="organization.id"
                                    :value="organization.id">
                                    {{ organization.name }}
                                </option>

                            </select>

                        </div>

                    </div>

                    <!-- Priority -->
                    <div>

                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Priority
                        </label>

                        <select v-model="form.priority" required
                            class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">

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
                    <div class="flex justify-end gap-3 border-t border-slate-200 pt-5">

                        <button type="button" @click="closeModal"
                            class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100">
                            Cancel
                        </button>

                        <button type="submit" :disabled="saving"
                            class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50">
                            {{ saving ? 'Submitting...' : 'Submit Concern' }}
                        </button>

                    </div>

                </form>

            </div>

        </div>

    </div>
</template>