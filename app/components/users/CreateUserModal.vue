<script setup>

import { useBodyScrollLock } from '~/composables/useBodyScrollLock'
import { roleDisplayName } from '~/composables/useRoleLabel'
import AppSelect from '~/components/AppSelect.vue'

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

const selectableRoles = computed(() =>
    (props.roles || []).filter((role) => role.name !== 'superadmin')
)

useBodyScrollLock(() => props.show)
const showSaveConfirmation = ref(false)

const confirmationMessage = computed(() => {
    const fullName = [props.form.first_name, props.form.last_name].filter(Boolean).join(' ').trim()
    const role = props.roles.find(item => Number(item.id) === Number(props.form.role_id))?.name
    const organization = props.organizations.find(item => Number(item.id) === Number(props.form.organization_id))?.name
    const details = [role, organization].filter(Boolean).join(' in ')

    return `Create the account for ${fullName || props.form.username || 'this user'}${details ? ` as ${details}` : ''}?`
})

function requestSubmit() {
    if (!props.saving) showSaveConfirmation.value = true
}

function confirmSubmit() {
    if (props.saving) return
    showSaveConfirmation.value = false
    emit('submit')
}

watch(() => props.show, (isShown) => {
    if (!isShown) showSaveConfirmation.value = false
})

</script>

<template>

    <div
        v-if="props.show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 p-2 backdrop-blur-[2px] sm:items-center sm:p-4"
    >

        <div
            class="modal-height-adaptive my-auto max-h-[calc(100dvh-1rem)] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-2rem)]"
        >

            <!-- Header -->
            <div
                class="modal-header-adaptive flex items-center justify-between gap-3 border-b border-slate-200 bg-white px-4 py-5 sm:px-6 sm:py-6"
            >

                <div class="flex items-center gap-3">

                    <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-blue-100 bg-blue-50 text-blue-800">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke-width="1.8" stroke="currentColor" class="h-6 w-6" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M18 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0ZM3.75 20.25a6.75 6.75 0 0 1 13.5 0v.75H3.75v-.75Z" />
                        </svg>
                    </span>

                    <div>

                    <h3 class="text-xl font-semibold text-slate-900">
                        Add User
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        Create a new system user.
                    </p>

                    </div>

                </div>

                <button
                    type="button"
                    @click="emit('close')"
                    aria-label="Close modal"
                    class="group relative flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center text-3xl leading-none text-red-700 transition-colors duration-200 hover:text-red-800"
                >
                    <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                        stroke="currentColor" aria-hidden="true"
                        class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                    </svg>
                </button>

            </div>

            <!-- Form -->
            <form
                @submit.prevent="requestSubmit"
                class="modal-form-content-adaptive modal-form-stack-adaptive modal-compact-fields space-y-5 px-4 py-5 sm:px-6 sm:py-6"
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

                        <AppSelect
                            v-model="props.form.role_id"
                            aria-label="Role"
                            name="role_id"
                            placeholder="Select role"
                            :required="true"
                            :options="[
                                { label: 'Select role', value: '', disabled: true },
                                ...selectableRoles.map(role => ({ label: roleDisplayName(role.name), value: role.id }))
                            ]"
                            @change="emit('role-change')"
                        />

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

                        <AppSelect
                            v-model="props.form.organization_id"
                            aria-label="Organization"
                            name="organization_id"
                            :placeholder="props.isSuperadminRole ? 'Not applicable' : 'Select organization'"
                            :disabled="props.isSuperadminRole"
                            :required="!props.isSuperadminRole"
                            :options="[
                                { label: props.isSuperadminRole ? 'Not applicable' : 'Select organization', value: '', disabled: !props.isSuperadminRole },
                                ...props.organizations.map(organization => ({ label: organization.name, value: organization.id }))
                            ]"
                        />

                    </div>

                </div>

                <!-- Footer -->
                <div
                    class="flex justify-end border-t border-slate-200 pt-5"
                >

                    <button
                        type="submit"
                        :disabled="props.saving"
                        class="primary-action-button w-full cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
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

        <ConfirmActionModal
            :show="showSaveConfirmation"
            title="Create this user?"
            :message="confirmationMessage"
            confirm-label="Create user"
            :loading="props.saving"
            @cancel="showSaveConfirmation = false"
            @confirm="confirmSubmit"
        />

    </div>

</template>
