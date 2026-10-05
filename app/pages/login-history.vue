<script setup>

definePageMeta({
    middleware: 'auth'
})

const currentUser = useState('current-user', () => null)

const loading = ref(true)
const errorMessage = ref('')
const sessions = ref([])

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
            limit: pageSize.value
        }
    })

    sessions.value = response.sessions || []
    totalSessions.value = Number(response.pagination?.total || 0)
    totalPages.value = Number(response.pagination?.totalPages || 0)
    currentPage.value = Number(response.pagination?.page || currentPage.value)
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

function sessionStatusClass(status) {
    const classes = {
        active: 'bg-emerald-100 text-emerald-700',
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

onMounted(() => {
    loadData()
})
</script>

<template>
    <div class="min-h-screen bg-slate-100">
        <aside class="fixed inset-y-0 left-0 z-40 hidden w-64 flex-col bg-emerald-950 text-white lg:flex">
            <div class="flex h-20 items-center border-b border-emerald-900/60 px-5">
                <div>
                    <h1 class="text-lg font-bold text-white">Felcris Centrale</h1>
                    <p class="mt-1 text-xs text-emerald-100/80">Concern Management System</p>
                </div>
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
                <UserProfileControl :current-user="currentUser" />
            </div>
        </aside>

        <main class="flex min-h-screen flex-col lg:ml-64">
            <MobileNavigation :current-user="currentUser" />

            <header class="border-b border-slate-200 bg-white px-4 py-5 sm:px-6 lg:px-8">
                <div>
                    <h2 class="text-xl font-semibold text-slate-900">Login History</h2>
                    <p class="mt-1 text-sm text-slate-500">
                        Audit trail of user login sessions and activity.
                    </p>
                </div>
            </header>

            <div class="mx-auto w-full max-w-[1600px] px-4 py-6 sm:px-6 sm:py-8">
                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
                    {{ errorMessage }}
                </div>

                <div v-if="loading" class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">
                    <div class="p-8 text-center text-sm text-slate-500">
                        Loading login history...
                    </div>
                </div>

                <div v-else class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">
                    <div class="overflow-x-auto">
                        <table class="min-w-full text-left">
                            <thead class="bg-slate-50">
                                <tr class="border-b border-slate-200">
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
                                </tr>
                            </thead>

                            <tbody v-if="sessions.length === 0" class="divide-y divide-slate-100">
                                <tr>
                                    <td colspan="6" class="px-5 py-12 text-center text-sm text-slate-500">
                                        No login sessions found.
                                    </td>
                                </tr>
                            </tbody>

                            <tbody v-else class="divide-y divide-slate-200">
                                <tr v-for="(session, index) in sessions" :key="session.id"
                                    :class="index % 2 === 0 ? 'bg-white' : 'bg-slate-50'"
                                    class="transition hover:bg-emerald-50/60">
                                    <td class="px-5 py-4">
                                        <p class="text-sm font-semibold text-slate-800">{{ session.full_name }}</p>
                                        <p class="mt-1 text-xs text-slate-500">{{ session.username }}</p>
                                    </td>

                                    <td class="px-5 py-4 text-sm text-slate-600">
                                        <span
                                            class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700">
                                            {{ session.role_name || '-' }}
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
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <div v-if="totalPages > 1"
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
                                    :class="page === currentPage ? 'bg-emerald-900 text-white' : 'border border-slate-300 text-slate-600 hover:bg-slate-50'"
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
        </main>
    </div>
</template>
