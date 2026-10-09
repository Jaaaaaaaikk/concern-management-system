<script setup>

import CreateOrganizationModal from '../components/organizations/CreateOrganizationModal.vue'
import EditOrganizationModal from '../components/organizations/EditOrganizationModal.vue'
import { useToast } from '~/composables/useToast'

definePageMeta({
    middleware: 'auth'
})

const currentUser = useState('current-user', () => null)
const organizations = ref([])
const loading = ref(true)
const errorMessage = ref('')
const { showToast } = useToast()
const showCreateModal = ref(false)
const showEditModal = ref(false)
const saving = ref(false)
const updating = ref(false)

const createForm = ref({
    name: '',
    description: '',
    address: ''
})

const editForm = ref({
    name: '',
    description: '',
    address: ''
})

const editingOrganization = ref(null)

const currentPage = ref(1)
const pageSize = ref(10)
const totalOrganizations = ref(0)
const totalPages = ref(0)

// --------------------------------------------------
// LOAD CURRENT USER
// --------------------------------------------------

async function loadCurrentUser() {
    const response = await $fetch(
        '/api/auth/me',
        {
            cache: 'no-store'
        }
    )

    currentUser.value = response.user
}


// --------------------------------------------------
// LOAD ORGANIZATIONS
// --------------------------------------------------

async function loadOrganizations() {
    const response = await $fetch(
        '/api/organizations',
        {
            credentials: 'include',
            query: {
                page: currentPage.value,
                limit: pageSize.value
            }
        }
    )

    organizations.value =
        response?.organizations || []

    const pagination =
        response?.pagination || {}

    totalOrganizations.value =
        Number(pagination.total || 0)

    totalPages.value =
        Number(pagination.totalPages || 0)

    currentPage.value =
        Number(pagination.page || 1)
}


// --------------------------------------------------
// LOAD ORGANIZATIONS WITH LOADING STATE
// --------------------------------------------------

async function loadOrganizationsWithLoading() {
    loading.value = true
    errorMessage.value = ''

    try {
        await loadOrganizations()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load organizations.'
    } finally {
        loading.value = false
    }
}


// --------------------------------------------------
// LOAD PAGE DATA
// --------------------------------------------------

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    try {
        await Promise.all([
            loadCurrentUser(),
            loadOrganizations()
        ])
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load organizations.'
    } finally {
        loading.value = false
    }
}


// --------------------------------------------------
// PAGINATION
// --------------------------------------------------

const showingFrom = computed(() => {
    if (totalOrganizations.value === 0) {
        return 0
    }

    return (
        (currentPage.value - 1) *
        pageSize.value
    ) + 1
})

const showingTo = computed(() => {
    return Math.min(
        currentPage.value * pageSize.value,
        totalOrganizations.value
    )
})

const paginationPages = computed(() => {
    const pages = []
    const total = totalPages.value

    if (total <= 7) {
        for (
            let page = 1;
            page <= total;
            page++
        ) {
            pages.push(page)
        }

        return pages
    }

    pages.push(1)

    if (currentPage.value > 4) {
        pages.push('...')
    }

    const start = Math.max(
        2,
        currentPage.value - 1
    )

    const end = Math.min(
        total - 1,
        currentPage.value + 1
    )

    for (
        let page = start;
        page <= end;
        page++
    ) {
        if (!pages.includes(page)) {
            pages.push(page)
        }
    }

    if (currentPage.value < total - 3) {
        pages.push('...')
    }

    if (!pages.includes(total)) {
        pages.push(total)
    }

    return pages
})

async function goToPage(page) {
    if (
        page === '...' ||
        page < 1 ||
        page > totalPages.value ||
        page === currentPage.value
    ) {
        return
    }

    currentPage.value = page

    await loadOrganizationsWithLoading()
}

async function goToPreviousPage() {
    if (currentPage.value <= 1) {
        return
    }

    currentPage.value--

    await loadOrganizationsWithLoading()
}

async function goToNextPage() {
    if (
        currentPage.value >= totalPages.value
    ) {
        return
    }

    currentPage.value++

    await loadOrganizationsWithLoading()
}


// --------------------------------------------------
// CREATE ORGANIZATION
// --------------------------------------------------

function resetCreateForm() {
    createForm.value = {
        name: '',
        description: '',
        address: ''
    }
}

function openAddModal() {
    errorMessage.value = ''
    resetCreateForm()
    showCreateModal.value = true
}

function closeCreateModal() {
    if (saving.value) {
        return
    }

    showCreateModal.value = false
}

async function createOrganization() {
    if (saving.value) {
        return
    }

    saving.value = true
    errorMessage.value = ''

    try {
        await $fetch(
            '/api/organizations',
            {
                method: 'POST',
                credentials: 'include',
                body: {
                    name: createForm.value.name,
                    description: createForm.value.description,
                    address: createForm.value.address
                }
            }
        )

        showCreateModal.value = false
        currentPage.value = 1
        resetCreateForm()

        await loadOrganizationsWithLoading()

        showToast(
            'Organization created successfully.'
        )
    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            'Failed to create organization.',
            'error'
        )
    } finally {
        saving.value = false
    }
}


// --------------------------------------------------
// EDIT ORGANIZATION
// --------------------------------------------------

function resetEditForm() {
    editForm.value = {
        name: '',
        description: '',
        address: ''
    }

    editingOrganization.value = null
}

function openEditModal(organization) {
    errorMessage.value = ''

    editingOrganization.value = organization

    editForm.value = {
        name: organization?.name || '',
        description: organization?.description || '',
        address: organization?.address || ''
    }

    showEditModal.value = true
}

function closeEditModal() {
    if (updating.value) {
        return
    }

    showEditModal.value = false
    resetEditForm()
}

async function updateOrganization() {
    if (
        updating.value ||
        !editingOrganization.value?.id
    ) {
        return
    }

    updating.value = true
    errorMessage.value = ''

    try {
        await $fetch(
            `/api/organizations/${editingOrganization.value.id}`,
            {
                method: 'PUT',
                credentials: 'include',
                body: {
                    name: editForm.value.name,
                    description: editForm.value.description,
                    address: editForm.value.address
                }
            }
        )

        showEditModal.value = false
        resetEditForm()

        await loadOrganizationsWithLoading()

        showToast(
            'Organization updated successfully.'
        )
    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            'Failed to update organization.',
            'error'
        )
    } finally {
        updating.value = false
    }
}


// --------------------------------------------------
// STATUS
// --------------------------------------------------

function statusClass(status) {
    if (status === 'active') {
        return 'bg-green-100 text-green-700'
    }

    return 'bg-red-100 text-red-700'
}


// --------------------------------------------------
// DATE
// --------------------------------------------------

function formatDate(date) {
    if (!date) {
        return '-'
    }

    return new Date(date).toLocaleString(
        'en-PH',
        {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        }
    )
}


// --------------------------------------------------
// LOGOUT
// --------------------------------------------------

async function logout() {
    try {
        await $fetch(
            '/api/auth/logout',
            {
                method: 'POST',
                credentials: 'include'
            }
        )
    } catch (error) {
        console.error(
            'Logout error:',
            error
        )
    }

    await navigateTo('/login')
}

function updateProfilePhoto(profilePhoto) {
    if (currentUser.value) {
        currentUser.value.profile_photo = profilePhoto
    }
}


// --------------------------------------------------
// MOUNT / UNMOUNT
// --------------------------------------------------

onMounted(() => {
    loadData()
})

</script>

<template>

    <div class="min-h-screen bg-slate-100">

        <MobileNavigation :current-user="currentUser" @logout="logout" @profile-updated="updateProfilePhoto" />

        <!-- Sidebar -->

        <aside class="fixed inset-y-0 left-0 z-40 hidden w-64 flex-col bg-blue-950 text-white lg:flex">

            <div class="border-b border-blue-900 px-6 py-5">

                <h1 class="text-lg font-bold">
                    Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>

            </div>


            <nav class="flex-1 space-y-1 px-3 py-4">

                <NuxtLink to="/dashboard"
                    :class="$route.path === '/dashboard' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-blue-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="dashboard" />
                    <span>Dashboard</span>
                </NuxtLink>


                <NuxtLink to="/organizations"
                    :class="$route.path === '/organizations' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-blue-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="organizations" />
                    <span>Manage Organizations</span>
                </NuxtLink>

                <NuxtLink to="/concerns"
                    :class="$route.path === '/concerns' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-blue-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="concerns" />
                    <span>Manage Concerns</span>
                </NuxtLink>

                <NuxtLink to="/users"
                    :class="$route.path === '/users' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-blue-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="users" />
                    <span>Manage Users</span>
                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/login-history"
                    :class="$route.path === '/login-history' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-blue-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="history" />
                    <span>Login History</span>
                </NuxtLink>


            </nav>


            <div class="border-t border-blue-900 p-4">
                <UserProfileControl :current-user="currentUser" @logout="logout"
                    @profile-updated="updateProfilePhoto" />
            </div>

        </aside>


        <!-- Main -->

        <main class="flex min-h-screen flex-col lg:ml-64">

            <!-- Header -->

            <header class="border-b border-slate-200 bg-white px-4 py-5 sm:px-6 lg:px-8">

                <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">

                    <div>

                        <h2 class="text-xl font-semibold text-slate-800">
                            Manage Organizations
                        </h2>

                        <p class="mt-1 text-sm text-slate-500">
                            Manage organizations registered in the system.
                        </p>

                    </div>


                    <button type="button" @click="openAddModal"
                        class="w-full cursor-pointer rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-blue-800 sm:w-auto">
                        + Add Organization
                    </button>

                </div>

            </header>


            <!-- Content -->

            <div class="p-4 sm:p-8">

                <!-- Error -->

                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {{ errorMessage }}
                </div>


                <!-- Loading -->

                <div v-if="loading" class="rounded-xl border border-slate-300 bg-white p-8 text-center shadow-md">

                    <p class="text-sm text-slate-500">
                        Loading organizations...
                    </p>

                </div>


                <!-- Table -->

                <div v-else class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">

                    <div class="overflow-x-auto">

                        <table class="min-w-full divide-y divide-slate-200">

                            <thead class="bg-slate-50">

                                <tr>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Name
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Address
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Description
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Status
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Created
                                    </th>

                                    <th
                                        class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Actions
                                    </th>

                                </tr>

                            </thead>


                            <tbody class="divide-y divide-slate-200">

                                <tr v-if="organizations.length === 0">

                                    <td colspan="6" class="px-6 py-10 text-center text-sm text-slate-500">
                                        No organizations found.
                                    </td>

                                </tr>


                                <tr v-for="(organization, index) in organizations" :key="organization.id"
                                    :class="index % 2 === 0 ? 'bg-white hover:bg-slate-50' : 'bg-slate-50 hover:bg-slate-100'"
                                    class="transition">

                                    <td class="whitespace-nowrap px-6 py-4 text-sm font-medium text-slate-800">
                                        {{ organization.name }}
                                    </td>


                                    <td class="max-w-xs px-6 py-4 text-sm text-slate-600">

                                        <div class="line-clamp-2">
                                            {{
                                                organization.address ||
                                                '-'
                                            }}
                                        </div>

                                    </td>


                                    <td class="max-w-xs px-6 py-4 text-sm text-slate-600">

                                        <div class="line-clamp-2">
                                            {{
                                                organization.description ||
                                                '-'
                                            }}
                                        </div>

                                    </td>


                                    <td class="whitespace-nowrap px-6 py-4">

                                        <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-medium"
                                            :class="statusClass(organization.status)">
                                            {{ organization.status }}
                                        </span>

                                    </td>


                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                                        {{ formatDate(organization.created_at) }}
                                    </td>


                                    <td class="whitespace-nowrap px-6 py-4 text-right">

                                        <button type="button" @click="openEditModal(organization)"
                                            class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-xs font-medium text-slate-600 transition hover:bg-slate-50">
                                            Edit
                                        </button>

                                    </td>

                                </tr>

                            </tbody>

                        </table>

                    </div>


                    <!-- Pagination -->

                    <div v-if="totalOrganizations > 0"
                        class="flex flex-col gap-4 border-t border-slate-200 px-6 py-4 sm:flex-row sm:items-center sm:justify-between">

                        <p class="text-sm text-slate-500">

                            Showing

                            <span class="font-medium text-slate-700">
                                {{ showingFrom }}
                            </span>

                            to

                            <span class="font-medium text-slate-700">
                                {{ showingTo }}
                            </span>

                            of

                            <span class="font-medium text-slate-700">
                                {{ totalOrganizations }}
                            </span>

                            organizations

                        </p>


                        <div class="flex items-center gap-1">

                            <button type="button" @click="goToPreviousPage" :disabled="currentPage === 1"
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                                Previous
                            </button>


                            <template v-for="page in paginationPages" :key="`page-${page}`">

                                <span v-if="page === '...'" class="px-2 py-2 text-sm text-slate-400">
                                    ...
                                </span>


                                <button v-else type="button" @click="goToPage(page)"
                                    class="cursor-pointer rounded-lg px-3 py-2 text-sm transition" :class="currentPage === page
                                        ? 'bg-blue-900 text-white'
                                        : 'border border-slate-300 text-slate-600 hover:bg-slate-50'
                                        ">
                                    {{ page }}
                                </button>

                            </template>


                            <button type="button" @click="goToNextPage" :disabled="currentPage === totalPages ||
                                totalPages === 0
                                "
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                                Next
                            </button>

                        </div>

                    </div>

                </div>

            </div>

            <AppFooter class="mt-auto" />
        </main>


        <!-- Create Organization Modal -->

        <CreateOrganizationModal :show="showCreateModal" :form="createForm" :saving="saving" @close="closeCreateModal"
            @submit="createOrganization" />


        <!-- Edit Organization Modal -->

        <EditOrganizationModal :show="showEditModal" :form="editForm" :updating="updating" @close="closeEditModal"
            @submit="updateOrganization" />

    </div>

</template>
