<script setup>

import { VueDatePicker } from '@vuepic/vue-datepicker'
import '@vuepic/vue-datepicker/dist/main.css'
import { useStickyHeader } from '~/composables/useStickyHeader'
import { roleDisplayName } from '~/composables/useRoleLabel'
import { useToast } from '~/composables/useToast'

const { showToast } = useToast()

definePageMeta({
    middleware: 'auth'
})

const currentUser = useState('current-user', () => null)
const isHeaderSticky = useStickyHeader()

const loading = ref(true)
const errorMessage = ref('')
const sessions = ref([])
const sessionView = ref('active')
const sessionCounts = ref({ active: 0, history: 0 })

const currentPage = ref(1)
const pageSize = ref(15)
const totalSessions = ref(0)
const totalPages = ref(0)

async function loadCurrentUser() {
    const response = await $fetch('/api/auth/me', {
        cache: 'no-store'
    })

    currentUser.value = response.user
}

async function loadLoginHistory() {
    const response = await $fetch('/api/auth/login-history', {
        cache: 'no-store',
        query: {
            page: currentPage.value,
            limit: pageSize.value,
            view: sessionView.value
        }
    })

    sessions.value = response.sessions || []
    sessionCounts.value = response.counts || sessionCounts.value
    totalSessions.value = Number(response.pagination?.total || 0)
    totalPages.value = Number(response.pagination?.totalPages || 0)
    currentPage.value = Number(response.pagination?.page || currentPage.value)
}

async function selectSessionView(view) {
    if (sessionView.value === view) {
        return
    }

    sessionView.value = view
    currentPage.value = 1
    selectedSessionIds.value = []
    loading.value = true

    try {
        await loadLoginHistory()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load login history.'
    } finally {
        loading.value = false
    }
}

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    try {
        await loadCurrentUser()

        if (currentUser.value?.role_name !== 'superadmin') {
            errorMessage.value = 'You do not have permission to view this page.'
            sessions.value = []
            totalSessions.value = 0
            totalPages.value = 0
            return
        }

        await loadLoginHistory()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load login history.'
    } finally {
        loading.value = false
    }
}

async function logout() {
    currentUser.value = null

    try {
        await $fetch('/api/auth/logout', {
            method: 'POST'
        })
    } catch (error) {
        // Continue to the login page even if the session is already invalid.
    }

    await navigateTo('/login')
}

const showRevokeModal = ref(false)
const sessionToRevoke = ref(null)
const revokingSessionId = ref(null)

function requestRevokeSession(session) {
    if (!session || session.session_status !== 'active') {
        return
    }

    sessionToRevoke.value = session
    showRevokeModal.value = true
}

async function confirmRevokeSession() {
    if (!sessionToRevoke.value || revokingSessionId.value) {
        return
    }

    revokingSessionId.value = sessionToRevoke.value.id

    try {
        await $fetch('/api/auth/login-history/revoke', {
            method: 'POST',
            body: {
                session_id: sessionToRevoke.value.id
            }
        })

        showToast('Session revoked successfully.')
        showRevokeModal.value = false
        sessionToRevoke.value = null
        await loadLoginHistory()
    } catch (error) {
        showToast(
            error?.data?.statusMessage || error?.statusMessage || 'Unable to revoke this session.',
            'error'
        )
    } finally {
        revokingSessionId.value = null
    }
}

const showClearModal = ref(false)
const clearingHistory = ref(false)
const clearMode = ref('all')
const selectedSessionIds = ref([])
const rangeDateFrom = ref(null)
const rangeDateTo = ref(null)

function toggleSessionSelection(sessionId) {
    if (selectedSessionIds.value.includes(sessionId)) {
        selectedSessionIds.value = selectedSessionIds.value.filter((id) => id !== sessionId)
    } else {
        selectedSessionIds.value = [...selectedSessionIds.value, sessionId]
    }
}

function allVisibleSessionsSelected() {
    return sessions.value.length > 0
        && sessions.value.every((session) => selectedSessionIds.value.includes(session.id))
}

function toggleAllVisibleSessions() {
    if (allVisibleSessionsSelected()) {
        const visibleIds = sessions.value.map((session) => session.id)
        selectedSessionIds.value = selectedSessionIds.value.filter((id) => !visibleIds.includes(id))
    } else {
        selectedSessionIds.value = [...new Set([
            ...selectedSessionIds.value,
            ...sessions.value.map((session) => session.id)
        ])]
    }
}

function requestClearHistory(mode = 'all') {
    if (sessionView.value !== 'history') return

    clearMode.value = mode

    if (mode === 'selected' && selectedSessionIds.value.length === 0) {
        showToast('Select at least one expired or revoked session.', 'error')
        return
    }

    if (mode === 'range' && (!rangeDateFrom.value || !rangeDateTo.value)) {
        showToast('Choose both a start date and end date.', 'error')
        return
    }

    showClearModal.value = true
}

async function confirmClearHistory() {
    if (clearingHistory.value) return

    clearingHistory.value = true

    try {
        const body = { mode: clearMode.value }

        if (clearMode.value === 'selected') {
            body.session_ids = selectedSessionIds.value
        } else if (clearMode.value === 'range') {
            const startDate = new Date(rangeDateFrom.value)
            const endDate = new Date(rangeDateTo.value)
            startDate.setHours(0, 0, 0, 0)
            endDate.setHours(23, 59, 59, 999)
            body.date_from = startDate.toISOString()
            body.date_to = endDate.toISOString()
        }

        const response = await $fetch('/api/auth/login-history/clear', {
            method: 'POST',
            body
        })

        showToast(response.message || 'Login history cleared successfully.')
        showClearModal.value = false
        selectedSessionIds.value = []
        currentPage.value = 1
        await loadLoginHistory()
    } catch (error) {
        showToast(
            error?.data?.statusMessage || error?.statusMessage || 'Unable to clear login history.',
            'error'
        )
    } finally {
        clearingHistory.value = false
    }
}

const showingFrom = computed(() => {
    if (totalSessions.value === 0) {
        return 0
    }

    return (currentPage.value - 1) * pageSize.value + 1
})

const showingTo = computed(() => {
    if (totalSessions.value === 0) {
        return 0
    }

    return Math.min(currentPage.value * pageSize.value, totalSessions.value)
})

const paginationPages = computed(() => {
    const total = totalPages.value
    const current = currentPage.value

    if (total <= 7) {
        return Array.from({ length: total }, (_, index) => index + 1)
    }

    const pages = [1]

    if (current > 4) {
        pages.push('...')
    }

    const start = Math.max(2, current - 1)
    const end = Math.min(total - 1, current + 1)

    for (let page = start; page <= end; page++) {
        if (!pages.includes(page)) {
            pages.push(page)
        }
    }

    if (current < total - 3) {
        pages.push('...')
    }

    if (!pages.includes(total)) {
        pages.push(total)
    }

    return pages
})

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

function formatDateOnly(value) {
    if (!value) return '-'

    return new Date(value).toLocaleDateString('en-PH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    })
}

function sessionStatusClass(status) {
    const classes = {
        active: 'bg-blue-100 text-blue-700',
        revoked: 'bg-red-100 text-red-700',
        expired: 'bg-slate-200 text-slate-700'
    }

    return classes[status] || 'bg-slate-100 text-slate-600'
}

function statusLabel(status) {
    const labels = {
        active: 'Active',
        revoked: 'Revoked',
        expired: 'Expired'
    }

    return labels[status] || 'Unknown'
}

async function goToPage(page) {
    if (page === '...' || page < 1 || page > totalPages.value || page === currentPage.value) {
        return
    }

    currentPage.value = page
    loading.value = true

    try {
        await loadLoginHistory()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load login history.'
    } finally {
        loading.value = false
    }
}

async function goToPreviousPage() {
    if (currentPage.value <= 1) {
        return
    }

    currentPage.value -= 1
    loading.value = true

    try {
        await loadLoginHistory()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load login history.'
    } finally {
        loading.value = false
    }
}

async function goToNextPage() {
    if (currentPage.value >= totalPages.value || totalPages.value === 0) {
        return
    }

    currentPage.value += 1
    loading.value = true

    try {
        await loadLoginHistory()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load login history.'
    } finally {
        loading.value = false
    }
}

const showDeletionAuditModal = ref(false)
const deletionAuditLoading = ref(false)
const deletionAuditRows = ref([])

async function openDeletionAudit() {
    showDeletionAuditModal.value = true
    deletionAuditLoading.value = true

    try {
        const response = await $fetch('/api/auth/login-history/deletion-audit', {
            cache: 'no-store'
        })
        deletionAuditRows.value = response.deletions || []
    } catch (error) {
        showToast(
            error?.data?.statusMessage || error?.statusMessage || 'Unable to load deletion history.',
            'error'
        )
    } finally {
        deletionAuditLoading.value = false
    }
}

function deletionModeLabel(mode) {
    if (mode === 'selected') return 'Selected records'
    if (mode === 'range') return 'Date range'
    return 'All history'
}

onMounted(loadData)
</script>

<template>
    <div class="min-h-screen bg-slate-100">
        <ConfirmActionModal
            :show="showRevokeModal"
            title="Revoke this active session?"
            :message="`This will immediately sign out the user for session #${sessionToRevoke?.id ?? ''}. They will need to log in again.`"
            confirm-label="Revoke session"
            :loading="Boolean(revokingSessionId)"
            tone="danger"
            @cancel="showRevokeModal = false; sessionToRevoke = null"
            @confirm="confirmRevokeSession"
        />
        <ConfirmActionModal
            :show="showClearModal"
            title="Clear login history?"
            :message="clearMode === 'selected'
                ? `This will permanently delete ${selectedSessionIds.length} selected expired or revoked login-history record${selectedSessionIds.length === 1 ? '' : 's'}.`
                : clearMode === 'range'
                    ? `This will permanently delete expired or revoked login-history records from ${formatDateOnly(rangeDateFrom)} through ${formatDateOnly(rangeDateTo)}.`
                    : `This will permanently delete ${sessionCounts.history} expired or revoked login-history record${sessionCounts.history === 1 ? '' : 's'} in the History view.`"
            confirm-label="Clear history"
            :loading="clearingHistory"
            tone="danger"
            @cancel="showClearModal = false"
            @confirm="confirmClearHistory"
        />
        <DeletionAuditModal
            :show="showDeletionAuditModal"
            :loading="deletionAuditLoading"
            :deletion-rows="deletionAuditRows"
            @close="showDeletionAuditModal = false"
        />
        <aside class="fixed inset-y-0 left-0 z-40 hidden h-screen w-64 flex-col bg-blue-950 text-white lg:flex">
            <div class="px-6 py-5">
                <div>
                    <h1 class="text-lg font-bold text-white">Felcris Centrale</h1>
                    <p class="mt-1 text-xs text-blue-100/80">Concern Management System</p>
                </div>
            </div>

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

            <div class="p-4">
                <UserProfileControl :current-user="currentUser" @logout="logout" />
            </div>
        </aside>

        <main class="flex min-h-screen flex-col lg:ml-64">
            <MobileNavigation :current-user="currentUser" @logout="logout" />

            <header :class="[
                'border-b border-slate-200 px-4 py-5 backdrop-blur-md transition-[transform,opacity,background-color,box-shadow,padding] duration-300 ease-out sm:px-6 lg:px-8',
                isHeaderSticky
                    ? 'lg:sticky lg:top-0 lg:z-30 lg:-translate-y-1 lg:py-3 bg-white/30 shadow-md'
                    : 'translate-y-0 bg-white/30 shadow-sm'
            ]">
                <div>
                    <h2 class="text-xl font-semibold text-slate-900">
                        Login History
                    </h2>
                    <p class="mt-1 text-sm text-slate-500">
                        Audit trail of user login sessions and activity.
                    </p>
                </div>
            </header>

            <div class="mx-auto w-full max-w-[1600px] flex-1 px-4 py-6 sm:px-6 sm:py-8">
                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
                    {{ errorMessage }}
                </div>

                <div data-tour="login-history-sessions" class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">
                    <div class="border-b border-slate-200 bg-slate-50/80 p-3 sm:p-4">
                        <div class="rounded-xl bg-slate-200/70 p-1">
                            <div class="relative grid grid-cols-2">
                                <span
                                    aria-hidden="true"
                                    class="absolute inset-y-0 left-0 w-1/2 rounded-lg bg-white shadow-sm ring-1 ring-blue-100 transition-transform duration-300 ease-in-out motion-reduce:transition-none"
                                    :class="sessionView === 'history' ? 'translate-x-full' : 'translate-x-0'"
                                ></span>
                                <button type="button" @click="selectSessionView('active')"
                                    :class="sessionView === 'active' ? 'text-blue-900' : 'text-slate-600 hover:text-slate-900'"
                                    class="relative z-10 flex cursor-pointer items-center justify-center gap-2 rounded-lg px-3 py-3 text-sm font-semibold transition-colors">
                                    <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
                                    Active now
                                    <span class="rounded-full bg-emerald-50 px-2 py-0.5 text-xs text-emerald-800">{{
                                        sessionCounts.active }}</span>
                                </button>
                                <button type="button" @click="selectSessionView('history')"
                                    :class="sessionView === 'history' ? 'text-blue-900' : 'text-slate-600 hover:text-slate-900'"
                                    class="relative z-10 flex cursor-pointer items-center justify-center gap-2 rounded-lg px-3 py-3 text-sm font-semibold transition-colors">
                                    Session history
                                    <span class="rounded-full bg-slate-200 px-2 py-0.5 text-xs text-slate-700">{{
                                        sessionCounts.history }}</span>
                                </button>
                            </div>
                        </div>
                        <div v-if="currentUser?.role_name === 'superadmin' && sessionView === 'history'"
                            class="mt-4 rounded-xl border border-slate-200 bg-white p-3 sm:p-4">
                            <div class="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
                                <div class="flex flex-col gap-3 sm:flex-row sm:items-end">
                                    <label class="block text-xs font-semibold text-slate-600">
                                        From
                                        <VueDatePicker
                                            v-model="rangeDateFrom"
                                            :max-date="rangeDateTo || undefined"
                                            :input-attrs="{ clearable: false }"
                                            :time-picker="false"
                                            :auto-apply="true"
                                            :formats="{ input: 'MMM d, yyyy', preview: 'MMM d, yyyy' }"
                                            placeholder="Start date"
                                            input-class-name="!cursor-pointer !rounded-lg !border-slate-300 !py-2 !text-sm focus:!border-blue-500"
                                            menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                                            class="mt-1 w-full cursor-pointer sm:w-44"
                                        />
                                    </label>
                                    <label class="block text-xs font-semibold text-slate-600">
                                        To
                                        <VueDatePicker
                                            v-model="rangeDateTo"
                                            :min-date="rangeDateFrom || undefined"
                                            :input-attrs="{ clearable: false }"
                                            :time-picker="false"
                                            :auto-apply="true"
                                            :formats="{ input: 'MMM d, yyyy', preview: 'MMM d, yyyy' }"
                                            placeholder="End date"
                                            input-class-name="!cursor-pointer !rounded-lg !border-slate-300 !py-2 !text-sm focus:!border-blue-500"
                                            menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                                            class="mt-1 w-full cursor-pointer sm:w-44"
                                        />
                                    </label>
                                    <button v-if="rangeDateFrom || rangeDateTo" type="button"
                                        class="min-h-10 cursor-pointer rounded-lg px-2 py-2 text-xs font-semibold text-slate-500 transition hover:bg-slate-100 hover:text-slate-800"
                                        @click="rangeDateFrom = null; rangeDateTo = null">
                                        Clear dates
                                    </button>
                                    <button type="button"
                                        :disabled="!rangeDateFrom || !rangeDateTo || sessionCounts.history === 0"
                                        class="inline-flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-lg border border-orange-200 bg-orange-50 px-3 py-2 text-xs font-semibold text-orange-800 transition hover:bg-orange-100 disabled:cursor-not-allowed disabled:opacity-40"
                                        @click="requestClearHistory('range')">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 6h18m-2 0-.9 14H5.9L5 6m4 0V4h6v2m-5 4v6m4-6v6" />
                                        </svg>
                                        Delete Date Range
                                    </button>
                                </div>

                                <div class="flex flex-wrap gap-2 border-t border-slate-100 pt-3 xl:border-0 xl:pt-0">
                                    <button type="button"
                                        :disabled="selectedSessionIds.length === 0"
                                        class="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-800 transition hover:bg-amber-100 disabled:cursor-not-allowed disabled:opacity-40"
                                        @click="requestClearHistory('selected')">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 6h18m-2 0-.9 14H5.9L5 6m4 0V4h6v2m-5 4v6m4-6v6" />
                                        </svg>
                                        Delete Selected ({{ selectedSessionIds.length }})
                                    </button>
                                    <button type="button"
                                        :disabled="sessionCounts.history === 0"
                                        class="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-red-300 bg-red-50 px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-40"
                                        @click="requestClearHistory('all')">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 6h18m-2 0-.9 14H5.9L5 6m4 0V4h6v2m-5 4v6m4-6v6" />
                                        </svg>
                                        Clear All History
                                    </button>
                                    <button type="button"
                                        class="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-blue-200 bg-blue-50 px-3 py-2 text-xs font-semibold text-blue-800 transition hover:bg-blue-100"
                                        @click="openDeletionAudit">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6l4 2m5-2a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                        </svg>
                                        Deletion History
                                    </button>
                                </div>
                            </div>
                            <p class="mt-3 flex items-start gap-2 rounded-lg bg-blue-50 px-3 py-2 text-xs leading-5 text-blue-800">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 16v-4m0-4h.008M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                </svg>
                                <span>Automatic cleanup removes expired or revoked login-history records once they are older than 6 months. Active sessions are not deleted by this cleanup.</span>
                            </p>
                        </div>
                        <p class="px-1 pt-3 text-xs text-slate-500">
                            {{ sessionView === 'active'
                                ? 'Sessions that are still valid and have not been revoked.'
                                : 'Sessions that have expired or were revoked.' }}
                        </p>
                    </div>

                    <div v-if="loading" class="p-8 text-center">
                        <CodeLoadingLine label="Loading login history..." />
                    </div>

                    <div v-else class="">
                        <div class="hidden overflow-x-auto lg:block">
                            <table class="min-w-full text-left">
                                <thead class="bg-slate-50">
                                    <tr class="border-b border-slate-200">
                                        <th v-if="sessionView === 'history'" class="w-12 px-5 py-3">
                                            <input type="checkbox"
                                                :checked="allVisibleSessionsSelected()"
                                                :indeterminate="selectedSessionIds.length > 0 && !allVisibleSessionsSelected()"
                                                aria-label="Select all visible login-history records"
                                                class="h-4 w-4 cursor-pointer"
                                                @change="toggleAllVisibleSessions" />
                                        </th>
                                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            User</th>
                                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Role</th>
                                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Organization</th>
                                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Status</th>
                                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Login</th>
                                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Expires</th>
                                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Action</th>
                                    </tr>
                                </thead>

                                <tbody v-if="sessions.length === 0" class="divide-y divide-slate-100">
                                    <tr>
                                        <td :colspan="sessionView === 'history' ? 8 : 7" class="px-5 py-12 text-center text-sm text-slate-500">
                                            No login sessions found.
                                        </td>
                                    </tr>
                                </tbody>

                                <tbody v-else class="divide-y divide-slate-200">
                                    <tr v-for="(session, index) in sessions" :key="session.id"
                                        :class="index % 2 === 0 ? 'bg-white' : 'bg-slate-50'"
                                        class="transition hover:bg-blue-50/60">
                                        <td v-if="sessionView === 'history'" class="w-12 px-5 py-4">
                                            <input type="checkbox"
                                                :checked="selectedSessionIds.includes(session.id)"
                                                :aria-label="`Select login session ${session.id}`"
                                                class="h-4 w-4 cursor-pointer"
                                                @change="toggleSessionSelection(session.id)" />
                                        </td>
                                        <td class="px-5 py-4">
                                            <p class="text-sm font-semibold text-slate-800">{{ session.full_name }}</p>
                                            <p class="mt-1 text-xs text-slate-500">{{ session.username }}</p>
                                        </td>

                                        <td class="px-5 py-4 text-sm text-slate-600">
                                            <span
                                                class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700">
                                                {{ roleDisplayName(session.role_name) }}
                                            </span>
                                        </td>

                                        <td class="px-5 py-4 text-sm text-slate-600">
                                            {{ session.organization_name || '-' }}
                                        </td>

                                        <td class="px-5 py-4">
                                            <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-medium"
                                                :class="sessionStatusClass(session.session_status)">
                                                {{ statusLabel(session.session_status) }}
                                            </span>
                                        </td>

                                        <td class="px-5 py-4 text-sm text-slate-600">
                                            {{ formatDate(session.login_at) }}
                                        </td>

                                        <td class="px-5 py-4 text-sm text-slate-600">
                                            {{ formatDate(session.expires_at) }}
                                        </td>

                                        <td v-if="session.session_status === 'active'" class="px-5 py-4">
                                            <button
                                                type="button"
                                                class="secondary-hover-button cursor-pointer rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-100"
                                                @click="requestRevokeSession(session)"
                                            >
                                                Revoke
                                            </button>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <div v-if="sessions.length === 0" class="px-4 py-10 text-center text-sm text-slate-500 lg:hidden">
                            No login sessions found.
                        </div>

                        <div v-else class="space-y-3 p-3 lg:hidden">
                            <article v-for="session in sessions" :key="session.id"
                                class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                                <div v-if="sessionView === 'history'" class="mb-3">
                                    <label class="flex cursor-pointer items-center gap-2 text-xs font-medium text-slate-600">
                                        <input type="checkbox"
                                            :checked="selectedSessionIds.includes(session.id)"
                                            class="h-4 w-4 cursor-pointer"
                                            @change="toggleSessionSelection(session.id)" />
                                        Select record
                                    </label>
                                </div>
                                <div class="flex items-start justify-between gap-3">
                                    <div class="min-w-0">
                                        <p class="truncate text-sm font-semibold text-slate-800">{{ session.full_name }}</p>
                                        <p class="mt-1 text-xs text-slate-500">{{ session.username }}</p>
                                    </div>
                                    <span class="inline-flex rounded-full px-2.5 py-1 text-[10px] font-medium"
                                        :class="sessionStatusClass(session.session_status)">
                                        {{ statusLabel(session.session_status) }}
                                    </span>
                                </div>

                                <div class="mt-3 grid grid-cols-2 gap-x-3 gap-y-3 text-xs text-slate-600">
                                    <div>
                                        <p class="text-slate-400">Role</p>
                                        <p class="mt-1 font-medium text-slate-700">{{ roleDisplayName(session.role_name) }}</p>
                                    </div>
                                    <div>
                                        <p class="text-slate-400">Organization</p>
                                        <p class="mt-1 font-medium text-slate-700">{{ session.organization_name || '-' }}</p>
                                    </div>
                                    <div>
                                        <p class="text-slate-400">Login</p>
                                        <p class="mt-1 font-medium text-slate-700">{{ formatDate(session.login_at) }}</p>
                                    </div>
                                    <div>
                                        <p class="text-slate-400">Expires</p>
                                        <p class="mt-1 font-medium text-slate-700">{{ formatDate(session.expires_at) }}</p>
                                    </div>
                                </div>

                                <div v-if="session.session_status === 'active'" class="mt-4 flex justify-end">
                                    <button
                                        type="button"
                                        class="secondary-hover-button cursor-pointer rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-100"
                                        @click="requestRevokeSession(session)"
                                    >
                                        Revoke
                                    </button>
                                </div>
                            </article>
                        </div>
                    </div>

                    <div v-if="!loading && totalPages > 1"
                        class="flex flex-col gap-3 border-t border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
                        <p class="text-xs text-slate-500">
                            Showing {{ showingFrom }}-{{ showingTo }} of {{ totalSessions }} sessions
                        </p>

                        <div class="flex items-center gap-1">
                            <button type="button" @click="goToPreviousPage" :disabled="currentPage === 1"
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                                Previous
                            </button>

                            <template v-for="(page, index) in paginationPages" :key="`${page}-${index}`">
                                <span v-if="page === '...'" class="px-2 py-2 text-sm text-slate-400">...</span>

                                <button v-else type="button" @click="goToPage(page)"
                                    :class="page === currentPage ? 'bg-blue-900 text-white' : 'border border-slate-300 text-slate-600 hover:bg-slate-50'"
                                    class="min-w-9 cursor-pointer rounded-lg px-3 py-2 text-sm font-medium transition">
                                    {{ page }}
                                </button>
                            </template>

                            <button type="button" @click="goToNextPage"
                                :disabled="currentPage >= totalPages || totalPages === 0"
                                class="cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                                Next
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            <AppFooter class="mt-auto" />
        </main>

        <Transition
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
        >
            <div v-if="showDeletionAuditModal"
                class="fixed inset-0 z-70 flex items-center justify-center bg-slate-950/55 p-4 backdrop-blur-sm"
                @click.self="showDeletionAuditModal = false">
                <section class="relative max-h-[80vh] w-full max-w-xl overflow-hidden rounded-2xl border border-white/60 bg-white shadow-2xl"
                    role="dialog" aria-modal="true" aria-label="Login history deletion history">
                    <div class="flex items-start justify-between border-b border-slate-200 px-5 py-4 sm:px-6">
                        <div>
                            <h3 class="text-lg font-semibold text-slate-900">Deletion History</h3>
                            <p class="mt-1 text-xs text-slate-500">Recent login-history deletion summaries.</p>
                        </div>
                        <button
                            type="button"
                            aria-label="Close deletion history"
                            class="group relative flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center text-3xl leading-none text-red-700 transition-colors duration-200 hover:text-red-800"
                            @click="showDeletionAuditModal = false"
                        >
                            <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                                stroke="currentColor" aria-hidden="true"
                                class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                            </svg>
                        </button>
                    </div>

                    <div class="max-h-[60vh] overflow-y-auto p-5 sm:p-6">
                        <div v-if="deletionAuditLoading" class="py-8 text-center">
                            <CodeLoadingLine label="Loading deletion history..." />
                        </div>
                        <div v-else-if="deletionAuditRows.length === 0" class="py-8 text-center text-sm text-slate-500">
                            No login-history deletions recorded.
                        </div>
                        <div v-else class="space-y-3">
                            <article v-for="row in deletionAuditRows" :key="row.id"
                                class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                                <div class="flex items-start justify-between gap-3">
                                    <div>
                                        <p class="text-sm font-semibold text-slate-800">
                                            {{ row.deleted_count }} record{{ row.deleted_count === 1 ? '' : 's' }} deleted
                                        </p>
                                        <p class="mt-1 text-xs text-slate-500">{{ deletionModeLabel(row.deletion_mode) }}</p>
                                    </div>
                                    <p class="text-right text-xs text-slate-500">{{ formatDate(row.created_at) }}</p>
                                </div>
                                <p v-if="row.deletion_mode === 'range'" class="mt-3 text-xs text-slate-600">
                                    Range: {{ formatDate(row.date_from) }} — {{ formatDate(row.date_to) }}
                                </p>
                            </article>
                        </div>
                    </div>
                </section>
            </div>
        </Transition>
    </div>
</template>

