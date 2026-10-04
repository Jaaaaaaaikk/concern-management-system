<script setup>

import ViewConcernModal from '~/components/concerns/ViewConcernModal.vue'

import CreateConcernModal from '~/components/concerns/CreateConcernModal.vue'

definePageMeta({

    middleware: 'auth'

})

let successTimeout = null
let errorTimeout = null
let searchTimeout = null

const concerns = ref([])
const concernTypes = ref([])
const organizations = ref([])
const currentUser = ref(null)

const loading = ref(true)

const errorMessage = ref('')
const successMessage = ref('')

const showModal = ref(false)

const search = ref('')
const statusFilter = ref('')
const priorityFilter = ref('')

const showViewModal = ref(false)
const selectedConcernId = ref(null)

/*--------------------------------------------------------------------------*/
/* PAGINATION */
/*--------------------------------------------------------------------------*/

const currentPage = ref(1)
const pageSize = ref(10)

const totalConcerns = ref(0)
const totalPages = ref(0)

/*--------------------------------------------------------------------------*/
/* CURRENT TIME / HANDLING DURATION */
/*--------------------------------------------------------------------------*/

const currentTime = ref(new Date())

let durationTimer = null

/*--------------------------------------------------------------------------*/
/* PAGINATION DISPLAY */
/*--------------------------------------------------------------------------*/

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

/*--------------------------------------------------------------------------*/
/* DISPLAY HELPERS */
/*--------------------------------------------------------------------------*/

function formatStatus(status) {

    const labels = {

        pending: 'Pending',

        in_progress: 'In Progress',

        on_hold: 'On Hold',

        resolved: 'Resolved',

        closed: 'Closed',

        cancelled: 'Cancelled'

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

        closed: 'bg-slate-200 text-slate-700',

        cancelled: 'bg-red-100 text-red-700'

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

/*--------------------------------------------------------------------------*/
/* ALERT MESSAGES */
/*--------------------------------------------------------------------------*/

function showSuccessMessage(message) {

    successMessage.value = message

    if (successTimeout) {
        clearTimeout(successTimeout)
    }

    successTimeout = setTimeout(() => {

        successMessage.value = ''

    }, 3000)

}

function showErrorMessage(message) {

    errorMessage.value = message

    if (errorTimeout) {
        clearTimeout(errorTimeout)
    }

    errorTimeout = setTimeout(() => {

        errorMessage.value = ''

    }, 5000)

}

/*--------------------------------------------------------------------------*/
/* CREATE CONCERN MODAL */
/*--------------------------------------------------------------------------*/

function openCreateModal() {

    errorMessage.value = ''

    showModal.value = true

}

function closeModal() {

    showModal.value = false

    errorMessage.value = ''

}

/*--------------------------------------------------------------------------*/
/* VIEW CONCERN MODAL */
/*--------------------------------------------------------------------------*/

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

/*--------------------------------------------------------------------------*/
/* DATA */
/*--------------------------------------------------------------------------*/

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

                priority: priorityFilter.value

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

/*--------------------------------------------------------------------------*/
/* FILTER / SEARCH */
/*--------------------------------------------------------------------------*/

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

async function handlePriorityChange() {

    currentPage.value = 1

    await loadConcernsWithLoading()

}

/*--------------------------------------------------------------------------*/
/* PAGINATION */
/*--------------------------------------------------------------------------*/

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

/*--------------------------------------------------------------------------*/
/* LOADING */
/*--------------------------------------------------------------------------*/

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

/*--------------------------------------------------------------------------*/
/* LOGOUT */
/*--------------------------------------------------------------------------*/

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

/*--------------------------------------------------------------------------*/
/* LIFECYCLE */
/*--------------------------------------------------------------------------*/

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

    if (successTimeout) {

        clearTimeout(successTimeout)

    }

    if (errorTimeout) {

        clearTimeout(errorTimeout)

    }

    if (searchTimeout) {

        clearTimeout(searchTimeout)

    }

})

</script>

<template>

<div class="min-h-screen bg-slate-100">

    <!-- Success Toast -->

    <Transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="translate-y-2 opacity-0"
        enter-to-class="translate-y-0 opacity-100"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
    >

        <div
            v-if="successMessage"
            class="fixed right-5 top-5 z-[100] flex max-w-lg items-start gap-3 rounded-xl border border-green-200 bg-white px-5 py-4 text-sm font-medium text-green-700 shadow-lg"
        >

            <span
                class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-green-100 font-bold text-green-700"
            >
                ✓
            </span>

            <span class="flex-1 leading-5">
                {{ successMessage }}
            </span>

            <button
                type="button"
                @click="successMessage = ''"
                class="cursor-pointer text-xl leading-none text-green-400 transition hover:text-green-700"
            >
                ×
            </button>

        </div>

    </Transition>

    <!-- Error Toast -->

    <Transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="translate-y-2 opacity-0"
        enter-to-class="translate-y-0 opacity-100"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
    >

        <div
            v-if="errorMessage"
            class="fixed right-5 top-5 z-[100] flex max-w-lg items-start gap-3 rounded-xl border border-red-200 bg-white px-5 py-4 text-sm font-medium text-red-700 shadow-lg"
        >

            <span
                class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-red-100 font-bold text-red-700"
            >
                !
            </span>

            <span class="flex-1 leading-5">
                {{ errorMessage }}
            </span>

            <button
                type="button"
                @click="errorMessage = ''"
                class="cursor-pointer text-xl leading-none text-red-400 transition hover:text-red-700"
            >
                ×
            </button>

        </div>

    </Transition>

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
                class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
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
                class="flex items-center gap-3 rounded-lg bg-slate-800 px-4 py-3 text-sm font-medium text-white"
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
                        Concerns
                    </h2>

                    <p class="mt-1 text-sm text-slate-500">
                        View and manage concerns.
                    </p>

                </div>

                <button
                    v-if="
                        currentUser?.role_name === 'admin' ||
                        currentUser?.role_name === 'user'
                    "
                    type="button"
                    @click="openCreateModal"
                    class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-slate-800 hover:shadow-md active:scale-[0.99]"
                >

                    <span class="text-lg leading-none">
                        +
                    </span>

                    Create Concern

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

            <!-- Filters -->

            <div
                class="mb-6 rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
            >

                <div class="grid gap-4 md:grid-cols-3">

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Search
                        </label>

                        <input
                            v-model="search"
                            @input="handleSearchInput"
                            type="text"
                            placeholder="Search concern number, title, or description..."
                            class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />

                    </div>

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Status
                        </label>

                        <select
                            v-model="statusFilter"
                            @change="handleStatusChange"
                            class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
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

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Priority
                        </label>

                        <select
                            v-model="priorityFilter"
                            @change="handlePriorityChange"
                            class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
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

            <!-- Concerns Table -->

            <div
                class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm"
            >

                <!-- Table Header -->

                <div class="border-b border-slate-200 px-5 py-4">

                    <h3 class="text-base font-semibold text-slate-800">
                        Concern List
                    </h3>

                    <p
                        v-if="loading"
                        class="mt-1 flex items-center gap-2 text-xs text-slate-400"
                    >

                        <span
                            class="inline-block h-2.5 w-2.5 animate-pulse rounded-full bg-slate-300"
                        ></span>

                        Loading concerns...

                    </p>

                    <p
                        v-else
                        class="mt-1 text-xs text-slate-500"
                    >

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

                <!-- Table -->

                <div class="overflow-x-auto">

                    <table class="min-w-[1150px] w-full text-left">

                        <!-- Table Head -->

                        <thead class="bg-slate-50">

                            <tr class="border-b border-slate-200">

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Concern No.
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Title
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Type
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Assigned To
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Priority
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Status
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Created By
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Date
                                </th>

                                <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                    Duration
                                </th>

                            </tr>

                        </thead>

                        <!-- Skeleton Loading -->

                        <tbody
                            v-if="loading"
                            class="divide-y divide-slate-100"
                        >

                            <tr
                                v-for="row in 5"
                                :key="row"
                                class="animate-pulse"
                            >

                                <!-- Concern Number -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-4 w-20 rounded bg-slate-200"
                                    ></div>

                                </td>

                                <!-- Title -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-4 w-44 rounded bg-slate-200"
                                    ></div>

                                    <div
                                        class="mt-2 h-3 w-32 rounded bg-slate-100"
                                    ></div>

                                </td>

                                <!-- Type -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-4 w-24 rounded bg-slate-200"
                                    ></div>

                                </td>

                                <!-- Assigned To -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-4 w-36 rounded bg-slate-200"
                                    ></div>

                                </td>

                                <!-- Priority -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-6 w-16 rounded-full bg-slate-200"
                                    ></div>

                                </td>

                                <!-- Status -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-6 w-20 rounded-full bg-slate-200"
                                    ></div>

                                </td>

                                <!-- Created By -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-4 w-28 rounded bg-slate-200"
                                    ></div>

                                    <div
                                        class="mt-2 h-3 w-20 rounded bg-slate-100"
                                    ></div>

                                </td>

                                <!-- Date -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-4 w-32 rounded bg-slate-200"
                                    ></div>

                                </td>

                                <!-- Duration -->

                                <td class="whitespace-nowrap px-5 py-5">

                                    <div
                                        class="h-4 w-16 rounded bg-slate-200"
                                    ></div>

                                </td>

                            </tr>

                        </tbody>

                        <!-- Empty State -->

                        <tbody
                            v-else-if="concerns.length === 0"
                            class="divide-y divide-slate-100"
                        >

                            <tr>

                                <td
                                    colspan="9"
                                    class="px-5 py-12 text-center"
                                >

                                    <p class="text-sm font-medium text-slate-600">
                                        No concerns found.
                                    </p>

                                    <p class="mt-1 text-xs text-slate-400">
                                        Try changing your search or filters.
                                    </p>

                                </td>

                            </tr>

                        </tbody>

                        <!-- Actual Concern Rows -->

                        <tbody
                            v-else
                            class="divide-y divide-slate-100"
                        >

                            <tr
                                v-for="concern in concerns"
                                :key="concern.id"
                                role="button"
                                tabindex="0"
                                @click="viewConcern(concern)"
                                @keydown="handleConcernRowKeydown($event, concern)"
                                class="cursor-pointer transition duration-150 hover:bg-slate-50 hover:shadow-[inset_3px_0_0_0_rgb(71_85_105)] focus:outline-none focus:ring-2 focus:ring-inset focus:ring-slate-400"
                            >

                                <td class="whitespace-nowrap px-5 py-4 text-sm font-semibold text-slate-700">

                                    {{ concern.concern_number }}

                                </td>

                                <td class="whitespace-nowrap px-5 py-4">

                                    <div
                                        class="block max-w-[260px] truncate text-sm font-semibold text-slate-800"
                                        :title="concern.title"
                                    >

                                        {{ concern.title }}

                                    </div>

                                    <div
                                        class="mt-1 block max-w-[250px] truncate text-xs text-slate-500"
                                        :title="concern.description"
                                    >

                                        {{ concern.description || '-' }}

                                    </div>

                                </td>

                                <td class="whitespace-nowrap px-5 py-4">

                                    <div
                                        class="block max-w-[180px] truncate text-sm text-slate-600"
                                        :title="concern.concern_type_name || '-'"
                                    >

                                        {{ concern.concern_type_name || '-' }}

                                    </div>

                                </td>

                                <td class="whitespace-nowrap px-5 py-4">

                                    <div
                                        class="block max-w-[200px] truncate text-sm font-medium text-slate-700"
                                        :title="concern.organization_name || '-'"
                                    >

                                        {{ concern.organization_name || '-' }}

                                    </div>

                                </td>

                                <td class="whitespace-nowrap px-5 py-4">

                                    <span
                                        class="rounded-full px-3 py-1 text-xs font-medium"
                                        :class="priorityClass(concern.priority)"
                                    >

                                        {{ formatPriority(concern.priority) }}

                                    </span>

                                </td>

                                <td class="whitespace-nowrap px-5 py-4">

                                    <span
                                        class="rounded-full px-3 py-1 text-xs font-medium"
                                        :class="statusClass(concern.status)"
                                    >

                                        {{ formatStatus(concern.status) }}

                                    </span>

                                </td>

                                <td class="whitespace-nowrap px-5 py-4">

                                    <div
                                        class="block max-w-[180px] truncate text-sm text-slate-600"
                                        :title="concern.created_by_name || '-'"
                                    >

                                        {{ concern.created_by_name || '-' }}

                                    </div>

                                    <div
                                        v-if="concern.creator_organization_name"
                                        class="mt-1 block max-w-[180px] truncate text-xs text-slate-400"
                                        :title="concern.creator_organization_name"
                                    >

                                        {{ concern.creator_organization_name }}

                                    </div>

                                </td>

                                <td class="whitespace-nowrap px-5 py-4 text-sm text-slate-500">

                                    {{ formatDate(concern.created_at) }}

                                </td>

                                <td class="whitespace-nowrap px-5 py-4 text-sm font-medium text-slate-700">

                                    {{ getConcernDuration(concern) }}

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

    <!-- Create Concern Modal -->

    <CreateConcernModal
        :show="showModal"
        :current-user="currentUser"
        :concern-types="concernTypes"
        :organizations="organizations"
        @close="closeModal"
        @success="showSuccessMessage"
        @error="showErrorMessage"
        @created="loadConcerns"
    />

    <!-- View Concern Modal -->

    <ViewConcernModal
        :show="showViewModal"
        :concern-id="selectedConcernId"
        :current-user="currentUser"
        @close="closeViewModal"
        @success="showSuccessMessage"
        @error="showErrorMessage"
        @refresh="loadConcerns"
    />

</div>

</template>