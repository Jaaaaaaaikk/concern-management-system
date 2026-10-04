<script setup>

definePageMeta({
    layout: false
})

async function goToLogin() {
    await navigateTo('/login')
}

</script>

<template>
    <div class="flex min-h-screen items-center justify-center bg-gray-100 px-4">
        <div class="w-full max-w-md">
            <div class="rounded-2xl bg-white p-8 text-center shadow-lg">

                <div
                    class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-red-100"
                >
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.8"
                        stroke="currentColor"
                        class="h-8 w-8 text-red-600"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M12 9v3.75m0 3.75h.008v.008H12v-.008z"
                        />
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"
                        />
                    </svg>
                </div>

                <h1 class="mt-6 text-2xl font-bold text-gray-900">
                    Account Deactivated
                </h1>

                <p class="mt-3 text-sm leading-6 text-gray-600">
                    Your account has been deactivated and you cannot access
                    the Concern Management System at this time.
                </p>

                <p class="mt-3 text-sm leading-6 text-gray-500">
                    Please contact your administrator if you believe this
                    was done by mistake.
                </p>

                <button
                    type="button"
                    @click="goToLogin"
                    class="mt-7 w-full rounded-lg bg-blue-600 px-4 py-2.5 font-medium text-white transition hover:bg-blue-700"
                >
                    Back to Login
                </button>

            </div>
        </div>
    </div>
</template>
