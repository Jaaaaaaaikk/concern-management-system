<script setup>
import { ref } from 'vue'
import { useToast } from '~/composables/useToast'

definePageMeta({
    layout: false
})

const showPassword = ref(false)
const username = ref('')
const password = ref('')
const loading = ref(false)
const { showToast } = useToast()
const currentYear = new Date().getFullYear()

const headers = import.meta.server
    ? useRequestHeaders(['cookie'])
    : undefined

try {
    await $fetch('/api/auth/me', {
        headers,
        cache: 'no-store'
    })

    await navigateTo('/dashboard')
} catch (error) {
    const statusCode = error?.statusCode ?? error?.response?.status

    if (statusCode !== 401) {
        throw error
    }
}

async function login() {
    if (!username.value || !password.value) {
        showToast('Please enter your username and password.', 'error')
        return
    }

    loading.value = true

    try {
        await $fetch('/api/auth/login', {
            method: 'POST',
            body: {
                username: username.value,
                password: password.value
            }
        })

        showToast('You have signed in successfully.')
        await navigateTo('/dashboard')
    } catch (error) {
        if (error?.statusCode === 403) {
            await navigateTo('/account-deactivated')
            return
        }

        showToast(
            error?.data?.statusMessage ||
            error?.data?.message ||
            'Login failed. Please check your username and password.',
            'error'
        )
    } finally {
        loading.value = false
    }
}

</script>

<template>
    <main class="relative flex min-h-screen items-start justify-center overflow-hidden bg-[#eef3f1] px-4 py-8 sm:px-6 lg:items-center lg:px-8">
        <div class="pointer-events-none absolute -left-24 -top-24 h-80 w-80 rounded-full bg-emerald-100/70 blur-3xl"></div>
        <div class="pointer-events-none absolute -bottom-32 -right-16 h-96 w-96 rounded-full bg-teal-100/70 blur-3xl"></div>

        <section class="relative flex w-full max-w-6xl flex-col-reverse overflow-hidden rounded-[28px] border border-slate-200 bg-white shadow-[0_28px_90px_-35px_rgba(15,57,52,0.42)] lg:min-h-[650px] lg:flex-row">
            <div class="flex w-full flex-col justify-center px-7 py-10 sm:px-12 sm:py-12 lg:w-[48%] lg:px-14">
                <div class="mb-10 flex items-center gap-3">
                    <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-emerald-900 text-white shadow-lg shadow-emerald-900/15">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" class="h-6 w-6" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 20.25h16.5M5.25 20.25V5.5l6.75-2.25v17m0-12.75 6.75-2.25v15M8.25 8.25v.01M8.25 11.25v.01M8.25 14.25v.01M14.25 9.75v.01M17.25 8.75v.01M14.25 12.75v.01M17.25 11.75v.01M14.25 15.75v.01M17.25 14.75v.01" />
                        </svg>
                    </div>
                    <div>
                        <p class="text-sm font-bold tracking-wide text-slate-900">FELCRIS</p>
                        <p class="text-xs font-medium tracking-[0.14em] text-slate-500">CONCERN MANAGEMENT</p>
                    </div>
                </div>

                <div class="mb-8">
                    <p class="mb-3 text-sm font-semibold uppercase tracking-[0.18em] text-emerald-800">Welcome back</p>
                    <h1 class="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">Sign in to your account</h1>
                    <p class="mt-3 max-w-sm text-sm leading-6 text-slate-500">
                        Manage concerns and stay connected with your organization.
                    </p>
                </div>

                <form @submit.prevent="login" class="space-y-5">
                    <div>
                        <label for="username" class="mb-2 block text-sm font-semibold text-slate-700">Username</label>
                        <input
                            id="username"
                            v-model="username"
                            type="text"
                            autocomplete="username"
                            required
                            placeholder="Enter your username"
                            class="w-full rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3.5 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-emerald-700 focus:bg-white focus:ring-4 focus:ring-emerald-800/10"
                        />
                    </div>

                    <div>
                        <label for="password" class="mb-2 block text-sm font-semibold text-slate-700">Password</label>
                        <div class="relative">
                            <input
                                id="password"
                                v-model="password"
                                :type="showPassword ? 'text' : 'password'"
                                autocomplete="current-password"
                                required
                                placeholder="Enter your password"
                                class="w-full rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3.5 pr-12 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-emerald-700 focus:bg-white focus:ring-4 focus:ring-emerald-800/10"
                            />
                            <button
                                type="button"
                                @click="showPassword = !showPassword"
                                class="absolute inset-y-0 right-0 flex items-center px-4 text-slate-400 transition hover:text-emerald-800"
                                :aria-label="showPassword ? 'Hide password' : 'Show password'"
                            >
                                <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor" class="h-5 w-5" aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.644C3.423 7.51 7.36 5 12 5c4.64 0 8.577 2.51 9.964 6.678.07.21.07.434 0 .644C20.577 16.49 16.64 19 12 19c-4.64 0-8.577-2.51-9.964-6.678z" />
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                </svg>
                                <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor" class="h-5 w-5" aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.3 19 12 19c1.655 0 3.22-.36 4.62-1.006M6.228 6.228A10.45 10.45 0 0112 5c4.7 0 8.773 2.662 10.065 7a10.523 10.523 0 01-4.293 5.274M6.228 6.228L3 3m3.228 3.228l3.65 3.65m0 0a3 3 0 104.243 4.243m-4.243-4.243l4.243 4.243m0 0L21 21" />
                                </svg>
                            </button>
                        </div>
                    </div>

                    <button
                        type="submit"
                        :disabled="loading"
                        class="flex w-full items-center justify-center gap-2 rounded-xl bg-emerald-900 px-5 py-3.5 text-sm font-semibold text-white shadow-lg shadow-emerald-900/15 transition hover:bg-emerald-800 focus:outline-none focus:ring-4 focus:ring-emerald-800/20 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        <svg v-if="loading" class="h-4 w-4 animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" aria-hidden="true">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                        </svg>
                        {{ loading ? 'Signing in...' : 'Sign In' }}
                    </button>
                </form>

                <p class="mt-10 text-xs leading-5 text-slate-400">
                    Your account and organization information are protected by secure sign-in.
                </p>
                <p class="mt-2 text-xs leading-5 text-slate-400">
                    © {{ currentYear }} Felcris Hotels &amp; Resorts Corporation. All rights reserved. · ICT Department
                </p>
            </div>

            <div class="relative flex min-h-[230px] w-full flex-col overflow-hidden bg-emerald-950 sm:min-h-[300px] lg:min-h-0 lg:w-[52%]">
                <img
                    src="/images/felcris-building.jpg"
                    alt="Felcris building overlooking the coastline"
                    class="h-auto w-full object-contain object-center"
                />
                <div class="p-6 text-white sm:p-8 lg:p-10">
                    <div class="mb-3 inline-flex items-center gap-2 rounded-full border border-white/25 bg-white/10 px-3 py-1.5 text-xs font-medium">
                        <span class="h-1.5 w-1.5 rounded-full bg-emerald-300"></span>
                        Felcris Hotels &amp; Resorts
                    </div>
                    <h2 class="max-w-md text-xl font-semibold leading-tight sm:text-2xl">
                        Better communication. Better care.
                    </h2>
                    <p class="mt-2 max-w-sm text-sm leading-6 text-white/80">
                        A connected place to raise, track, and resolve concerns.
                    </p>
                </div>
            </div>
        </section>
    </main>
</template>
