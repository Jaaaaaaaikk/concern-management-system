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
    } catch (error) { console.error('Failed to load current user:', error) }
}
await loadCurrentUser()

const { data, error } = await useFetch('/api/dashboard/superadmin')

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

function getStatusTotal(status) {
    const item = data.value?.status?.find(
        item => item.status === status
    )

    return item?.total ?? 0
}

function getPriorityTotal(priority) {
    const item = data.value?.priority?.find(
        item => item.priority === priority
    )

    return item?.total ?? 0
}

function formatDate(date) {
    if (!date) {
        return '-'
    }

    return new Date(date).toLocaleString()
}
</script>

<template>
    <div class="min-h-screen bg-gray-100">

        <!-- Sidebar -->
        <aside class="fixed inset-y-0 left-0 z-30 w-64 bg-slate-900 text-white">
            <div class="flex h-16 items-center px-6 border-b border-slate-700">
                <h1 class="text-lg font-bold">
                    Concern Management
                </h1>
            </div>


            <nav class="p-4 space-y-2">

                <!-- Dashboard -->
                <NuxtLink to="/dashboard" class="block rounded-lg bg-slate-700 px-4 py-3 text-sm font-medium">
                    Dashboard
                </NuxtLink>

                <!-- Organizations -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/organizations"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Organizations
                </NuxtLink>

                <!-- Users -->
                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/users"
                    class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Users
                </NuxtLink>

                <!-- Concerns -->
                <NuxtLink to="/concerns" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Concerns
                </NuxtLink>

                <!-- Reports -->
                <NuxtLink v-if="
                    currentUser?.role_name === 'superadmin' ||
                    currentUser?.role_name === 'admin'
                " to="/reports" class="block rounded-lg px-4 py-3 text-sm text-slate-300 hover:bg-slate-800">
                    Reports
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
                        Dashboard
                    </h2>

                    <p class="text-sm text-gray-500">
                        Overview of the concern management system
                    </p>
                </div>

            </header>

            <!-- Content -->
            <div class="p-8">

                <!-- Error -->
                <div v-if="error" class="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
                    Failed to load dashboard data.
                </div>

                <!-- Summary Cards -->
                <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-5">

                    <!-- Total -->
                    <div class="rounded-xl bg-white p-5 shadow-sm border">
                        <p class="text-sm text-gray-500">
                            Total Concerns
                        </p>

                        <p class="mt-2 text-3xl font-bold text-gray-900">
                            {{ data?.summary?.total ?? 0 }}
                        </p>
                    </div>

                    <!-- Pending -->
                    <div class="rounded-xl bg-white p-5 shadow-sm border">
                        <p class="text-sm text-gray-500">
                            Pending
                        </p>

                        <p class="mt-2 text-3xl font-bold text-yellow-600">
                            {{ getStatusTotal('pending') }}
                        </p>
                    </div>

                    <!-- In Progress -->
                    <div class="rounded-xl bg-white p-5 shadow-sm border">
                        <p class="text-sm text-gray-500">
                            In Progress
                        </p>

                        <p class="mt-2 text-3xl font-bold text-blue-600">
                            {{ getStatusTotal('in_progress') }}
                        </p>
                    </div>

                    <!-- Resolved -->
                    <div class="rounded-xl bg-white p-5 shadow-sm border">
                        <p class="text-sm text-gray-500">
                            Resolved
                        </p>

                        <p class="mt-2 text-3xl font-bold text-green-600">
                            {{ getStatusTotal('resolved') }}
                        </p>
                    </div>

                    <!-- Closed -->
                    <div class="rounded-xl bg-white p-5 shadow-sm border">
                        <p class="text-sm text-gray-500">
                            Closed
                        </p>

                        <p class="mt-2 text-3xl font-bold text-gray-600">
                            {{ getStatusTotal('closed') }}
                        </p>
                    </div>

                </div>

                <!-- Middle Section -->
                <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">

                    <!-- Priority -->
                    <div class="rounded-xl bg-white p-6 shadow-sm border">

                        <h3 class="text-lg font-semibold text-gray-900">
                            Concerns by Priority
                        </h3>

                        <div class="mt-6 space-y-5">

                            <!-- Low -->
                            <div>
                                <div class="flex justify-between text-sm">
                                    <span class="text-gray-600">
                                        Low
                                    </span>

                                    <span class="font-medium">
                                        {{ getPriorityTotal('low') }}
                                    </span>
                                </div>

                                <div class="mt-2 h-2 rounded-full bg-gray-100">
                                    <div class="h-2 rounded-full bg-gray-400" :style="{
                                        width: `${data?.summary?.total
                                            ? (getPriorityTotal('low') / data.summary.total) * 100
                                            : 0}%`
                                    }"></div>
                                </div>
                            </div>

                            <!-- Medium -->
                            <div>
                                <div class="flex justify-between text-sm">
                                    <span class="text-gray-600">
                                        Medium
                                    </span>

                                    <span class="font-medium">
                                        {{ getPriorityTotal('medium') }}
                                    </span>
                                </div>

                                <div class="mt-2 h-2 rounded-full bg-gray-100">
                                    <div class="h-2 rounded-full bg-blue-500" :style="{
                                        width: `${data?.summary?.total
                                            ? (getPriorityTotal('medium') / data.summary.total) * 100
                                            : 0}%`
                                    }"></div>
                                </div>
                            </div>

                            <!-- High -->
                            <div>
                                <div class="flex justify-between text-sm">
                                    <span class="text-gray-600">
                                        High
                                    </span>

                                    <span class="font-medium">
                                        {{ getPriorityTotal('high') }}
                                    </span>
                                </div>

                                <div class="mt-2 h-2 rounded-full bg-gray-100">
                                    <div class="h-2 rounded-full bg-orange-500" :style="{
                                        width: `${data?.summary?.total
                                            ? (getPriorityTotal('high') / data.summary.total) * 100
                                            : 0}%`
                                    }"></div>
                                </div>
                            </div>

                            <!-- Urgent -->
                            <div>
                                <div class="flex justify-between text-sm">
                                    <span class="text-gray-600">
                                        Urgent
                                    </span>

                                    <span class="font-medium">
                                        {{ getPriorityTotal('urgent') }}
                                    </span>
                                </div>

                                <div class="mt-2 h-2 rounded-full bg-gray-100">
                                    <div class="h-2 rounded-full bg-red-500" :style="{
                                        width: `${data?.summary?.total
                                            ? (getPriorityTotal('urgent') / data.summary.total) * 100
                                            : 0}%`
                                    }"></div>
                                </div>
                            </div>

                        </div>
                    </div>

                    <!-- Organizations -->
                    <div class="rounded-xl bg-white p-6 shadow-sm border">

                        <h3 class="text-lg font-semibold text-gray-900">
                            Concerns by Organization
                        </h3>

                        <div v-if="!data?.organizations?.length" class="mt-6 text-sm text-gray-500">
                            No concern data available yet.
                        </div>

                        <div v-else class="mt-5 space-y-4">
                            <div v-for="organization in data.organizations" :key="organization.id"
                                class="flex items-center justify-between border-b pb-3 last:border-b-0">
                                <span class="text-sm text-gray-700">
                                    {{ organization.name }}
                                </span>

                                <span class="rounded-full bg-gray-100 px-3 py-1 text-sm font-medium">
                                    {{ organization.total_concerns }}
                                </span>
                            </div>
                        </div>

                    </div>

                </div>

                <!-- Recent Concerns -->
                <div class="mt-6 rounded-xl bg-white shadow-sm border">

                    <div class="border-b px-6 py-5">
                        <h3 class="text-lg font-semibold text-gray-900">
                            Recent Concerns
                        </h3>

                        <p class="mt-1 text-sm text-gray-500">
                            Latest concerns submitted to the system
                        </p>
                    </div>

                    <div class="overflow-x-auto">

                        <table class="min-w-full text-sm">

                            <thead class="bg-gray-50 text-left text-gray-500">
                                <tr>
                                    <th class="px-6 py-3 font-medium">
                                        Concern #
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Title
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Created By
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Organization
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Priority
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Status
                                    </th>

                                    <th class="px-6 py-3 font-medium">
                                        Date
                                    </th>
                                </tr>
                            </thead>

                            <tbody class="divide-y">

                                <tr v-for="concern in data?.recentConcerns || []" :key="concern.id"
                                    class="hover:bg-gray-50">

                                    <td class="px-6 py-4 font-medium text-gray-900">
                                        {{ concern.concern_number }}
                                    </td>

                                    <td class="px-6 py-4 text-gray-700">
                                        {{ concern.title }}
                                    </td>

                                    <td class="px-6 py-4 text-gray-700">
                                        {{ concern.created_by_name }}
                                    </td>

                                    <td class="px-6 py-4 text-gray-700">
                                        {{ concern.organization_name || '-' }}
                                    </td>

                                    <td class="px-6 py-4">
                                        <span class="capitalize">
                                            {{ concern.priority }}
                                        </span>
                                    </td>

                                    <td class="px-6 py-4">
                                        <span class="capitalize">
                                            {{ concern.status.replace('_', ' ') }}
                                        </span>
                                    </td>

                                    <td class="px-6 py-4 text-gray-500">
                                        {{ formatDate(concern.created_at) }}
                                    </td>

                                </tr>

                                <tr v-if="!data?.recentConcerns?.length">
                                    <td colspan="7" class="px-6 py-10 text-center text-gray-500">
                                        No concerns have been submitted yet.
                                    </td>
                                </tr>

                            </tbody>

                        </table>

                    </div>

                </div>

            </div>
        </main>

    </div>
</template>