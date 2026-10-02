```vue
<script setup>
definePageMeta({
    middleware: 'auth'
})

const currentUser = ref(null)

async function loadCurrentUser() {
    try {
        const response = await $fetch('/api/auth/me')
        currentUser.value = response.user
    } catch (error) {
        console.error('Failed to load current user:', error)
    }
}

await loadCurrentUser()



const organizations = ref([])
const loading = ref(true)
const errorMessage = ref('')
const successMessage = ref('')

const showModal = ref(false)
const saving = ref(false)

const form = ref({
    name: '',
    code: '',
    description: '',
    contact_email: '',
    contact_number: '',
    address: ''
})

async function loadOrganizations() {
    loading.value = true
    errorMessage.value = ''

    try {
        const response = await $fetch('/api/organizations')

        organizations.value = response.organizations || []
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load organizations.'
    } finally {
        loading.value = false
    }
}

function openAddModal() {
    errorMessage.value = ''
    successMessage.value = ''

    form.value = {
        name: '',
        code: '',
        description: '',
        contact_email: '',
        contact_number: '',
        address: ''
    }

    showModal.value = true
}

function closeModal() {
    if (saving.value) {
        return
    }

    showModal.value = false
}

async function createOrganization() {
    errorMessage.value = ''
    successMessage.value = ''

    if (!form.value.name.trim()) {
        errorMessage.value = 'Organization name is required.'
        return
    }

    saving.value = true

    try {
        await $fetch('/api/organizations', {
            method: 'POST',
            body: {
                name: form.value.name,
                code: form.value.code,
                description: form.value.description,
                contact_email: form.value.contact_email,
                contact_number: form.value.contact_number,
                address: form.value.address
            }
        })

        showModal.value = false

        successMessage.value =
            'Organization created successfully.'

        await loadOrganizations()
    } catch (error) {
        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to create organization.'
    } finally {
        saving.value = false
    }
}

async function logout() {
    try {
        await $fetch('/api/auth/logout', {
            method: 'POST'
        })

        await navigateTo('/login')
    } catch (error) {
        console.error('Logout error:', error)
    }
}

onMounted(() => {
    loadOrganizations()
})
</script>

<template>
    <div class="min-h-screen bg-gray-100">

        <!-- Sidebar -->
        <aside class="fixed inset-y-0 left-0 z-30 w-64 bg-slate-900 text-white">
            <div class="flex h-16 items-center border-b border-slate-700 px-6">
                <h1 class="text-lg font-bold">
                    Concern Management
                </h1>
            </div>


            <nav class="p-4 space-y-2"> <!-- Dashboard -->
                <NuxtLink to="/dashboard" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Dashboard </NuxtLink> <!-- Organizations -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/organizations"
                    class="block rounded-lg bg-slate-700 px-4 py-3 text-sm font-medium"> Organizations </NuxtLink>
                <!-- Users -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/users"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"> Users </NuxtLink>
                <!-- Concerns -->
                <NuxtLink to="/concerns" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Concerns </NuxtLink> <!-- Reports -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin' || currentUser?.role_name === 'admin'"
                    to="/reports" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800"> Reports
                </NuxtLink>
            </nav>



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

                <button @click="logout"
                    class="w-full rounded-lg bg-slate-800 px-4 py-2 text-sm text-slate-300 hover:bg-slate-700">
                    Logout
                </button>
            </div>
        </aside>

        <!-- Main -->
        <main class="ml-64 min-h-screen">

            <!-- Header -->
            <header class="sticky top-0 z-20 flex h-16 items-center justify-between border-b bg-white px-8">
                <div>
                    <h2 class="text-xl font-semibold text-gray-900">
                        Organizations
                    </h2>

                    <p class="text-sm text-gray-500">
                        Manage organizations and departments
                    </p>
                </div>

                <button @click="openAddModal"
                    class="rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white hover:bg-slate-800">
                    + Add Organization
                </button>
            </header>

            <!-- Content -->
            <div class="p-8">

                <!-- Success Message -->
                <div v-if="successMessage"
                    class="mb-6 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700">
                    {{ successMessage }}
                </div>

                <!-- Error Message -->
                <div v-if="errorMessage"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {{ errorMessage }}
                </div>

                <!-- Organization Table -->
                <div class="overflow-hidden rounded-xl border bg-white shadow-sm">

                    <!-- Table Header -->
                    <div class="border-b px-6 py-5">
                        <h3 class="text-lg font-semibold text-gray-900">
                            Organization List
                        </h3>

                        <p class="mt-1 text-sm text-gray-500">
                            Organizations and departments registered in the system
                        </p>
                    </div>

                    <!-- Table -->
                    <div class="overflow-x-auto">

                        <table class="min-w-full text-sm">

                            <thead class="bg-gray-50 text-left text-gray-500">
                                <tr>

                                    <th class="px-6 py-3 font-medium">
                                        Name
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Code
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Contact Email
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Contact Number
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Status
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Created
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Actions
                                    </th>

                                </tr>
                            </thead>

                            <tbody class="divide-y">

                                <!-- Organizations -->
                                <tr v-for="organization in organizations" :key="organization.id"
                                    class="hover:bg-gray-50">

                                    <!-- Name -->
                                    <td class="px-6 py-4">

                                        <div class="font-medium text-gray-900">
                                            {{ organization.name }}
                                        </div>

                                        <div v-if="organization.description" class="mt-1 text-xs text-gray-500">
                                            {{ organization.description }}
                                        </div>

                                    </td>

                                    <!-- Code -->
                                    <td class="px-6 py-4 text-gray-700">
                                        {{ organization.code || '-' }}
                                    </td>

                                    <!-- Email -->
                                    <td class="px-6 py-4 text-gray-700">
                                        {{ organization.contact_email || '-' }}
                                    </td>

                                    <!-- Contact -->
                                    <td class="px-6 py-4 text-gray-700">
                                        {{ organization.contact_number || '-' }}
                                    </td>

                                    <!-- Status -->
                                    <td class="px-6 py-4">

                                        <span class="rounded-full px-3 py-1 text-xs font-medium" :class="organization.status === 'active'
                                            ? 'bg-green-100 text-green-700'
                                            : 'bg-gray-100 text-gray-600'
                                            ">
                                            {{ organization.status }}
                                        </span>

                                    </td>

                                    <!-- Created -->
                                    <td class="px-6 py-4 text-gray-500">
                                        {{
                                            new Date(
                                                organization.created_at
                                            ).toLocaleDateString()
                                        }}
                                    </td>

                                    <!-- Actions -->
                                    <td class="px-6 py-4">

                                        <button type="button"
                                            class="text-sm font-medium text-blue-600 hover:text-blue-800">
                                            Edit
                                        </button>

                                    </td>

                                </tr>

                                <!-- Empty -->
                                <tr v-if="!loading && !organizations.length">
                                    <td colspan="7" class="px-6 py-10 text-center text-gray-500">
                                        No organizations found.
                                    </td>
                                </tr>

                                <!-- Loading -->
                                <tr v-if="loading">
                                    <td colspan="7" class="px-6 py-10 text-center text-gray-500">
                                        Loading organizations...
                                    </td>
                                </tr>

                            </tbody>

                        </table>

                    </div>

                </div>

            </div>
        </main>

        <!-- Add Organization Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">

            <div class="w-full max-w-2xl rounded-xl bg-white shadow-xl">

                <!-- Modal Header -->
                <div class="flex items-center justify-between border-b px-6 py-4">

                    <div>
                        <h3 class="text-lg font-semibold text-gray-900">
                            Add Organization
                        </h3>

                        <p class="text-sm text-gray-500">
                            Enter the organization or department details.
                        </p>
                    </div>

                    <button type="button" @click="closeModal" class="text-2xl text-gray-400 hover:text-gray-600">
                        &times;
                    </button>

                </div>

                <!-- Form -->
                <form @submit.prevent="createOrganization" class="space-y-5 p-6">

                    <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">

                        <!-- Organization Name -->
                        <div class="sm:col-span-2">

                            <label class="mb-1 block text-sm font-medium text-gray-700">
                                Organization Name
                            </label>

                            <input v-model="form.name" type="text"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                                placeholder="e.g. IT Department" />

                        </div>

                        <!-- Code -->
                        <div>

                            <label class="mb-1 block text-sm font-medium text-gray-700">
                                Code
                            </label>

                            <input v-model="form.code" type="text"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                                placeholder="e.g. IT" />

                        </div>

                        <!-- Contact Email -->
                        <div>

                            <label class="mb-1 block text-sm font-medium text-gray-700">
                                Contact Email
                            </label>

                            <input v-model="form.contact_email" type="email"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                                placeholder="department@example.com" />

                        </div>

                        <!-- Contact Number -->
                        <div>

                            <label class="mb-1 block text-sm font-medium text-gray-700">
                                Contact Number
                            </label>

                            <input v-model="form.contact_number" type="text"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                                placeholder="09XXXXXXXXX" />

                        </div>

                        <!-- Address -->
                        <div>

                            <label class="mb-1 block text-sm font-medium text-gray-700">
                                Address
                            </label>

                            <input v-model="form.address" type="text"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                                placeholder="Organization address" />

                        </div>

                        <!-- Description -->
                        <div class="sm:col-span-2">

                            <label class="mb-1 block text-sm font-medium text-gray-700">
                                Description
                            </label>

                            <textarea v-model="form.description" rows="3"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                                placeholder="Short description"></textarea>

                        </div>

                    </div>

                    <!-- Buttons -->
                    <div class="flex justify-end gap-3 border-t pt-5">

                        <button type="button" @click="closeModal"
                            class="rounded-lg border border-gray-300 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">
                            Cancel
                        </button>

                        <button type="submit" :disabled="saving"
                            class="rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50">
                            {{ saving ? 'Saving...' : 'Save Organization' }}
                        </button>

                    </div>

                </form>

            </div>

        </div>

    </div>
</template>