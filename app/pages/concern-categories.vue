<script setup>
import CreateConcernCategoryModal from '~/components/concern-categories/CreateConcernCategoryModal.vue'
import ConcernCategoryStatusModal from '~/components/concern-categories/ConcernCategoryStatusModal.vue'
import { useToast } from '~/composables/useToast'
import { useStickyHeader } from '~/composables/useStickyHeader'

definePageMeta({
    middleware: 'auth'
})

const currentUser = useState('current-user', () => null)
const isHeaderSticky = useStickyHeader()
const { showToast } = useToast()
const categories = ref([])
const organizations = ref([])
const loading = ref(true)
const saving = ref(false)
const updatingId = ref(null)
const showCreateModal = ref(false)
const categoryToToggle = ref(null)
const errorMessage = ref('')
const form = ref({ name: '', description: '', organization_ids: [] })

const activeCount = computed(() =>
    categories.value.filter(category => category.status === 'active').length
)

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    try {
        const userResponse = await $fetch('/api/auth/me', { cache: 'no-store' })
        currentUser.value = userResponse.user

        if (currentUser.value?.role_name !== 'superadmin') {
            showToast('Only Superadmins can manage concern categories.', 'error')
            await navigateTo('/dashboard')
            return
        }

        await Promise.all([
            loadCategories(),
            loadOrganizations()
        ])
    } catch (error) {
        errorMessage.value = error?.data?.statusMessage || 'Failed to load concern categories.'
    } finally {
        loading.value = false
    }
}

function openCreateModal() {
    form.value = { name: '', description: '', organization_ids: [] }
    showCreateModal.value = true
}

function closeCreateModal() {
    if (!saving.value) showCreateModal.value = false
}

async function createCategory() {
    if (saving.value) return

    saving.value = true
    try {
        await $fetch('/api/concern-types', {
            method: 'POST',
            body: {
                name: form.value.name.trim(),
                description: form.value.description.trim(),
                organization_ids: form.value.organization_ids
            }
        })
        showCreateModal.value = false
        await loadCategories()
        showToast('Concern category created successfully.')
    } catch (error) {
        showToast(error?.data?.statusMessage || 'Failed to create concern category.', 'error')
    } finally {
        saving.value = false
    }
}

async function loadCategories() {
    const response = await $fetch('/api/concern-types', {
        cache: 'no-store',
        query: { includeInactive: 'true' }
    })
    categories.value = response.concernTypes || []
}

async function loadOrganizations() {
    const response = await $fetch('/api/organizations', {
        cache: 'no-store'
    })
    organizations.value = (response?.organizations || [])
        .filter(organization => organization.status === 'active')
}

function toggleCategory(category) {
    categoryToToggle.value = category
}

async function confirmToggleCategory() {
    const category = categoryToToggle.value
    if (!category) return

    updatingId.value = category.id
    const nextStatus = category.status === 'active' ? 'inactive' : 'active'
    const action = nextStatus === 'inactive' ? 'remove' : 'restore'

    try {
        const response = await $fetch(`/api/concern-types/${category.id}`, {
            method: 'PATCH',
            body: { status: nextStatus }
        })
        categoryToToggle.value = null
        await loadCategories()
        showToast(response.message || `Concern category ${action === 'remove' ? 'removed' : 'restored'} successfully.`)
    } catch (error) {
        showToast(error?.data?.statusMessage || `Failed to ${action} concern category.`, 'error')
    } finally {
        updatingId.value = null
    }
}

function closeToggleConfirmation() {
    if (!updatingId.value) categoryToToggle.value = null
}

function formatDate(date) {
    if (!date) return '-'
    return new Date(date).toLocaleDateString('en-PH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    })
}

async function logout() {
    currentUser.value = null

    try {
        await $fetch('/api/auth/logout', { method: 'POST' })
    } catch (error) {
        // Clear the client session even if the server session already expired.
    } finally {
        await navigateTo('/login')
    }
}

function updateProfilePhoto(profilePhoto) {
    if (currentUser.value) currentUser.value.profile_photo = profilePhoto
}

onMounted(loadData)
</script>

<template>
    <div class="min-h-screen bg-slate-100">
        <MobileNavigation :current-user="currentUser" @logout="logout" @profile-updated="updateProfilePhoto" />

        <aside class="fixed inset-y-0 left-0 z-40 hidden h-screen w-64 flex-col bg-blue-950 text-white lg:flex">
            <div class="px-6 py-5">
                <h1 class="text-lg font-bold">Felcris Centrale</h1>
                <p class="mt-1 text-xs text-slate-400">Concern Management System</p>
            </div>
            <nav class="sidebar-navigation flex-1 space-y-1 overflow-y-auto px-3 py-4">
                <NuxtLink to="/dashboard" :class="$route.path === '/dashboard' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'" class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium"><NavIcon name="dashboard" /><span>Dashboard</span></NuxtLink>
                <NuxtLink v-if="['superadmin', 'system_admin'].includes(currentUser?.role_name)" to="/users" :class="$route.path === '/users' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'" class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium"><NavIcon name="users" /><span>Manage Users</span></NuxtLink>
                <NuxtLink v-if="['superadmin', 'system_admin'].includes(currentUser?.role_name)" to="/organizations" :class="$route.path === '/organizations' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'" class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium"><NavIcon name="organizations" /><span>Manage Organizations</span></NuxtLink>
                <NuxtLink to="/concerns" :class="$route.path === '/concerns' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'" class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium"><NavIcon name="concerns" /><span>Manage Concerns</span></NuxtLink>
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/concern-categories" :class="$route.path === '/concern-categories' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'" class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium"><NavIcon name="categories" /><span>Concern Categories</span></NuxtLink>
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/login-history" :class="$route.path === '/login-history' ? 'bg-blue-800 text-white' : 'text-blue-100/80 transition hover:bg-white hover:text-black'" class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium"><NavIcon name="history" /><span>Login History</span></NuxtLink>
            </nav>
            <div class="p-4"><UserProfileControl :current-user="currentUser" @logout="logout" @profile-updated="updateProfilePhoto" /></div>
        </aside>

        <main class="flex min-h-screen flex-col lg:ml-64">
            <header :class="['border-b border-slate-200 px-4 py-5 backdrop-blur-md transition-[transform,opacity,background-color,box-shadow,padding] duration-300 ease-out sm:px-6 lg:px-8', isHeaderSticky ? 'lg:sticky lg:top-0 lg:z-30 lg:-translate-y-1 lg:py-3 bg-white/30 shadow-md' : 'translate-y-0 bg-white/30 shadow-sm']">
                <div class="flex flex-row items-center justify-between gap-3">
                    <div>
                        <h2 class="text-xl font-semibold text-slate-900">Concern Categories</h2>
                        <p class="mt-1 text-sm text-slate-500">Manage the categories available when submitting concerns.</p>
                    </div>
                    <button type="button" data-tour="categories-add" aria-label="Add category" class="primary-action-button inline-flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-lg bg-blue-900 p-0 text-sm font-semibold text-white transition hover:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:ring-offset-2 sm:h-auto sm:w-auto sm:gap-2 sm:px-4 sm:py-2.5" @click="openCreateModal">
                        <span aria-hidden="true" class="text-lg leading-none">+</span>
                        <span class="hidden sm:inline">Add Category</span>
                    </button>
                </div>
            </header>

            <section class="mx-auto w-full max-w-[1600px] flex-1 p-4 sm:p-8">
                <div class="mb-5 grid grid-cols-2 gap-3 sm:gap-4">
                    <div class="rounded-xl border border-slate-200 bg-white p-3 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md sm:p-5">
                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Active categories</p>
                        <p class="mt-2 text-2xl font-bold text-blue-950 sm:text-3xl">{{ activeCount }}</p>
                    </div>
                    <div class="rounded-xl border border-slate-200 bg-white p-3 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md sm:p-5">
                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Total categories</p>
                        <p class="mt-2 text-2xl font-bold text-blue-950 sm:text-3xl">{{ categories.length }}</p>
                    </div>
                </div>

                <div v-if="errorMessage" class="mb-5 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{{ errorMessage }}</div>
                <div v-if="loading" class="rounded-xl border border-slate-300 bg-white p-8 text-center shadow-md">
                    <CodeLoadingLine label="Loading concern categories..." />
                </div>
                <div v-else data-tour="categories-list" class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">
                    <div class="border-b border-slate-200 px-5 py-4 sm:px-6">
                        <h3 class="font-semibold text-slate-900">Category list</h3>
                        <p class="mt-1 text-sm text-slate-500">Inactive categories are hidden from new concern submissions. Existing concerns remain unchanged.</p>
                    </div>
                    <div v-if="categories.length" class="divide-y divide-slate-200">
                        <article v-for="(category, index) in categories" :key="category.id" class="flex items-center justify-between gap-3 px-4 py-4 transition-colors duration-200 hover:bg-blue-50/50 sm:px-6 sm:py-5" :class="index % 2 === 1 ? 'bg-slate-50/50' : 'bg-white'">
                            <div class="flex min-w-0 items-start gap-3">
                                <span class="mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-blue-800"><NavIcon name="categories" /></span>
                                <div class="min-w-0">
                                    <div class="flex flex-wrap items-center gap-2">
                                        <h4 class="font-semibold text-slate-900">{{ category.name }}</h4>
                                        <span class="rounded-full px-2.5 py-1 text-[11px] font-semibold" :class="category.status === 'active' ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-200 text-slate-600'">{{ category.status === 'active' ? 'Active' : 'Inactive' }}</span>
                                    </div>
                                    <p class="mt-1 text-sm leading-5 text-slate-500">{{ category.description || 'No description provided.' }}</p>
                                    <div class="mt-3">
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Assigned organizations</p>
                                        <div v-if="category.assigned_organizations?.length" class="mt-1 flex flex-wrap gap-1.5">
                                            <span v-for="organization in category.assigned_organizations" :key="organization.id" class="rounded-full border px-2.5 py-1 text-xs font-medium" :class="organization.status === 'active' ? 'border-blue-100 bg-blue-50 text-blue-800' : 'border-slate-200 bg-slate-100 text-slate-500'">
                                                {{ organization.name }}{{ organization.status === 'active' ? '' : ' (inactive)' }}
                                            </span>
                                        </div>
                                        <p v-else class="mt-1 text-xs text-amber-700">No organizations assigned</p>
                                    </div>
                                    <p class="mt-2 text-xs text-slate-400">Added {{ formatDate(category.created_at) }}</p>
                                </div>
                            </div>
                            <button type="button" :disabled="updatingId === category.id" class="secondary-hover-button shrink-0 cursor-pointer rounded-lg border px-3 py-2 text-xs font-semibold transition disabled:cursor-wait disabled:opacity-60 sm:text-sm" :class="category.status === 'active' ? 'border-red-200 text-red-700 hover:bg-red-50' : 'border-blue-200 text-blue-800 hover:bg-blue-50'" @click="toggleCategory(category)">{{ updatingId === category.id ? 'Saving…' : category.status === 'active' ? 'Remove' : 'Restore' }}</button>
                        </article>
                    </div>
                    <div v-else class="px-6 py-12 text-center">
                        <p class="font-semibold text-slate-800">No categories yet</p>
                        <p class="mt-1 text-sm text-slate-500">Add a category to make it available for new concerns.</p>
                    </div>
                </div>
            </section>
        </main>

        <CreateConcernCategoryModal
            :show="showCreateModal"
            :form="form"
            :saving="saving"
            :organizations="organizations"
            @close="closeCreateModal"
            @submit="createCategory"
        />

        <ConcernCategoryStatusModal
            :category="categoryToToggle"
            :loading="updatingId !== null"
            @cancel="closeToggleConfirmation"
            @confirm="confirmToggleCategory"
        />
    </div>
</template>
