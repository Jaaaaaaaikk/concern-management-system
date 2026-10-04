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
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
    >
        <div class="w-full max-w-2xl rounded-xl bg-white shadow-xl">

            <div
                class="flex items-center justify-between border-b border-slate-200 px-6 py-5"
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
                    class="cursor-pointer text-2xl leading-none text-slate-400 hover:text-slate-700"
                >
                    ×
                </button>
            </div>

            <form
                @submit.prevent="emit('submit')"
                class="space-y-5 px-6 py-6"
            >

                <div class="grid gap-4 md:grid-cols-2">

                    <div>
                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Username
                        </label>

                        <input
                            v-model="props.form.username"
                            type="text"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />
                    </div>

                    <div>
                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Password
                        </label>

                        <input
                            v-model="props.form.password"
                            type="password"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />
                    </div>

                </div>

                <div class="grid gap-4 md:grid-cols-3">

                    <div>
                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            First Name
                        </label>

                        <input
                            v-model="props.form.first_name"
                            type="text"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />
                    </div>

                    <div>
                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Middle Name
                        </label>

                        <input
                            v-model="props.form.middle_name"
                            type="text"
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />
                    </div>

                    <div>
                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Last Name
                        </label>

                        <input
                            v-model="props.form.last_name"
                            type="text"
                            required
                            class="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-100"
                        />
                    </div>

                </div>

                <div class="grid gap-4 md:grid-cols-2">

                    <div>
                        <label
                            class="mb-2 block text-sm font-medium text-slate-700"
                        >
                            Role
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

                <div
                    class="flex justify-end gap-3 border-t border-slate-200 pt-5"
                >

                    <button
                        type="button"
                        @click="emit('close')"
                        :disabled="props.saving"
                        class="cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        Cancel
                    </button>

                    <button
                        type="submit"
                        :disabled="props.saving"
                        class="cursor-pointer rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
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
