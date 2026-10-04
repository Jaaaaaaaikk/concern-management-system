<script setup>
definePageMeta({
    middleware: 'auth'
})

const currentUser = ref(null)
const dashboardData = ref(null)

const loading = ref(true)
const errorMessage = ref('')

async function loadCurrentUser() {
    try {
        const response = await $fetch('/api/auth/me')

        currentUser.value = response.user
    } catch (error) {
        console.error(
            'Failed to load current user:',
            error
        )

        throw error
    }
}

async function loadDashboard() {
    try {
        const response = await $fetch('/api/dashboard')

        dashboardData.value = response
    } catch (error) {
        console.error(
            'Failed to load dashboard:',
            error
        )

        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load dashboard data.'
    }
}

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    try {
        await loadCurrentUser()
        await loadDashboard()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load dashboard data.'
    } finally {
        loading.value = false
    }
}

/*
|--------------------------------------------------------------------------
| Status
|--------------------------------------------------------------------------
*/

function getStatusTotal(status) {
    const item =
        dashboardData.value?.status?.find(
            item => item.status === status
        )

    return Number(item?.total || 0)
}

function getStatusPercentage(status) {
    const total =
        Number(
            dashboardData.value?.summary?.total || 0
        )

    if (total === 0) {
        return 0
    }

    return (
        getStatusTotal(status) /
        total
    ) * 100
}

/*
|--------------------------------------------------------------------------
| Priority
|--------------------------------------------------------------------------
*/

function getPriorityTotal(priority) {
    const item =
        dashboardData.value?.priority?.find(
            item => item.priority === priority
        )

    return Number(item?.total || 0)
}

function getPriorityPercentage(priority) {
    const total =
        Number(
            dashboardData.value?.summary?.total || 0
        )

    if (total === 0) {
        return 0
    }

    return (
        getPriorityTotal(priority) /
        total
    ) * 100
}

/*
|--------------------------------------------------------------------------
| Organization
|--------------------------------------------------------------------------
*/

function getOrganizationTotal(organization) {
    return Number(
        organization?.total_concerns || 0
    )
}

function getOrganizationPercentage(organization) {
    const total =
        Number(
            dashboardData.value?.summary?.total || 0
        )

    if (total === 0) {
        return 0
    }

    return (
        getOrganizationTotal(organization) /
        total
    ) * 100
}

const maximumOrganizationTotal = computed(() => {
    const organizations =
        dashboardData.value?.organizations || []

    if (organizations.length === 0) {
        return 0
    }

    return Math.max(
        ...organizations.map(
            organization =>
                getOrganizationTotal(organization)
        )
    )
})

function getOrganizationBarPercentage(organization) {
    const maximum =
        maximumOrganizationTotal.value

    if (maximum === 0) {
        return 0
    }

    return (
        getOrganizationTotal(organization) /
        maximum
    ) * 100
}

/*
|--------------------------------------------------------------------------
| Formatting
|--------------------------------------------------------------------------
*/

function formatStatus(status) {
    if (!status) {
        return '-'
    }

    return status
        .replaceAll('_', ' ')
        .replace(/\b\w/g, letter =>
            letter.toUpperCase()
        )
}

function formatPriority(priority) {
    if (!priority) {
        return '-'
    }

    return priority.charAt(0).toUpperCase() +
        priority.slice(1)
}

/*
|--------------------------------------------------------------------------
| Graph colors
|--------------------------------------------------------------------------
*/

function statusBarClass(status) {
    switch (status) {
        case 'pending':
            return 'bg-yellow-400'

        case 'in_progress':
            return 'bg-blue-500'

        case 'on_hold':
            return 'bg-orange-400'

        case 'resolved':
            return 'bg-green-500'

        case 'closed':
            return 'bg-slate-500'

        case 'cancelled':
            return 'bg-red-500'

        default:
            return 'bg-slate-300'
    }
}

function priorityBarClass(priority) {
    switch (priority) {
        case 'low':
            return 'bg-slate-400'

        case 'medium':
            return 'bg-blue-500'

        case 'high':
            return 'bg-orange-500'

        case 'urgent':
            return 'bg-red-500'

        default:
            return 'bg-slate-300'
    }
}

function priorityTextClass(priority) {
    switch (priority) {
        case 'low':
            return 'text-slate-600'

        case 'medium':
            return 'text-blue-600'

        case 'high':
            return 'text-orange-600'

        case 'urgent':
            return 'text-red-600'

        default:
            return 'text-slate-600'
    }
}

function statusDotClass(status) {
    switch (status) {
        case 'pending':
            return 'bg-yellow-400'

        case 'in_progress':
            return 'bg-blue-500'

        case 'on_hold':
            return 'bg-orange-400'

        case 'resolved':
            return 'bg-green-500'

        case 'closed':
            return 'bg-slate-500'

        case 'cancelled':
            return 'bg-red-500'

        default:
            return 'bg-slate-300'
    }
}

/*
|--------------------------------------------------------------------------
| Logout
|--------------------------------------------------------------------------
*/

async function logout() {
    try {
        await $fetch('/api/auth/logout', {
            method: 'POST'
        })

        await navigateTo('/login')
    } catch (error) {
        console.error(
            'Logout error:',
            error
        )
    }
}

onMounted(() => {
    loadData()
})
</script>

<template>
    <div class="min-h-screen bg-slate-100">

        <!-- ========================================================= -->
        <!-- Sidebar -->
        <!-- ========================================================= -->

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
                <NuxtLink to="/dashboard"
                    class="block rounded-lg bg-slate-700 px-4 py-3 text-sm font-medium text-white">
                    Dashboard
                </NuxtLink>

                <!-- Organizations -->
                <NuxtLink v-if="
                    currentUser?.role_name === 'superadmin'
                " to="/organizations" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Manage Organizations
                </NuxtLink>

                <!-- Users -->
                <NuxtLink v-if="
                    currentUser?.role_name === 'superadmin'
                " to="/users" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Manage Users
                </NuxtLink>

                <!-- Concerns -->
                <NuxtLink to="/concerns" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    dsa Concerns
                </NuxtLink>

                <!-- Reports -->
                <NuxtLink v-if="
                    currentUser?.role_name === 'superadmin' ||
                    currentUser?.role_name === 'admin'
                " to="/reports" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Manage Reports
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

                    <p class="truncate text-xs text-slate-400">
                        {{ currentUser?.organization_name }}
                    </p>

                </div>

                <button type="button" @click="logout"
                    class="w-full rounded-lg bg-slate-800 px-4 py-2 text-sm text-slate-300 hover:bg-slate-700">
                    Logout
                </button>

            </div>

        </aside>

        <!-- ========================================================= -->
        <!-- Main -->
        <!-- ========================================================= -->

        <main class="ml-64 min-h-screen">

            <!-- Header -->
            <header class="sticky top-0 z-20 flex h-16 items-center justify-between border-b bg-white px-8">

                <div>

                    <h2 class="text-xl font-semibold text-gray-900">
                        Dashboard
                    </h2>

                    <p class="mt-1 text-sm text-gray-500">
                        Overview of the concern management system
                    </p>

                </div>

            </header>

            <!-- ===================================================== -->
            <!-- Content -->
            <!-- ===================================================== -->

            <div class="p-8">

                <!-- Error -->
                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
                    {{ errorMessage }}
                </div>

                <!-- Loading -->
                <div v-if="loading" class="rounded-xl bg-white p-10 text-center shadow-sm">

                    <p class="text-sm text-gray-500">
                        Loading dashboard...
                    </p>

                </div>

                <!-- Dashboard -->
                <template v-else>

                    <!-- ================================================= -->
                    <!-- Summary Cards -->
                    <!-- ================================================= -->

                    <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-5">

                        <!-- Total -->
                        <div class="rounded-xl border bg-white p-5 shadow-sm">

                            <p class="text-sm text-gray-500">
                                Total Concerns
                            </p>

                            <p class="mt-2 text-3xl font-bold text-gray-900">
                                {{
                                    dashboardData?.summary?.total ?? 0
                                }}
                            </p>

                        </div>

                        <!-- Pending -->
                        <div class="rounded-xl border bg-white p-5 shadow-sm">

                            <p class="text-sm text-gray-500">
                                Pending
                            </p>

                            <p class="mt-2 text-3xl font-bold text-yellow-600">
                                {{ getStatusTotal('pending') }}
                            </p>

                        </div>

                        <!-- In Progress -->
                        <div class="rounded-xl border bg-white p-5 shadow-sm">

                            <p class="text-sm text-gray-500">
                                In Progress
                            </p>

                            <p class="mt-2 text-3xl font-bold text-blue-600">
                                {{ getStatusTotal('in_progress') }}
                            </p>

                        </div>

                        <!-- Resolved -->
                        <div class="rounded-xl border bg-white p-5 shadow-sm">

                            <p class="text-sm text-gray-500">
                                Resolved
                            </p>

                            <p class="mt-2 text-3xl font-bold text-green-600">
                                {{ getStatusTotal('resolved') }}
                            </p>

                        </div>

                        <!-- Closed -->
                        <div class="rounded-xl border bg-white p-5 shadow-sm">

                            <p class="text-sm text-gray-500">
                                Closed
                            </p>

                            <p class="mt-2 text-3xl font-bold text-slate-600">
                                {{ getStatusTotal('closed') }}
                            </p>

                        </div>

                    </div>

                    <!-- ================================================= -->
                    <!-- Status Distribution -->
                    <!-- ================================================= -->

                    <div class="mt-6 rounded-xl border bg-white p-6 shadow-sm">

                        <div class="flex flex-wrap items-start justify-between gap-4">

                            <div>

                                <h3 class="text-lg font-semibold text-gray-900">
                                    Concern Status Distribution
                                </h3>

                                <p class="mt-1 text-sm text-gray-500">
                                    Current distribution of all concerns by status.
                                </p>

                            </div>

                            <div class="rounded-lg bg-slate-50 px-4 py-2">

                                <span class="text-sm text-slate-500">
                                    Total:
                                </span>

                                <span class="ml-1 font-semibold text-slate-800">
                                    {{
                                        dashboardData?.summary?.total ?? 0
                                    }}
                                </span>

                            </div>

                        </div>

                        <!-- Stacked graph -->
                        <div class="mt-8">

                            <div class="flex h-12 w-full overflow-hidden rounded-lg bg-slate-100">

                                <!-- Pending -->
                                <div v-if="getStatusPercentage('pending') > 0"
                                    class="flex items-center justify-center bg-yellow-400 text-xs font-semibold text-yellow-950 transition-all"
                                    :style="{
                                        width: `${getStatusPercentage('pending')}%`
                                    }" :title="`Pending: ${getStatusTotal('pending')}`">
                                    <span v-if="getStatusPercentage('pending') >= 8">
                                        {{ getStatusTotal('pending') }}
                                    </span>
                                </div>

                                <!-- In Progress -->
                                <div v-if="getStatusPercentage('in_progress') > 0"
                                    class="flex items-center justify-center bg-blue-500 text-xs font-semibold text-white transition-all"
                                    :style="{
                                        width: `${getStatusPercentage('in_progress')}%`
                                    }" :title="`In Progress: ${getStatusTotal('in_progress')}`">
                                    <span v-if="getStatusPercentage('in_progress') >= 8">
                                        {{ getStatusTotal('in_progress') }}
                                    </span>
                                </div>

                                <!-- On Hold -->
                                <div v-if="getStatusPercentage('on_hold') > 0"
                                    class="flex items-center justify-center bg-orange-400 text-xs font-semibold text-orange-950 transition-all"
                                    :style="{
                                        width: `${getStatusPercentage('on_hold')}%`
                                    }" :title="`On Hold: ${getStatusTotal('on_hold')}`">
                                    <span v-if="getStatusPercentage('on_hold') >= 8">
                                        {{ getStatusTotal('on_hold') }}
                                    </span>
                                </div>

                                <!-- Resolved -->
                                <div v-if="getStatusPercentage('resolved') > 0"
                                    class="flex items-center justify-center bg-green-500 text-xs font-semibold text-white transition-all"
                                    :style="{
                                        width: `${getStatusPercentage('resolved')}%`
                                    }" :title="`Resolved: ${getStatusTotal('resolved')}`">
                                    <span v-if="getStatusPercentage('resolved') >= 8">
                                        {{ getStatusTotal('resolved') }}
                                    </span>
                                </div>

                                <!-- Closed -->
                                <div v-if="getStatusPercentage('closed') > 0"
                                    class="flex items-center justify-center bg-slate-500 text-xs font-semibold text-white transition-all"
                                    :style="{
                                        width: `${getStatusPercentage('closed')}%`
                                    }" :title="`Closed: ${getStatusTotal('closed')}`">
                                    <span v-if="getStatusPercentage('closed') >= 8">
                                        {{ getStatusTotal('closed') }}
                                    </span>
                                </div>

                                <!-- Cancelled -->
                                <div v-if="getStatusPercentage('cancelled') > 0"
                                    class="flex items-center justify-center bg-red-500 text-xs font-semibold text-white transition-all"
                                    :style="{
                                        width: `${getStatusPercentage('cancelled')}%`
                                    }" :title="`Cancelled: ${getStatusTotal('cancelled')}`">
                                    <span v-if="getStatusPercentage('cancelled') >= 8">
                                        {{ getStatusTotal('cancelled') }}
                                    </span>
                                </div>

                            </div>

                            <!-- Legend -->
                            <div class="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">

                                <div class="flex items-center gap-2">

                                    <span class="h-3 w-3 rounded-full bg-yellow-400"></span>

                                    <span class="text-sm text-slate-600">
                                        Pending
                                    </span>

                                    <span class="ml-auto font-semibold text-slate-800">
                                        {{ getStatusTotal('pending') }}
                                    </span>

                                </div>

                                <div class="flex items-center gap-2">

                                    <span class="h-3 w-3 rounded-full bg-blue-500"></span>

                                    <span class="text-sm text-slate-600">
                                        In Progress
                                    </span>

                                    <span class="ml-auto font-semibold text-slate-800">
                                        {{ getStatusTotal('in_progress') }}
                                    </span>

                                </div>

                                <div class="flex items-center gap-2">

                                    <span class="h-3 w-3 rounded-full bg-orange-400"></span>

                                    <span class="text-sm text-slate-600">
                                        On Hold
                                    </span>

                                    <span class="ml-auto font-semibold text-slate-800">
                                        {{ getStatusTotal('on_hold') }}
                                    </span>

                                </div>

                                <div class="flex items-center gap-2">

                                    <span class="h-3 w-3 rounded-full bg-green-500"></span>

                                    <span class="text-sm text-slate-600">
                                        Resolved
                                    </span>

                                    <span class="ml-auto font-semibold text-slate-800">
                                        {{ getStatusTotal('resolved') }}
                                    </span>

                                </div>

                                <div class="flex items-center gap-2">

                                    <span class="h-3 w-3 rounded-full bg-slate-500"></span>

                                    <span class="text-sm text-slate-600">
                                        Closed
                                    </span>

                                    <span class="ml-auto font-semibold text-slate-800">
                                        {{ getStatusTotal('closed') }}
                                    </span>

                                </div>

                                <div class="flex items-center gap-2">

                                    <span class="h-3 w-3 rounded-full bg-red-500"></span>

                                    <span class="text-sm text-slate-600">
                                        Cancelled
                                    </span>

                                    <span class="ml-auto font-semibold text-slate-800">
                                        {{ getStatusTotal('cancelled') }}
                                    </span>

                                </div>

                            </div>

                        </div>

                    </div>

                    <!-- ================================================= -->
                    <!-- Priority + Organization -->
                    <!-- ================================================= -->

                    <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">

                        <!-- Priority Bar Graph -->
                        <div class="rounded-xl border bg-white p-6 shadow-sm">

                            <div>

                                <h3 class="text-lg font-semibold text-gray-900">
                                    Concerns by Priority
                                </h3>

                                <p class="mt-1 text-sm text-gray-500">
                                    Number of concerns under each priority level.
                                </p>

                            </div>

                            <div class="mt-8 space-y-6">

                                <!-- Low -->
                                <div>

                                    <div class="mb-2 flex items-center justify-between">

                                        <span class="text-sm font-medium text-slate-700">
                                            Low
                                        </span>

                                        <span class="text-sm font-semibold text-slate-800">
                                            {{ getPriorityTotal('low') }}
                                        </span>

                                    </div>

                                    <div class="h-4 overflow-hidden rounded-full bg-slate-100">

                                        <div class="h-full rounded-full bg-slate-400 transition-all" :style="{
                                            width: `${getPriorityPercentage('low')}%`
                                        }"></div>

                                    </div>

                                </div>

                                <!-- Medium -->
                                <div>

                                    <div class="mb-2 flex items-center justify-between">

                                        <span class="text-sm font-medium text-slate-700">
                                            Medium
                                        </span>

                                        <span class="text-sm font-semibold text-blue-600">
                                            {{ getPriorityTotal('medium') }}
                                        </span>

                                    </div>

                                    <div class="h-4 overflow-hidden rounded-full bg-slate-100">

                                        <div class="h-full rounded-full bg-blue-500 transition-all" :style="{
                                            width: `${getPriorityPercentage('medium')}%`
                                        }"></div>

                                    </div>

                                </div>

                                <!-- High -->
                                <div>

                                    <div class="mb-2 flex items-center justify-between">

                                        <span class="text-sm font-medium text-slate-700">
                                            High
                                        </span>

                                        <span class="text-sm font-semibold text-orange-600">
                                            {{ getPriorityTotal('high') }}
                                        </span>

                                    </div>

                                    <div class="h-4 overflow-hidden rounded-full bg-slate-100">

                                        <div class="h-full rounded-full bg-orange-500 transition-all" :style="{
                                            width: `${getPriorityPercentage('high')}%`
                                        }"></div>

                                    </div>

                                </div>

                                <!-- Urgent -->
                                <div>

                                    <div class="mb-2 flex items-center justify-between">

                                        <span class="text-sm font-medium text-slate-700">
                                            Urgent
                                        </span>

                                        <span class="text-sm font-semibold text-red-600">
                                            {{ getPriorityTotal('urgent') }}
                                        </span>

                                    </div>

                                    <div class="h-4 overflow-hidden rounded-full bg-slate-100">

                                        <div class="h-full rounded-full bg-red-500 transition-all" :style="{
                                            width: `${getPriorityPercentage('urgent')}%`
                                        }"></div>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!-- Organization Bar Graph -->
                        <div class="rounded-xl border bg-white p-6 shadow-sm">

                            <div>

                                <h3 class="text-lg font-semibold text-gray-900">
                                    Concerns by Organization
                                </h3>

                                <p class="mt-1 text-sm text-gray-500">
                                    Number of concerns assigned to each organization.
                                </p>

                            </div>

                            <div v-if="
                                !dashboardData?.organizations?.length
                            " class="mt-8 rounded-lg bg-slate-50 p-6 text-center text-sm text-slate-500">
                                No organization data available.
                            </div>

                            <div v-else class="mt-8 space-y-6">

                                <div v-for="
organization in dashboardData.organizations
                                    " :key="organization.id">

                                    <div class="mb-2 flex items-center justify-between gap-4">

                                        <span class="truncate text-sm font-medium text-slate-700"
                                            :title="organization.name">
                                            {{ organization.name }}
                                        </span>

                                        <span class="shrink-0 text-sm font-semibold text-slate-800">
                                            {{
                                                getOrganizationTotal(
                                                    organization
                                                )
                                            }}
                                        </span>

                                    </div>

                                    <div class="h-4 overflow-hidden rounded-full bg-slate-100">

                                        <div class="h-full rounded-full bg-slate-700 transition-all" :style="{
                                            width: `${getOrganizationBarPercentage(organization)}%`
                                        }"></div>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                    <!-- ================================================= -->
                    <!-- Dashboard Information -->
                    <!-- ================================================= -->

                    <div class="mt-6 rounded-xl border bg-white p-6 shadow-sm">

                        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">

                            <div>

                                <h3 class="text-lg font-semibold text-gray-900">
                                    Concern Management Overview
                                </h3>

                                <p class="mt-1 text-sm text-gray-500">
                                    Use the Concerns page to view individual concern records, search, filter, update
                                    statuses, and view concern details.
                                </p>

                            </div>

                            <NuxtLink to="/concerns"
                                class="inline-flex items-center justify-center rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800">
                                View Concerns
                            </NuxtLink>

                        </div>

                    </div>

                </template>

            </div>

        </main>

    </div>
</template>