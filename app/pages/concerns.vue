<script setup>

import ViewConcernModal from '~/components/concerns/ViewConcernModal.vue'

import CreateConcernModal from '~/components/concerns/CreateConcernModal.vue'
import { useToast } from '~/composables/useToast'

definePageMeta({
    middleware: 'auth'
})

let searchTimeout = null
const { showToast } = useToast()

const concerns = ref([])
const concernTypes = ref([])
const organizations = ref([])
const currentUser = useState('current-user', () => null)

const loading = ref(true)
const exporting = ref(false)

const errorMessage = ref('')

const showModal = ref(false)
const showExportModal = ref(false)

const route = useRoute()

const search = ref('')
const statusFilter = ref(
    String(route.query.status || '').trim()
)
const priorityFilter = ref('')
const exportDateFilter = ref('')

const showViewModal = ref(false)
const selectedConcernId = ref(null)

/*
 * PAGINATION
 */

const currentPage = ref(1)
const pageSize = ref(10)
const totalConcerns = ref(0)
const totalPages = ref(0)

/*
 * CURRENT TIME / HANDLING DURATION
 */

const currentTime = ref(new Date())
let durationTimer = null

/*
 * PAGINATION DISPLAY
 */

const showingFrom = computed(() => {
    if (totalConcerns.value === 0) {
        return 0
    }

    return (
        (currentPage.value - 1) *
        pageSize.value
    ) + 1
})

const showingTo = computed(() => {
    if (totalConcerns.value === 0) {
        return 0
    }

    return Math.min(
        currentPage.value * pageSize.value,
        totalConcerns.value
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

    const pages = []

    pages.push(1)

    if (current > 4) {
        pages.push('...')
    }

    const start = Math.max(
        2,
        current - 1
    )

    const end = Math.min(
        total - 1,
        current + 1
    )

    for (
        let page = start;
        page <= end;
        page++
    ) {
        pages.push(page)
    }

    if (current < total - 3) {
        pages.push('...')
    }

    pages.push(total)

    return pages
})

/*
 * DISPLAY HELPERS
 */

function formatStatus(status) {
    const labels = {
        pending: 'Pending',
        in_progress: 'In Progress',
        on_hold: 'On Hold',
        resolved: 'Resolved',
        closed: 'Closed'
    }

    return labels[status] || status || '-'
}

function formatPriority(priority) {
    const labels = {
        low: 'Low',
        medium: 'Medium',
        high: 'High',
        urgent: 'Urgent'
    }

    return labels[priority] || priority || '-'
}

function statusClass(status) {
    const classes = {
        pending: 'bg-amber-100 text-amber-700',
        in_progress: 'bg-blue-100 text-blue-700',
        on_hold: 'bg-orange-100 text-orange-700',
        resolved: 'bg-green-100 text-green-700',
        closed: 'bg-slate-200 text-slate-700'
    }

    return (
        classes[status] ||
        'bg-slate-100 text-slate-600'
    )
}

function priorityClass(priority) {
    const classes = {
        low: 'bg-slate-100 text-slate-600',
        medium: 'bg-blue-100 text-blue-700',
        high: 'bg-orange-100 text-orange-700',
        urgent: 'bg-red-100 text-red-700'
    }

    return (
        classes[priority] ||
        'bg-slate-100 text-slate-600'
    )
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

function parseDate(value) {
    if (!value) {
        return null
    }

    const date = new Date(value)

    if (Number.isNaN(date.getTime())) {
        return null
    }

    return date
}

function getConcernDuration(concern) {
    if (!concern?.acknowledged_at) {
        return '-'
    }

    const start = parseDate(
        concern.acknowledged_at
    )

    if (!start) {
        return '-'
    }

    let end = null

    if (concern.resolved_at) {
        end = parseDate(
            concern.resolved_at
        )
    } else if (
        concern.status === 'in_progress' ||
        concern.status === 'on_hold'
    ) {
        end = currentTime.value
    }

    if (!end) {
        return '-'
    }

    const difference =
        end.getTime() -
        start.getTime()

    if (difference < 0) {
        return '-'
    }

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
 * EXPORT DATE LABEL
 */

function getExportDateLabel() {
    const labels = {
        '': 'All Dates',
        today: 'Today',
        week: 'This Week',
        month: 'This Month',
        year: 'This Year'
    }

    return (
        labels[exportDateFilter.value] ||
        'All Dates'
    )
}

/*
 * ALERT MESSAGES
 */

function showSuccessMessage(message) {
    showToast(message)
}

function showErrorMessage(message) {
    errorMessage.value = message
    showToast(message, 'error')
}

/*
 * CREATE CONCERN MODAL
 */

function openCreateModal() {
    errorMessage.value = ''
    showModal.value = true
}

function closeModal() {
    showModal.value = false
    errorMessage.value = ''
}

/*
 * VIEW CONCERN MODAL
 */

function viewConcern(concern) {
    errorMessage.value = ''
    selectedConcernId.value = concern.id
    showViewModal.value = true
}

function handleConcernRowKeydown(event, concern) {
    if (
        event.key === 'Enter' ||
        event.key === ' '
    ) {
        event.preventDefault()
        viewConcern(concern)
    }
}

function closeViewModal() {
    showViewModal.value = false
    selectedConcernId.value = null
}

/*
 * DATA
 */

async function loadCurrentUser() {
    const response = await $fetch(
        '/api/auth/me',
        {
            cache: 'no-store'
        }
    )

    currentUser.value =
        response.user
}

async function loadConcerns() {
    const response = await $fetch(
        '/api/concerns',
        {
            cache: 'no-store',
            query: {
                page: currentPage.value,
                limit: pageSize.value,
                search: search.value.trim(),
                status: statusFilter.value,
                priority: priorityFilter.value,
                date: exportDateFilter.value
            }
        }
    )

    concerns.value =
        response.concerns || []

    totalConcerns.value =
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


/*
 * EXPORT TO EXCEL
 */

function openExportModal() {
    if (exporting.value) {
        return
    }

    errorMessage.value = ''
    showExportModal.value = true
}

function closeExportModal() {
    if (exporting.value) {
        return
    }

    showExportModal.value = false
}

async function confirmExport() {
    if (exporting.value) {
        return
    }

    exporting.value = true
    errorMessage.value = ''

    try {
        const query = new URLSearchParams()

        const trimmedSearch =
            search.value.trim()

        if (trimmedSearch) {
            query.set(
                'search',
                trimmedSearch
            )
        }

        if (statusFilter.value) {
            query.set(
                'status',
                statusFilter.value
            )
        }

        if (priorityFilter.value) {
            query.set(
                'priority',
                priorityFilter.value
            )
        }

        if (exportDateFilter.value) {
            query.set(
                'date',
                exportDateFilter.value
            )
        }

        const queryString =
            query.toString()

        const exportUrl =
            queryString
                ? `/api/concerns/export?${queryString}`
                : '/api/concerns/export'

        /*
         * Get the Excel file from the server.
         */

        const response = await $fetch(
            exportUrl,
            {
                method: 'GET',
                responseType: 'blob',
                cache: 'no-store'
            }
        )

        const blob =
            response instanceof Blob
                ? response
                : new Blob(
                    [response],
                    {
                        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                    }
                )

        const fileName =
            `concerns-report-${new Date().toISOString().slice(0, 10)}.xlsx`

        /*
         * Use the browser's Save As / Browse dialog
         * when File System Access API is available.
         */

        if (
            'showSaveFilePicker' in window
        ) {
            const fileHandle =
                await window.showSaveFilePicker({
                    suggestedName: fileName,
                    types: [
                        {
                            description: 'Excel Workbook',
                            accept: {
                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': [
                                    '.xlsx'
                                ]
                            }
                        }
                    ]
                })

            /*
             * The user selected a location and clicked Save.
             */

            const writable =
                await fileHandle.createWritable()

            await writable.write(blob)

            await writable.close()

            /*
             * Close the export modal after
             * the file has been saved.
             *
             * No success toast is shown.
             */

            showExportModal.value = false

            return
        }

        /*
         * Fallback for browsers that do not support
         * showSaveFilePicker().
         *
         * This starts the normal browser download.
         */

        const url =
            window.URL.createObjectURL(blob)

        const link =
            document.createElement('a')

        link.href = url
        link.download = fileName

        document.body.appendChild(link)

        link.click()

        link.remove()

        window.URL.revokeObjectURL(url)

        /*
         * Close the modal after starting
         * the normal browser download.
         *
         * No success toast is shown.
         */

        showExportModal.value = false

    } catch (error) {

        /*
         * the browser's Save As / Browse dialog.
         *
         * Do nothing.
         */

        if (error?.name === 'AbortError') {
            return
        }

        /*
         * Show an error only when the export
         * or save operation actually fails.
         */

        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            error?.message ||
            'Failed to export concern report.'
        )

    } finally {
        exporting.value = false
    }
}

/*
 * FILTER / SEARCH
 */

function refreshFilteredConcerns() {
    currentPage.value = 1
    loadConcernsWithLoading()
}

function handleSearchInput() {
    if (searchTimeout) {
        clearTimeout(searchTimeout)
    }

    searchTimeout = setTimeout(() => {
        refreshFilteredConcerns()
    }, 300)
}

async function handleStatusChange() {
    currentPage.value = 1
    await loadConcernsWithLoading()
}

async function handleExportDateChange() {
    currentPage.value = 1
    await loadConcernsWithLoading()
}

async function handlePriorityChange() {
    currentPage.value = 1
    await loadConcernsWithLoading()
}

/*
 * PAGINATION
 */

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
    await loadConcernsWithLoading()
}

async function goToPreviousPage() {
    if (currentPage.value <= 1) {
        return
    }

    currentPage.value -= 1
    await loadConcernsWithLoading()
}

async function goToNextPage() {
    if (
        currentPage.value >= totalPages.value
    ) {
        return
    }

    currentPage.value += 1
    await loadConcernsWithLoading()
}

/*
 * LOADING
 */

async function loadConcernsWithLoading() {
    loading.value = true
    errorMessage.value = ''

    try {
        await loadConcerns()
    } catch (error) {
        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load concerns.'
        )
    } finally {
        loading.value = false
    }
}

async function loadConcernTypes() {
    const response = await $fetch(
        '/api/concern-types',
        {
            cache: 'no-store'
        }
    )

    concernTypes.value =
        response.concernTypes || []
}

async function loadOrganizations() {
    const response = await $fetch(
        '/api/organizations',
        {
            cache: 'no-store'
        }
    )

    organizations.value =
        response.organizations || []
}

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    try {
        await Promise.all([
            loadCurrentUser(),
            loadConcerns(),
            loadConcernTypes(),
            loadOrganizations()
        ])
    } catch (error) {
        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load concern data.'
        )
    } finally {
        loading.value = false
    }
}

/*
 * LOGOUT
 */

async function logout() {
    try {
        await $fetch(
            '/api/auth/logout',
            {
                method: 'POST'
            }
        )
    } catch (error) {
        // Continue to login even if logout request fails.
    }

    navigateTo('/login')
}

function updateProfilePhoto(profilePhoto) {
    if (currentUser.value) {
        currentUser.value.profile_photo = profilePhoto
    }
}

/*
 * LIFECYCLE
 */

onMounted(() => {
    loadData()

    durationTimer = setInterval(() => {
        currentTime.value =
            new Date()
    }, 60000)
})

onUnmounted(() => {
    if (durationTimer) {
        clearInterval(durationTimer)
    }

    if (searchTimeout) {
        clearTimeout(searchTimeout)
    }
})

</script>

<template>

    <div class="min-h-screen bg-slate-100">

        <MobileNavigation :current-user="currentUser" @logout="logout" @profile-updated="updateProfilePhoto" />

        <!-- Sidebar -->

        <aside class="fixed inset-y-0 left-0 z-40 hidden w-64 flex-col bg-emerald-950 text-white lg:flex">

            <div class="border-b border-emerald-900 px-6 py-5">

                <h1 class="text-lg font-bold">
                    Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>

            </div>

            <nav class="flex-1 space-y-1 px-3 py-4">

                <NuxtLink to="/dashboard"
                    :class="$route.path === '/dashboard' ? 'bg-emerald-800 text-white' : 'text-emerald-100/80 transition hover:bg-emerald-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="dashboard" />
                    <span>Dashboard</span>
                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/organizations"
                    :class="$route.path === '/organizations' ? 'bg-emerald-800 text-white' : 'text-emerald-100/80 transition hover:bg-emerald-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="organizations" />
                    <span>Manage Organizations</span>
                </NuxtLink>

                <NuxtLink to="/concerns"
                    :class="$route.path === '/concerns' ? 'bg-emerald-800 text-white' : 'text-emerald-100/80 transition hover:bg-emerald-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="concerns" />
                    <span>Manage Concerns</span>
                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/users"
                    :class="$route.path === '/users' ? 'bg-emerald-800 text-white' : 'text-emerald-100/80 transition hover:bg-emerald-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="users" />
                    <span>Manage Users</span>
                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/login-history"
                    :class="$route.path === '/login-history' ? 'bg-emerald-800 text-white' : 'text-emerald-100/80 transition hover:bg-emerald-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="history" />
                    <span>Login History</span>
                </NuxtLink>
            </nav>

            <div class="border-t border-emerald-900 p-4">
                <UserProfileControl :current-user="currentUser" @logout="logout"
                    @profile-updated="updateProfilePhoto" />
            </div>

        </aside>

        <!-- Main Content -->

        <main class="flex min-h-screen flex-col lg:ml-64">

            <div class="mx-auto w-full max-w-[1600px] px-4 py-6 sm:px-6 sm:py-8">

                <!-- Header -->

                <div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">

                    <div>

                        <h2 class="text-2xl font-bold text-slate-800">
                            Concerns
                        </h2>

                        <p class="mt-1 text-sm text-slate-500">
                            View and manage concerns.
                        </p>

                    </div>

                    <button v-if="
                        currentUser?.role_name === 'admin' ||
                        currentUser?.role_name === 'user'
                    " type="button" @click="openCreateModal"
                        class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg bg-emerald-900 px-5 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-emerald-800 hover:shadow-md active:scale-[0.99]">
                        <span class="text-lg leading-none">
                            +
                        </span>
                        Create Concern
                    </button>

                </div>

                <!-- Error -->

                <div v-if="errorMessage"
                    class="mb-5 flex items-start justify-between gap-4 rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700">

                    <p>
                        {{ errorMessage }}
                    </p>

                    <button type="button" @click="errorMessage = ''"
                        class="cursor-pointer text-xl leading-none text-red-400 transition hover:text-red-700">
                        ×
                    </button>

                </div>

                <!-- Filters -->

                <div class="mb-6 rounded-xl border border-slate-300 bg-white p-5 shadow-md">

                    <div class="grid gap-4 md:grid-cols-4">

                        <!-- Search -->

                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Search
                            </label>

                            <input v-model="search" @input="handleSearchInput" type="text"
                                placeholder="Search concern number, title, or description..."
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100" />

                        </div>

                        <!-- Status -->

                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Status
                            </label>

                            <select v-model="statusFilter" @change="handleStatusChange"
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">

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

                            </select>

                        </div>

                        <!-- Priority -->

                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Priority
                            </label>

                            <select v-model="priorityFilter" @change="handlePriorityChange"
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">

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

                        <!-- Export Date -->

                        <div>

                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Date
                            </label>

                            <select v-model="exportDateFilter" @change="handleExportDateChange"
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">

                                <option value="">
                                    All Dates
                                </option>

                                <option value="today">
                                    Today
                                </option>

                                <option value="week">
                                    This Week
                                </option>

                                <option value="month">
                                    This Month
                                </option>

                                <option value="year">
                                    This Year
                                </option>

                            </select>

                        </div>

                    </div>

                    <!-- Export -->

                    <div class="mt-4 flex justify-end border-t border-slate-100 pt-4">

                        <button type="button" @click="openExportModal" :disabled="exporting"
                            class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50">

                            <svg v-if="!exporting" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v12m0 0 4-4m-4 4-4-4" />

                                <path stroke-linecap="round" stroke-linejoin="round" d="M5 21h14" />
                            </svg>

                            <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                stroke-width="1.8" stroke="currentColor" class="h-5 w-5 animate-spin">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3a9 9 0 1 0 9 9" />
                            </svg>

                            <span v-if="!exporting">
                                Export to Excel
                            </span>

                            <span v-else>
                                Exporting...
                            </span>

                        </button>

                    </div>

                </div>

                <!-- Concerns Table -->

                <div class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">

                    <!-- Table Header -->

                    <div class="border-b border-slate-200 px-5 py-4">

                        <h3 class="text-base font-semibold text-slate-800">
                            Concern List
                        </h3>

                        <p v-if="loading" class="mt-1 flex items-center gap-2 text-xs text-slate-400">

                            <span class="inline-block h-2.5 w-2.5 animate-pulse rounded-full bg-slate-300"></span>

                            Loading concerns...

                        </p>

                        <p v-else class="mt-1 text-xs text-slate-500">

                            <template v-if="totalConcerns > 0">

                                Showing
                                {{ showingFrom }}–{{ showingTo }}
                                of
                                {{ totalConcerns }}
                                concern{{ totalConcerns === 1 ? '' : 's' }}

                            </template>

                            <template v-else>
                                No concerns
                            </template>

                        </p>

                    </div>

                    <!-- Compact table for desktop -->
                    <div v-if="loading" class="hidden animate-pulse lg:block">
                        <div class="grid grid-cols-6 gap-6 border-b border-slate-200 bg-slate-50 px-5 py-3">
                            <div v-for="column in 6" :key="column" class="h-3 rounded bg-slate-200"></div>
                        </div>
                        <div v-for="row in 5" :key="row"
                            class="grid grid-cols-6 gap-6 border-b border-slate-100 px-5 py-5">
                            <div class="col-span-2 space-y-2">
                                <div class="h-4 w-24 rounded bg-slate-200"></div>
                                <div class="h-3 w-36 rounded bg-slate-100"></div>
                            </div>
                            <div class="h-4 rounded bg-slate-200"></div>
                            <div class="h-6 w-16 rounded-full bg-slate-200"></div>
                            <div class="h-6 w-20 rounded-full bg-slate-200"></div>
                            <div class="h-4 w-24 rounded bg-slate-200"></div>
                        </div>
                    </div>

                    <div v-if="loading" class="space-y-3 p-4 lg:hidden">
                        <div v-for="row in 4" :key="row" class="animate-pulse rounded-xl border border-slate-200 p-4">
                            <div class="h-4 w-28 rounded bg-slate-200"></div>
                            <div class="mt-3 h-4 w-3/4 rounded bg-slate-200"></div>
                            <div class="mt-4 h-3 w-1/2 rounded bg-slate-100"></div>
                        </div>
                    </div>

                    <div v-else-if="concerns.length === 0" class="px-5 py-12 text-center">
                        <p class="text-sm font-medium text-slate-600">No concerns found.</p>
                        <p class="mt-1 text-xs text-slate-400">Try changing your search or filters.</p>
                    </div>

                    <template v-else>
                        <div class="hidden lg:block">
                            <table class="w-full table-fixed text-left">
                                <colgroup>
                                    <col class="w-[34%]" />
                                    <col class="w-[22%]" />
                                    <col class="w-[12%]" />
                                    <col class="w-[14%]" />
                                    <col class="w-[18%]" />
                                </colgroup>
                                <thead class="bg-slate-50">
                                    <tr class="border-b border-slate-200">
                                        <th
                                            class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Concern</th>
                                        <th
                                            class="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Assigned To</th>
                                        <th
                                            class="px-3 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Priority</th>
                                        <th
                                            class="px-3 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Status</th>
                                        <th
                                            class="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Handling / created</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-slate-200">
                                    <tr v-for="(concern, index) in concerns" :key="concern.id" role="button"
                                        tabindex="0" @click="viewConcern(concern)"
                                        @keydown="handleConcernRowKeydown($event, concern)"
                                        :class="index % 2 === 0 ? 'bg-white hover:bg-emerald-50/50' : 'bg-slate-50 hover:bg-emerald-50/70'"
                                        class="cursor-pointer transition focus:outline-none focus:ring-2 focus:ring-inset focus:ring-emerald-700">
                                        <td class="px-5 py-4">
                                            <p class="text-xs font-semibold text-emerald-800">{{ concern.concern_number
                                            }}</p>
                                            <p class="mt-1 truncate text-sm font-semibold text-slate-800"
                                                :title="concern.title">
                                                {{ concern.title }}
                                            </p>
                                            <p class="mt-1 truncate text-xs text-slate-500"
                                                :title="concern.description">
                                                {{ concern.description || '-' }}
                                            </p>
                                        </td>
                                        <td class="px-4 py-4">
                                            <p class="truncate text-sm font-medium text-slate-700"
                                                :title="concern.organization_name || '-'">
                                                {{ concern.organization_name || '-' }}
                                            </p>
                                        </td>
                                        <td class="px-3 py-4">
                                            <span
                                                class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                                                :class="priorityClass(concern.priority)">
                                                {{ formatPriority(concern.priority) }}
                                            </span>
                                        </td>
                                        <td class="px-3 py-4">
                                            <span
                                                class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                                                :class="statusClass(concern.status)">
                                                {{ formatStatus(concern.status) }}
                                            </span>
                                        </td>
                                        <td class="px-4 py-4">
                                            <p class="text-sm font-semibold text-slate-800">
                                                {{ getConcernDuration(concern) }}
                                            </p>
                                            <p class="mt-1 text-xs text-slate-500">
                                                Created {{ formatDate(concern.created_at) }}
                                            </p>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <div class="space-y-3 p-3 lg:hidden">
                            <article v-for="(concern, index) in concerns" :key="concern.id" role="button" tabindex="0"
                                @click="viewConcern(concern)" @keydown="handleConcernRowKeydown($event, concern)"
                                :class="index % 2 === 0 ? 'border-slate-200 bg-white hover:border-emerald-300 hover:bg-emerald-50/30' : 'border-slate-200 bg-slate-50 hover:border-emerald-300 hover:bg-emerald-50/70'"
                                class="cursor-pointer rounded-xl border p-4 transition focus:outline-none focus:ring-2 focus:ring-emerald-700">
                                <div class="flex items-start justify-between gap-3">
                                    <div class="min-w-0">
                                        <p class="text-xs font-semibold text-emerald-800">{{ concern.concern_number }}
                                        </p>
                                        <h4 class="mt-1 break-words text-sm font-semibold text-slate-900">{{
                                            concern.title }}</h4>
                                    </div>
                                    <span class="shrink-0 rounded-full px-2.5 py-1 text-xs font-medium"
                                        :class="statusClass(concern.status)">
                                        {{ formatStatus(concern.status) }}
                                    </span>
                                </div>
                                <p class="mt-2 line-clamp-2 text-xs leading-5 text-slate-500">
                                    {{ concern.description || 'No description' }}
                                </p>
                                <div class="mt-3 flex flex-wrap items-center gap-2">
                                    <span class="rounded-full px-2.5 py-1 text-xs font-medium"
                                        :class="priorityClass(concern.priority)">
                                        {{ formatPriority(concern.priority) }}
                                    </span>
                                    <span class="text-xs text-slate-500">{{ formatDate(concern.created_at) }}</span>
                                </div>
                                <div
                                    class="mt-3 grid grid-cols-2 gap-x-3 gap-y-2 border-t border-slate-100 pt-3 text-xs">
                                    <div class="min-w-0">
                                        <p class="text-slate-400">Assigned to</p>
                                        <p class="mt-0.5 truncate font-medium text-slate-700"
                                            :title="concern.organization_name || '-'">
                                            {{ concern.organization_name || '-' }}
                                        </p>
                                    </div>
                                    <div class="min-w-0">
                                        <p class="text-slate-400">Type</p>
                                        <p class="mt-0.5 truncate font-medium text-slate-700">
                                            {{ concern.concern_type_name || '-' }}
                                        </p>
                                    </div>
                                    <div class="min-w-0">
                                        <p class="text-slate-400">Created by</p>
                                        <p class="mt-0.5 truncate font-medium text-slate-700">
                                            {{ concern.created_by_name || '-' }}
                                        </p>
                                    </div>
                                    <div>
                                        <p class="text-slate-400">Duration</p>
                                        <p class="mt-0.5 font-medium text-slate-700">{{ getConcernDuration(concern) }}
                                        </p>
                                    </div>
                                </div>
                            </article>
                        </div>
                    </template>

                    <!-- Pagination -->

                    <div v-if="!loading && totalPages > 1"
                        class="flex flex-col gap-3 border-t border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">

                        <p class="text-xs text-slate-500">

                            Page
                            {{ currentPage }}
                            of
                            {{ totalPages }}

                        </p>

                        <div class="flex items-center gap-1">

                            <button type="button" @click="goToPreviousPage" :disabled="currentPage === 1"
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                                Previous
                            </button>

                            <template v-for="(page, index) in paginationPages" :key="`${page}-${index}`">

                                <span v-if="page === '...'" class="px-2 py-2 text-sm text-slate-400">
                                    ...
                                </span>

                                <button v-else type="button" @click="goToPage(page)" :class="page === currentPage
                                    ? 'bg-emerald-900 text-white'
                                    : 'border border-slate-300 text-slate-600 hover:bg-slate-50'
                                    "
                                    class="min-w-9 cursor-pointer rounded-lg px-3 py-2 text-sm font-medium transition">
                                    {{ page }}
                                </button>

                            </template>

                            <button type="button" @click="goToNextPage" :disabled="currentPage === totalPages ||
                                totalPages === 0
                                "
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                                Next
                            </button>

                        </div>

                    </div>

                </div>

            </div>

            <AppFooter class="mt-auto" />
        </main>

        <!-- Create Concern Modal -->

        <CreateConcernModal :show="showModal" :current-user="currentUser" :concern-types="concernTypes"
            :organizations="organizations" @close="closeModal" @success="showSuccessMessage" @error="showErrorMessage"
            @created="loadConcerns" />

        <!-- View Concern Modal -->

        <ViewConcernModal :show="showViewModal" :concern-id="selectedConcernId" :current-user="currentUser"
            @close="closeViewModal" @success="showSuccessMessage" @error="showErrorMessage" @refresh="loadConcerns" />

        <!-- Export Confirmation Modal -->

        <Transition enter-active-class="transition duration-200 ease-out" enter-from-class="opacity-0"
            enter-to-class="opacity-100" leave-active-class="transition duration-150 ease-in"
            leave-from-class="opacity-100" leave-to-class="opacity-0">

            <div v-if="showExportModal"
                class="fixed inset-0 z-[90] flex items-start justify-center overflow-y-auto bg-slate-950/50 px-2 py-3 backdrop-blur-[2px] sm:items-center sm:px-4 sm:py-6"
                @click.self="closeExportModal">

                <Transition appear enter-active-class="transition duration-200 ease-out"
                    enter-from-class="translate-y-3 scale-95 opacity-0"
                    enter-to-class="translate-y-0 scale-100 opacity-100"
                    leave-active-class="transition duration-150 ease-in"
                    leave-from-class="translate-y-0 scale-100 opacity-100"
                    leave-to-class="translate-y-3 scale-95 opacity-0">

                    <div v-if="showExportModal" class="w-full max-w-md overflow-hidden rounded-2xl bg-white shadow-2xl"
                        role="dialog" aria-modal="true" aria-labelledby="export-modal-title">

                        <!-- Modal Header -->

                        <div class="border-b border-slate-100 px-6 py-5">

                            <div class="flex items-start gap-4">

                                <div
                                    class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-green-50 text-green-600">

                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                        stroke-width="1.8" stroke="currentColor" class="h-6 w-6">

                                        <path stroke-linecap="round" stroke-linejoin="round"
                                            d="M12 3v12m0 0 4-4m-4 4-4-4" />

                                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 21h14" />

                                    </svg>

                                </div>

                                <div class="min-w-0 flex-1">

                                    <h3 id="export-modal-title" class="text-lg font-semibold text-slate-900">
                                        Export Concern Report
                                    </h3>

                                    <p class="mt-1 text-sm leading-5 text-slate-500">
                                        Review the export settings before continuing.
                                    </p>

                                </div>

                                <button type="button" @click="closeExportModal" :disabled="exporting"
                                    class="cursor-pointer rounded-lg p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 disabled:cursor-not-allowed disabled:opacity-50">

                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                        stroke-width="2" stroke="currentColor" class="h-5 w-5">

                                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />

                                    </svg>

                                </button>

                            </div>

                        </div>

                        <!-- Modal Body -->

                        <div class="px-6 py-5">

                            <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">

                                <div class="flex items-center justify-between gap-4">

                                    <div>

                                        <p class="text-xs font-medium uppercase tracking-wide text-slate-400">
                                            Export Date
                                        </p>

                                        <p class="mt-1 text-sm font-semibold text-slate-800">
                                            {{ getExportDateLabel() }}
                                        </p>

                                    </div>

                                    <div
                                        class="flex h-9 w-9 items-center justify-center rounded-lg bg-white text-slate-500 shadow-sm">

                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                            stroke-width="1.8" stroke="currentColor" class="h-5 w-5">

                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                d="M6.75 3v2.25M17.25 3v2.25M3.75 9h16.5M5.25 5.25h13.5a2.25 2.25 0 0 1 2.25 2.25v11.25a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25Z" />

                                        </svg>

                                    </div>

                                </div>

                            </div>

                            <div class="mt-4 rounded-xl border border-blue-100 bg-blue-50 px-4 py-3">

                                <div class="flex gap-3">

                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                        stroke-width="1.8" stroke="currentColor"
                                        class="mt-0.5 h-5 w-5 shrink-0 text-blue-600">

                                        <path stroke-linecap="round" stroke-linejoin="round"
                                            d="M12 9.75h.008v.008H12V9.75Zm0 3v3.75m9-4.5a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />

                                    </svg>

                                    <div>

                                        <p class="text-sm font-medium text-blue-800">
                                            All matching concerns will be exported.
                                        </p>

                                        <p class="mt-1 text-xs leading-5 text-blue-700">
                                            The export is not limited to the current table page.
                                            Your search, status, priority, and selected date will be applied.
                                        </p>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!-- Modal Footer -->

                        <div
                            class="flex items-center justify-end gap-3 border-t border-slate-100 bg-slate-50 px-6 py-4">

                            <button type="button" @click="closeExportModal" :disabled="exporting"
                                class="cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50">
                                Cancel
                            </button>

                            <button type="button" @click="confirmExport" :disabled="exporting"
                                class="inline-flex min-w-[120px] cursor-pointer items-center justify-center gap-2 rounded-lg bg-emerald-900 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition hover:bg-emerald-800 disabled:cursor-not-allowed disabled:opacity-50">

                                <svg v-if="exporting" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke-width="1.8" stroke="currentColor" class="h-4 w-4 animate-spin">

                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 3a9 9 0 1 0 9 9" />

                                </svg>

                                <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke-width="1.8" stroke="currentColor" class="h-4 w-4">

                                    <path stroke-linecap="round" stroke-linejoin="round"
                                        d="M12 3v12m0 0 4-4m-4 4-4-4" />

                                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 21h14" />

                                </svg>

                                <span v-if="!exporting">
                                    Export Excel
                                </span>

                                <span v-else>
                                    Exporting...
                                </span>

                            </button>

                        </div>

                    </div>

                </Transition>

            </div>

        </Transition>

    </div>

</template>
