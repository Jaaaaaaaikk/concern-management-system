<script setup>

import {
    Chart,
    registerables
} from 'chart.js'
import { watch } from 'vue'
import { useToast } from '~/composables/useToast'

Chart.register(...registerables)

definePageMeta({
    middleware: 'auth'
})

const currentUser = useState('current-user', () => null)

const dashboardData = ref(null)

const loading = ref(true)

const errorMessage = ref('')
const { showToast } = useToast()

watch(errorMessage, (message) => {
    if (message) {
        showToast(message, 'error')
    }
})

const selectedRange = ref('30d')

const selectedOrganization = ref('all')

const loadingRange = ref(false)

const statusChartCanvas = ref(null)

const priorityChartCanvas = ref(null)

const trendChartCanvas = ref(null)

const organizationChartCanvas = ref(null)

const creatorChartCanvas = ref(null)

let statusChart = null

let priorityChart = null

let trendChart = null

let organizationChart = null

let creatorChart = null


/* --------------------------------------------------------------------------
| Current User
|-------------------------------------------------------------------------- */

async function loadCurrentUser() {

    try {

        const response = await $fetch(
            '/api/auth/me',
            {
                cache: 'no-store'
            }
        )

        currentUser.value =
            response.user

    } catch (error) {

        console.error(
            'Failed to load current user:',
            error
        )

        throw error
    }
}


/* --------------------------------------------------------------------------
| Dashboard
|-------------------------------------------------------------------------- */

async function loadDashboard() {

    try {

        const response = await $fetch(
            '/api/dashboard',
            {
                cache: 'no-store',

                query: {
                    range:
                        selectedRange.value,

                    organization_id:
                        selectedOrganization.value
                }
            }
        )

        dashboardData.value =
            response

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


/* --------------------------------------------------------------------------
| Load Everything
|-------------------------------------------------------------------------- */

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

    if (!errorMessage.value) {
        await nextTick()

        destroyCharts()
        renderCharts()
    }
}



/* --------------------------------------------------------------------------
| Change Dashboard Filter
|-------------------------------------------------------------------------- */

async function changeDashboardFilter() {

    loadingRange.value = true

    errorMessage.value = ''

    try {

        await loadDashboard()

        await nextTick()

        destroyCharts()

        renderCharts()

    } catch (error) {

        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to update dashboard data.'

    } finally {

        loadingRange.value = false
    }
}


/* --------------------------------------------------------------------------
| Status Helpers
|-------------------------------------------------------------------------- */

function getStatusTotal(status) {

    const item =
        dashboardData.value?.status?.find(
            item =>
                item.status === status
        )

    return Number(
        item?.total || 0
    )
}


/* --------------------------------------------------------------------------
| Priority Helpers
|-------------------------------------------------------------------------- */

function getPriorityTotal(priority) {

    const item =
        dashboardData.value?.priority?.find(
            item =>
                item.priority === priority
        )

    return Number(
        item?.total || 0
    )
}


/* --------------------------------------------------------------------------
| Formatting
|-------------------------------------------------------------------------- */

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

    return (
        priority.charAt(0).toUpperCase() +
        priority.slice(1)
    )
}


/* --------------------------------------------------------------------------
| Date Formatting
|-------------------------------------------------------------------------- */

function formatTrendDate(dateValue) {

    if (!dateValue) {
        return ''
    }

    /*
     * The API may return either:
     *
     * 2026-10-02
     *
     * or:
     *
     * 2026-10-02T16:00:00.000Z
     *
     * We only need the calendar date for the dashboard.
     */

    const datePart =
        String(dateValue).slice(0, 10)

    const date =
        new Date(
            `${datePart}T00:00:00`
        )

    if (
        Number.isNaN(
            date.getTime()
        )
    ) {
        return ''
    }

    return date.toLocaleDateString(
        'en-US',
        {
            month: 'short',
            day: 'numeric'
        }
    )
}


function formatTrendTooltipDate(dateValue) {

    if (!dateValue) {
        return ''
    }

    const datePart =
        String(dateValue).slice(0, 10)

    const date =
        new Date(
            `${datePart}T00:00:00`
        )

    if (
        Number.isNaN(
            date.getTime()
        )
    ) {
        return ''
    }

    return date.toLocaleDateString(
        'en-US',
        {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        }
    )
}


/* --------------------------------------------------------------------------
| Date Range Label
|-------------------------------------------------------------------------- */

const selectedRangeLabel = computed(() => {

    const labels = {

        today: 'Today',

        '7d': 'Last 7 Days',

        '30d': 'Last 30 Days',

        '3m': 'Last 3 Months',

        '6m': 'Last 6 Months',

        year: 'This Year',

        all: 'All Time'

    }

    return (
        labels[selectedRange.value] ||
        'Last 30 Days'
    )
})


/* --------------------------------------------------------------------------
| Organization Label
|-------------------------------------------------------------------------- */

const selectedOrganizationLabel = computed(() => {

    if (
        currentUser.value?.role_name !==
        'superadmin'
    ) {
        return ''
    }

    if (
        selectedOrganization.value ===
        'all'
    ) {
        return 'All Organizations'
    }

    const organization =
        dashboardData.value
            ?.organizationOptions
            ?.find(
                item =>
                    String(item.id) ===
                    String(
                        selectedOrganization.value
                    )
            )

    return (
        organization?.name ||
        'Selected Organization'
    )
})


/* --------------------------------------------------------------------------
| Chart Colors
|-------------------------------------------------------------------------- */

const statusColors = {

    pending: '#facc15',

    in_progress: '#3b82f6',

    on_hold: '#fb923c',

    resolved: '#22c55e',

    closed: '#64748b',

    cancelled: '#ef4444'

}


const priorityColors = {

    low: '#94a3b8',

    medium: '#3b82f6',

    high: '#f97316',

    urgent: '#ef4444'

}


/* --------------------------------------------------------------------------
| Destroy Charts
|-------------------------------------------------------------------------- */

function destroyCharts() {

    if (statusChart) {

        statusChart.destroy()

        statusChart = null
    }

    if (priorityChart) {

        priorityChart.destroy()

        priorityChart = null
    }

    if (trendChart) {

        trendChart.destroy()

        trendChart = null
    }

    if (organizationChart) {

        organizationChart.destroy()

        organizationChart = null
    }

    if (creatorChart) {

        creatorChart.destroy()

        creatorChart = null
    }
}


/* --------------------------------------------------------------------------
| Status Chart
|-------------------------------------------------------------------------- */

function renderStatusChart() {

    if (!statusChartCanvas.value) {
        return
    }

    const statuses = [

        'pending',

        'in_progress',

        'on_hold',

        'resolved',

        'closed',

        'cancelled'

    ]

    const labels =
        statuses.map(
            status =>
                formatStatus(status)
        )

    const values =
        statuses.map(
            status =>
                getStatusTotal(status)
        )

    statusChart =
        new Chart(
            statusChartCanvas.value,
            {

                type: 'doughnut',

                data: {

                    labels,

                    datasets: [

                        {

                            data: values,

                            backgroundColor:
                                statuses.map(
                                    status =>
                                        statusColors[
                                        status
                                        ]
                                ),

                            borderWidth: 2,

                            borderColor: '#ffffff',

                            hoverOffset: 6

                        }

                    ]

                },

                options: {

                    responsive: true,

                    maintainAspectRatio: false,

                    cutout: '65%',

                    plugins: {

                        legend: {

                            display: false

                        },

                        tooltip: {

                            callbacks: {

                                label(context) {

                                    const value =
                                        context.raw || 0

                                    const total =
                                        values.reduce(
                                            (
                                                sum,
                                                item
                                            ) =>
                                                sum +
                                                item,
                                            0
                                        )

                                    const percentage =
                                        total > 0
                                            ? (
                                                value /
                                                total
                                            ) *
                                            100
                                            : 0

                                    return `${value} (${percentage.toFixed(1)}%)`
                                }

                            }

                        }

                    }

                }

            }
        )
}


/* --------------------------------------------------------------------------
| Priority Chart
|-------------------------------------------------------------------------- */

function renderPriorityChart() {

    if (!priorityChartCanvas.value) {
        return
    }

    const priorities = [

        'low',

        'medium',

        'high',

        'urgent'

    ]

    priorityChart =
        new Chart(
            priorityChartCanvas.value,
            {

                type: 'bar',

                data: {

                    labels:
                        priorities.map(
                            priority =>
                                formatPriority(
                                    priority
                                )
                        ),

                    datasets: [

                        {

                            label:
                                'Number of Concerns',

                            data:
                                priorities.map(
                                    priority =>
                                        getPriorityTotal(
                                            priority
                                        )
                                ),

                            backgroundColor:
                                priorities.map(
                                    priority =>
                                        priorityColors[
                                        priority
                                        ]
                                ),

                            borderRadius: 6,

                            borderSkipped: false

                        }

                    ]

                },

                options: {

                    responsive: true,

                    maintainAspectRatio: false,

                    plugins: {

                        legend: {

                            display: false

                        },

                        tooltip: {

                            callbacks: {

                                label(context) {

                                    return `${context.raw} concerns`
                                }

                            }

                        }

                    },

                    scales: {

                        y: {

                            beginAtZero: true,

                            ticks: {

                                precision: 0

                            },

                            grid: {

                                color: '#e2e8f0'

                            }

                        },

                        x: {

                            grid: {

                                display: false

                            }

                        }

                    }

                }

            }
        )
}


/* --------------------------------------------------------------------------
| Trend Chart
|-------------------------------------------------------------------------- */

function renderTrendChart() {

    if (!trendChartCanvas.value) {
        return
    }

    const trend =
        dashboardData.value?.trend || []

    const labels =
        trend.map(
            item =>
                formatTrendDate(
                    item.date
                )
        )

    const values =
        trend.map(
            item =>
                Number(
                    item.total || 0
                )
        )

    trendChart =
        new Chart(
            trendChartCanvas.value,
            {

                type: 'line',

                data: {

                    labels,

                    datasets: [

                        {

                            label:
                                'Concerns Created',

                            data: values,

                            borderColor:
                                '#0f172a',

                            backgroundColor:
                                'rgba(15, 23, 42, 0.08)',

                            borderWidth: 2,

                            fill: true,

                            tension: 0.3,

                            pointRadius:
                                trend.length > 60
                                    ? 0
                                    : 3,

                            pointHoverRadius: 5

                        }

                    ]

                },

                options: {

                    responsive: true,

                    maintainAspectRatio: false,

                    interaction: {

                        intersect: false,

                        mode: 'index'

                    },

                    plugins: {

                        legend: {

                            display: false

                        },

                        tooltip: {

                            callbacks: {

                                title(items) {

                                    if (
                                        !items ||
                                        !items.length
                                    ) {
                                        return ''
                                    }

                                    const index =
                                        items[0]
                                            .dataIndex

                                    const item =
                                        trend[index]

                                    return formatTrendTooltipDate(
                                        item?.date
                                    )
                                },

                                label(context) {

                                    return `${context.raw} concerns created`
                                }

                            }

                        }

                    },

                    scales: {

                        y: {

                            beginAtZero: true,

                            ticks: {

                                precision: 0

                            },

                            grid: {

                                color: '#e2e8f0'

                            }

                        },

                        x: {

                            grid: {

                                display: false

                            },

                            ticks: {

                                maxRotation: 45,

                                minRotation: 0,

                                autoSkip: true,

                                maxTicksLimit: 12

                            }

                        }

                    }

                }

            }
        )
}


/* --------------------------------------------------------------------------
| Organization Chart
|-------------------------------------------------------------------------- */

function renderOrganizationChart() {

    if (!organizationChartCanvas.value) {
        return
    }

    const organizations =
        dashboardData.value?.organizations || []

    const sortedOrganizations =
        [...organizations]
            .sort(
                (a, b) =>
                    Number(
                        b.total_concerns || 0
                    ) -
                    Number(
                        a.total_concerns || 0
                    )
            )

    const labels =
        sortedOrganizations.map(
            organization =>
                organization.name
        )

    const values =
        sortedOrganizations.map(
            organization =>
                Number(
                    organization.total_concerns ||
                    0
                )
        )

    organizationChart =
        new Chart(
            organizationChartCanvas.value,
            {

                type: 'bar',

                data: {

                    labels,

                    datasets: [

                        {

                            label:
                                'Number of Concerns',

                            data: values,

                            backgroundColor:
                                '#334155',

                            borderRadius: 5,

                            borderSkipped: false

                        }

                    ]

                },

                options: {

                    indexAxis: 'y',

                    responsive: true,

                    maintainAspectRatio: false,

                    plugins: {

                        legend: {

                            display: false

                        },

                        tooltip: {

                            callbacks: {

                                label(context) {

                                    return `${context.raw} concerns`
                                }

                            }

                        }

                    },

                    scales: {

                        x: {

                            beginAtZero: true,

                            ticks: {

                                precision: 0

                            },

                            grid: {

                                color: '#e2e8f0'

                            }

                        },

                        y: {

                            grid: {

                                display: false

                            }

                        }

                    }

                }

            }
        )
}


/* --------------------------------------------------------------------------
| Top Creator Chart
|-------------------------------------------------------------------------- */

function renderCreatorChart() {

    if (!creatorChartCanvas.value) {
        return
    }

    const creators =
        dashboardData.value?.topCreators || []

    const sortedCreators =
        [...creators]
            .sort(
                (a, b) =>
                    Number(
                        b.total_concerns || 0
                    ) -
                    Number(
                        a.total_concerns || 0
                    )
            )

    const labels =
        sortedCreators.map(
            creator =>
                creator.name
        )

    const values =
        sortedCreators.map(
            creator =>
                Number(
                    creator.total_concerns ||
                    0
                )
        )

    creatorChart =
        new Chart(
            creatorChartCanvas.value,
            {

                type: 'bar',

                data: {

                    labels,

                    datasets: [

                        {

                            label:
                                'Concerns Created',

                            data: values,

                            backgroundColor:
                                '#475569',

                            borderRadius: 5,

                            borderSkipped: false

                        }

                    ]

                },

                options: {

                    indexAxis: 'y',

                    responsive: true,

                    maintainAspectRatio: false,

                    plugins: {

                        legend: {

                            display: false

                        },

                        tooltip: {

                            callbacks: {

                                label(context) {

                                    return `${context.raw} concerns`
                                }

                            }

                        }

                    },

                    scales: {

                        x: {

                            beginAtZero: true,

                            ticks: {

                                precision: 0

                            },

                            grid: {

                                color: '#e2e8f0'

                            }

                        },

                        y: {

                            grid: {

                                display: false

                            }

                        }

                    }

                }

            }
        )
}


/* --------------------------------------------------------------------------
| Render All Charts
|-------------------------------------------------------------------------- */

function renderCharts() {

    if (!dashboardData.value) {
        return
    }

    renderStatusChart()

    renderPriorityChart()

    renderTrendChart()

    renderOrganizationChart()

    renderCreatorChart()
}


/* --------------------------------------------------------------------------
| Logout
|-------------------------------------------------------------------------- */

async function logout() {

    try {

        await $fetch(
            '/api/auth/logout',
            {
                method: 'POST'
            }
        )

        await navigateTo('/login')

    } catch (error) {

        console.error(
            'Logout error:',
            error
        )
    }
}


/* --------------------------------------------------------------------------
| Cleanup
|-------------------------------------------------------------------------- */

onBeforeUnmount(() => {

    destroyCharts()

})


/* --------------------------------------------------------------------------
| Initial Load
|-------------------------------------------------------------------------- */

function updateProfilePhoto(profilePhoto) {
    if (currentUser.value) {
        currentUser.value.profile_photo = profilePhoto
    }
}

onMounted(() => {

    loadData()

})

</script>

<template>

    <div class="min-h-screen bg-slate-100">

        <MobileNavigation :current-user="currentUser" @logout="logout" @profile-updated="updateProfilePhoto" />

        <!-- Sidebar -->

        <aside class="fixed inset-y-0 left-0 z-40 hidden w-64 flex-col bg-blue-950 text-white lg:flex">

            <!-- Logo -->

            <div class="border-b border-blue-900 px-6 py-5">

                <h1 class="text-lg font-bold">
                    Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>

            </div>


            <!-- Navigation -->

            <nav class="flex-1 space-y-1 px-3 py-4">

                <NuxtLink to="/dashboard"
                    :class="$route.path === '/dashboard' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-blue-900 hover:text-white'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="dashboard" />
                    <span>Dashboard</span>
                </NuxtLink>


                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/organizations"
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

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/users"
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


            <!-- Logged-in User -->

            <div class="border-t border-blue-900 p-4">
                <UserProfileControl :current-user="currentUser" @logout="logout"
                    @profile-updated="updateProfilePhoto" />
            </div>

        </aside>


        <!-- Main Content -->

        <main class="flex min-h-screen flex-col lg:ml-64">

            <!-- Header -->

            <header
                class="sticky top-0 z-20 flex min-h-16 flex-col items-start justify-between gap-4 border-b border-slate-200 bg-white px-4 py-4 sm:flex-row sm:items-center sm:px-6 lg:px-8">

                <div>

                    <h2 class="text-xl font-semibold text-slate-900">
                        Dashboard
                    </h2>

                    <p class="mt-1 text-sm text-slate-500">
                        Overview of the concern management system
                    </p>

                </div>


                <!-- Dashboard Filters -->

                <div class="flex flex-wrap items-center justify-end gap-3">

                    <!-- Date Range -->

                    <div class="flex items-center gap-3">

                        <label for="dashboard-range" class="hidden text-sm font-medium text-slate-600 sm:block">
                            Date Range
                        </label>

                        <select id="dashboard-range" v-model="selectedRange" @change="changeDashboardFilter"
                            :disabled="loadingRange"
                            class="cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-200 disabled:cursor-not-allowed disabled:opacity-60">

                            <option value="today">
                                Today
                            </option>

                            <option value="7d">
                                Last 7 Days
                            </option>

                            <option value="30d">
                                Last 30 Days
                            </option>

                            <option value="3m">
                                Last 3 Months
                            </option>

                            <option value="6m">
                                Last 6 Months
                            </option>

                            <option value="year">
                                This Year
                            </option>

                            <option value="all">
                                All Time
                            </option>

                        </select>

                    </div>


                    <!-- Organization -->

                    <div v-if="currentUser?.role_name === 'superadmin'" class="flex items-center gap-3">

                        <label for="dashboard-organization" class="hidden text-sm font-medium text-slate-600 xl:block">
                            Organization
                        </label>

                        <select id="dashboard-organization" v-model="selectedOrganization"
                            @change="changeDashboardFilter" :disabled="loadingRange"
                            class="max-w-[240px] cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-200 disabled:cursor-not-allowed disabled:opacity-60">

                            <option value="all">
                                All Organizations
                            </option>

                            <option v-for="organization in dashboardData?.organizationOptions || []"
                                :key="organization.id" :value="String(organization.id)">
                                {{ organization.name }}
                            </option>

                        </select>

                    </div>

                </div>

            </header>


            <!-- Content -->

            <div class="p-8">

                <!-- Error -->

                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
                    {{ errorMessage }}
                </div>


                <!-- Loading -->

                <div v-if="loading" class="rounded-xl border border-slate-300 bg-white p-10 text-center shadow-md">

                    <p class="text-sm text-slate-500">
                        Loading dashboard...
                    </p>

                </div>


                <!-- Dashboard -->

                <template v-else>

                    <!-- Dashboard Filters Summary -->

                    <div class="mb-6 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">

                        <div>

                            <p class="text-sm font-medium text-slate-700">
                                Dashboard Overview
                            </p>

                            <p class="text-xs text-slate-500">

                                Showing data for
                                {{ selectedRangeLabel.toLowerCase() }}

                                <template v-if="currentUser?.role_name === 'superadmin'">
                                    · {{ selectedOrganizationLabel }}
                                </template>

                                .

                            </p>

                        </div>


                        <div v-if="loadingRange" class="text-xs font-medium text-slate-500">
                            Updating dashboard...
                        </div>

                    </div>


                    <!-- Summary Cards -->

                    <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-5">

                        <!-- Total -->

                        <NuxtLink to="/concerns"
                            class="group rounded-xl border border-slate-300 bg-white p-5 shadow-md transition hover:-translate-y-0.5 hover:border-slate-400 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-slate-300">
                            <p class="text-sm text-slate-500">
                                Total Concerns
                            </p>

                            <p class="mt-2 text-3xl font-bold text-slate-900">
                                {{
                                    dashboardData?.summary?.total ?? 0
                                }}
                            </p>

                            <p class="mt-2 text-xs font-medium text-slate-400 transition group-hover:text-slate-600">
                                View all concerns
                            </p>
                        </NuxtLink>


                        <!-- Pending -->

                        <NuxtLink :to="{
                            path: '/concerns',
                            query: {
                                status: 'pending'
                            }
                        }"
                            class="group rounded-xl border border-slate-300 bg-white p-5 shadow-md transition hover:-translate-y-0.5 hover:border-yellow-300 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-yellow-200">
                            <p class="text-sm text-slate-500">
                                Pending
                            </p>

                            <p class="mt-2 text-3xl font-bold text-yellow-600">
                                {{ getStatusTotal('pending') }}
                            </p>

                            <p class="mt-2 text-xs font-medium text-slate-400 transition group-hover:text-yellow-600">
                                View pending concerns
                            </p>
                        </NuxtLink>


                        <!-- In Progress -->

                        <NuxtLink :to="{
                            path: '/concerns',
                            query: {
                                status: 'in_progress'
                            }
                        }"
                            class="group rounded-xl border border-slate-300 bg-white p-5 shadow-md transition hover:-translate-y-0.5 hover:border-blue-300 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-blue-200">
                            <p class="text-sm text-slate-500">
                                In Progress
                            </p>

                            <p class="mt-2 text-3xl font-bold text-blue-600">
                                {{ getStatusTotal('in_progress') }}
                            </p>

                            <p class="mt-2 text-xs font-medium text-slate-400 transition group-hover:text-blue-600">
                                View in-progress concerns
                            </p>
                        </NuxtLink>


                        <!-- Resolved -->

                        <NuxtLink :to="{
                            path: '/concerns',
                            query: {
                                status: 'resolved'
                            }
                        }"
                            class="group rounded-xl border border-slate-300 bg-white p-5 shadow-md transition hover:-translate-y-0.5 hover:border-green-300 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-green-200">
                            <p class="text-sm text-slate-500">
                                Resolved
                            </p>

                            <p class="mt-2 text-3xl font-bold text-green-600">
                                {{ getStatusTotal('resolved') }}
                            </p>

                            <p class="mt-2 text-xs font-medium text-slate-400 transition group-hover:text-green-600">
                                View resolved concerns
                            </p>
                        </NuxtLink>


                        <!-- Closed -->

                        <NuxtLink :to="{
                            path: '/concerns',
                            query: {
                                status: 'closed'
                            }
                        }"
                            class="group rounded-xl border border-slate-300 bg-white p-5 shadow-md transition hover:-translate-y-0.5 hover:border-slate-400 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-slate-300">
                            <p class="text-sm text-slate-500">
                                Closed
                            </p>

                            <p class="mt-2 text-3xl font-bold text-slate-600">
                                {{ getStatusTotal('closed') }}
                            </p>

                            <p class="mt-2 text-xs font-medium text-slate-400 transition group-hover:text-slate-600">
                                View closed concerns
                            </p>
                        </NuxtLink>


                    </div>



                    <!-- Status + Priority -->

                    <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">

                        <!-- Status -->

                        <div class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

                            <div class="flex flex-wrap items-start justify-between gap-4">

                                <div>

                                    <h3 class="text-lg font-semibold text-slate-900">
                                        Concern Status Distribution
                                    </h3>

                                    <p class="mt-1 text-sm text-slate-500">
                                        Distribution of concerns by current status.
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


                            <div v-if="dashboardData?.summary?.total > 0" class="mt-6 h-[280px]">

                                <canvas ref="statusChartCanvas"></canvas>

                            </div>


                            <div v-else class="mt-6 flex h-[280px] items-center justify-center rounded-lg bg-slate-50">

                                <p class="text-sm text-slate-500">
                                    No concern data available for this period.
                                </p>

                            </div>


                            <!-- Status Legend -->

                            <div class="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3">

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


                        <!-- Priority -->

                        <div class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

                            <div>

                                <h3 class="text-lg font-semibold text-slate-900">
                                    Concerns by Priority
                                </h3>

                                <p class="mt-1 text-sm text-slate-500">
                                    Number of concerns under each priority level.
                                </p>

                            </div>


                            <div v-if="dashboardData?.summary?.total > 0" class="mt-8 h-[360px]">

                                <canvas ref="priorityChartCanvas"></canvas>

                            </div>


                            <div v-else class="mt-8 flex h-[360px] items-center justify-center rounded-lg bg-slate-50">

                                <p class="text-sm text-slate-500">
                                    No priority data available for this period.
                                </p>

                            </div>

                        </div>

                    </div>


                    <!-- Trend -->

                    <div class="mt-6 rounded-xl border border-slate-300 bg-white p-6 shadow-md">

                        <div class="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">

                            <div>

                                <h3 class="text-lg font-semibold text-slate-900">
                                    Concerns Created Over Time
                                </h3>

                                <p class="mt-1 text-sm text-slate-500">
                                    Number of concerns created during the selected period.
                                </p>

                            </div>


                            <div class="rounded-lg bg-slate-50 px-4 py-2">

                                <span class="text-xs font-medium text-slate-500">
                                    {{ selectedRangeLabel }}
                                </span>

                            </div>

                        </div>


                        <div v-if="dashboardData?.trend?.length" class="mt-6 h-[330px]">

                            <canvas ref="trendChartCanvas"></canvas>

                        </div>


                        <div v-else class="mt-6 flex h-[330px] items-center justify-center rounded-lg bg-slate-50">

                            <p class="text-sm text-slate-500">
                                No concern activity available for this period.
                            </p>

                        </div>

                    </div>


                    <!-- Organization + Top Creators -->

                    <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">

                        <!-- Organization -->

                        <div class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

                            <div>

                                <h3 class="text-lg font-semibold text-slate-900">
                                    Concerns by Organization
                                </h3>

                                <p class="mt-1 text-sm text-slate-500">
                                    Number of concerns related to each organization.
                                </p>

                            </div>


                            <div v-if="dashboardData?.organizations?.length" class="mt-6 h-[360px]">

                                <canvas ref="organizationChartCanvas"></canvas>

                            </div>


                            <div v-else class="mt-6 flex h-[360px] items-center justify-center rounded-lg bg-slate-50">

                                <p class="text-sm text-slate-500">
                                    No organization data available.
                                </p>

                            </div>

                        </div>


                        <!-- Top Creators -->

                        <div class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

                            <div>

                                <h3 class="text-lg font-semibold text-slate-900">
                                    Top Concern Creators
                                </h3>

                                <p class="mt-1 text-sm text-slate-500">
                                    Users who created the most concerns during the selected period.
                                </p>

                            </div>


                            <div v-if="dashboardData?.topCreators?.length" class="mt-6 h-[360px]">

                                <canvas ref="creatorChartCanvas"></canvas>

                            </div>


                            <div v-else class="mt-6 flex h-[360px] items-center justify-center rounded-lg bg-slate-50">

                                <p class="text-sm text-slate-500">
                                    No creator data available.
                                </p>

                            </div>

                        </div>

                    </div>


                </template>

            </div>

            <AppFooter class="mt-auto" />
        </main>

    </div>

</template>
