<script setup>

definePageMeta({
    middleware: 'auth'
})

const users = ref([])
const roles = ref([])
const organizations = ref([])

const currentUser = ref(null)

const loading = ref(true)
const saving = ref(false)
const updating = ref(false)

const errorMessage = ref('')
const successMessage = ref('')

const showModal = ref(false)
const showEditModal = ref(false)

const editingUser = ref(null)

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
    organization_id: ''
})

/*
|--------------------------------------------------------------------------
| Current User
|--------------------------------------------------------------------------
*/

async function loadCurrentUser() {
    try {
        const response = await $fetch('/api/auth/me')

        currentUser.value = response.user
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load current user.'
    }
}

/*
|--------------------------------------------------------------------------
| Load Users
|--------------------------------------------------------------------------
*/

async function loadUsers() {
    try {
        const response = await $fetch('/api/users')

        users.value = response.users || []
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load users.'
    }
}

/*
|--------------------------------------------------------------------------
| Load Roles
|--------------------------------------------------------------------------
*/

async function loadRoles() {
    try {
        const response = await $fetch('/api/roles')

        roles.value = response.roles || []
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load roles.'
    }
}

/*
|--------------------------------------------------------------------------
| Load Organizations
|--------------------------------------------------------------------------
*/

async function loadOrganizations() {
    try {
        const response = await $fetch('/api/organizations')

        organizations.value = response.organizations || []
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load organizations.'
    }
}

/*
|--------------------------------------------------------------------------
| Load All Data
|--------------------------------------------------------------------------
*/

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    await Promise.all([
        loadCurrentUser(),
        loadUsers(),
        loadRoles(),
        loadOrganizations()
    ])

    loading.value = false
}

/*
|--------------------------------------------------------------------------
| Role Helpers
|--------------------------------------------------------------------------
*/

/*
 * Check if the selected role in the Add User form
 * is Superadmin.
 */
const isSuperadminRole = computed(() => {
    const selectedRole = roles.value.find(
        role => Number(role.id) === Number(form.value.role_id)
    )

    return selectedRole?.name === 'superadmin'
})

/*
 * Check if the selected role in the Edit User form
 * is Superadmin.
 */
const isEditSuperadminRole = computed(() => {
    const selectedRole = roles.value.find(
        role => Number(role.id) === Number(editForm.value.role_id)
    )

    return selectedRole?.name === 'superadmin'
})

/*
|--------------------------------------------------------------------------
| Add User
|--------------------------------------------------------------------------
*/

function openCreateModal() {
    errorMessage.value = ''
    successMessage.value = ''

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

/*
 * When the selected role changes in Add User:
 * Superadmin does not need an organization.
 */
function handleRoleChange() {
    if (isSuperadminRole.value) {
        form.value.organization_id = ''
    }
}

function closeModal() {
    if (saving.value) return

    showModal.value = false
}

async function createUser() {
    saving.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        /*
         * Superadmin must not have an organization.
         */
        const organizationId = isSuperadminRole.value
            ? null
            : (
                form.value.organization_id
                    ? Number(form.value.organization_id)
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

        successMessage.value = 'User created successfully.'

        showModal.value = false

        await loadUsers()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to create user.'
    } finally {
        saving.value = false
    }
}

/*
|--------------------------------------------------------------------------
| Edit User
|--------------------------------------------------------------------------
*/

function openEditModal(user) {
    errorMessage.value = ''
    successMessage.value = ''

    editingUser.value = user

    editForm.value = {
        username: user.username || '',

        /*
         * Password is intentionally empty.
         *
         * We never load the existing password.
         * Leave this blank to keep the current password.
         */
        password: '',

        first_name: user.first_name || '',
        middle_name: user.middle_name || '',
        last_name: user.last_name || '',
        role_id: user.role_id || '',
        organization_id: user.organization_id || ''
    }

    /*
     * If the existing user is already a Superadmin,
     * make sure the organization field is empty.
     */
    const selectedRole = roles.value.find(
        role => Number(role.id) === Number(user.role_id)
    )

    if (selectedRole?.name === 'superadmin') {
        editForm.value.organization_id = ''
    }

    showEditModal.value = true
}

/*
 * When the selected role changes in Edit User:
 * Superadmin does not need an organization.
 */
function handleEditRoleChange() {
    if (isEditSuperadminRole.value) {
        editForm.value.organization_id = ''
    }
}

function closeEditModal() {
    if (updating.value) return

    showEditModal.value = false
    editingUser.value = null

    /*
     * Clear password from memory when closing the modal.
     */
    editForm.value.password = ''
}

async function updateUser() {
    if (!editingUser.value) return

    updating.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        /*
         * Superadmin must not have an organization.
         */
        const organizationId = isEditSuperadminRole.value
            ? null
            : (
                editForm.value.organization_id
                    ? Number(editForm.value.organization_id)
                    : null
            )

        /*
         * Build the update request.
         *
         * Password is intentionally NOT included by default.
         * This means an empty password keeps the existing password.
         */
        const body = {
            username: editForm.value.username,
            first_name: editForm.value.first_name,
            middle_name: editForm.value.middle_name,
            last_name: editForm.value.last_name,
            role_id: Number(editForm.value.role_id),
            organization_id: organizationId
        }

        /*
         * Only send a password when Superadmin
         * entered a new password.
         */
        if (editForm.value.password.trim() !== '') {
            body.password = editForm.value.password
        }

        /*
         * Correct API URL.
         *
         * Do NOT put spaces inside the URL.
         */
        await $fetch(`/api/users/${editingUser.value.id}`, {
            method: 'PUT',
            body
        })

        successMessage.value = 'User updated successfully.'

        showEditModal.value = false
        editingUser.value = null

        /*
         * Clear the password field after saving.
         */
        editForm.value.password = ''

        await loadUsers()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to update user.'
    } finally {
        updating.value = false
    }
}

/*
|--------------------------------------------------------------------------
| User Status
|--------------------------------------------------------------------------
*/

async function toggleStatus(user) {
    const newStatus =
        user.status === 'active'
            ? 'inactive'
            : 'active'

    const action =
        newStatus === 'active'
            ? 'activate'
            : 'deactivate'

    const confirmed = window.confirm(
        `Are you sure you want to ${action} ${user.username}?`
    )

    if (!confirmed) return

    updating.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        await $fetch(`/api/users/${user.id}/status`, {
            method: 'PATCH',
            body: {
                status: newStatus
            }
        })

        successMessage.value =
            `User ${action}d successfully.`

        await loadUsers()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            `Failed to ${action} user.`
    } finally {
        updating.value = false
    }
}

/*
|--------------------------------------------------------------------------
| Display Helpers
|--------------------------------------------------------------------------
*/

function fullName(user) {
    return [
        user.first_name,
        user.middle_name,
        user.last_name
    ]
        .filter(Boolean)
        .join(' ')
}

function roleLabel(role) {
    if (role === 'superadmin') return 'Superadmin'
    if (role === 'admin') return 'Admin'
    if (role === 'user') return 'User'

    return role || '-'
}

function statusClass(status) {
    if (status === 'active') {
        return 'bg-green-100 text-green-700'
    }

    return 'bg-red-100 text-red-700'
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
    } finally {
        await navigateTo('/login')
    }
}

/*
|--------------------------------------------------------------------------
| Initial Load
|--------------------------------------------------------------------------
*/

onMounted(() => {
    loadData()
})

</script>

<template>
    <div class="min-h-screen bg-slate-100">

        <!-- Sidebar -->
        <aside class="fixed inset-y-0 left-0 z-30 w-64 bg-slate-900 text-white">

            <!-- System Header -->
            <div class="flex h-16 items-center border-b border-slate-700 px-6">

                <h1 class="text-lg font-bold">
                    Concern Management
                </h1>

            </div>

            <!-- Navigation -->
            <nav class="space-y-2 p-4">

                <!-- Dashboard -->
                <NuxtLink
                    to="/dashboard"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Dashboard
                </NuxtLink>

                <!-- Organizations -->
                <NuxtLink
                    v-if="currentUser?.role_name === 'superadmin'"
                    to="/organizations"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Organizations
                </NuxtLink>

                <!-- Users - Active -->
                <NuxtLink
                    v-if="currentUser?.role_name === 'superadmin'"
                    to="/users"
                    class="block rounded-lg bg-slate-700 px-4 py-3 text-sm font-medium text-white"
                >
                    Users
                </NuxtLink>

                <!-- Concerns -->
                <NuxtLink
                    to="/concerns"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Concerns
                </NuxtLink>

                <!-- Reports -->
                <NuxtLink
                    v-if="
                        currentUser?.role_name === 'superadmin' ||
                        currentUser?.role_name === 'admin'
                    "
                    to="/reports"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"
                >
                    Reports
                </NuxtLink>

            </nav>

            <!-- User Information -->
            <div class="absolute bottom-0 w-full border-t border-slate-700 p-4">

                <div class="mb-3">

                    <p class="truncate text-sm font-medium">
                        {{ currentUser?.first_name }}
                        {{ currentUser?.last_name }}
                    </p>

                    <p class="truncate text-xs text-slate-400">
                        {{ currentUser?.role_name }}
                    </p>

                </div>

                <button
                    @click="logout"
                    class="w-full rounded-lg bg-slate-800 px-4 py-2 text-sm text-slate-300 hover:bg-slate-700"
                >
                    Logout
                </button>

            </div>

        </aside>

        <!-- Main content -->
        <main class="ml-64 min-h-screen">

            <!-- Header -->
            <header
                class="sticky top-0 z-20 flex h-16 items-center justify-between border-b bg-white px-8"
            >

                <div>

                    <h2 class="text-xl font-semibold text-gray-900">
                        Users
                    </h2>

                    <p class="mt-1 text-sm text-slate-500">
                        Manage system users and their roles.
                    </p>

                </div>

                <button
                    @click="openCreateModal"
                    class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800"
                >
                    + Add User
                </button>

            </header>

            <div class="p-8">

                <!-- Messages -->
                <div
                    v-if="successMessage"
                    class="mb-6 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700"
                >
                    {{ successMessage }}
                </div>

                <div
                    v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
                >
                    {{ errorMessage }}
                </div>

                <!-- Loading -->
                <div
                    v-if="loading"
                    class="rounded-xl bg-white p-8 text-center text-sm text-slate-500 shadow-sm"
                >
                    Loading users...
                </div>

                <!-- Table -->
                <div
                    v-else
                    class="overflow-hidden rounded-xl bg-white shadow-sm"
                >

                    <div class="overflow-x-auto">

                        <table class="min-w-full divide-y divide-slate-200">

                            <thead class="bg-slate-50">

                                <tr>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Username
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Name
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Role
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Organization
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Status
                                    </th>

                                    <th
                                        class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500"
                                    >
                                        Actions
                                    </th>

                                </tr>

                            </thead>

                            <tbody class="divide-y divide-slate-100">

                                <!-- No Users -->
                                <tr v-if="users.length === 0">

                                    <td
                                        colspan="6"
                                        class="px-6 py-10 text-center text-sm text-slate-500"
                                    >
                                        No users found.
                                    </td>

                                </tr>

                                <!-- Users -->
                                <tr
                                    v-for="user in users"
                                    :key="user.id"
                                    class="hover:bg-slate-50"
                                >

                                    <!-- Username -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm font-medium text-slate-800"
                                    >
                                        {{ user.username }}
                                    </td>

                                    <!-- Name -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm text-slate-700"
                                    >
                                        {{ fullName(user) }}
                                    </td>

                                    <!-- Role -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm text-slate-700"
                                    >
                                        {{ roleLabel(user.role_name) }}
                                    </td>

                                    <!-- Organization -->
                                    <td
                                        class="whitespace-nowrap px-6 py-4 text-sm text-slate-600"
                                    >
                                        {{ user.organization_name || '-' }}
                                    </td>

                                    <!-- Status -->
                                    <td class="whitespace-nowrap px-6 py-4">

                                        <span
                                            class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(user.status)"
                                        >
                                            {{ user.status }}
                                        </span>

                                    </td>

                                    <!-- Actions -->
                                    <td class="whitespace-nowrap px-6 py-4 text-right">

                                        <div class="flex justify-end gap-2">

                                            <!-- Edit -->
                                            <button
                                                @click="openEditModal(user)"
                                                class="rounded-lg border border-slate-300 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-100"
                                            >
                                                Edit
                                            </button>

                                            <!-- Activate / Deactivate -->
                                            <button
                                                @click="toggleStatus(user)"
                                                :disabled="updating"
                                                class="rounded-lg border px-3 py-2 text-xs font-medium disabled:cursor-not-allowed disabled:opacity-50"
                                                :class="
                                                    user.status === 'active'
                                                        ? 'border-red-200 text-red-600 hover:bg-red-50'
                                                        : 'border-green-200 text-green-600 hover:bg-green-50'
                                                "
                                            >
                                                {{
                                                    user.status === 'active'
                                                        ? 'Deactivate'
                                                        : 'Activate'
                                                }}
                                            </button>

                                        </div>

                                    </td>

                                </tr>

                            </tbody>

                        </table>

                    </div>

                </div>

            </div>

        </main>

        <!-- ================================================================ -->
        <!-- Add User Modal -->
        <!-- ================================================================ -->

        <div
            v-if="showModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4"
        >

            <div
                class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white shadow-xl"
            >

                <!-- Modal Header -->
                <div
                    class="flex items-center justify-between border-b border-slate-200 px-6 py-5"
                >

                    <div>

                        <h3 class="text-lg font-bold text-slate-800">
                            Add User
                        </h3>

                        <p class="mt-1 text-sm text-slate-500">
                            Create a new system user.
                        </p>

                    </div>

                    <button
                        @click="closeModal"
                        class="text-2xl text-slate-400 hover:text-slate-700"
                    >
                        ×
                    </button>

                </div>

                <form
                    @submit.prevent="createUser"
                    class="space-y-5 p-6"
                >

                    <!-- Username and Password -->
                    <div class="grid gap-5 md:grid-cols-2">

                        <!-- Username -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Username
                            </label>

                            <input
                                v-model="form.username"
                                type="text"
                                required
                                autocomplete="username"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                        <!-- Password -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Password
                            </label>

                            <input
                                v-model="form.password"
                                type="password"
                                required
                                minlength="8"
                                autocomplete="new-password"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                            <p class="mt-1 text-xs text-slate-500">
                                Password must be at least 8 characters.
                            </p>

                        </div>

                    </div>

                    <!-- Name -->
                    <div class="grid gap-5 md:grid-cols-3">

                        <!-- First Name -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                First Name
                            </label>

                            <input
                                v-model="form.first_name"
                                type="text"
                                required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                        <!-- Middle Name -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Middle Name
                            </label>

                            <input
                                v-model="form.middle_name"
                                type="text"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                        <!-- Last Name -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Last Name
                            </label>

                            <input
                                v-model="form.last_name"
                                type="text"
                                required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                    </div>

                    <!-- Role and Organization -->
                    <div class="grid gap-5 md:grid-cols-2">

                        <!-- Role -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Role
                            </label>

                            <select
                                v-model="form.role_id"
                                @change="handleRoleChange"
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500"
                            >

                                <option
                                    value=""
                                    disabled
                                >
                                    Select role
                                </option>

                                <option
                                    v-for="role in roles"
                                    :key="role.id"
                                    :value="role.id"
                                >
                                    {{ roleLabel(role.name) }}
                                </option>

                            </select>

                        </div>

                        <!-- Organization -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Organization
                            </label>

                            <select
                                v-model="form.organization_id"
                                :disabled="isSuperadminRole"
                                :required="!isSuperadminRole"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
                            >

                                <option value="">
                                    No organization
                                </option>

                                <option
                                    v-for="organization in organizations"
                                    :key="organization.id"
                                    :value="organization.id"
                                >
                                    {{ organization.name }}
                                </option>

                            </select>

                            <p
                                v-if="isSuperadminRole"
                                class="mt-1 text-xs text-slate-500"
                            >
                                Superadmin does not require an organization.
                            </p>

                        </div>

                    </div>

                    <!-- Buttons -->
                    <div
                        class="flex justify-end gap-3 border-t border-slate-200 pt-5"
                    >

                        <button
                            type="button"
                            @click="closeModal"
                            class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100"
                        >
                            Cancel
                        </button>

                        <button
                            type="submit"
                            :disabled="saving"
                            class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{ saving ? 'Saving...' : 'Create User' }}
                        </button>

                    </div>

                </form>

            </div>

        </div>

        <!-- ================================================================ -->
        <!-- Edit User Modal -->
        <!-- ================================================================ -->

        <div
            v-if="showEditModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4"
        >

            <div
                class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white shadow-xl"
            >

                <!-- Modal Header -->
                <div
                    class="flex items-center justify-between border-b border-slate-200 px-6 py-5"
                >

                    <div>

                        <h3 class="text-lg font-bold text-slate-800">
                            Edit User
                        </h3>

                        <p class="mt-1 text-sm text-slate-500">
                            Update user information.
                        </p>

                    </div>

                    <button
                        @click="closeEditModal"
                        class="text-2xl text-slate-400 hover:text-slate-700"
                    >
                        ×
                    </button>

                </div>

                <form
                    @submit.prevent="updateUser"
                    class="space-y-5 p-6"
                >

                    <!-- Username -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Username
                        </label>

                        <input
                            v-model="editForm.username"
                            type="text"
                            required
                            autocomplete="username"
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                        />

                    </div>

                    <!-- New Password -->
                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            New Password
                        </label>

                        <input
                            v-model="editForm.password"
                            type="password"
                            minlength="8"
                            autocomplete="new-password"
                            placeholder="Leave blank to keep current password"
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                        />

                        <p class="mt-1 text-xs text-slate-500">
                            Leave this blank if you do not want to change the
                            password.
                        </p>

                    </div>

                    <!-- Name -->
                    <div class="grid gap-5 md:grid-cols-3">

                        <!-- First Name -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                First Name
                            </label>

                            <input
                                v-model="editForm.first_name"
                                type="text"
                                required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                        <!-- Middle Name -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Middle Name
                            </label>

                            <input
                                v-model="editForm.middle_name"
                                type="text"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                        <!-- Last Name -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Last Name
                            </label>

                            <input
                                v-model="editForm.last_name"
                                type="text"
                                required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500"
                            />

                        </div>

                    </div>

                    <!-- Role and Organization -->
                    <div class="grid gap-5 md:grid-cols-2">

                        <!-- Role -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Role
                            </label>

                            <select
                                v-model="editForm.role_id"
                                @change="handleEditRoleChange"
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500"
                            >

                                <option
                                    value=""
                                    disabled
                                >
                                    Select role
                                </option>

                                <option
                                    v-for="role in roles"
                                    :key="role.id"
                                    :value="role.id"
                                >
                                    {{ roleLabel(role.name) }}
                                </option>

                            </select>

                        </div>

                        <!-- Organization -->
                        <div>

                            <label
                                class="mb-2 block text-sm font-medium text-slate-700"
                            >
                                Organization
                            </label>

                            <select
                                v-model="editForm.organization_id"
                                :disabled="isEditSuperadminRole"
                                :required="!isEditSuperadminRole"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
                            >

                                <option value="">
                                    No organization
                                </option>

                                <option
                                    v-for="organization in organizations"
                                    :key="organization.id"
                                    :value="organization.id"
                                >
                                    {{ organization.name }}
                                </option>

                            </select>

                            <p
                                v-if="isEditSuperadminRole"
                                class="mt-1 text-xs text-slate-500"
                            >
                                Superadmin does not require an organization.
                            </p>

                        </div>

                    </div>

                    <!-- Buttons -->
                    <div
                        class="flex justify-end gap-3 border-t border-slate-200 pt-5"
                    >

                        <button
                            type="button"
                            @click="closeEditModal"
                            class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100"
                        >
                            Cancel
                        </button>

                        <button
                            type="submit"
                            :disabled="updating"
                            class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{ updating ? 'Updating...' : 'Save Changes' }}
                        </button>

                    </div>

                </form>

            </div>

        </div>

    </div>
</template>
