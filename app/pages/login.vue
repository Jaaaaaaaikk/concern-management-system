<script setup>
import { ref } from 'vue'

definePageMeta({
    layout: false
})

const showPassword = ref(false)

const username = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

async function login() {
    errorMessage.value = ''

    if (!username.value || !password.value) {
        errorMessage.value = 'Please enter your username and password.'
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

        await navigateTo('/dashboard')
    } catch (error) {
        if (error?.statusCode === 403) {
            await navigateTo('/account-deactivated')
            return
        }

        errorMessage.value =
            error?.data?.statusMessage ||
            error?.data?.message ||
            'Login failed. Please check your username and password.'
    } finally {
        loading.value = false
    }
}

function clearLoginError() {
    errorMessage.value = ''
    showPassword.value = false
}
</script>

<template>
    <div class="min-h-screen bg-gray-100 flex items-center justify-center px-4">
        <div class="w-full max-w-md">
            <div class="bg-white rounded-2xl shadow-lg p-8">
                <div class="text-center mb-8">
                    <h1 class="text-2xl font-bold text-gray-900">
                        Concern Management System
                    </h1>

                    <p class="mt-2 text-sm text-gray-500">
                        Sign in to your account
                    </p>
                </div>

                <form @submit.prevent="login" class="space-y-5">
                    <div>
                        <label for="username" class="block text-sm font-medium text-gray-700 mb-1">
                            Username
                        </label>

                        <input id="username" v-model="username" @input="clearLoginError" type="text"
                            autocomplete="username"
                            class="w-full rounded-lg border border-gray-300 px-4 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                            placeholder="Enter username" />
                    </div>


                    <div>
                        <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
                            Password
                        </label>

                        <div class="relative">
                            <input id="password" v-model="password" @input="clearLoginError"
                                :type="showPassword ? 'text' : 'password'" autocomplete="current-password"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2.5 pr-12 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                                placeholder="Enter password" />

                            <button type="button" @click="showPassword = !showPassword"
                                class="absolute inset-y-0 right-0 flex items-center px-4 text-gray-500 hover:text-gray-700"
                                :aria-label="showPassword ? 'Hide password' : 'Show password'">
                                <!-- Show password -->
                                <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" fill="none"
                                    viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                        d="M2.036 12.322a1.012 1.012 0 010-.644C3.423 7.51 7.36 5 12 5c4.64 0 8.577 2.51 9.964 6.678.07.21.07.434 0 .644C20.577 16.49 16.64 19 12 19c-4.64 0-8.577-2.51-9.964-6.678z" />
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                </svg>

                                <!-- Hide password -->
                                <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke-width="1.5" stroke="currentColor" class="h-5 w-5">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                        d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.3 19 12 19c1.655 0 3.22-.36 4.62-1.006M6.228 6.228A10.45 10.45 0 0112 5c4.7 0 8.773 2.662 10.065 7a10.523 10.523 0 01-4.293 5.274M6.228 6.228L3 3m3.228 3.228l3.65 3.65m0 0a3 3 0 104.243 4.243m-4.243-4.243l4.243 4.243m0 0L21 21" />
                                </svg>
                            </button>
                        </div>
                    </div>



                    <div v-if="errorMessage"
                        class="rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                        {{ errorMessage }}
                    </div>

                    <button type="submit" :disabled="loading"
                        class="w-full rounded-lg bg-blue-600 px-4 py-2.5 font-medium text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50">
                        {{ loading ? 'Signing in...' : 'Sign In' }}
                    </button>
                </form>
            </div>
        </div>
    </div>
</template>