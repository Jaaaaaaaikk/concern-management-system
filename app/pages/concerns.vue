<script setup>

import ViewConcernModal from '~/components/concerns/ViewConcernModal.vue'
import CreateConcernModal from '~/components/concerns/CreateConcernModal.vue'
import AppSelect from '~/components/AppSelect.vue'
import { useToast } from '~/composables/useToast'

definePageMeta({
    middleware: 'auth'
})

let searchTimeout = null

const { showToast } = useToast()

const concerns = ref([])
const concernTypes = ref([])
const organizations = ref([])
const currentUser = useState(
    'current-user',
    () => null
)

const loading = ref(true)
const exporting = ref(false)
const isHeaderSticky = ref(false)

const errorMessage = ref('')

const showModal = ref(false)
const showExportModal = ref(false)

const route = useRoute()
const showFilterPanel = ref(Boolean(
    route.query.status ||
    route.query.late_response
))

const search = ref('')

const statusFilter = ref(
    String(
        route.query.status || ''
    ).trim()
)

const priorityFilter = ref('')

const departmentFilter = ref('')

const exportDateFilter = ref('')

const showViewModal = ref(false)

const selectedConcernId = ref(null)
const trashView = ref(false)

/*
 * PAGINATION
 */

const currentPage = ref(1)

const pageSize = ref(10)

const sortBy = ref('created_at')

const sortDirection = ref('desc')
const lateResponseFilter = ref(String(route.query.late_response || '') === '1')

const statusDropdownValue = computed({
    get: () => lateResponseFilter.value ? 'late_response' : statusFilter.value,
    set: (value) => {
        if (value === 'late_response') {
            statusFilter.value = ''
            lateResponseFilter.value = true
            return
        }

        lateResponseFilter.value = false
        statusFilter.value = value
    }
})

const activeFilterCount = computed(() => [
    statusDropdownValue.value,
    priorityFilter.value,
    departmentFilter.value,
    exportDateFilter.value
].filter(Boolean).length)

const totalConcerns = ref(0)

const totalPages = ref(0)

/*
 * CURRENT TIME / HANDLING DURATION
 */

const currentTime = ref(
    new Date()
)

const RESPONSE_ATTENTION_HOURS = 4

let durationTimer = null

function handlePageScroll() {
    const scrollY = window.scrollY

    if (!isHeaderSticky.value && scrollY > 96) {
        isHeaderSticky.value = true
    } else if (isHeaderSticky.value && scrollY <= 24) {
        isHeaderSticky.value = false
    }
}

/*
 * PAGINATION DISPLAY
 */

const showingFrom = computed(() => {

    if (
        totalConcerns.value === 0
    ) {
        return 0
    }

    return (
        (
            currentPage.value - 1
        ) *
        pageSize.value
    ) + 1
})

const showingTo = computed(() => {

    if (
        totalConcerns.value === 0
    ) {
        return 0
    }

    return Math.min(
        currentPage.value *
        pageSize.value,
        totalConcerns.value
    )
})

const paginationPages = computed(() => {

    const total =
        totalPages.value

    const current =
        currentPage.value

    if (
        total <= 7
    ) {
        return Array.from(
            {
                length: total
            },
            (_, index) =>
                index + 1
        )
    }

    const pages = []

    pages.push(1)

    if (
        current > 4
    ) {
        pages.push('...')
    }

    const start =
        Math.max(
            2,
            current - 1
        )

    const end =
        Math.min(
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

    if (
        current <
        total - 3
    ) {
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

    return (
        labels[status] ||
        status ||
        '-'
    )
}

function formatPriority(priority) {

    const labels = {
        low: 'Low',
        medium: 'Medium',
        high: 'High',
        urgent: 'Urgent'
    }

    return (
        labels[priority] ||
        priority ||
        '-'
    )
}

function statusClass(status) {

    const classes = {
        pending:
            'bg-amber-100 text-amber-700',

        in_progress:
            'bg-blue-100 text-blue-700',

        on_hold:
            'bg-orange-100 text-orange-700',

        resolved:
            'bg-green-100 text-green-700',

        closed:
            'bg-slate-200 text-slate-700'
    }

    return (
        classes[status] ||
        'bg-slate-100 text-slate-600'
    )
}

function priorityClass(priority) {

    const classes = {
        low:
            'bg-slate-100 text-slate-600',

        medium:
            'bg-blue-100 text-blue-700',

        high:
            'bg-orange-100 text-orange-700',

        urgent:
            'bg-red-100 text-red-700'
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

    const date =
        new Date(value)

    if (
        Number.isNaN(
            date.getTime()
        )
    ) {
        return value
    }

    return date.toLocaleString(
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

function formatDateOnly(value) {
    const date = parseDate(value)

    if (!date) {
        return '-'
    }

    return date.toLocaleDateString('en-PH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    })
}

function parseDate(value) {

    if (!value) {
        return null
    }

    if (value instanceof Date) {
        return Number.isNaN(value.getTime())
            ? null
            : new Date(value.getTime())
    }

    const stringValue = String(value).trim()
    const dateOnlyMatch = stringValue.match(/^(\d{4})-(\d{2})-(\d{2})$/)

    if (dateOnlyMatch) {
        const [, year, month, day] = dateOnlyMatch.map(Number)
        const localDate = new Date(year, month - 1, day)

        return localDate.getFullYear() === year &&
            localDate.getMonth() === month - 1 &&
            localDate.getDate() === day
            ? localDate
            : null
    }

    const normalized =
        stringValue.replace(' ', 'T')

    const date =
        new Date(normalized)

    if (
        Number.isNaN(
            date.getTime()
        )
    ) {
        return null
    }

    return date
}

function getScheduledStartFromRemarks(remarks) {
    const match = String(remarks || '').match(
        /(?:commitment start(?: date)?|scheduled start(?: date(?:\/time)?)?|target resolution date):\s*(\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?)?)/i
    )

    return match ? parseDate(match[1]) : null
}

function responseAttentionState(concern) {
    if (
        !concern ||
        concern.deleted_at ||
        trashView.value ||
        concern.status !== 'pending'
    ) {
        return ''
    }

    const createdAt = parseDate(concern.created_at)

    if (!createdAt) {
        return ''
    }

    const responseDeadline = createdAt.getTime() + RESPONSE_ATTENTION_HOURS * 60 * 60 * 1000
    const handlerResponses = [
        parseDate(concern.first_handler_status_response_at),
        parseDate(concern.first_handler_comment_response_at)
    ].filter(Boolean)

    if (handlerResponses.length) {
        const firstResponseAt = Math.min(
            ...handlerResponses.map(response => response.getTime())
        )

        return firstResponseAt > responseDeadline ? 'late' : ''
    }

    return currentTime.value.getTime() > responseDeadline
        ? 'overdue'
        : ''
}

/*
 * Handling duration is accumulated across In Progress periods.
 * Each period starts at its recipient commitment time in target_commitment_at and
 * pauses when the concern leaves In Progress.
 */

function getConcernDuration(
    concern
) {
    if (!concern) {
        return 'Not started'
    }

    const histories = (concern.statusHistory || [])
        .slice()
        .sort((left, right) =>
            new Date(left.created_at) - new Date(right.created_at)
        )
    let elapsedMilliseconds = 0
    let activeSince = null
    const latestInProgressHistory = [...histories]
        .reverse()
        .find((history) => history.new_status === 'in_progress')
    const latestInProgressAt = parseDate(latestInProgressHistory?.created_at)
    const reopenedAfterResolution = Boolean(
        latestInProgressAt && histories.some((history) =>
            history.new_status === 'resolved' &&
            parseDate(history.created_at)?.getTime() < latestInProgressAt.getTime()
        )
    )

    for (const history of histories) {
        const changedAt = parseDate(history.created_at)

        if (!changedAt) {
            continue
        }

        if (history.new_status === 'in_progress') {
            activeSince =
                getScheduledStartFromRemarks(history.remarks) ||
                (
                    history === latestInProgressHistory && !reopenedAfterResolution
                        ? parseDate(concern.target_commitment_at)
                        : null
                ) ||
                changedAt
        } else if (
            ['on_hold', 'resolved', 'closed', 'cancelled'].includes(history.new_status) &&
            activeSince
        ) {
            elapsedMilliseconds += Math.max(
                0,
                changedAt.getTime() - activeSince.getTime()
            )
            activeSince = null
        }
    }

    if (activeSince && concern.status === 'in_progress') {
        elapsedMilliseconds += Math.max(
            0,
            currentTime.value.getTime() - activeSince.getTime()
        )
    }

    if (histories.length === 0 && concern.target_commitment_at) {
        const start = parseDate(concern.target_commitment_at)
        const end = concern.resolved_at
            ? parseDate(concern.resolved_at)
            : concern.status === 'in_progress'
                ? currentTime.value
                : null

        if (start && end) {
            elapsedMilliseconds = Math.max(
                0,
                end.getTime() - start.getTime()
            )
        }
    }

    if (elapsedMilliseconds <= 0) {
        return 'Not started'
    }

    const days = Math.floor(elapsedMilliseconds / 86400000)
    return `${days} day${days === 1 ? '' : 's'}`
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
        labels[
        exportDateFilter.value
        ] ||
        'All Dates'
    )
}

/*
 * ALERT MESSAGES
 */

function showSuccessMessage(
    message
) {
    showToast(message)
}

function showErrorMessage(
    message
) {

    errorMessage.value =
        message

    showToast(
        message,
        'error'
    )
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

function viewConcern(
    concern
) {

    errorMessage.value = ''

    selectedConcernId.value =
        concern.id

    showViewModal.value = true
}

function handleConcernRowKeydown(
    event,
    concern
) {

    if (
        event.key === 'Enter' ||
        event.key === ' '
    ) {

        event.preventDefault()

        viewConcern(
            concern
        )
    }
}

function closeViewModal() {

    showViewModal.value = false

    selectedConcernId.value =
        null
}

/*
 * DATA
 */

async function loadCurrentUser() {

    const response =
        await $fetch(
            '/api/auth/me',
            {
                cache: 'no-store'
            }
        )

    currentUser.value =
        response.user
}

async function loadConcerns() {

    const response =
        await $fetch(
            '/api/concerns',
            {
                cache: 'no-store',

                query: {
                    page:
                        currentPage.value,

                    limit:
                        pageSize.value,

                    search:
                        search.value.trim(),

                    status:
                        statusFilter.value,

                    priority:
                        priorityFilter.value,

                    department:
                        departmentFilter.value,

                    date:
                        exportDateFilter.value,

                    view:
                        trashView.value ? 'trash' : 'active',

                    late_response:
                        lateResponseFilter.value ? '1' : '',

                    sortBy:
                        sortBy.value,

                    sortDirection:
                        sortDirection.value
                }
            }
        )

    concerns.value =
        response.concerns || []

    totalConcerns.value =
        Number(
            response.pagination?.total ||
            0
        )

    totalPages.value =
        Number(
            response.pagination?.totalPages ||
            0
        )

    currentPage.value =
        Number(
            response.pagination?.page ||
            currentPage.value
        )
}

async function toggleTrashView() {
    trashView.value = !trashView.value
    currentPage.value = 1
    await loadConcernsWithLoading()
}

async function changeSort(column) {
    if (sortBy.value === column) {
        sortDirection.value = sortDirection.value === 'asc'
            ? 'desc'
            : 'asc'
    } else {
        sortBy.value = column
        sortDirection.value = 'asc'
    }

    currentPage.value = 1
    await loadConcernsWithLoading()
}

function sortIndicator(column) {
    if (sortBy.value !== column) {
        return '↕'
    }

    return sortDirection.value === 'asc'
        ? '↑'
        : '↓'
}

/*
 * EXPORT TO EXCEL
 */

function openExportModal() {

    if (
        exporting.value
    ) {
        return
    }

    errorMessage.value = ''

    showExportModal.value =
        true
}

function closeExportModal() {

    if (
        exporting.value
    ) {
        return
    }

    showExportModal.value =
        false
}

async function confirmExport() {

    if (
        exporting.value
    ) {
        return
    }

    exporting.value = true

    errorMessage.value = ''

    try {

        const query =
            new URLSearchParams()

        const trimmedSearch =
            search.value.trim()

        if (
            trimmedSearch
        ) {

            query.set(
                'search',
                trimmedSearch
            )
        }

        if (
            statusFilter.value
        ) {

            query.set(
                'status',
                statusFilter.value
            )
        }

        if (
            priorityFilter.value
        ) {

            query.set(
                'priority',
                priorityFilter.value
            )
        }

        if (
            departmentFilter.value
        ) {

            query.set(
                'department',
                departmentFilter.value
            )
        }

        if (
            exportDateFilter.value
        ) {

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

        const response =
            await $fetch(
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
                        type:
                            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                    }
                )

        const fileName =
            `concerns-report-${new Date().toISOString().slice(0, 10)}.xlsx`

        /*
         * Use Save As when available.
         */

        if (
            'showSaveFilePicker' in
            window
        ) {

            const fileHandle =
                await window.showSaveFilePicker(
                    {
                        suggestedName:
                            fileName,

                        types: [
                            {
                                description:
                                    'Excel Workbook',

                                accept: {
                                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
                                        [
                                            '.xlsx'
                                        ]
                                }
                            }
                        ]
                    }
                )

            const writable =
                await fileHandle.createWritable()

            await writable.write(
                blob
            )

            await writable.close()

            showToast(
                'Excel report saved successfully.',
                'success'
            )

            showExportModal.value =
                false

            return
        }

        /*
         * Browser fallback.
         */

        const url =
            window.URL.createObjectURL(
                blob
            )

        const link =
            document.createElement(
                'a'
            )

        link.href = url

        link.download =
            fileName

        document.body.appendChild(
            link
        )

        link.click()

        link.remove()

        window.URL.revokeObjectURL(
            url
        )

        showToast(
            'Excel report download started successfully.',
            'success'
        )

        showExportModal.value =
            false

    } catch (error) {

        /*
         * User cancelled Save As.
         */

        if (
            error?.name ===
            'AbortError'
        ) {
            return
        }

        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            error?.message ||
            'Failed to export concern report.'
        )

    } finally {

        exporting.value =
            false
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

    if (
        searchTimeout
    ) {

        clearTimeout(
            searchTimeout
        )
    }

    searchTimeout =
        setTimeout(
            () => {
                refreshFilteredConcerns()
            },
            300
        )
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

async function handleDepartmentChange() {

    currentPage.value = 1

    await loadConcernsWithLoading()
}

async function clearLateResponseFilter() {
    lateResponseFilter.value = false
    currentPage.value = 1
    await navigateTo({
        path: '/concerns',
        query: {}
    })
    await loadConcernsWithLoading()
}

async function clearAllFilters() {
    statusDropdownValue.value = ''
    priorityFilter.value = ''
    departmentFilter.value = ''
    exportDateFilter.value = ''
    currentPage.value = 1
    await navigateTo({
        path: '/concerns',
        query: {}
    })
    await loadConcernsWithLoading()
}

/*
 * PAGINATION
 */

async function goToPage(
    page
) {

    if (
        page === '...' ||
        page ===
        currentPage.value ||
        page < 1 ||
        page >
        totalPages.value
    ) {
        return
    }

    currentPage.value =
        page

    await loadConcernsWithLoading()
}

async function goToPreviousPage() {

    if (
        currentPage.value <= 1
    ) {
        return
    }

    currentPage.value -= 1

    await loadConcernsWithLoading()
}

async function goToNextPage() {

    if (
        currentPage.value >=
        totalPages.value
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

    const response =
        await $fetch(
            '/api/concern-types',
            {
                cache: 'no-store'
            }
        )

    concernTypes.value =
        response.concernTypes || []
}

async function loadOrganizations() {

    const response =
        await $fetch(
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

let handlingGuideCreateAction = false

async function handleGuideCreateAction() {
    if (route.query.guideAction !== 'create' || handlingGuideCreateAction) {
        return
    }

    handlingGuideCreateAction = true

    try {
        if (!currentUser.value) {
            await loadCurrentUser()
        }

        if (['concern_handler', 'requestor'].includes(currentUser.value?.role_name)) {
            showModal.value = true
        }

        const query = { ...route.query }
        delete query.guideAction
        await navigateTo({ path: route.path, query }, { replace: true })
    } finally {
        handlingGuideCreateAction = false
    }
}

watch(
    () => route.query.guideAction,
    (action) => {
        if (action === 'create') {
            handleGuideCreateAction()
        }
    }
)

/*
 * LOGOUT
 */

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
        // Continue to login.
    }

    await navigateTo('/login')
}

function updateProfilePhoto(
    profilePhoto
) {

    if (
        currentUser.value
    ) {

        currentUser.value.profile_photo =
            profilePhoto
    }
}

/*
 * LIFECYCLE
 */

onMounted(() => {

    window.addEventListener('scroll', handlePageScroll, { passive: true })

    if (route.query.guideAction === 'create') {
        loadData().then(handleGuideCreateAction)
    } else {
        loadData()
    }

    durationTimer =
        setInterval(
            () => {

                currentTime.value =
                    new Date()

            },
            60000
        )
})

onUnmounted(() => {

    window.removeEventListener('scroll', handlePageScroll)

    if (
        durationTimer
    ) {

        clearInterval(
            durationTimer
        )
    }

    if (
        searchTimeout
    ) {

        clearTimeout(
            searchTimeout
        )
    }
})

</script>

<template>

    <div class="min-h-screen bg-slate-100">

        <MobileNavigation :current-user="currentUser" @logout="logout" @profile-updated="updateProfilePhoto" />

        <!-- Sidebar -->

        <aside class="fixed inset-y-0 left-0 z-40 hidden h-screen w-64 flex-col bg-blue-950 text-white lg:flex">

            <div class="px-6 py-5">

                <h1 class="text-lg font-bold">
                    Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>

            </div>

            <nav class="sidebar-navigation flex-1 space-y-1 px-3 py-4">

                <NuxtLink to="/dashboard" :class="$route.path === '/dashboard'
                    ? 'bg-blue-800 text-white'
                    : 'text-blue-100/80 transition hover:bg-white hover:text-black'
                    " class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">

                    <NavIcon name="dashboard" />

                    <span>
                        Dashboard
                    </span>

                </NuxtLink>

                <NuxtLink v-if="
                    ['superadmin', 'system_admin'].includes(currentUser?.role_name)
                " to="/users" :class="$route.path === '/users'
                    ? 'bg-blue-800 text-white'
                    : 'text-blue-100/80 transition hover:bg-white hover:text-black'
                    " class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">

                    <NavIcon name="users" />

                    <span>
                        Manage Users
                    </span>

                </NuxtLink>


                <NuxtLink v-if="
                    ['superadmin', 'system_admin'].includes(currentUser?.role_name)
                " to="/organizations" :class="$route.path === '/organizations'
                    ? 'bg-blue-800 text-white'
                    : 'text-blue-100/80 transition hover:bg-white hover:text-black'
                    " class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">

                    <NavIcon name="organizations" />

                    <span>
                        Manage Organizations
                    </span>

                </NuxtLink>

                <NuxtLink to="/concerns" :class="$route.path === '/concerns'
                    ? 'bg-blue-800 text-white'
                    : 'text-blue-100/80 transition hover:bg-white hover:text-black'
                    " class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">

                    <NavIcon name="concerns" />

                    <span>
                        Manage Concerns
                    </span>

                </NuxtLink>
                
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/concern-categories" :class="$route.path === '/concern-categories'
                    ? 'bg-blue-800 text-white'
                    : 'text-blue-100/80 transition hover:bg-white hover:text-black'
                    " class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">

                    <NavIcon name="categories" />

                    <span>
                        Concern Categories
                    </span>

                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/login-history" :class="$route.path === '/login-history'
                    ? 'bg-blue-800 text-white'
                    : 'text-blue-100/80 transition hover:bg-white hover:text-black'
                    " class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium">

                    <NavIcon name="history" />

                    <span>
                        Login History
                    </span>

                </NuxtLink>

            </nav>

            <div class="p-4">

                <UserProfileControl :current-user="currentUser" @logout="logout"
                    @profile-updated="updateProfilePhoto" />

            </div>

        </aside>

        <!-- Main Content -->

        <main class="flex min-h-screen flex-col lg:ml-64">

            <!-- Header -->

            <div :class="[
                'w-full transition-[transform,opacity,background-color,box-shadow] duration-300 ease-out',
                isHeaderSticky
                    ? 'lg:sticky lg:top-0 lg:z-30 lg:-translate-y-1 lg:bg-white/30 lg:shadow-md lg:backdrop-blur-md'
                    : 'translate-y-0'
            ]">

                <div :class="[
                    'mx-auto flex w-full max-w-[1600px] flex-col gap-4 px-4 transition-[padding] duration-300 sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8',
                    isHeaderSticky ? 'py-6 sm:py-8 lg:py-3' : 'py-6 sm:py-8'
                ]">

                    <div class="flex min-w-0 items-start justify-between gap-3">
                        <div class="min-w-0">
                        <h2 class="text-xl font-semibold text-slate-900">
                            Concerns
                        </h2>

                        <p class="mt-1 text-sm text-slate-500">
                            View and manage concerns.
                        </p>
                        </div>
                        <button v-if="['superadmin', 'system_admin', 'concern_handler', 'requestor'].includes(currentUser?.role_name)" type="button"
                            @click="toggleTrashView"
                            class="secondary-hover-button inline-flex shrink-0 cursor-pointer items-center justify-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-50 sm:px-4 sm:py-2.5 sm:text-sm lg:hidden">
                            <span aria-hidden="true">{{ trashView ? '←' : '▱' }}</span>
                            {{ trashView ? 'Back to Concerns' : 'View Trash' }}
                        </button>
                    </div>

                    <div class="flex flex-col gap-2 sm:flex-row">
                        <button v-if="['superadmin', 'system_admin', 'concern_handler', 'requestor'].includes(currentUser?.role_name)" type="button"
                            @click="toggleTrashView"
                            class="secondary-hover-button hidden shrink-0 cursor-pointer items-center justify-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-50 sm:px-4 sm:py-2.5 sm:text-sm lg:inline-flex">
                            <span aria-hidden="true">{{ trashView ? '←' : '▱' }}</span>
                            {{ trashView ? 'Back to Concerns' : 'View Trash' }}
                        </button>
                        <button v-if="!trashView && ['concern_handler', 'requestor'].includes(currentUser?.role_name)" type="button"
                            @click="openCreateModal"
                            data-tour="create-concern"
                            class="primary-action-button inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg bg-linear-to-r from-emerald-600 to-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-md shadow-emerald-950/15 transition-all duration-200 ease-out hover:-translate-y-0.5 hover:scale-[1.03] hover:from-emerald-700 hover:to-teal-700 hover:shadow-lg hover:shadow-emerald-950/25 active:translate-y-0 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-emerald-200 motion-reduce:transition-none">
                            <span class="text-lg leading-none">+</span>
                            Create Concern
                        </button>
                    </div>

                </div>

            </div>

            <div class="mx-auto w-full max-w-[1600px] px-4 pt-1 pb-6 sm:px-6 sm:pt-2 sm:pb-8">

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

                <!-- Search and quick actions -->
                <div class="mb-4 flex flex-row items-center gap-2 sm:gap-3">
                    <div class="relative min-w-0 flex-1">
                        <label for="concern-search" class="sr-only">Search concerns</label>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="pointer-events-none absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" aria-hidden="true">
                            <circle cx="10.8" cy="10.8" r="6.8" />
                            <path stroke-linecap="round" d="m16 16 4.2 4.2" />
                        </svg>
                        <input
                            id="concern-search"
                            data-tour="concern-search"
                            v-model="search"
                            @input="handleSearchInput"
                            type="search"
                            placeholder="Search concern number, title, or description..."
                            class="w-full rounded-xl border border-slate-300 bg-white py-3 pl-10 pr-2 text-xs outline-none shadow-sm transition placeholder:text-slate-400 focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15 sm:pl-11 sm:pr-4 sm:text-sm"
                        />
                    </div>

                    <div class="flex shrink-0 items-center gap-1.5 sm:gap-2">
                        <button
                            type="button"
                            data-tour="concern-filters"
                            :aria-expanded="showFilterPanel"
                            aria-controls="concern-filter-panel"
                            class="secondary-hover-button inline-flex h-11 w-11 cursor-pointer items-center justify-center gap-2 rounded-xl border px-2 py-2 text-sm font-semibold shadow-sm transition focus:outline-none focus:ring-2 focus:ring-blue-700/20 sm:h-auto sm:w-auto sm:px-4 sm:py-3"
                            :class="showFilterPanel || activeFilterCount
                                ? 'border-blue-300 bg-blue-50 text-blue-900 hover:bg-blue-100'
                                : 'border-slate-300 bg-white text-slate-700 hover:bg-slate-50'"
                            @click="showFilterPanel = !showFilterPanel"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M7 12h10m-7 6h4" />
                            </svg>
                            <span class="sr-only sm:not-sr-only">Filters</span>
                            <span v-if="activeFilterCount" class="flex h-5 min-w-5 items-center justify-center rounded-full bg-blue-900 px-1 text-[10px] font-bold text-white">{{ activeFilterCount }}</span>
                        </button>

                        <button
                            type="button"
                            @click="openExportModal"
                            :disabled="exporting"
                            class="secondary-hover-button inline-flex h-11 w-11 cursor-pointer items-center justify-center gap-2 rounded-xl border border-blue-200 bg-blue-50 px-2 py-2 text-sm font-semibold text-blue-900 shadow-sm transition hover:border-blue-300 hover:bg-blue-100 focus:outline-none focus:ring-2 focus:ring-blue-700/20 disabled:cursor-not-allowed disabled:opacity-50 sm:h-auto sm:w-auto sm:px-4 sm:py-3"
                        >
                            <svg v-if="!exporting" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v12m0 0 4-4m-4 4-4-4M5 21h14" />
                            </svg>
                            <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5 animate-spin" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3a9 9 0 1 0 9 9" />
                            </svg>
                            <span class="sr-only sm:not-sr-only">{{ exporting ? 'Exporting…' : 'Export' }}</span>
                        </button>
                    </div>
                </div>

                <Transition
                    enter-active-class="transition duration-200 ease-out"
                    enter-from-class="-translate-y-1 opacity-0"
                    enter-to-class="translate-y-0 opacity-100"
                    leave-active-class="transition duration-150 ease-in"
                    leave-from-class="translate-y-0 opacity-100"
                    leave-to-class="-translate-y-1 opacity-0"
                >
                    <section v-if="showFilterPanel" id="concern-filter-panel" class="mb-6 rounded-xl border border-slate-200 bg-white p-4 shadow-sm sm:p-5">
                        <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
                            <div>
                                <h3 class="text-sm font-semibold text-slate-900">Filter concerns</h3>
                                <p class="mt-0.5 text-xs text-slate-500">Choose one or more filters to narrow the list.</p>
                            </div>
                            <button v-if="activeFilterCount" type="button" class="secondary-hover-button cursor-pointer rounded-lg px-3 py-2 text-xs font-semibold text-blue-800 transition hover:bg-blue-50" @click="clearAllFilters">
                                Clear filters
                            </button>
                        </div>

                        <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                            <label class="block rounded-xl border border-slate-200 bg-slate-50/70 p-3">
                                <span class="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500">Status</span>
                                <AppSelect
                                    v-model="statusDropdownValue"
                                    aria-label="Filter by status"
                                    placeholder="All statuses"
                                    :options="[
                                        { label: 'All statuses', value: '' },
                                        { label: 'Pending', value: 'pending' },
                                        { label: 'In Progress', value: 'in_progress' },
                                        { label: 'On Hold', value: 'on_hold' },
                                        { label: 'Resolved', value: 'resolved' },
                                        { label: 'Closed', value: 'closed' },
                                        { label: 'Late Response', value: 'late_response' }
                                    ]"
                                    @change="handleStatusChange"
                                />
                            </label>

                            <label class="block rounded-xl border border-slate-200 bg-slate-50/70 p-3">
                                <span class="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500">Priority</span>
                                <AppSelect
                                    v-model="priorityFilter"
                                    aria-label="Filter by priority"
                                    placeholder="All priorities"
                                    :options="[
                                        { label: 'All priorities', value: '' },
                                        { label: 'Low', value: 'low' },
                                        { label: 'Medium', value: 'medium' },
                                        { label: 'High', value: 'high' },
                                        { label: 'Urgent', value: 'urgent' }
                                    ]"
                                    @change="handlePriorityChange"
                                />
                            </label>

                            <label class="block rounded-xl border border-slate-200 bg-slate-50/70 p-3">
                                <span class="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500">Department</span>
                                <AppSelect
                                    v-model="departmentFilter"
                                    aria-label="Filter by department"
                                    placeholder="All departments"
                                    :options="[
                                        { label: 'All departments', value: '' },
                                        ...organizations.map(organization => ({ label: organization.name, value: String(organization.id) }))
                                    ]"
                                    @change="handleDepartmentChange"
                                />
                            </label>

                            <label class="block rounded-xl border border-slate-200 bg-slate-50/70 p-3">
                                <span class="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500">Date created</span>
                                <AppSelect
                                    v-model="exportDateFilter"
                                    aria-label="Filter by date created"
                                    placeholder="All dates"
                                    :options="[
                                        { label: 'All dates', value: '' },
                                        { label: 'Today', value: 'today' },
                                        { label: 'This week', value: 'week' },
                                        { label: 'This month', value: 'month' },
                                        { label: 'This year', value: 'year' }
                                    ]"
                                    @change="handleExportDateChange"
                                />
                            </label>
                        </div>
                    </section>
                </Transition>

                <!-- Concerns Table -->

                <div v-if="lateResponseFilter && !trashView" class="mb-4 flex flex-col gap-3 rounded-xl border border-rose-300 bg-rose-50 px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-start gap-3">
                        <span class="mt-0.5 text-rose-700" aria-hidden="true">⏱</span>
                        <div>
                            <p class="text-sm font-semibold text-amber-950">Late response concerns</p>
                            <p class="mt-0.5 text-xs leading-5 text-amber-900">Pending concerns with no response from the assigned organization within four hours.</p>
                        </div>
                    </div>
                    <button type="button" class="secondary-hover-button cursor-pointer self-start rounded-lg border border-rose bg-white px-3 py-2 text-xs font-semibold text-amber-900 transition hover:bg-rose-100 sm:self-auto" @click="clearLateResponseFilter">Clear filter</button>
                </div>

                <div data-tour="concern-list" class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">

                    <!-- Table Header -->

                    <div class="border-b border-slate-200 px-5 py-4">

                        <h3 class="text-base font-semibold text-slate-800">
                            {{ trashView ? 'Trashed Concerns' : 'Concern List' }}
                        </h3>

                        <div v-if="loading" class="mt-2">
                            <CodeLoadingLine label="Loading concerns..." />
                        </div>

                        <p v-else class="mt-1 text-xs text-slate-500">

                            <template v-if="totalConcerns > 0">

                                Showing
                                {{ showingFrom }}–{{ showingTo }}
                                of
                                {{ totalConcerns }}
                                concern{{
                                    totalConcerns === 1
                                        ? ''
                                        : 's'
                                }}

                            </template>

                            <template v-else>
                                No concerns
                            </template>

                        </p>

                    </div>

                    <!-- Desktop Loading -->

                    <div v-if="loading" class="hidden lg:block">

                        <div class="grid grid-cols-6 gap-6 border-b border-slate-200 bg-slate-50 px-5 py-3">

                            <CodeSkeleton v-for="column in 6" :key="column" :length="6" class="h-3 w-full rounded" />

                        </div>

                        <div v-for="row in 5" :key="row"
                            class="grid grid-cols-6 gap-6 border-b border-slate-100 px-5 py-5">

                            <div class="col-span-2 space-y-2">

                                <CodeSkeleton :length="7" class="h-4 w-24 rounded" />

                                <CodeSkeleton :length="10" class="h-3 w-36 rounded" />

                            </div>

                            <CodeSkeleton :length="10" class="h-4 rounded" />

                            <CodeSkeleton :length="5" class="h-6 w-16 rounded-full" />

                            <CodeSkeleton :length="6" class="h-6 w-20 rounded-full" />

                            <CodeSkeleton :length="7" class="h-4 w-24 rounded" />

                        </div>

                    </div>

                    <!-- Mobile Loading -->

                    <div v-if="loading" class="space-y-3 p-4 lg:hidden">

                        <div v-for="row in 4" :key="row" class="rounded-xl border border-slate-200 p-4">

                            <CodeSkeleton :length="8" class="h-4 w-28 rounded" />

                            <CodeSkeleton :length="12" class="mt-3 h-4 w-3/4 rounded" />

                            <CodeSkeleton :length="9" class="mt-4 h-3 w-1/2 rounded" />

                        </div>

                    </div>

                    <!-- Empty -->

                    <div v-else-if="concerns.length === 0" class="px-5 py-12 text-center">

                        <p class="text-sm font-medium text-slate-600">
                            No concerns found.
                        </p>

                        <p class="mt-1 text-xs text-slate-400">
                            {{ trashView ? 'There are no concerns in trash.' : 'Try changing your search or filters.' }}
                        </p>

                    </div>

                    <template v-else>

                        <!-- Desktop Table -->

                        <div class="hidden lg:block">

                            <table class="w-full table-fixed text-left">

                                <colgroup>

                                    <col class="w-[29%]" />
                                    <col class="w-[17%]" />
                                    <col class="w-[16%]" />
                                    <col class="w-[10%]" />
                                    <col class="w-[12%]" />
                                    <col class="w-[16%]" />

                                </colgroup>

                                <thead class="bg-slate-50">

                                    <tr class="border-b border-slate-200">

                                        <th
                                            class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            <button type="button" @click="changeSort('title')"
                                                class="inline-flex cursor-pointer items-center gap-1.5 transition hover:text-blue-800"
                                                :aria-label="`Sort by concern title ${sortDirection === 'asc' ? 'descending' : 'ascending'}`">
                                                Concern
                                                <span class="text-sm" aria-hidden="true">{{ sortIndicator('title')
                                                }}</span>
                                            </button>
                                        </th>

                                        <th class="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            <button type="button" @click="changeSort('created_by')"
                                                class="inline-flex cursor-pointer items-center gap-1.5 transition hover:text-blue-800">
                                                Created By
                                                <span class="text-sm" aria-hidden="true">{{ sortIndicator('created_by')
                                                }}</span>
                                            </button>
                                        </th>

                                        <th
                                            class="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            <button type="button" @click="changeSort('assigned_to')"
                                                class="inline-flex cursor-pointer items-center gap-1.5 transition hover:text-blue-800">
                                                Assigned To
                                                <span class="text-sm" aria-hidden="true">{{ sortIndicator('assigned_to')
                                                }}</span>
                                            </button>
                                        </th>

                                        <th
                                            class="px-3 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            <button type="button" @click="changeSort('priority')"
                                                class="inline-flex cursor-pointer items-center gap-1.5 transition hover:text-blue-800">
                                                Priority
                                                <span class="text-sm" aria-hidden="true">{{ sortIndicator('priority')
                                                }}</span>
                                            </button>
                                        </th>

                                        <th
                                            class="px-3 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            <button type="button" @click="changeSort('status')"
                                                class="inline-flex cursor-pointer items-center gap-1.5 transition hover:text-blue-800">
                                                Status
                                                <span class="text-sm" aria-hidden="true">{{ sortIndicator('status')
                                                }}</span>
                                            </button>
                                        </th>

                                        <th
                                            class="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            <button type="button" @click="changeSort('target_commitment_at')"
                                                class="inline-flex cursor-pointer items-center gap-1.5 transition hover:text-blue-800">
                                                Committed Start
                                                <span class="text-sm" aria-hidden="true">{{
                                                    sortIndicator('target_commitment_at') }}</span>
                                            </button>
                                        </th>

                                    </tr>

                                </thead>

                                <tbody class="divide-y divide-slate-200">

                                        <tr v-for="(concern, index) in concerns" :key="concern.id" data-tour="concern-row" role="button"
                                        tabindex="0" @click="viewConcern(concern)"
                                        @keydown="handleConcernRowKeydown($event, concern)" :class="index % 2 === 0
                                            ? (responseAttentionState(concern) ? 'bg-rose-50 hover:bg-rose-100/80' : 'bg-white hover:bg-blue-50/50')
                                            : (responseAttentionState(concern) ? 'bg-rose-50/70 hover:bg-rose-100/80' : 'bg-slate-50 hover:bg-blue-50/70')
                                            "
                                        class="cursor-pointer transition focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-700">

                                        <!-- Concern -->

                                        <td class="px-5 py-4">

                                            <p class="text-xs font-semibold text-blue-800">
                                                {{
                                                    concern.concern_number
                                                }}
                                            </p>

                                            <span
                                                v-if="responseAttentionState(concern)"
                                                class="mt-1 inline-flex items-center gap-1 rounded-full border px-2 py-1 text-[10px] font-bold"
                                                :class="responseAttentionState(concern) === 'overdue'
                                                    ? 'border-rose-300 bg-rose-100 text-rose-900'
                                                    : 'border-rose-300 bg-rose-100 text-rose-900'"
                                                :title="responseAttentionState(concern) === 'overdue'
                                                    ? 'The assigned organization has not responded within 4 hours.'
                                                    : 'The assigned organization’s first response came after the 4-hour target.'"
                                            >
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-3 w-3" aria-hidden="true">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.75v5.25l3.25 1.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                                </svg>
                                                {{ responseAttentionState(concern) === 'overdue' ? 'Needs attention · No response in 4h' : 'Late response · over 4h' }}
                                            </span>

                                            <p class="mt-1 truncate text-sm font-semibold text-slate-800"
                                                :title="concern.title">
                                                {{
                                                    concern.title
                                                }}
                                            </p>

                                            <p class="mt-1 text-[10px] font-semibold text-blue-700/70">
                                                Click row to view details <span aria-hidden="true">→</span>
                                            </p>

                                            <p class="mt-1 truncate text-xs text-slate-500"
                                                :title="concern.description">
                                                {{
                                                    concern.description ||
                                                    '-'
                                                }}
                                            </p>

                                        </td>

                                        <!-- Created By -->

                                        <td class="px-4 py-4">
                                            <p class="truncate text-sm font-medium text-slate-700" :title="concern.created_by_name || '-'">
                                                {{ concern.created_by_name || '-' }}
                                            </p>
                                            <p v-if="concern.creator_organization_name" class="mt-1 truncate text-xs text-slate-500" :title="concern.creator_organization_name">
                                                {{ concern.creator_organization_name }}
                                            </p>
                                        </td>

                                        <!-- Assigned To -->

                                        <td class="px-4 py-4">

                                            <p class="truncate text-sm font-medium text-slate-700" :title="concern.organization_name ||
                                                '-'
                                                ">
                                                {{
                                                    concern.organization_name ||
                                                    '-'
                                                }}
                                            </p>

                                        </td>

                                        <!-- Priority -->

                                        <td class="px-3 py-4">

                                            <span
                                                class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                                                :class="priorityClass(
                                                    concern.priority
                                                )
                                                    ">

                                                {{
                                                    formatPriority(
                                                        concern.priority
                                                    )
                                                }}

                                            </span>

                                        </td>

                                        <!-- Status -->

                                        <td class="px-3 py-4">

                                            <span
                                                class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium"
                                                :class="statusClass(
                                                    concern.status
                                                )
                                                    ">

                                                {{
                                                    formatStatus(
                                                        concern.status
                                                    )
                                                }}

                                            </span>

                                        </td>

                                        <!-- Target Commitment -->

                                        <td class="px-4 py-4">

                                            <p class="text-sm font-semibold text-slate-800">

                                                {{
                                                    formatDateOnly(
                                                        concern.target_commitment_at
                                                    )
                                                }}

                                            </p>

                                            <p class="mt-1 text-xs text-slate-500">

                                                <span class="font-medium text-slate-600">
                                                    Duration:
                                                </span>

                                                {{
                                                    getConcernDuration(
                                                        concern
                                                    )
                                                }}

                                            </p>

                                            <p class="mt-1 text-xs text-slate-400">

                                                Created
                                                {{
                                                    formatDate(
                                                        concern.created_at
                                                    )
                                                }}

                                            </p>

                                        </td>

                                    </tr>

                                </tbody>

                            </table>

                        </div>

                        <!-- Mobile Cards -->

                        <div class="space-y-3 p-3 lg:hidden">

                            <article v-for="(concern, index) in concerns" :key="concern.id" data-tour="concern-row" role="button" tabindex="0"
                                @click="viewConcern(concern)" @keydown="handleConcernRowKeydown($event, concern)"
                                :class="responseAttentionState(concern)
                                    ? 'border-rose-300 bg-rose-50 hover:border-rose-400 hover:bg-rose-100'
                                    : index % 2 === 0
                                        ? 'border-slate-200 bg-white hover:border-blue-300 hover:bg-blue-50/30'
                                        : 'border-slate-200 bg-slate-50 hover:border-blue-300 hover:bg-blue-50/70'"
                                class="cursor-pointer rounded-xl border p-4 transition focus:outline-none focus:ring-2 focus:ring-blue-700">

                                <div class="flex items-start justify-between gap-3">

                                    <div class="min-w-0">

                                        <p class="text-xs font-semibold text-blue-800">
                                            {{
                                                concern.concern_number
                                            }}
                                        </p>

                                        <h4 class="mt-1 break-words text-sm font-semibold text-slate-900">
                                            {{
                                                concern.title
                                            }}
                                        </h4>

                                    </div>

                                    <div class="flex shrink-0 flex-col items-end gap-1">
                                    <span class="rounded-full px-2.5 py-1 text-xs font-medium" :class="statusClass(
                                        concern.status
                                    )
                                        ">
                                        {{
                                            formatStatus(
                                                concern.status
                                            )
                                        }}
                                    </span>
                                    <span
                                        v-if="responseAttentionState(concern)"
                                        class="inline-flex items-center gap-1 rounded-full border px-2 py-1 text-[10px] font-bold"
                                        :class="responseAttentionState(concern) === 'overdue'
                                            ? 'border-rose-300 bg-rose-100 text-rose-900'
                                            : 'border-rose-300 bg-rose-100 text-rose-900'"
                                    >
                                        <span aria-hidden="true">⏱</span>
                                        {{ responseAttentionState(concern) === 'overdue' ? 'Needs attention' : 'Late response' }}
                                    </span>
                                    </div>

                                </div>

                                <p class="mt-2 line-clamp-2 text-xs leading-5 text-slate-500">
                                    {{
                                        concern.description ||
                                        'No description'
                                    }}
                                </p>

                                <p class="mt-2 text-[11px] font-semibold text-blue-800">
                                    Tap card to view concern <span aria-hidden="true">→</span>
                                </p>

                                <div class="mt-3 flex flex-wrap items-center gap-2">

                                    <span class="rounded-full px-2.5 py-1 text-xs font-medium" :class="priorityClass(
                                        concern.priority
                                    )
                                        ">
                                        {{
                                            formatPriority(
                                                concern.priority
                                            )
                                        }}
                                    </span>

                                    <span class="text-xs text-slate-500">
                                        {{
                                            formatDate(
                                                concern.created_at
                                            )
                                        }}
                                    </span>

                                </div>

                                <div
                                    class="mt-3 grid grid-cols-2 gap-x-3 gap-y-3 border-t border-slate-100 pt-3 text-xs">

                                    <!-- Created By -->

                                    <div class="min-w-0">

                                        <p class="text-slate-400">
                                            Created By
                                        </p>

                                        <p class="mt-0.5 truncate font-medium text-slate-700">
                                            {{
                                                concern.created_by_name ||
                                                '-'
                                            }}
                                        </p>

                                    </div>

                                    <!-- Assigned To -->

                                    <div class="min-w-0">

                                        <p class="text-slate-400">
                                            Assigned To
                                        </p>

                                        <p class="mt-0.5 truncate font-medium text-slate-700" :title="concern.organization_name ||
                                            '-'
                                            ">
                                            {{
                                                concern.organization_name ||
                                                '-'
                                            }}
                                        </p>

                                    </div>

                                    <!-- Type -->

                                    <div class="min-w-0">

                                        <p class="text-slate-400">
                                            Type
                                        </p>

                                        <p class="mt-0.5 truncate font-medium text-slate-700">
                                            {{
                                                concern.concern_type_name ||
                                                '-'
                                            }}
                                        </p>

                                    </div>

                                    <!-- Target Commitment -->

                                    <div class="min-w-0">

                                        <p class="text-slate-400">
                                            Committed Start
                                        </p>

                                        <p class="mt-0.5 font-medium text-slate-700">
                                            {{
                                                formatDateOnly(
                                                    concern.target_commitment_at
                                                )
                                            }}
                                        </p>

                                    </div>

                                    <!-- Duration -->

                                    <div class="min-w-0">

                                        <p class="text-slate-400">
                                            Duration
                                        </p>

                                        <p class="mt-0.5 font-medium text-slate-700">
                                            {{
                                                getConcernDuration(
                                                    concern
                                                )
                                            }}
                                        </p>

                                    </div>

                                </div>

                            </article>

                        </div>

                    </template>

                    <!-- Pagination -->

                    <div v-if="
                        !loading &&
                        totalPages > 1
                    "
                        class="flex flex-col gap-3 border-t border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">

                        <p class="text-xs text-slate-500">

                            Page
                            {{ currentPage }}
                            of
                            {{ totalPages }}

                        </p>

                        <div class="flex items-center gap-1">

                            <button type="button" @click="goToPreviousPage" :disabled="currentPage === 1
                                "
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                                Previous
                            </button>

                            <template v-for="(page, index) in paginationPages" :key="`${page}-${index}`">

                                <span v-if="
                                    page === '...'
                                " class="px-2 py-2 text-sm text-slate-400">
                                    ...
                                </span>

                                <button v-else type="button" @click="goToPage(page)" :class="page === currentPage
                                    ? 'bg-blue-900 text-white'
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
            :organizations="organizations" @close="closeModal" @created="loadConcerns" />

        <!-- View Concern Modal -->

        <ViewConcernModal :show="showViewModal" :concern-id="selectedConcernId" :current-user="currentUser"
            @close="closeViewModal" @refresh="loadConcerns" />

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
                                            {{
                                                getExportDateLabel()
                                            }}
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
                                            Your search, status, priority, department, and selected date will be
                                            applied.
                                        </p>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!-- Modal Footer -->

                        <div
                            class="flex items-center justify-end gap-3 border-t border-slate-100 bg-slate-50 px-6 py-4">

                            <button type="button" @click="closeExportModal" :disabled="exporting"
                                class="secondary-hover-button cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50">
                                Cancel
                            </button>

                            <button type="button" @click="confirmExport" :disabled="exporting"
                                class="secondary-hover-button inline-flex min-w-[120px] cursor-pointer items-center justify-center gap-2 rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50">

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