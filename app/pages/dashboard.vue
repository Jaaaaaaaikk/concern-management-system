<script setup>

import {
    Chart,
    registerables
} from 'chart.js'
import { VueDatePicker } from '@vuepic/vue-datepicker'
import '@vuepic/vue-datepicker/dist/main.css'
import { watch } from 'vue'
import AppSelect from '~/components/AppSelect.vue'
import { useToast } from '~/composables/useToast'
import { useStickyHeader } from '~/composables/useStickyHeader'

Chart.register(...registerables)
Chart.defaults.animation.duration = 1000
Chart.defaults.animation.easing = 'easeOutQuart'

definePageMeta({
    middleware: 'auth',
    pageTransition: {
        name: 'dashboard-zoom',
        mode: 'out-in'
    }
})

const currentUser = useState('current-user', () => null)
const isHeaderSticky = useStickyHeader()

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

const customStartDate = ref('')

const customEndDate = ref('')

const draftStartDate = ref('')

const draftEndDate = ref('')

const isDateFilterOpen = ref(false)

const selectedOrganization = ref('all')

const loadingRange = ref(false)
const showMobileFilters = ref(false)

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

let scrollRevealObserver = null


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
                        customStartDate.value || customEndDate.value
                            ? 'custom'
                            : selectedRange.value,

                    ...(customStartDate.value || customEndDate.value
                        ? {
                            start_date: customStartDate.value,
                            end_date: customEndDate.value
                        }
                        : {}),

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
        setupScrollReveal()
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

function handleDashboardRangeChange() {
    customStartDate.value = ''
    customEndDate.value = ''
    draftStartDate.value = ''
    draftEndDate.value = ''
    isDateFilterOpen.value = false
    changeDashboardFilter()
}

function openDateFilter() {
    draftStartDate.value = customStartDate.value
    draftEndDate.value = customEndDate.value
    isDateFilterOpen.value = !isDateFilterOpen.value
}

function applyDashboardDateRange() {
    if (
        draftStartDate.value &&
        draftEndDate.value &&
        draftStartDate.value > draftEndDate.value
    ) {
        showToast('The start date must be on or before the end date.', 'error')
        return
    }

    customStartDate.value = draftStartDate.value
    customEndDate.value = draftEndDate.value
    isDateFilterOpen.value = false
    changeDashboardFilter()
}

function resetDashboardDateRange() {
    draftStartDate.value = ''
    draftEndDate.value = ''
    customStartDate.value = ''
    customEndDate.value = ''
    isDateFilterOpen.value = false
    changeDashboardFilter()
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

    if (customStartDate.value || customEndDate.value) {
        const formatDate = (dateValue) => dateValue
            ? new Date(`${dateValue}T00:00:00`).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            })
            : ''

        if (customStartDate.value && customEndDate.value) {
            return `${formatDate(customStartDate.value)} to ${formatDate(customEndDate.value)}`
        }

        return customStartDate.value
            ? `From ${formatDate(customStartDate.value)}`
            : `Through ${formatDate(customEndDate.value)}`
    }

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
        !['superadmin', 'system_admin', 'system_monitor'].includes(currentUser.value?.role_name)
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

    closed: '#64748b'

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

        'closed'

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

                            data: values.map(() => 0),

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

                    animation: {

                        duration: 1400,

                        easing: 'easeOutQuart',

                        delay: 100,

                        animateRotate: true,

                        animateScale: true

                    },

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

    const chartInstance = statusChart

    requestAnimationFrame(() => {
        if (statusChart !== chartInstance) {
            return
        }

        chartInstance.data.datasets[0].data = values
        chartInstance.update()
    })
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

    const values =
        priorities.map(
            priority =>
                getPriorityTotal(priority)
        )

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

                            data: values.map(() => 0),

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

                    animation: {

                        duration: 1400,

                        easing: 'easeOutQuart',

                        delay: 250

                    },

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

    const chartInstance = priorityChart

    requestAnimationFrame(() => {
        if (priorityChart !== chartInstance) {
            return
        }

        chartInstance.data.datasets[0].data = values
        chartInstance.update()
    })
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

function setupScrollReveal() {
    if (
        typeof window === 'undefined' ||
        !('IntersectionObserver' in window) ||
        window.matchMedia('(prefers-reduced-motion: reduce)').matches
    ) {
        return
    }

    const sections = document.querySelectorAll('[data-scroll-reveal]')

    if (sections.length === 0) {
        return
    }

    scrollRevealObserver?.disconnect()
    document.documentElement.classList.add('has-scroll-reveal')

    scrollRevealObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            entry.target.classList.toggle('is-scroll-visible', entry.isIntersecting)
        })
    }, {
        threshold: 0.12,
        rootMargin: '0px 0px -48px 0px'
    })

    sections.forEach((section, index) => {
        section.style.setProperty('--scroll-reveal-delay', `${(index % 2) * 100}ms`)
        scrollRevealObserver.observe(section)
    })
}

function cleanupScrollReveal() {
    scrollRevealObserver?.disconnect()
    scrollRevealObserver = null
    document.documentElement.classList.remove('has-scroll-reveal')
}


/* --------------------------------------------------------------------------
| Logout
|-------------------------------------------------------------------------- */

async function logout() {

    currentUser.value = null

    try {

        await $fetch(
            '/api/auth/logout',
            {
                method: 'POST'
            }
        )

    } catch (error) {

        // Continue to login even if the session is already invalid.
    }

    await navigateTo('/login')
}


/* --------------------------------------------------------------------------
| Cleanup
|-------------------------------------------------------------------------- */

onBeforeUnmount(() => {

    destroyCharts()
    cleanupScrollReveal()

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

        <aside class="fixed inset-y-0 left-0 z-40 hidden h-screen w-64 flex-col bg-blue-950 text-white lg:flex">

            <!-- Logo -->

            <div class="px-6 py-5">

                <h1 class="text-lg font-bold">
                    Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>

            </div>


            <!-- Navigation -->

            <nav class="sidebar-navigation flex-1 space-y-1 px-3 py-4">

                <NuxtLink to="/dashboard"
                    :class="$route.path === '/dashboard' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="dashboard" />
                    <span>Dashboard</span>
                </NuxtLink>

                <NuxtLink v-if="['superadmin', 'system_admin'].includes(currentUser?.role_name)" to="/users"
                    :class="$route.path === '/users' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="users" />
                    <span>Manage Users</span>
                </NuxtLink>

                <NuxtLink v-if="['superadmin', 'system_admin'].includes(currentUser?.role_name)" to="/organizations"
                    :class="$route.path === '/organizations' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="organizations" />
                    <span>Manage Organizations</span>
                </NuxtLink>

                <NuxtLink to="/concerns"
                    :class="$route.path === '/concerns' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="concerns" />
                    <span>Manage Concerns</span>
                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/concern-categories"
                    :class="$route.path === '/concern-categories' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="categories" />
                    <span>Concern Categories</span>
                </NuxtLink>



                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/login-history"
                    :class="$route.path === '/login-history' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">
                    <NavIcon name="history" />
                    <span>Login History</span>
                </NuxtLink>

            </nav>


            <!-- Logged-in User -->

            <div class="p-4">
                <UserProfileControl :current-user="currentUser" @logout="logout"
                    @profile-updated="updateProfilePhoto" />
            </div>

        </aside>


        <!-- Main Content -->

        <main class="flex min-h-screen flex-col lg:ml-64">

            <!-- Header -->

            <header :class="[
                'relative z-50 flex min-h-16 flex-col items-start justify-between gap-4 border-b border-slate-200 px-4 py-4 backdrop-blur-md transition-[transform,opacity,background-color,box-shadow,padding] duration-300 ease-out sm:flex-row sm:items-center sm:px-6 lg:px-8',
                isHeaderSticky
                    ? 'lg:sticky lg:top-0 lg:z-50 lg:-translate-y-1 lg:py-3 bg-white/30 shadow-md'
                    : 'translate-y-0 bg-white/30 shadow-sm'
            ]">

                <div class="w-full flex-1">
                    <div class="flex items-start justify-between gap-3">
                        <div>
                            <h2 class="text-xl font-semibold text-slate-900">
                                Dashboard
                            </h2>
                            <p class="mt-1 text-sm text-slate-500">
                                Overview of the concern management system
                            </p>
                        </div>
                        <button
                            type="button"
                            data-tour="dashboard-mobile-filters-toggle"
                            class="inline-flex shrink-0 cursor-pointer items-center gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-blue-300 hover:bg-blue-50 hover:text-blue-900 focus:outline-none focus:ring-2 focus:ring-blue-700/20 lg:hidden"
                            :aria-expanded="showMobileFilters"
                            aria-controls="dashboard-mobile-filters"
                            @click="showMobileFilters = !showMobileFilters"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M7 12h10m-7 6h4" />
                            </svg>
                            Filters
                        </button>
                    </div>

                    <div v-if="showMobileFilters" id="dashboard-mobile-filters" class="mt-4 grid grid-cols-1 gap-3 rounded-xl border border-slate-200 bg-slate-50 p-3 sm:grid-cols-2 lg:hidden">
                        <div class="min-w-0 rounded-xl border border-slate-200 bg-white p-3 sm:col-span-2">
                            <span class="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500">Date created</span>
                            <AppSelect
                                v-model="selectedRange"
                                aria-label="Date range"
                                compact
                                data-tour="dashboard-range"
                                :disabled="loadingRange"
                                :options="[
                                    { label: 'Today', value: 'today' },
                                    { label: 'Last 7 Days', value: '7d' },
                                    { label: 'Last 30 Days', value: '30d' },
                                    { label: 'Last 3 Months', value: '3m' },
                                    { label: 'Last 6 Months', value: '6m' },
                                    { label: 'This Year', value: 'year' },
                                    { label: 'All Time', value: 'all' }
                                ]"
                                @change="handleDashboardRangeChange"
                            />
                            <div class="mt-3 grid grid-cols-2 gap-2">
                                <label class="text-[11px] font-medium text-slate-500">
                                    From
                                    <VueDatePicker
                                        v-model="draftStartDate"
                                        model-type="yyyy-MM-dd"
                                        format="MMM d, yyyy"
                                        placeholder="Any start date"
                                        :enable-time-picker="false"
                                        :auto-apply="true"
                                        :clearable="true"
                                        :max-date="draftEndDate || undefined"
                                        :teleport="true"
                                        :disabled="loadingRange"
                                        input-class-name="!cursor-pointer !rounded-lg !border-slate-300 !py-2 !text-xs focus:!border-blue-700"
                                        menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                                        class="mt-1 w-full"
                                        aria-label="Created date from"
                                    />
                                </label>
                                <label class="text-[11px] font-medium text-slate-500">
                                    To
                                    <VueDatePicker
                                        v-model="draftEndDate"
                                        model-type="yyyy-MM-dd"
                                        format="MMM d, yyyy"
                                        placeholder="Any end date"
                                        :enable-time-picker="false"
                                        :auto-apply="true"
                                        :clearable="true"
                                        :min-date="draftStartDate || undefined"
                                        :teleport="true"
                                        :disabled="loadingRange"
                                        input-class-name="!cursor-pointer !rounded-lg !border-slate-300 !py-2 !text-xs focus:!border-blue-700"
                                        menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                                        class="mt-1 w-full"
                                        aria-label="Created date to"
                                    />
                                </label>
                            </div>
                            <div class="mt-3 flex justify-end">
                                <button type="button" :disabled="loadingRange || (!draftStartDate && !draftEndDate)" class="cursor-pointer rounded-lg bg-blue-900 px-3 py-2 text-xs font-semibold text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50" @click="applyDashboardDateRange">
                                    Apply dates
                                </button>
                            </div>
                        </div>

                        <label v-if="['superadmin', 'system_admin', 'system_monitor'].includes(currentUser?.role_name)" class="flex min-w-0 items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2">
                            <span class="shrink-0 rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-700">Organization</span>
                            <AppSelect
                                v-model="selectedOrganization"
                                aria-label="Organization filter"
                                compact
                                data-tour="dashboard-organization"
                                :disabled="loadingRange"
                                :options="[
                                    { label: 'All Organizations', value: 'all' },
                                    ...(dashboardData?.organizationOptions || []).map(organization => ({ label: organization.name, value: String(organization.id) }))
                                ]"
                                @change="changeDashboardFilter"
                            />
                        </label>
                    </div>
                </div>


                <!-- Dashboard Filters -->

                <div class="hidden flex-wrap items-end justify-end gap-3 lg:flex">

                    <!-- Date Range -->

                    <div class="relative">
                        <button
                            type="button"
                            data-tour="dashboard-range"
                            aria-label="Filter dashboard by date created"
                            :aria-expanded="isDateFilterOpen"
                            aria-haspopup="dialog"
                            :disabled="loadingRange"
                            class="inline-flex h-10 min-w-40 cursor-pointer items-center justify-between gap-3 rounded-lg border border-slate-300 bg-white px-3 text-sm font-medium text-slate-700 shadow-sm transition hover:border-blue-400 hover:bg-blue-50/50 focus:outline-none focus:ring-2 focus:ring-blue-700/20 disabled:cursor-not-allowed disabled:opacity-60"
                            @click="openDateFilter"
                        >
                            <span class="flex min-w-0 items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4 shrink-0 text-slate-500" aria-hidden="true">
                                    <rect width="18" height="18" x="3" y="4" rx="2" />
                                    <path stroke-linecap="round" d="M16 2v4M8 2v4M3 10h18" />
                                </svg>
                                <span class="truncate">{{ selectedRangeLabel }}</span>
                            </span>
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4 shrink-0 text-slate-400 transition-transform" :class="isDateFilterOpen ? 'rotate-180' : ''" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="m6 9 6 6 6-6" />
                            </svg>
                        </button>

                        <div v-if="isDateFilterOpen" role="dialog" aria-label="Date created filter" class="absolute right-0 top-full z-50 mt-2 w-[min(22rem,calc(100vw-2rem))] rounded-xl border border-slate-200 bg-white p-4 shadow-xl ring-1 ring-slate-900/5">
                            <div class="flex items-start justify-between gap-3">
                                <div>
                                    <h3 class="text-sm font-semibold text-slate-900">Date created</h3>
                                    <p class="mt-0.5 text-xs text-slate-500">Choose a preset or set exact dates.</p>
                                </div>
                                <button type="button" aria-label="Close date filter" class="cursor-pointer rounded-md p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700" @click="isDateFilterOpen = false">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="m6 6 12 12M18 6 6 18" />
                                    </svg>
                                </button>
                            </div>

                            <div class="mt-3 grid grid-cols-2 gap-2">
                                <button
                                    v-for="range in [
                                        { label: 'Today', value: 'today' },
                                        { label: 'Last 7 days', value: '7d' },
                                        { label: 'Last 30 days', value: '30d' },
                                        { label: 'Last 3 months', value: '3m' },
                                        { label: 'Last 6 months', value: '6m' },
                                        { label: 'This year', value: 'year' },
                                        { label: 'All time', value: 'all' }
                                    ]"
                                    :key="range.value"
                                    type="button"
                                    class="cursor-pointer rounded-lg border px-3 py-2 text-left text-xs font-medium transition"
                                    :class="!customStartDate && !customEndDate && selectedRange === range.value ? 'border-blue-300 bg-blue-50 text-blue-900' : 'border-slate-200 text-slate-600 hover:border-slate-300 hover:bg-slate-50'"
                                    @click="selectedRange = range.value; handleDashboardRangeChange()"
                                >
                                    {{ range.label }}
                                </button>
                            </div>

                            <div class="my-4 flex items-center gap-3 text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                                <span class="h-px flex-1 bg-slate-200"></span>
                                Custom range
                                <span class="h-px flex-1 bg-slate-200"></span>
                            </div>

                            <div class="grid grid-cols-2 gap-3">
                                <label class="text-xs font-medium text-slate-600">
                                    From
                                    <VueDatePicker
                                        v-model="draftStartDate"
                                        model-type="yyyy-MM-dd"
                                        format="MMM d, yyyy"
                                        placeholder="Any start date"
                                        :enable-time-picker="false"
                                        :auto-apply="true"
                                        :clearable="true"
                                        :max-date="draftEndDate || undefined"
                                        :teleport="true"
                                        :disabled="loadingRange"
                                        input-class-name="!cursor-pointer !rounded-lg !border-slate-300 !py-2 !text-sm focus:!border-blue-700"
                                        menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                                        class="mt-1 w-full"
                                        aria-label="Created date from"
                                    />
                                </label>
                                <label class="text-xs font-medium text-slate-600">
                                    To
                                    <VueDatePicker
                                        v-model="draftEndDate"
                                        model-type="yyyy-MM-dd"
                                        format="MMM d, yyyy"
                                        placeholder="Any end date"
                                        :enable-time-picker="false"
                                        :auto-apply="true"
                                        :clearable="true"
                                        :min-date="draftStartDate || undefined"
                                        :teleport="true"
                                        :disabled="loadingRange"
                                        input-class-name="!cursor-pointer !rounded-lg !border-slate-300 !py-2 !text-sm focus:!border-blue-700"
                                        menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                                        class="mt-1 w-full"
                                        aria-label="Created date to"
                                    />
                                </label>
                            </div>
                            <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3">
                                <button type="button" class="cursor-pointer text-xs font-medium text-slate-500 transition hover:text-slate-800" @click="resetDashboardDateRange">
                                    Reset to preset
                                </button>
                                <button type="button" :disabled="loadingRange || (!draftStartDate && !draftEndDate)" class="cursor-pointer rounded-lg bg-blue-900 px-3.5 py-2 text-xs font-semibold text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50" @click="applyDashboardDateRange">
                                    Apply range
                                </button>
                            </div>
                        </div>
                    </div>


                    <!-- Organization -->

                    <div v-if="['superadmin', 'system_admin', 'system_monitor'].includes(currentUser?.role_name)" class="flex items-center gap-3">

                        <label for="dashboard-organization" class="hidden text-sm font-medium text-slate-600 xl:block">
                            Organization
                        </label>

                        <AppSelect
                            id="dashboard-organization"
                            v-model="selectedOrganization"
                            aria-label="Organization filter"
                            data-tour="dashboard-organization"
                            :disabled="loadingRange"
                            class="max-w-60"
                            :options="[
                                { label: 'All Organizations', value: 'all' },
                                ...(dashboardData?.organizationOptions || []).map(organization => ({ label: organization.name, value: String(organization.id) }))
                            ]"
                            @change="changeDashboardFilter"
                        />

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

                    <CodeLoadingLine label="Loading dashboard..." />

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

                                <template v-if="['superadmin', 'system_admin', 'system_monitor'].includes(currentUser?.role_name)">
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

                    <div data-scroll-reveal class="grid grid-cols-3 gap-2 sm:grid-cols-2 sm:gap-5 lg:grid-cols-3 xl:grid-cols-7">

                        <!-- Total -->

                        <NuxtLink to="/concerns"
                            class="group rounded-xl border border-slate-200 bg-white p-2 shadow-md transition duration-200 hover:-translate-y-0.5 hover:border-slate-400 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-slate-300 sm:p-5">
                            <div class="flex items-start justify-between gap-1 sm:gap-3">
                                <p class="text-[11px] font-semibold leading-tight text-slate-700 sm:text-sm">Total Concerns</p>
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-slate-100 text-slate-700 transition group-hover:bg-slate-200 sm:h-9 sm:w-9 sm:rounded-xl" aria-hidden="true">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3.5 w-3.5 sm:h-5 sm:w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12m-12 5.25h12m-12 5.25h12M3.75 6.75h.008v.008H3.75V6.75Zm0 5.25h.008v.008H3.75V12Zm0 5.25h.008v.008H3.75v-.008Z" />
                                    </svg>
                                </span>
                            </div>

                            <p class="mt-1 text-xl font-bold text-slate-900 sm:mt-2 sm:text-3xl">
                                {{
                                    dashboardData?.summary?.total ?? 0
                                }}
                            </p>

                            <p class="mt-2 hidden text-xs font-medium text-slate-500 transition group-hover:text-slate-700 sm:block">
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
                            class="group rounded-xl border border-yellow-200 bg-yellow-50/60 p-2 shadow-md transition duration-200 hover:-translate-y-0.5 hover:border-yellow-300 hover:bg-yellow-50 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-yellow-200 sm:p-5">
                            <div class="flex items-start justify-between gap-1 sm:gap-3">
                                <p class="text-[11px] font-semibold leading-tight text-yellow-950 sm:text-sm">Pending</p>
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-yellow-100 text-yellow-800 transition group-hover:bg-yellow-200 sm:h-9 sm:w-9 sm:rounded-xl" aria-hidden="true">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3.5 w-3.5 sm:h-5 sm:w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 3.75h9A2.25 2.25 0 0 1 18.75 6v15l-6.75-3.75L5.25 21V6A2.25 2.25 0 0 1 7.5 3.75Z" />
                                    </svg>
                                </span>
                            </div>

                            <p class="mt-1 text-xl font-bold text-yellow-700 sm:mt-2 sm:text-3xl">
                                {{ getStatusTotal('pending') }}
                            </p>

                            <p class="mt-2 hidden text-xs font-medium text-yellow-800 transition group-hover:text-yellow-950 sm:block">
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
                            class="group rounded-xl border border-blue-200 bg-blue-50/60 p-2 shadow-md transition duration-200 hover:-translate-y-0.5 hover:border-blue-300 hover:bg-blue-50 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-blue-200 sm:p-5">
                            <div class="flex items-start justify-between gap-1 sm:gap-3">
                                <p class="text-[11px] font-semibold leading-tight text-blue-900 sm:text-sm">In Progress</p>
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-blue-100 text-blue-700 transition group-hover:bg-blue-200 sm:h-9 sm:w-9 sm:rounded-xl" aria-hidden="true">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3.5 w-3.5 sm:h-5 sm:w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12h3l2.25-6 4.5 12 2.25-6h3" />
                                    </svg>
                                </span>
                            </div>

                            <p class="mt-1 text-xl font-bold text-blue-600 sm:mt-2 sm:text-3xl">
                                {{ getStatusTotal('in_progress') }}
                            </p>

                            <p class="mt-2 hidden text-xs font-medium text-blue-700 transition group-hover:text-blue-900 sm:block">
                                View in-progress concerns
                            </p>
                        </NuxtLink>


                        <!-- On Hold -->

                        <NuxtLink :to="{
                            path: '/concerns',
                            query: {
                                status: 'on_hold'
                            }
                        }"
                            class="group rounded-xl border border-orange-300 bg-orange-100/70 p-2 shadow-md transition duration-200 hover:-translate-y-0.5 hover:border-orange-400 hover:bg-orange-100 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-orange-300 sm:p-5">
                            <div class="flex items-start justify-between gap-1 sm:gap-3">
                                <p class="text-[11px] font-semibold leading-tight text-orange-900 sm:text-sm">On Hold</p>
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-orange-100 text-orange-700 transition group-hover:bg-orange-200 sm:h-9 sm:w-9 sm:rounded-xl" aria-hidden="true">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3.5 w-3.5 sm:h-5 sm:w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75v10.5m7.5-10.5v10.5M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                    </svg>
                                </span>
                            </div>

                            <p class="mt-1 text-xl font-bold text-orange-700 sm:mt-2 sm:text-3xl">
                                {{ getStatusTotal('on_hold') }}
                            </p>

                            <p class="mt-2 hidden text-xs font-medium text-orange-800 transition group-hover:text-orange-950 sm:block">
                                View on-hold concerns
                            </p>
                        </NuxtLink>


                        <!-- Resolved -->

                        <NuxtLink :to="{
                            path: '/concerns',
                            query: {
                                status: 'resolved'
                            }
                        }"
                            class="group rounded-xl border border-emerald-200 bg-emerald-50/60 p-2 shadow-md transition duration-200 hover:-translate-y-0.5 hover:border-emerald-300 hover:bg-emerald-50 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-emerald-200 sm:p-5">
                            <div class="flex items-start justify-between gap-1 sm:gap-3">
                                <p class="text-[11px] font-semibold leading-tight text-emerald-900 sm:text-sm">Resolved</p>
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-emerald-100 text-emerald-700 transition group-hover:bg-emerald-200 sm:h-9 sm:w-9 sm:rounded-xl" aria-hidden="true">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3.5 w-3.5 sm:h-5 sm:w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="m5.25 12.75 4.5 4.5 9-10.5" />
                                    </svg>
                                </span>
                            </div>

                            <p class="mt-1 text-xl font-bold text-green-600 sm:mt-2 sm:text-3xl">
                                {{ getStatusTotal('resolved') }}
                            </p>

                            <p class="mt-2 hidden text-xs font-medium text-emerald-700 transition group-hover:text-emerald-900 sm:block">
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
                            class="group rounded-xl border border-slate-300 bg-slate-50 p-2 shadow-md transition duration-200 hover:-translate-y-0.5 hover:border-slate-400 hover:bg-slate-100 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-slate-300 sm:p-5">
                            <div class="flex items-start justify-between gap-1 sm:gap-3">
                                <p class="text-[11px] font-semibold leading-tight text-slate-800 sm:text-sm">Closed</p>
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-slate-200 text-slate-700 transition group-hover:bg-slate-300 sm:h-9 sm:w-9 sm:rounded-xl" aria-hidden="true">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3.5 w-3.5 sm:h-5 sm:w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 10.5V7.875a4.5 4.5 0 0 1 9 0V10.5m-11.25 0h13.5v10.125H5.25V10.5Z" />
                                    </svg>
                                </span>
                            </div>

                            <p class="mt-1 text-xl font-bold text-slate-600 sm:mt-2 sm:text-3xl">
                                {{ getStatusTotal('closed') }}
                            </p>

                            <p class="mt-2 hidden text-xs font-medium text-slate-600 transition group-hover:text-slate-800 sm:block">
                                View closed concerns
                            </p>
                        </NuxtLink>

                        <!-- Late Response -->

                        <NuxtLink :to="{
                            path: '/concerns',
                            query: {
                                late_response: '1'
                            }
                        }"
                            class="group cursor-pointer rounded-xl border border-rose-300 bg-rose-50 p-2 shadow-md transition duration-200 hover:-translate-y-0.5 hover:border-rose-400 hover:bg-rose-100 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-rose-300 sm:p-5">
                            <div class="flex items-start justify-between gap-1 sm:gap-3">
                                <p class="text-[11px] font-semibold leading-tight text-rose-950 sm:text-sm">
                                    Late Response
                                </p>
                                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-rose-200/70 text-rose-800 transition group-hover:bg-rose-300/70 sm:h-9 sm:w-9 sm:rounded-xl" aria-hidden="true">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3.5 w-3.5 sm:h-5 sm:w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.75v5.25l3.25 1.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                    </svg>
                                </span>
                            </div>

                            <p class="mt-1 text-xl font-bold text-rose-800 sm:mt-2 sm:text-3xl">
                                {{ dashboardData?.summary?.lateResponses ?? 0 }}
                            </p>

                            <p class="mt-2 hidden text-xs font-medium text-rose-700 transition group-hover:text-rose-950 sm:block">
                                View late responses
                            </p>
                        </NuxtLink>


                    </div>



                    <!-- Status + Priority -->

                    <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">

                        <!-- Status -->

                        <div data-scroll-reveal class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

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

                            <div class="mt-6 grid grid-cols-1 gap-2 sm:grid-cols-2">

                                <div class="flex min-w-0 items-center gap-2 rounded-lg bg-slate-50 px-3 py-2">

                                    <span class="h-3 w-3 rounded-full bg-yellow-400"></span>

                                    <span class="text-sm text-slate-600">
                                        Pending
                                    </span>

                                    <span class="ml-auto min-w-9 shrink-0 rounded-md bg-white px-2 py-1 text-right text-sm font-bold text-slate-800">
                                        {{ getStatusTotal('pending') }}
                                    </span>

                                </div>


                                <div class="flex min-w-0 items-center gap-2 rounded-lg bg-slate-50 px-3 py-2">

                                    <span class="h-3 w-3 rounded-full bg-blue-500"></span>

                                    <span class="text-sm text-slate-600">
                                        In Progress
                                    </span>

                                    <span class="ml-auto min-w-9 shrink-0 rounded-md bg-white px-2 py-1 text-right text-sm font-bold text-slate-800">
                                        {{ getStatusTotal('in_progress') }}
                                    </span>

                                </div>


                                <div class="flex min-w-0 items-center gap-2 rounded-lg bg-slate-50 px-3 py-2">

                                    <span class="h-3 w-3 rounded-full bg-orange-400"></span>

                                    <span class="text-sm text-slate-600">
                                        On Hold
                                    </span>

                                    <span class="ml-auto min-w-9 shrink-0 rounded-md bg-white px-2 py-1 text-right text-sm font-bold text-slate-800">
                                        {{ getStatusTotal('on_hold') }}
                                    </span>

                                </div>


                                <div class="flex min-w-0 items-center gap-2 rounded-lg bg-slate-50 px-3 py-2">

                                    <span class="h-3 w-3 rounded-full bg-green-500"></span>

                                    <span class="text-sm text-slate-600">
                                        Resolved
                                    </span>

                                    <span class="ml-auto min-w-9 shrink-0 rounded-md bg-white px-2 py-1 text-right text-sm font-bold text-slate-800">
                                        {{ getStatusTotal('resolved') }}
                                    </span>

                                </div>


                                <div class="flex min-w-0 items-center gap-2 rounded-lg bg-slate-50 px-3 py-2">

                                    <span class="h-3 w-3 rounded-full bg-slate-500"></span>

                                    <span class="text-sm text-slate-600">
                                        Closed
                                    </span>

                                    <span class="ml-auto min-w-9 shrink-0 rounded-md bg-white px-2 py-1 text-right text-sm font-bold text-slate-800">
                                        {{ getStatusTotal('closed') }}
                                    </span>

                                </div>


                            </div>

                        </div>


                        <!-- Priority -->

                        <div data-scroll-reveal class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

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

                    <div data-scroll-reveal class="mt-6 rounded-xl border border-slate-300 bg-white p-6 shadow-md">

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

                        <div data-scroll-reveal class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

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

                        <div data-scroll-reveal class="rounded-xl border border-slate-300 bg-white p-6 shadow-md">

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
