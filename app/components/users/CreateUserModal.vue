<script setup>

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
                class="flex items-center justify-between border-b border-slate-200 px-4 py-4 sm:px-6 sm:py-5"
            >

                <div>

                    <h3 class="text-lg font-semibold text-slate-800">
                        Add User
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        Create a new system user.
                    </p>

                </div>

                <button
                    type="button"
                    @click="emit('close')"
                    class="-poincursorter text-2xl leading-none text-slate-400 hover:text-slate-700"
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
                        class="w-full cursor-pointer rounded-lg bg-emerald-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-emerald-800 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
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
