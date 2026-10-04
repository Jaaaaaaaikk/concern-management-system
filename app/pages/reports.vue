<script setup>

definePageMeta({
    middleware: 'auth'
})

const currentUser = ref(null)
const loading = ref(true)
const errorMessage = ref('')

/* --------------------------------------------------------------------------
| Current User
|-------------------------------------------------------------------------- */

async function loadCurrentUser() {

    try {

        const response = await $fetch(
            '/api/auth/me',
            {
                cache: 'no-store'
            }
        )

        currentUser.value =
            response.user

    } catch (error) {

        console.error(
            'Failed to load current user:',
            error
        )

        errorMessage.value =
            error?.data?.statusMessage ||
            'Failed to load user information.'

    } finally {

        loading.value = false

    }
}

/* --------------------------------------------------------------------------
| Logout
|-------------------------------------------------------------------------- */

async function logout() {

    try {

        await $fetch(
            '/api/auth/logout',
            {
                method: 'POST'
            }
        )

        await navigateTo('/login')

    } catch (error) {

        console.error(
            'Logout error:',
            error
        )

    }
}

/* --------------------------------------------------------------------------
| Initial Load
|-------------------------------------------------------------------------- */

onMounted(() => {

    loadCurrentUser()

})

</script>

<template>

    <div class="min-h-screen bg-slate-100">

        <!-- Error Toast -->
        <div
            v-if="errorMessage"
            class="fixed right-5 top-5 z-[100] flex max-w-lg items-start gap-3 rounded-xl border border-red-200 bg-white px-5 py-4 text-sm font-medium text-red-700 shadow-lg"
        >

            <span
                class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-red-100 font-bold text-red-700"
            >
                !
            </span>

            <span class="flex-1 leading-5">
                {{ errorMessage }}
            </span>

            <button
                type="button"
                @click="errorMessage = ''"
                class="cursor-pointer text-xl leading-none text-red-400 transition hover:text-red-700"
            >
                ×
            </button>

        </div>


        <!-- Sidebar -->
        <aside
            class="fixed inset-y-0 left-0 z-40 flex w-64 flex-col bg-slate-900 text-white"
        >

            <!-- Logo -->
            <div class="border-b border-slate-800 px-6 py-5">

                <h1 class="text-lg font-bold">
                    ICT Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>

            </div>


            <!-- Navigation -->
            <nav class="flex-1 space-y-1 px-3 py-4">

                <NuxtLink
                    to="/dashboard"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >

                    <span>▦</span>

                    <span>
                        Dashboard
                    </span>

                </NuxtLink>


                <NuxtLink
                    v-if="currentUser?.role_name === 'superadmin'"
                    to="/organizations"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >

                    <span>▣</span>

                    <span>
                        Manage Organizations
                    </span>

                </NuxtLink>


                <NuxtLink
                    v-if="currentUser?.role_name === 'superadmin'"
                    to="/users"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >

                    <span>♙</span>

                    <span>
                        Manage Users
                    </span>

                </NuxtLink>


                <NuxtLink
                    to="/concerns"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
                >

                    <span>⚠</span>

                    <span>
                        Manage Concerns
                    </span>

                </NuxtLink>


                <NuxtLink
                    v-if="
                        currentUser?.role_name === 'superadmin' ||
                        currentUser?.role_name === 'admin'
                    "
                    to="/reports"
                    class="flex items-center gap-3 rounded-lg bg-slate-800 px-4 py-3 text-sm font-medium text-white"
                >

                    <span>▤</span>

                    <span>
                        Manage Reports
                    </span>

                </NuxtLink>

            </nav>


            <!-- Logged-in User -->
            <div class="border-t border-slate-800 p-4">

                <div class="mb-3 rounded-lg bg-slate-800 p-3">

                    <p class="truncate text-sm font-semibold text-white">

                        {{
                            currentUser
                                ? `${currentUser.first_name || ''} ${currentUser.last_name || ''}`.trim()
                                : '-'
                        }}

                    </p>

                    <p class="mt-1 text-xs text-slate-400">

                        {{ currentUser?.role_name || '-' }}

                    </p>

                    <p
                        v-if="currentUser?.organization_name"
                        class="mt-1 truncate text-xs text-slate-500"
                        :title="currentUser.organization_name"
                    >

                        {{ currentUser.organization_name }}

                    </p>

                </div>


                <button
                    type="button"
                    @click="logout"
                    class="flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg border border-slate-700 px-4 py-2.5 text-sm font-medium text-slate-300 transition hover:border-red-400 hover:bg-red-500/10 hover:text-red-300"
                >

                    Logout

                </button>

            </div>

        </aside>


        <!-- Main Content -->
        <main class="ml-64 min-h-screen">

            <!-- Header -->
            <header
                class="sticky top-0 z-20 flex min-h-16 items-center justify-between border-b border-slate-200 bg-white px-8 py-4"
            >

                <div>

                    <h2 class="text-xl font-semibold text-slate-900">
                        Manage Reports
                    </h2>

                    <p class="mt-1 text-sm text-slate-500">
                        View and generate reports from the concern management system.
                    </p>

                </div>

            </header>


            <!-- Content -->
            <div class="p-8">

                <!-- Loading -->
                <div
                    v-if="loading"
                    class="rounded-xl border border-slate-200 bg-white p-10 text-center shadow-sm"
                >

                    <p class="text-sm text-slate-500">
                        Loading...
                    </p>

                </div>


                <!-- Reports Page -->
                <template v-else>

                    <div class="mx-auto max-w-5xl">

                        <!-- Main Coming Soon Card -->
                        <div
                            class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"
                        >

                            <div
                                class="px-6 py-12 text-center sm:px-10 sm:py-16"
                            >

                                <!-- Cute Illustration -->
                                <div
                                    class="mx-auto flex h-28 w-28 items-center justify-center rounded-full bg-slate-100"
                                >

                                    <div class="relative">

                                        <!-- Document -->
                                        <div
                                            class="relative h-16 w-14 rounded-lg border-2 border-slate-300 bg-white shadow-sm"
                                        >

                                            <!-- Fold -->
                                            <div
                                                class="absolute right-0 top-0 h-4 w-4 border-b-2 border-l-2 border-slate-300 bg-slate-100"
                                            ></div>


                                            <!-- Lines -->
                                            <div class="absolute left-3 top-6 space-y-1.5">

                                                <div class="h-1.5 w-7 rounded-full bg-slate-200"></div>

                                                <div class="h-1.5 w-9 rounded-full bg-slate-200"></div>

                                                <div class="h-1.5 w-6 rounded-full bg-slate-200"></div>

                                            </div>


                                            <!-- Small Chart -->
                                            <div
                                                class="absolute bottom-2 left-3 flex items-end gap-1"
                                            >

                                                <div
                                                    class="h-2 w-1.5 rounded-t bg-slate-300"
                                                ></div>

                                                <div
                                                    class="h-4 w-1.5 rounded-t bg-slate-400"
                                                ></div>

                                                <div
                                                    class="h-6 w-1.5 rounded-t bg-slate-500"
                                                ></div>

                                            </div>

                                        </div>


                                        <!-- Sparkles -->
                                        <span
                                            class="absolute -right-5 -top-5 text-lg"
                                        >
                                            ✨
                                        </span>

                                        <span
                                            class="absolute -bottom-3 -left-6 text-sm"
                                        >
                                            ✨
                                        </span>

                                    </div>

                                </div>


                                <!-- Title -->
                                <h3
                                    class="mt-7 text-2xl font-bold text-slate-900"
                                >
                                    Reports are coming soon
                                </h3>


                                <!-- Description -->
                                <p
                                    class="mx-auto mt-3 max-w-xl text-sm leading-6 text-slate-500"
                                >
                                    We're still deciding what reports should
                                    be available here. This section will
                                    eventually contain useful reports based
                                    on the concerns managed in the system.
                                </p>


                                <!-- Status -->
                                <div class="mt-6">

                                    <span
                                        class="inline-flex items-center gap-2 rounded-full bg-slate-100 px-4 py-2 text-xs font-medium text-slate-600"
                                    >

                                        <span>
                                            🚧
                                        </span>

                                        <span>
                                            Still under development
                                        </span>

                                    </span>

                                </div>

                            </div>

                        </div>


                        <!-- Possible Reports -->
                        <div class="mt-8">

                            <div class="mb-4">

                                <h3
                                    class="text-lg font-semibold text-slate-900"
                                >
                                    Possible Reports
                                </h3>

                                <p
                                    class="mt-1 text-sm text-slate-500"
                                >
                                    Some ideas that may be added later.
                                </p>

                            </div>


                            <div
                                class="grid grid-cols-1 gap-5 md:grid-cols-3"
                            >

                                <!-- Report Idea 1 -->
                                <div
                                    class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                                >

                                    <div
                                        class="flex h-11 w-11 items-center justify-center rounded-lg bg-slate-100 text-xl"
                                    >
                                        📊
                                    </div>

                                    <h4
                                        class="mt-4 font-semibold text-slate-900"
                                    >
                                        Concern Summary
                                    </h4>

                                    <p
                                        class="mt-2 text-sm leading-5 text-slate-500"
                                    >
                                        A summary of concerns by status,
                                        priority, organization, and date.
                                    </p>

                                    <div class="mt-4">

                                        <span
                                            class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-500"
                                        >
                                            Planned
                                        </span>

                                    </div>

                                </div>


                                <!-- Report Idea 2 -->
                                <div
                                    class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                                >

                                    <div
                                        class="flex h-11 w-11 items-center justify-center rounded-lg bg-slate-100 text-xl"
                                    >
                                        🏢
                                    </div>

                                    <h4
                                        class="mt-4 font-semibold text-slate-900"
                                    >
                                        Organization Report
                                    </h4>

                                    <p
                                        class="mt-2 text-sm leading-5 text-slate-500"
                                    >
                                        A report showing concern activity
                                        and workload for each organization.
                                    </p>

                                    <div class="mt-4">

                                        <span
                                            class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-500"
                                        >
                                            Planned
                                        </span>

                                    </div>

                                </div>


                                <!-- Report Idea 3 -->
                                <div
                                    class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                                >

                                    <div
                                        class="flex h-11 w-11 items-center justify-center rounded-lg bg-slate-100 text-xl"
                                    >
                                        ⏱️
                                    </div>

                                    <h4
                                        class="mt-4 font-semibold text-slate-900"
                                    >
                                        Resolution Report
                                    </h4>

                                    <p
                                        class="mt-2 text-sm leading-5 text-slate-500"
                                    >
                                        A report showing resolution times and
                                        completed concerns.
                                    </p>

                                    <div class="mt-4">

                                        <span
                                            class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-500"
                                        >
                                            Planned
                                        </span>

                                    </div>

                                </div>

                            </div>

                        </div>


                        <!-- Bottom Note -->
                        <div class="mt-6 text-center">

                            <p class="text-xs text-slate-400">
                                Reports will be added once the report
                                requirements are finalized.
                            </p>

                        </div>

                    </div>

                </template>

            </div>

        </main>

    </div>

</template>
