```vue
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
    email: '',
    contact_number: '',
    role_id: '',
    organization_id: ''
})

const editForm = ref({
    username: '',
    first_name: '',
    middle_name: '',
    last_name: '',
    email: '',
    contact_number: '',
    role_id: '',
    organization_id: ''
})

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

function openCreateModal() {
    errorMessage.value = ''
    successMessage.value = ''

    form.value = {
        username: '',
        password: '',
        first_name: '',
        middle_name: '',
        last_name: '',
        email: '',
        contact_number: '',
        role_id: '',
        organization_id: ''
    }

    showModal.value = true
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
        await $fetch('/api/users', {
            method: 'POST',
            body: {
                username: form.value.username,
                password: form.value.password,
                first_name: form.value.first_name,
                middle_name: form.value.middle_name,
                last_name: form.value.last_name,
                email: form.value.email,
                contact_number: form.value.contact_number,
                role_id: Number(form.value.role_id),
                organization_id: form.value.organization_id
                    ? Number(form.value.organization_id)
                    : null
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

function openEditModal(user) {
    errorMessage.value = ''
    successMessage.value = ''

    editingUser.value = user

    editForm.value = {
        username: user.username || '',
        first_name: user.first_name || '',
        middle_name: user.middle_name || '',
        last_name: user.last_name || '',
        email: user.email || '',
        contact_number: user.contact_number || '',
        role_id: user.role_id || '',
        organization_id: user.organization_id || ''
    }

    showEditModal.value = true
}

function closeEditModal() {
    if (updating.value) return

    showEditModal.value = false
    editingUser.value = null
}

async function updateUser() {
    if (!editingUser.value) return

    updating.value = true
    errorMessage.value = ''
    successMessage.value = ''

    try {
        await $fetch(`/api/users/${editingUser.value.id}`, {
            method: 'PUT',
            body: {
                username: editForm.value.username,
                first_name: editForm.value.first_name,
                middle_name: editForm.value.middle_name,
                last_name: editForm.value.last_name,
                email: editForm.value.email,
                contact_number: editForm.value.contact_number,
                role_id: Number(editForm.value.role_id),
                organization_id: editForm.value.organization_id
                    ? Number(editForm.value.organization_id)
                    : null
            }
        })

        successMessage.value = 'User updated successfully.'

        showEditModal.value = false
        editingUser.value = null

        await loadUsers()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to update user.'
    } finally {
        updating.value = false
    }
}

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

async function logout() {
    try {
        await $fetch('/api/auth/logout', {
            method: 'POST'
        })
    } finally {
        await navigateTo('/login')
    }
}

onMounted(() => {
    loadData()
})
</script>

<template>
    <div class="min-h-screen bg-slate-100">

        <!-- Sidebar -->
        <aside class="fixed inset-y-0 left-0 z-30 w-64 bg-slate-900 text-white"> <!-- System Header -->
            <div class="flex h-16 items-center border-b border-slate-700 px-6">
                <h1 class="text-lg font-bold">
                    Concern Management
                </h1>
            </div> <!-- Navigation -->
            <nav class="space-y-2 p-4"> <!-- Dashboard -->
                <NuxtLink to="/dashboard" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Dashboard </NuxtLink> <!-- Organizations -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/organizations"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"> Organizations
                </NuxtLink> <!-- Users - Active -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/users"
                    class="block rounded-lg bg-slate-700 px-4 py-3 text-sm font-medium text-white"> Users </NuxtLink>
                <!-- Concerns -->
                <NuxtLink to="/concerns" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Concerns </NuxtLink> <!-- Reports -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin' || currentUser?.role_name === 'admin'"
                    to="/reports" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"> Reports
                </NuxtLink>
            </nav> <!-- User Information -->
            <div class="absolute bottom-0 w-full border-t border-slate-700 p-4">
                <div class="mb-3">
                    <p class="truncate text-sm font-medium"> {{ currentUser?.first_name }} {{ currentUser?.last_name }}
                    </p>
                    <p class="truncate text-xs text-slate-400"> {{ currentUser?.role_name }} </p>
                </div> <button @click="logout"
                    class="w-full rounded-lg bg-slate-800 px-4 py-2 text-sm text-slate-300 hover:bg-slate-700"> Logout
                </button>
            </div>
        </aside>



        <!-- Main content -->
        <main class="ml-64 min-h-screen">

            <!-- Header -->
            <header class="sticky top-0 z-20 flex h-16 items-center justify-between border-b bg-white px-8">
                <div>
                    <h2 class="text-xl font-semibold text-gray-900">
                        Users
                    </h2>

                    <p class="mt-1 text-sm text-slate-500">
                        Manage system users and their roles.
                    </p>
                </div>

                <button @click="openCreateModal"
                    class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800">
                    + Add User
                </button>
            </header>
            


            <div class="p-8">

                <!-- Messages -->
                <div v-if="successMessage"
                    class="mb-6 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700">
                    {{ successMessage }}
                </div>

                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {{ errorMessage }}
                </div>

                <!-- Loading -->
                <div v-if="loading" class="rounded-xl bg-white p-8 text-center text-sm text-slate-500 shadow-sm">
                    Loading users...
                </div>

                <!-- Table -->
                <div v-else class="overflow-hidden rounded-xl bg-white shadow-sm">
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-slate-200">

                            <thead class="bg-slate-50">
                                <tr>
                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Username
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Name
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Email
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Role
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Organization
                                    </th>

                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Status
                                    </th>

                                    <th
                                        class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                                        Actions
                                    </th>
                                </tr>
                            </thead>

                            <tbody class="divide-y divide-slate-100">

                                <tr v-if="users.length === 0">
                                    <td colspan="7" class="px-6 py-10 text-center text-sm text-slate-500">
                                        No users found.
                                    </td>
                                </tr>

                                <tr v-for="user in users" :key="user.id" class="hover:bg-slate-50">
                                    <td class="whitespace-nowrap px-6 py-4 text-sm font-medium text-slate-800">
                                        {{ user.username }}
                                    </td>

                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-700">
                                        {{ fullName(user) }}
                                    </td>

                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                                        {{ user.email || '-' }}
                                    </td>

                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-700">
                                        {{ roleLabel(user.role_name) }}
                                    </td>

                                    <td class="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                                        {{ user.organization_name || '-' }}
                                    </td>

                                    <td class="whitespace-nowrap px-6 py-4">
                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(user.status)">
                                            {{ user.status }}
                                        </span>
                                    </td>

                                    <td class="whitespace-nowrap px-6 py-4 text-right">
                                        <div class="flex justify-end gap-2">

                                            <button @click="openEditModal(user)"
                                                class="rounded-lg border border-slate-300 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-100">
                                                Edit
                                            </button>

                                            <button @click="toggleStatus(user)" :disabled="updating"
                                                class="rounded-lg border px-3 py-2 text-xs font-medium disabled:cursor-not-allowed disabled:opacity-50"
                                                :class="user.status === 'active'
                                                    ? 'border-red-200 text-red-600 hover:bg-red-50'
                                                    : 'border-green-200 text-green-600 hover:bg-green-50'
                                                    ">
                                                {{ user.status === 'active' ? 'Deactivate' : 'Activate' }}
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

        <!-- Add User Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
            <div class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white shadow-xl">

                <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5">
                    <div>
                        <h3 class="text-lg font-bold text-slate-800">
                            Add User
                        </h3>

                        <p class="mt-1 text-sm text-slate-500">
                            Create a new system user.
                        </p>
                    </div>

                    <button @click="closeModal" class="text-2xl text-slate-400 hover:text-slate-700">
                        ×
                    </button>
                </div>

                <form @submit.prevent="createUser" class="space-y-5 p-6">

                    <div class="grid gap-5 md:grid-cols-2">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Username
                            </label>

                            <input v-model="form.username" type="text" required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Password
                            </label>

                            <input v-model="form.password" type="password" required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                    </div>

                    <div class="grid gap-5 md:grid-cols-3">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                First Name
                            </label>

                            <input v-model="form.first_name" type="text" required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Middle Name
                            </label>

                            <input v-model="form.middle_name" type="text"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Last Name
                            </label>

                            <input v-model="form.last_name" type="text" required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                    </div>

                    <div class="grid gap-5 md:grid-cols-2">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Email
                            </label>

                            <input v-model="form.email" type="email"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Contact Number
                            </label>

                            <input v-model="form.contact_number" type="text"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                    </div>

                    <div class="grid gap-5 md:grid-cols-2">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Role
                            </label>

                            <select v-model="form.role_id" required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">
                                <option value="" disabled>
                                    Select role
                                </option>

                                <option v-for="role in roles" :key="role.id" :value="role.id">
                                    {{ roleLabel(role.name) }}
                                </option>
                            </select>
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Organization
                            </label>

                            <select v-model="form.organization_id"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">
                                <option value="">
                                    No organization
                                </option>

                                <option v-for="organization in organizations" :key="organization.id"
                                    :value="organization.id">
                                    {{ organization.name }}
                                </option>
                            </select>
                        </div>

                    </div>

                    <div class="flex justify-end gap-3 border-t border-slate-200 pt-5">

                        <button type="button" @click="closeModal"
                            class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100">
                            Cancel
                        </button>

                        <button type="submit" :disabled="saving"
                            class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50">
                            {{ saving ? 'Saving...' : 'Create User' }}
                        </button>

                    </div>

                </form>
            </div>
        </div>

        <!-- Edit User Modal -->
        <div v-if="showEditModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
            <div class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white shadow-xl">

                <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5">
                    <div>
                        <h3 class="text-lg font-bold text-slate-800">
                            Edit User
                        </h3>

                        <p class="mt-1 text-sm text-slate-500">
                            Update user information.
                        </p>
                    </div>

                    <button @click="closeEditModal" class="text-2xl text-slate-400 hover:text-slate-700">
                        ×
                    </button>
                </div>

                <form @submit.prevent="updateUser" class="space-y-5 p-6">

                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700">
                            Username
                        </label>

                        <input v-model="editForm.username" type="text" required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                    </div>

                    <div class="grid gap-5 md:grid-cols-3">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                First Name
                            </label>

                            <input v-model="editForm.first_name" type="text" required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Middle Name
                            </label>

                            <input v-model="editForm.middle_name" type="text"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Last Name
                            </label>

                            <input v-model="editForm.last_name" type="text" required
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                    </div>

                    <div class="grid gap-5 md:grid-cols-2">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Email
                            </label>

                            <input v-model="editForm.email" type="email"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Contact Number
                            </label>

                            <input v-model="editForm.contact_number" type="text"
                                class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500" />
                        </div>

                    </div>

                    <div class="grid gap-5 md:grid-cols-2">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Role
                            </label>

                            <select v-model="editForm.role_id" required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">
                                <option value="" disabled>
                                    Select role
                                </option>

                                <option v-for="role in roles" :key="role.id" :value="role.id">
                                    {{ roleLabel(role.name) }}
                                </option>
                            </select>
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Organization
                            </label>

                            <select v-model="editForm.organization_id"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500">
                                <option value="">
                                    No organization
                                </option>

                                <option v-for="organization in organizations" :key="organization.id"
                                    :value="organization.id">
                                    {{ organization.name }}
                                </option>
                            </select>
                        </div>

                    </div>

                    <div class="flex justify-end gap-3 border-t border-slate-200 pt-5">

                        <button type="button" @click="closeEditModal"
                            class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100">
                            Cancel
                        </button>

                        <button type="submit" :disabled="updating"
                            class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50">
                            {{ updating ? 'Updating...' : 'Save Changes' }}
                        </button>

                    </div>

                </form>
            </div>
        </div>

    </div>
</template>