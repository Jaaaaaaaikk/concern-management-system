<script setup>

definePageMeta({
    middleware: 'auth'
})

const currentUser = ref(null)
const organizations = ref([])

const loading = ref(true)
const errorMessage = ref('')
const successMessage = ref('')

const showModal = ref(false)
const saving = ref(false)

const form = ref({
    name: '',
    description: '',
    address: ''
})

const currentPage = ref(1)
const pageSize = ref(10)
const totalOrganizations = ref(0)
const totalPages = ref(0)

async function loadCurrentUser() {
    try {
        const response = await $fetch('/api/auth/me', {
            cache: 'no-store'
        })

        currentUser.value = response.user
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load current user.'
    }
}

async function loadOrganizations() {
    const response = await $fetch('/api/organizations', {
        cache: 'no-store',
        query: {
            page: currentPage.value,
            limit: pageSize.value
        }
    })

    organizations.value =
        response.organizations || []

    totalOrganizations.value =
        Number(
            response.pagination?.total || 0
        )

    totalPages.value =
        Number(
            response.pagination?.totalPages || 0
        )

    currentPage.value =
        Number(
            response.pagination?.page ||
            currentPage.value
        )
}

async function loadOrganizationsWithLoading() {
    loading.value = true
    errorMessage.value = ''

    try {
        await loadOrganizations()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load organizations.'
    } finally {
        loading.value = false
    }
}

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
            'Failed to load organization data.'
    } finally {
        loading.value = false
    }
}

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
    if (totalOrganizations.value === 0) {
        return 0
    }

    return Math.min(
        currentPage.value * pageSize.value,
        totalOrganizations.value
    )
})

const paginationPages = computed(() => {
    const total = totalPages.value
    const current = currentPage.value

    if (total <= 7) {
        return Array.from(
            { length: total },
            (_, index) => index + 1
        )
    }

    if (current <= 4) {
        return [
            1,
            2,
            3,
            4,
            5,
            '...',
            total
        ]
    }

    if (current >= total - 3) {
        return [
            1,
            '...',
            total - 4,
            total - 3,
            total - 2,
            total - 1,
            total
        ]
    }

    return [
        1,
        '...',
        current - 1,
        current,
        current + 1,
        '...',
        total
    ]
})

async function goToPage(page) {
    if (
        page === '...' ||
        page === currentPage.value ||
        page < 1 ||
        page > totalPages.value
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

    currentPage.value -= 1

    await loadOrganizationsWithLoading()
}

async function goToNextPage() {
    if (
        currentPage.value >= totalPages.value
    ) {
        return
    }

    currentPage.value += 1

    await loadOrganizationsWithLoading()
}

function openAddModal() {
    errorMessage.value = ''
    successMessage.value = ''

    form.value = {
        name: '',
        description: '',
        address: ''
    }

    showModal.value = true
}

function closeModal() {
    if (saving.value) {
        return
    }

    showModal.value = false
}

async function createOrganization() {
    saving.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        await $fetch('/api/organizations', {
            method: 'POST',
            body: {
                name: form.value.name,
                description: form.value.description,
                address: form.value.address
            }
        })

        successMessage.value =
            'Organization created successfully.'

        showModal.value = false

        currentPage.value = 1

        form.value = {
            name: '',
            description: '',
            address: ''
        }

        await loadOrganizationsWithLoading()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to create organization.'
    } finally {
        saving.value = false
    }
}

function statusClass(status) {
    if (status === 'active') {
        return 'bg-green-100 text-green-700'
    }

    return 'bg-red-100 text-red-700'
}

function formatDate(value) {
    if (!value) {
        return '-'
    }

    const date = new Date(value)

    if (Number.isNaN(date.getTime())) {
        return value
    }

    return date.toLocaleString('en-PH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit'
    })
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
        <aside
            class="fixed inset-y-0 left-0 z-40 flex w-64 flex-col bg-slate-900 text-white"
        >
            <div class="border-b border-slate-800 px-6 py-5">
                <h1 class="text-lg font-bold">
                    ICT Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>
            </div>

            <nav class="flex-1 space-y-1 px-3 py-4">
                <NuxtLink
                    to="/dashboard"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >
                    <span>▦</span>
                    <span>Dashboard</span>
                </NuxtLink>

                <NuxtLink
                    v-if="currentUser?.role_name === 'superadmin'"
                    to="/organizations"
                    class="flex items-center gap-3 rounded-lg bg-slate-800 px-4 py-3 text-sm font-medium text-white"
                >
                    <span>▣</span>
                    <span>Manage Organizations</span>
                </NuxtLink>

                <NuxtLink
                    v-if="currentUser?.role_name === 'superadmin'"
                    to="/users"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >
                    <span>♙</span>
                    <span>Manage Users</span>
                </NuxtLink>

                <NuxtLink
                    to="/concerns"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >
                    <span>⚠</span>
                    <span>Manage Concerns</span>
                </NuxtLink>

                <NuxtLink
                    v-if="
                        currentUser?.role_name === 'superadmin' ||
                        currentUser?.role_name === 'admin'
                    "
                    to="/reports"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >
                    <span>▤</span>
                    <span>Manage Reports</span>
                </NuxtLink>
            </nav>

            <div class="border-t border-slate-800 p-4">
                <div class="mb-3 rounded-lg bg-slate-800 p-3">
                    <p class="truncate text-sm font-semibold text-white">
                        {{
                            currentUser
                                ? `${currentUser.first_name || ''} ${currentUser.last_name || ''}`.trim()
                                : '-'
                        }}
                    </p>

                    <p class="mt-1 text-xs text-slate-400">
                        {{ currentUser?.role_name || '-' }}
                    </p>

                    <p
                        v-if="currentUser?.organization_name"
                        class="mt-1 truncate text-xs text-slate-500"
                        :title="currentUser.organization_name"
                    >
                        {{ currentUser.organization_name }}
                    </p>
                </div>

                <button
                    type="button"
                    @click="logout"
                    class="flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg border border-slate-700 px-4 py-2.5 text-sm font-medium text-slate-300 transition hover:border-red-400 hover:bg-red-500/10 hover:text-red-300"
                >
                    Logout
                </button>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="ml-64 min-h-screen">
            <div class="mx-auto w-full max-w-[1600px] px-6 py-8">

                <!-- Header -->
                <div
                    class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
                >
                    <div>
                        <h2 class="text-2xl font-bold text-slate-800">
                            Organizations
                        </h2>

                        <p class="mt-1 text-sm text-slate-500">
                            Manage organizations in the system.
                        </p>
                    </div>

                    <button
                        type="button"
                        @click="openAddModal"
                        class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-slate-800 hover:shadow-md active:scale-[0.99]"
                    >
                        <span class="text-lg leading-none">
                            +
                        </span>

                        Add Organization
                    </button>
                </div>

                <!-- Error -->
                <div
                    v-if="errorMessage"
                    class="mb-5 flex items-start justify-between gap-4 rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700"
                >
                    <p>
                        {{ errorMessage }}
                    </p>

                    <button
                        type="button"
                        @click="errorMessage = ''"
                        class="cursor-pointer text-xl leading-none text-red-400 transition hover:text-red-700"
                    >
                        ×
                    </button>
                </div>

                <!-- Success -->
                <div
                    v-if="successMessage"
                    class="mb-5 flex items-start justify-between gap-4 rounded-xl border border-green-200 bg-green-50 px-5 py-4 text-sm text-green-700"
                >
                    <p>
                        {{ successMessage }}
                    </p>

                    <button
                        type="button"
                        @click="successMessage = ''"
                        class="cursor-pointer text-xl leading-none text-green-400 transition hover:text-green-700"
                    >
                        ×
                    </button>
                </div>

                <!-- Organizations Table -->
                <div
                    class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm"
                >
                    <!-- Table Header -->
                    <div class="border-b border-slate-200 px-5 py-4">
                        <h3 class="text-base font-semibold text-slate-800">
                            Organization List
                        </h3>

                        <p
                            v-if="loading"
                            class="mt-1 flex items-center gap-2 text-xs text-slate-400"
                        >
                            <span
                                class="inline-block h-2.5 w-2.5 animate-pulse rounded-full bg-slate-300"
                            ></span>

                            Loading organizations...
                        </p>

                        <p
                            v-else
                            class="mt-1 text-xs text-slate-500"
                        >
                            <template v-if="totalOrganizations > 0">
                                Showing
                                {{ showingFrom }}–{{ showingTo }}
                                of
                                {{ totalOrganizations }}
                                organization{{ totalOrganizations === 1 ? '' : 's' }}
                            </template>

                            <template v-else>
                                No organizations
                            </template>
                        </p>
                    </div>

                    <!-- Table -->
                    <div class="overflow-x-auto">
                        <table class="min-w-[900px] w-full text-left">
                            <thead class="bg-slate-50">
                                <tr class="border-b border-slate-200">
                                    <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Name
                                    </th>

                                    <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Address
                                    </th>

                                    <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Description
                                    </th>

                                    <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Status
                                    </th>

                                    <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Created
                                    </th>

                                    <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Actions
                                    </th>
                                </tr>
                            </thead>

                            <!-- Loading -->
                            <tbody
                                v-if="loading"
                                class="divide-y divide-slate-100"
                            >
                                <tr
                                    v-for="row in 5"
                                    :key="row"
                                    class="animate-pulse"
                                >
                                    <td class="px-5 py-5">
                                        <div class="h-4 w-36 rounded bg-slate-200"></div>
                                    </td>

                                    <td class="px-5 py-5">
                                        <div class="h-4 w-44 rounded bg-slate-200"></div>
                                    </td>

                                    <td class="px-5 py-5">
                                        <div class="h-4 w-52 rounded bg-slate-200"></div>
                                    </td>

                                    <td class="px-5 py-5">
                                        <div class="h-6 w-16 rounded-full bg-slate-200"></div>
                                    </td>

                                    <td class="px-5 py-5">
                                        <div class="h-4 w-32 rounded bg-slate-200"></div>
                                    </td>

                                    <td class="px-5 py-5">
                                        <div class="h-9 w-20 rounded bg-slate-200"></div>
                                    </td>
                                </tr>
                            </tbody>

                            <!-- Empty -->
                            <tbody
                                v-else-if="organizations.length === 0"
                                class="divide-y divide-slate-100"
                            >
                                <tr>
                                    <td
                                        colspan="6"
                                        class="px-5 py-12 text-center"
                                    >
                                        <p class="text-sm font-medium text-slate-600">
                                            No organizations found.
                                        </p>

                                        <p class="mt-1 text-xs text-slate-400">
                                            There are no organizations to display.
                                        </p>
                                    </td>
                                </tr>
                            </tbody>

                            <!-- Organizations -->
                            <tbody
                                v-else
                                class="divide-y divide-slate-100"
                            >
                                <tr
                                    v-for="organization in organizations"
                                    :key="organization.id"
                                    class="transition hover:bg-slate-50"
                                >
                                    <td class="whitespace-nowrap px-5 py-4 text-sm font-semibold text-slate-700">
                                        {{ organization.name }}
                                    </td>

                                    <td class="px-5 py-4 text-sm text-slate-600">
                                        {{ organization.address || '-' }}
                                    </td>

                                    <td class="px-5 py-4 text-sm text-slate-600">
                                        {{ organization.description || '-' }}
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <span
                                            class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(organization.status)"
                                        >
                                            {{
                                                organization.status === 'active'
                                                    ? 'Active'
                                                    : 'Inactive'
                                            }}
                                        </span>
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4 text-sm text-slate-500">
                                        {{ formatDate(organization.created_at) }}
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <button
                                            type="button"
                                            class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                                        >
                                            Edit
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination -->
                    <div
                        v-if="!loading && totalPages > 1"
                        class="flex flex-col gap-3 border-t border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between"
                    >
                        <p class="text-xs text-slate-500">
                            Page
                            {{ currentPage }}
                            of
                            {{ totalPages }}
                        </p>

                        <div class="flex items-center gap-1">
                            <button
                                type="button"
                                @click="goToPreviousPage"
                                :disabled="currentPage === 1"
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
                            >
                                Previous
                            </button>

                            <template
                                v-for="(page, index) in paginationPages"
                                :key="`${page}-${index}`"
                            >
                                <span
                                    v-if="page === '...'"
                                    class="px-2 py-2 text-sm text-slate-400"
                                >
                                    ...
                                </span>

                                <button
                                    v-else
                                    type="button"
                                    @click="goToPage(page)"
                                    :class="
                                        page === currentPage
                                            ? 'bg-slate-900 text-white'
                                            : 'border border-slate-300 text-slate-600 hover:bg-slate-50'
                                    "
                                    class="min-w-9 cursor-pointer rounded-lg px-3 py-2 text-sm font-medium transition"
                                >
                                    {{ page }}
                                </button>
                            </template>

                            <button
                                type="button"
                                @click="goToNextPage"
                                :disabled="
                                    currentPage === totalPages ||
                                    totalPages === 0
                                "
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
                            >
                                Next
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- Add Organization Modal -->
        <div
            v-if="showModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
        >
            <div class="w-full max-w-lg rounded-xl bg-white shadow-xl">
                <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5">
                    <div>
                        <h3 class="text-lg font-semibold text-slate-800">
                            Add Organization
                        </h3>

                        <p class="mt-1 text-sm text-slate-500">
                            Create a new organization.
                        </p>
                    </div>

                    <button
                        type="button"
                        @click="closeModal"
                        class="cursor-pointer text-2xl leading-none text-slate-400 hover:text-slate-700"
                    >
                        ×
                    </button>
                </div>

                <form
                    @submit.prevent="createOrganization"
                    class="space-y-5 px-6 py-6"
                >
                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Name
                        </label>

                        <input
                            v-model="form.name"
                            type="text"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />
                    </div>

                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Address
                        </label>

                        <textarea
                            v-model="form.address"
                            rows="3"
                            class="w-full resize-none rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        ></textarea>
                    </div>

                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Description
                        </label>

                        <textarea
                            v-model="form.description"
                            rows="4"
                            class="w-full resize-none rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        ></textarea>
                    </div>

                    <div class="flex justify-end gap-3 border-t border-slate-200 pt-5">
                        <button
                            type="button"
                            @click="closeModal"
                            :disabled="saving"
                            class="cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            Cancel
                        </button>

                        <button
                            type="submit"
                            :disabled="saving"
                            class="cursor-pointer rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{
                                saving
                                    ? 'Creating...'
                                    : 'Create Organization'
                            }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>