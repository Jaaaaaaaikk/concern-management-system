<script setup>

import { useBodyScrollLock } from '~/composables/useBodyScrollLock'

const props = defineProps({

    show: {
        type: Boolean,
        default: false
    },

    form: {
        type: Object,
        required: true
    },

    roles: {
        type: Array,
        default: () => []
    },

    organizations: {
        type: Array,
        default: () => []
    },

    isSuperadminRole: {
        type: Boolean,
        default: false
    },

    saving: {
        type: Boolean,
        default: false
    }

})

const emit = defineEmits([
    'close',
    'submit',
    'role-change'
])

useBodyScrollLock(() => props.show)

function roleLabel(role) {

    if (role === 'superadmin') {
        return 'Superadmin'
    }

    if (role === 'admin') {
        return 'Admin'
    }

    if (role === 'user') {
        return 'User'
    }

    return role || '-'

}

</script>

<template>

    <div
        v-if="props.show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 p-2 backdrop-blur-[2px] sm:items-center sm:p-4"
    >

        <div
            class="my-auto max-h-[calc(100dvh-1rem)] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-2rem)]"
        >

            <!-- Header -->
            <div
                class="flex items-center justify-between border-b border-blue-800 bg-linear-to-r from-blue-950 via-blue-900 to-indigo-800 px-4 py-5 text-white sm:px-6 sm:py-6"
            >

                <div class="flex items-center gap-3">

                    <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-white/15 bg-white/10 text-blue-100 shadow-inner">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke-width="1.8" stroke="currentColor" class="h-6 w-6" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M18 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0ZM3.75 20.25a6.75 6.75 0 0 1 13.5 0v.75H3.75v-.75Z" />
                        </svg>
                    </span>

                    <div>

                    <h3 class="text-lg font-bold tracking-tight text-white">
                        Add User
                    </h3>

                    <p class="mt-1 text-sm text-blue-100/80">
                        Create a new system user.
                    </p>

                    </div>

                </div>

                <button
                    type="button"
                    @click="emit('close')"
                    class="cursor-pointer rounded-lg p-1 text-2xl leading-none text-blue-100 transition hover:bg-white/10 hover:text-white"
                >
                    ×
                </button>

            </div>

            <!-- Form -->
            <form
                @submit.prevent="emit('submit')"
                class="space-y-5 px-4 py-5 sm:px-6 sm:py-6"
            >

                <!-- Username / Password -->
                <div class="grid gap-4 md:grid-cols-2">

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Username
                            <span class="text-red-500">*</span>
                        </label>

                        <input
                            v-model="props.form.username"
                            type="text"
                            placeholder="Enter username"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />

                    </div>

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Password
                            <span class="text-red-500">*</span>
                        </label>

                        <input
                            v-model="props.form.password"
                            type="password"
                            placeholder="Enter password"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />

                    </div>

                </div>

                <!-- Name -->
                <div class="grid gap-4 md:grid-cols-3">

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            First Name
                            <span class="text-red-500">*</span>
                        </label>

                        <input
                            v-model="props.form.first_name"
                            type="text"
                            placeholder="Enter first name"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />

                    </div>

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Middle Initial
                            <span class="text-slate-400">(Optional)</span>
                        </label>

                        <input
                            v-model="props.form.middle_name"
                            type="text"
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />

                    </div>

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Last Name
                            <span class="text-red-500">*</span>
                        </label>

                        <input
                            v-model="props.form.last_name"
                            type="text"
                            placeholder="Enter last name"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />

                    </div>

                </div>

                <!-- Role / Organization -->
                <div class="grid gap-4 md:grid-cols-2">

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Role
                            <span class="text-red-500">*</span>
                        </label>

                        <select
                            v-model="props.form.role_id"
                            @change="emit('role-change')"
                            required
                            class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        >

                            <option value="" disabled>
                                Select role
                            </option>

                            <option
                                v-for="role in props.roles"
                                :key="role.id"
                                :value="role.id"
                            >
                                {{ roleLabel(role.name) }}
                            </option>

                        </select>

                    </div>

                    <div>

                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Organization
                            <span
                                v-if="!props.isSuperadminRole"
                                class="text-red-500"
                            >
                                *
                            </span>
                            <span
                                v-else
                                class="text-slate-400"
                            >
                                (Not applicable)
                            </span>
                        </label>

                        <select
                            v-model="props.form.organization_id"
                            :disabled="props.isSuperadminRole"
                            :required="!props.isSuperadminRole"
                            class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100 disabled:cursor-not-allowed disabled:bg-slate-100"
                        >

                            <option value="">

                                {{
                                    props.isSuperadminRole
                                        ? 'Not applicable'
                                        : 'Select organization'
                                }}

                            </option>

                            <option
                                v-for="organization in props.organizations"
                                :key="organization.id"
                                :value="organization.id"
                            >
                                {{ organization.name }}
                            </option>

                        </select>

                    </div>

                </div>

                <!-- Footer -->
                <div
                    class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end"
                >

                    <button
                        type="button"
                        @click="emit('close')"
                        :disabled="props.saving"
                        class="w-full cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                    >
                        Cancel
                    </button>

                    <button
                        type="submit"
                        :disabled="props.saving"
                        class="w-full cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                    >

                        {{
                            props.saving
                                ? 'Creating...'
                                : 'Create User'
                        }}

                    </button>

                </div>

            </form>

        </div>

    </div>

</template>
