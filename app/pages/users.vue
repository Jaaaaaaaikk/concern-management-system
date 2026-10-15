<script setup>

import CreateUserModal from '../components/users/CreateUserModal.vue'

import EditUserModal from '../components/users/EditUserModal.vue'
import { useToast } from '~/composables/useToast'
import { useStickyHeader } from '~/composables/useStickyHeader'
import { roleDisplayName } from '~/composables/useRoleLabel'

definePageMeta({
    middleware: 'auth'
})

const users = ref([])

const roles = ref([])

const organizations = ref([])

const currentUser = useState('current-user', () => null)
const isHeaderSticky = useStickyHeader()

const loading = ref(true)

const saving = ref(false)

const updating = ref(false)

const errorMessage = ref('')
const { showToast } = useToast()

const showModal = ref(false)

const showEditModal = ref(false)

const editingUser = ref(null)

const statusConfirmation = ref(null)

const statusConfirmationLoading = ref(false)

const form = ref({
    username: '',
    password: '',
    first_name: '',
    middle_name: '',
    last_name: '',
    role_id: '',
    organization_id: ''
})

const editForm = ref({
    username: '',
    password: '',
    first_name: '',
    middle_name: '',
    last_name: '',
    role_id: '',
    organization_id: '',
    profile_photo_url: '',
    profile_photo_file: null,
    profile_photo_remove: false,
    status: 'active'
})

const currentPage = ref(1)

const pageSize = ref(10)

const totalUsers = ref(0)

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

async function loadUsers() {

    const response = await $fetch('/api/users', {
        cache: 'no-store',
        query: {
            page: currentPage.value,
            limit: pageSize.value
        }
    })

    users.value =
        response.users || []

    totalUsers.value =
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

async function loadRoles() {

    try {

        const response = await $fetch('/api/roles', {
            cache: 'no-store'
        })

        roles.value =
            response.roles || []

    } catch (error) {

        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load roles.'

    }

}

async function loadOrganizations() {

    try {

        const response = await $fetch('/api/organizations', {
            cache: 'no-store'
        })

        organizations.value =
            response.organizations || []

    } catch (error) {

        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load organizations.'

    }

}

async function loadUsersWithLoading() {

    loading.value = true

    errorMessage.value = ''

    try {

        await loadUsers()

    } catch (error) {

        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load users.'

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
            loadUsers(),
            loadRoles(),
            loadOrganizations()
        ])

    } catch (error) {

        errorMessage.value =
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load user data.'

    } finally {

        loading.value = false

    }

}

const showingFrom = computed(() => {

    if (totalUsers.value === 0) {

        return 0

    }

    return (
        (currentPage.value - 1) *
        pageSize.value
    ) + 1

})

const showingTo = computed(() => {

    if (totalUsers.value === 0) {

        return 0

    }

    return Math.min(
        currentPage.value * pageSize.value,
        totalUsers.value
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

    await loadUsersWithLoading()

}

async function goToPreviousPage() {

    if (currentPage.value <= 1) {

        return

    }

    currentPage.value -= 1

    await loadUsersWithLoading()

}

async function goToNextPage() {

    if (
        currentPage.value >= totalPages.value
    ) {

        return

    }

    currentPage.value += 1

    await loadUsersWithLoading()

}

const isSuperadminRole = computed(() => {

    const selectedRole = roles.value.find(
        role =>
            Number(role.id) ===
            Number(form.value.role_id)
    )

    return ['superadmin', 'system_admin'].includes(selectedRole?.name)

})

const isEditSuperadminRole = computed(() => {

    if (
        editingUser.value &&
        isCurrentUser(editingUser.value) &&
        Number(editForm.value.role_id) === Number(currentUser.value?.role_id)
    ) {
        return ['superadmin', 'system_admin'].includes(currentUser.value?.role_name)
    }

    const selectedRole = roles.value.find(
        role =>
            Number(role.id) ===
            Number(editForm.value.role_id)
    )

    return ['superadmin', 'system_admin'].includes(selectedRole?.name)

})

const hasUserEditChanges = computed(() => {
    const user = editingUser.value

    if (!user) {
        return false
    }

    const organizationId = isEditSuperadminRole.value
        ? null
        : editForm.value.organization_id
            ? Number(editForm.value.organization_id)
            : null
    const originalOrganizationId = user.organization_id == null
        ? null
        : Number(user.organization_id)

    return editForm.value.username !== (user.username || '') ||
        editForm.value.first_name !== (user.first_name || '') ||
        editForm.value.middle_name !== (user.middle_name || '') ||
        editForm.value.last_name !== (user.last_name || '') ||
        Number(editForm.value.role_id) !== Number(user.role_id) ||
        organizationId !== originalOrganizationId ||
        Boolean(editForm.value.password.trim()) ||
        Boolean(editForm.value.profile_photo_file) ||
        Boolean(editForm.value.profile_photo_remove)
})

const creatableRoles = computed(() => {
    if (currentUser.value?.role_name === 'system_admin') {
        return roles.value.filter(role => ['concern_handler', 'requestor'].includes(role.name))
    }

    return roles.value.filter(role => role.name !== 'superadmin')
})

function openCreateModal() {

    errorMessage.value = ''

    form.value = {
        username: '',
        password: '',
        first_name: '',
        middle_name: '',
        last_name: '',
        role_id: '',
        organization_id: ''
    }

    showModal.value = true

}

function handleRoleChange() {

    if (isSuperadminRole.value) {

        form.value.organization_id = ''

    }

}

function closeModal() {

    if (saving.value) {

        return

    }

    showModal.value = false

}

async function createUser() {

    saving.value = true

    errorMessage.value = ''

    try {

        const organizationId =
            isSuperadminRole.value
                ? null
                : (
                    form.value.organization_id
                        ? Number(
                            form.value.organization_id
                        )
                        : null
                )

        await $fetch('/api/users', {
            method: 'POST',
            body: {
                username: form.value.username,
                password: form.value.password,
                first_name: form.value.first_name,
                middle_name: form.value.middle_name,
                last_name: form.value.last_name,
                role_id: Number(form.value.role_id),
                organization_id: organizationId
            }
        })

        showModal.value = false

        currentPage.value = 1

        await loadUsersWithLoading()

        showToast('User created successfully.')

    } catch (error) {

        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to create user.',
            'error'
        )

    } finally {

        saving.value = false

    }

}

function openEditModal(user) {

    if (!canEditUser(user)) {
        showToast('System Administrators cannot edit Superadmin or System Administrator accounts.', 'error')
        return
    }

    errorMessage.value = ''

    editingUser.value = user

    editForm.value = {
        username: user.username || '',
        password: '',
        first_name: user.first_name || '',
        middle_name: user.middle_name || '',
        last_name: user.last_name || '',
        role_id: user.role_id || '',
        organization_id: user.organization_id || '',
        profile_photo_url: user.profile_photo || '',
        profile_photo_file: null,
        profile_photo_remove: false,
        status: user.status || 'active'
    }

    const selectedRole = roles.value.find(
        role =>
            Number(role.id) ===
            Number(user.role_id)
    )

    if (selectedRole?.name === 'superadmin') {

        editForm.value.organization_id = ''

    }

    showEditModal.value = true

}

function requestEditUserStatusChange() {
    if (!editingUser.value || isCurrentUser(editingUser.value)) {
        return
    }

    const user = editingUser.value
    showEditModal.value = false
    toggleStatus(user)
}

function handleUserRowKeydown(event, user) {
    if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault()
        openEditModal(user)
    }
}

function handleEditRoleChange() {

    if (isEditSuperadminRole.value) {

        editForm.value.organization_id = ''

    }

}

function closeEditModal() {

    if (updating.value) {

        return

    }

    showEditModal.value = false

    editingUser.value = null

    editForm.value.password = ''

}

async function updateUser() {

    if (!editingUser.value) {

        return

    }

    if (!hasUserEditChanges.value) {
        showToast('There are no changes to save.', 'info')
        return
    }

    updating.value = true

    errorMessage.value = ''

    try {

        const organizationId =
            isEditSuperadminRole.value
                ? null
                : (
                    editForm.value.organization_id
                        ? Number(
                            editForm.value.organization_id
                        )
                        : null
                )

        const body = {
            username: editForm.value.username,
            first_name: editForm.value.first_name,
            middle_name: editForm.value.middle_name,
            last_name: editForm.value.last_name,
            role_id: Number(editForm.value.role_id),
            organization_id: organizationId
        }

        if (
            editForm.value.password.trim() !== ''
        ) {

            body.password =
                editForm.value.password

        }

        await $fetch(
            `/api/users/${editingUser.value.id}`,
            {
                method: 'PUT',
                body
            }
        )

        let profilePhotoError = ''

        if (
            editForm.value.profile_photo_file ||
            editForm.value.profile_photo_remove
        ) {
            const photoForm = new FormData()

            if (editForm.value.profile_photo_file) {
                photoForm.append(
                    'photo',
                    editForm.value.profile_photo_file
                )
            } else {
                photoForm.append('remove', 'true')
            }

            try {
                const photoResponse = await $fetch(
                    `/api/users/${editingUser.value.id}/profile-photo`,
                    {
                        method: 'PUT',
                        body: photoForm
                    }
                )

                editForm.value.profile_photo_url =
                    photoResponse.profile_photo || ''
            } catch (error) {
                profilePhotoError =
                    error?.data?.statusMessage ||
                    error?.statusMessage ||
                    'Profile photo could not be updated.'
            }
        }

        showEditModal.value = false

        editingUser.value = null

        editForm.value.password = ''

        await loadUsersWithLoading()

        // Refresh the current user's information as well.
        // This is useful if the superadmin edits their own account.
        await loadCurrentUser()
        showToast(
            profilePhotoError
                ? `User details were saved, but the profile photo was not updated: ${profilePhotoError}`
                : 'User updated successfully.',
            profilePhotoError ? 'error' : 'success'
        )

    } catch (error) {

        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to update user.',
            'error'
        )

    } finally {

        updating.value = false

    }

}

async function toggleStatus(user) {

    // Prevent the currently logged-in user from changing
    // their own account status from the interface.
    if (isCurrentUser(user)) {

        return

    }

    const newStatus =
        user.status === 'active'
            ? 'inactive'
            : 'active'

    const action =
        newStatus === 'active'
            ? 'activate'
            : 'deactivate'

    statusConfirmation.value = {
        user,
        newStatus,
        action
    }

}

function closeStatusConfirmation() {

    if (statusConfirmationLoading.value) {

        return

    }

    statusConfirmation.value = null

}

async function confirmStatusChange() {

    if (!statusConfirmation.value) {

        return

    }

    const { user, newStatus, action } = statusConfirmation.value

    statusConfirmationLoading.value = true

    errorMessage.value = ''

    try {

        await $fetch(
            `/api/users/${user.id}/status`,
            {
                method: 'PATCH',
                body: {
                    status: newStatus
                }
            }
        )

        statusConfirmation.value = null
        await loadUsersWithLoading()
        showToast(`User ${action}d successfully.`)

    } catch (error) {

        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            `Failed to ${action} user.`,
            'error'
        )

    } finally {

        statusConfirmationLoading.value = false

    }

}

function isCurrentUser(user) {

    return Number(user.id) === Number(currentUser.value?.id)

}

function canEditUser(user) {
    return !(
        currentUser.value?.role_name === 'system_admin' &&
        !isCurrentUser(user) &&
        ['superadmin', 'system_admin'].includes(user.role_name)
    )
}

function formatAuditDate(value) {
    if (!value) return '—'

    const date = new Date(value)
    return Number.isNaN(date.getTime())
        ? '—'
        : date.toLocaleString('en-PH', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        })
}

function fullName(user) {

    return [
        user.first_name,
        user.middle_name,
        user.last_name
    ]
        .filter(Boolean)
        .join(' ')

}

function statusClass(status) {

    if (status === 'active') {

        return 'bg-green-100 text-green-700'

    }

    return 'bg-red-100 text-red-700'

}

async function logout() {

    currentUser.value = null

    try {

        await $fetch('/api/auth/logout', {
            method: 'POST'
        })

    } finally {

        await navigateTo('/login')

    }

}

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

            <div class="px-6 py-5">

                <h1 class="text-lg font-bold">
                    Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>

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
                <UserProfileControl :current-user="currentUser" @logout="logout"
                    @profile-updated="updateProfilePhoto" />
            </div>

        </aside>

        <!-- Main Content -->
        <main class="flex min-h-screen flex-col lg:ml-64">

            <div :class="[
                'w-full transition-[transform,opacity,background-color,box-shadow] duration-300 ease-out lg:backdrop-blur-md',
                isHeaderSticky
                    ? 'lg:sticky lg:top-0 lg:z-30 lg:-translate-y-1 lg:bg-white/30 lg:shadow-md'
                    : 'translate-y-0'
            ]">

                <div :class="[
                    'mx-auto w-full max-w-[1600px] px-4 transition-[padding] duration-300 sm:px-6 lg:px-8',
                    isHeaderSticky ? 'py-6 sm:py-8 lg:py-3' : 'py-6 sm:py-8'
                ]">

                    <!-- Header -->
                    <div class="mb-7 flex min-h-16 flex-row items-center justify-between gap-3 sm:flex-row sm:items-center sm:justify-between">

                        <div>

                            <h2 class="text-xl font-semibold text-slate-900">
                                Users
                            </h2>

                            <p class="mt-1 text-sm text-slate-500">
                                Manage system users and their roles.
                            </p>

                        </div>

                        <button type="button" data-tour="users-add" @click="openCreateModal"
                            aria-label="Add user"
                            class="primary-action-button inline-flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-lg bg-linear-to-r from-emerald-600 to-teal-600 p-0 text-sm font-semibold text-white shadow-md shadow-emerald-950/15 transition-all duration-200 ease-out hover:-translate-y-0.5 hover:scale-[1.03] hover:from-emerald-700 hover:to-teal-700 hover:shadow-lg hover:shadow-emerald-950/25 active:translate-y-0 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-emerald-200 motion-reduce:transition-none sm:h-auto sm:w-auto sm:gap-2 sm:px-5 sm:py-3">

                            <span class="text-lg leading-none" aria-hidden="true">
                                +
                            </span>

                            <span class="hidden sm:inline">Add User</span>

                        </button>

                    </div>

                </div>

            </div>

            <div class="mx-auto w-full max-w-[1600px] px-4 pb-6 sm:px-6 sm:pb-8">

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

                <!-- Users Table -->
                <div data-tour="users-list" class="overflow-hidden rounded-xl border border-slate-300 bg-white shadow-md">

                    <!-- Table Header -->
                    <div class="border-b border-slate-200 px-5 py-4">

                        <h3 class="text-base font-semibold text-slate-800">
                            User List
                        </h3>

                        <div v-if="loading" class="mt-2">
                            <CodeLoadingLine label="Loading users..." />
                        </div>

                        <p v-else class="mt-1 text-xs text-slate-500">

                            <template v-if="totalUsers > 0">

                                Showing
                                {{ showingFrom }}–{{ showingTo }}
                                of
                                {{ totalUsers }}
                                user{{ totalUsers === 1 ? '' : 's' }}

                            </template>

                            <template v-else>

                                No users

                            </template>

                        </p>

                    </div>

                    <!-- Table -->
                    <div class="hidden md:block">

                        <table class="w-full table-fixed text-left">

                            <thead class="bg-slate-50">

                                <tr class="border-b border-slate-200">

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Username
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Name
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Role
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Organization
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Status
                                    </th>

                                    <th class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Audit Trail
                                    </th>

                                </tr>

                            </thead>

                            <!-- Loading -->
                            <tbody v-if="loading" class="divide-y divide-slate-100">

                                <tr v-for="row in 5" :key="row">

                                    <td class="px-5 py-5">
                                        <CodeSkeleton :length="8" class="h-4 w-28 rounded" />
                                    </td>

                                    <td class="px-5 py-5">
                                        <CodeSkeleton :length="10" class="h-4 w-36 rounded" />
                                    </td>

                                    <td class="px-5 py-5">
                                        <CodeSkeleton :length="6" class="h-6 w-20 rounded-full" />
                                    </td>

                                    <td class="px-5 py-5">
                                        <CodeSkeleton :length="9" class="h-4 w-32 rounded" />
                                    </td>

                                    <td class="px-5 py-5">
                                        <CodeSkeleton :length="5" class="h-6 w-16 rounded-full" />
                                    </td>

                                    <td class="px-5 py-5">
                                        <CodeSkeleton :length="10" class="h-4 w-32 rounded" />
                                    </td>

                                </tr>

                            </tbody>

                            <!-- Empty -->
                            <tbody v-else-if="users.length === 0" class="divide-y divide-slate-100">

                                <tr>

                                    <td colspan="6" class="px-5 py-12 text-center">

                                        <p class="text-sm font-medium text-slate-600">
                                            No users found.
                                        </p>

                                        <p class="mt-1 text-xs text-slate-400">
                                            There are no users to display.
                                        </p>

                                    </td>

                                </tr>

                            </tbody>

                            <!-- Users -->
                            <tbody v-else class="divide-y divide-slate-200">

                                <tr v-for="(user, index) in users" :key="user.id"
                                    :class="[
                                        index % 2 === 0 ? 'bg-white' : 'bg-slate-50',
                                        canEditUser(user) ? 'cursor-pointer hover:bg-slate-50' : 'cursor-not-allowed opacity-75'
                                    ]"
                                    class="transition focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-700"
                                    role="button" :aria-disabled="!canEditUser(user)" :tabindex="canEditUser(user) ? 0 : -1" @click="openEditModal(user)"
                                    @keydown="handleUserRowKeydown($event, user)">

                                    <!-- Username -->
                                    <td class="px-4 py-4 text-sm font-semibold text-slate-700">

                                        {{ user.username }}

                                        <span v-if="isCurrentUser(user)"
                                            class="ml-2 rounded-full bg-blue-100 px-2 py-1 text-[11px] font-medium text-blue-700">
                                            You
                                        </span>

                                    </td>

                                    <!-- Name -->
                                    <td class="px-4 py-4 text-sm text-slate-600">
                                        <div class="flex min-w-0 items-center gap-3">
                                            <UserAvatar :name="fullName(user) || user.username"
                                                :photo-url="user.profile_photo" />
                                            <span class="truncate">{{ fullName(user) || '-' }}</span>
                                        </div>
                                    </td>

                                    <!-- Role -->
                                    <td class="px-4 py-4">

                                        <span
                                            class="rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-700">
                                            {{ roleDisplayName(user.role_name) }}
                                        </span>

                                    </td>

                                    <!-- Organization -->
                                    <td class="px-4 py-4 text-sm text-slate-600">
                                        <span class="block max-w-48 truncate" :title="user.organization_name || '-'">
                                            {{ user.organization_name || '-' }}
                                        </span>
                                    </td>

                                    <!-- Status -->
                                    <td class="px-4 py-4">

                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(user.status)">

                                            {{
                                                user.status === 'active'
                                                    ? 'Active'
                                                    : 'Inactive'
                                            }}

                                        </span>

                                    </td>

                                    <!-- Audit Trail -->
                                    <td class="px-4 py-4 text-xs leading-5 text-slate-500">
                                        <p><span class="font-medium text-slate-600">Created by:</span> {{ user.created_by_name || 'Legacy / Unknown' }}</p>
                                        <p><span class="font-medium text-slate-600">Updated:</span> {{ formatAuditDate(user.updated_at) }}</p>
                                        <p><span class="font-medium text-slate-600">Updated by:</span> {{ user.updated_by_name || '—' }}</p>
                                    </td>

                                </tr>

                            </tbody>

                        </table>

                    </div>

                    <!-- Compact touch-friendly user cards -->
                    <div v-if="!loading && users.length" class="space-y-3 p-3 md:hidden">
                        <button v-for="user in users" :key="user.id" type="button" @click="openEditModal(user)"
                            :disabled="!canEditUser(user)"
                            class="w-full rounded-xl border border-slate-200 bg-white p-4 text-left shadow-sm transition focus:outline-none focus:ring-2 focus:ring-blue-700 disabled:cursor-not-allowed disabled:opacity-75 enabled:cursor-pointer enabled:hover:border-blue-300 enabled:hover:bg-blue-50/40">
                            <div class="flex items-start gap-3">
                                <UserAvatar :name="fullName(user) || user.username" :photo-url="user.profile_photo" />
                                <div class="min-w-0 flex-1">
                                    <div class="flex items-start justify-between gap-2">
                                        <div class="min-w-0">
                                            <p class="truncate text-sm font-semibold text-slate-900">{{ fullName(user)
                                                || user.username }}
                                            </p>
                                            <p class="mt-0.5 truncate text-xs text-slate-500">@{{ user.username }}</p>
                                        </div>
                                        <div class="flex shrink-0 flex-col items-end gap-1">
                                            <span class="rounded-full px-2.5 py-1 text-[11px] font-semibold"
                                                :class="statusClass(user.status)">{{ user.status === 'active' ? 'Active' :
                                                    'Inactive' }}</span>
                                            <span class="text-[10px] font-semibold" :class="canEditUser(user) ? 'text-blue-800' : 'text-slate-400'">{{ canEditUser(user) ? 'Edit →' : 'Restricted' }}</span>
                                        </div>
                                    </div>
                                    <div class="mt-3 flex flex-wrap gap-2">
                                        <span
                                            class="rounded-full bg-blue-50 px-2.5 py-1 text-[11px] font-medium text-blue-800">{{
                                                roleDisplayName(user.role_name) }}</span>
                                        <span
                                            class="max-w-full truncate rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-medium text-slate-600">{{
                                                user.organization_name || 'No organization' }}</span>
                                    </div>
                                    <div class="mt-3 border-t border-slate-100 pt-2 text-[11px] leading-5 text-slate-500">
                                        <p>Created by: {{ user.created_by_name || 'Legacy / Unknown' }}</p>
                                        <p>Updated: {{ formatAuditDate(user.updated_at) }}</p>
                                        <p>Updated by: {{ user.updated_by_name || '—' }}</p>
                                    </div>
                                </div>
                            </div>
                        </button>
                    </div>

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

        <!-- Create User Modal -->
        <CreateUserModal :show="showModal" :form="form" :roles="creatableRoles" :organizations="organizations"
            :is-superadmin-role="isSuperadminRole" :saving="saving" @close="closeModal" @submit="createUser"
            @role-change="handleRoleChange" />

        <!-- Edit User Modal -->
        <EditUserModal :show="showEditModal" :form="editForm" :roles="roles" :organizations="organizations"
            :current-user-role="currentUser?.role_name"
            :is-current-user="editingUser ? isCurrentUser(editingUser) : false"
            :is-superadmin-role="isEditSuperadminRole" :has-changes="hasUserEditChanges" :updating="updating" @close="closeEditModal" @submit="updateUser"
            @role-change="handleEditRoleChange" @status-toggle="requestEditUserStatusChange" />

        <div v-if="statusConfirmation"
            class="fixed inset-0 z-60 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-[2px]"
            @click.self="closeStatusConfirmation" @keydown.esc="closeStatusConfirmation">
            <section role="dialog" aria-modal="true" aria-labelledby="user-status-confirmation-title"
                aria-describedby="user-status-confirmation-description" tabindex="-1"
                class="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl sm:p-6">
                <div class="flex items-start gap-4">
                    <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl"
                        :class="statusConfirmation.newStatus === 'inactive' ? 'bg-red-50 text-red-700' : 'bg-blue-50 text-blue-700'">
                        <svg v-if="statusConfirmation.newStatus === 'inactive'" xmlns="http://www.w3.org/2000/svg"
                            fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-6 w-6"
                            aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M12 9v3.75m0 3.75h.008v.008H12v-.008z" />
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                        </svg>
                        <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke-width="1.8" stroke="currentColor" class="h-6 w-6" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                        </svg>
                    </div>
                    <div>
                        <h2 id="user-status-confirmation-title" class="text-lg font-bold text-slate-900">
                            {{ statusConfirmation.newStatus ===
                                'inactive' ? 'Deactivate this user?' : 'Activate this user ? '
                            }}
                        </h2>

                        <p id="user-status-confirmation-description" class="mt-2 text-sm leading-6 text-slate-600">
                            {{
                                statusConfirmation.newStatus === 'inactive'
                                    ? `Are you sure you want to deactivate ${statusConfirmation.user.username}? They will no
                            longer be
                            able to access the system.`
                                    : `Are you sure you want to reactivate ${statusConfirmation.user.username}? They will be
                            able to
                            access the system again.`
                            }}
                        </p>

                    </div>
                </div>

                <div class="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                    <button type="button" :disabled="statusConfirmationLoading"
                        class="secondary-hover-button cursor-pointer rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
                        @click="closeStatusConfirmation">
                        Cancel
                    </button>
                    <button type="button" :disabled="statusConfirmationLoading"
                        class="cursor-pointer rounded-lg px-4 py-2.5 text-sm font-semibold text-white transition disabled:cursor-not-allowed disabled:opacity-60"
                        :class="statusConfirmation.newStatus === 'inactive' ? 'bg-red-700 hover:bg-red-800' : 'bg-blue-800 hover:bg-blue-900'"
                        @click="confirmStatusChange">
                        {{ statusConfirmationLoading
                            ? 'Saving...'
                            : statusConfirmation.newStatus === 'inactive'
                                ? 'Deactivate user'
                                : 'Activate user' }}
                    </button>
                </div>
            </section>
        </div>

    </div>

</template>

