<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useBodyScrollLock } from '~/composables/useBodyScrollLock'
import { roleDisplayName } from '~/composables/useRoleLabel'

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
    isCurrentUser: {
        type: Boolean,
        default: false
    },
    updating: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits([
    'close',
    'submit',
    'role-change',
    'status-toggle'
])

useBodyScrollLock(() => props.show)

const showSaveConfirmation = ref(false)

function requestSubmit() {
    if (!props.updating) showSaveConfirmation.value = true
}

function confirmSubmit() {
    if (props.updating) return
    showSaveConfirmation.value = false
    emit('submit')
}

watch(() => props.show, (isShown) => {
    if (!isShown) showSaveConfirmation.value = false
})

const photoPreview = ref('')
let photoPreviewUrl = null

const profileInitials = computed(() => {
    const initials = [
        props.form.first_name,
        props.form.last_name
    ]
        .filter(Boolean)
        .map((name) => name.trim().charAt(0))
        .join('')
        .toUpperCase()

    return initials || 'U'
})

function releasePhotoPreview() {
    if (photoPreviewUrl) {
        URL.revokeObjectURL(photoPreviewUrl)
        photoPreviewUrl = null
    }

    photoPreview.value = ''
}

function handleProfilePhotoChange(event) {
    const file = event.target.files?.[0]

    if (!file) {
        return
    }

    releasePhotoPreview()
    props.form.profile_photo_file = file
    props.form.profile_photo_remove = false
    photoPreviewUrl = URL.createObjectURL(file)
    photoPreview.value = photoPreviewUrl
    event.target.value = ''
}

function removeProfilePhoto() {
    releasePhotoPreview()
    props.form.profile_photo_file = null
    props.form.profile_photo_remove = true
}

watch(
    () => props.form,
    releasePhotoPreview
)

onBeforeUnmount(releasePhotoPreview)

</script>

<template>
    <div
        v-if="props.show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 p-2 backdrop-blur-[2px] sm:items-center sm:p-4"
    >
        <div class="my-auto max-h-[calc(100dvh-1rem)] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-2rem)]">

            <div
                class="flex items-center justify-between border-b border-blue-800 bg-linear-to-r from-blue-950 to-blue-800 px-4 py-4 text-white sm:px-6 sm:py-5"
            >
                <div>
                    <h3 class="text-lg font-semibold text-white">
                        Edit User
                    </h3>

                    <p class="mt-1 text-sm text-blue-100/80">
                        Manage profile, access, and account status.
                    </p>
                </div>

                <button
                    type="button"
                    @click="emit('close')"
                    class="cursor-pointer rounded-lg p-1 text-2xl leading-none text-blue-100 transition hover:bg-white/10 hover:text-white"
                >
                    ×
                </button>
            </div>

            <form
                @submit.prevent="requestSubmit"
                class="space-y-5 px-4 py-5 sm:px-6 sm:py-6"
            >

                <div class="flex flex-col gap-4 rounded-xl border border-blue-100 bg-blue-50/60 p-4 sm:flex-row sm:items-center">
                    <div class="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-full bg-blue-900 text-lg font-semibold text-white ring-4 ring-white">
                        <img
                            v-if="photoPreview || (!props.form.profile_photo_remove && props.form.profile_photo_url)"
                            :src="photoPreview || props.form.profile_photo_url"
                            alt="User profile photo"
                            class="h-full w-full object-cover"
                        />
                        <span v-else>{{ profileInitials }}</span>
                    </div>
                    <div class="min-w-0 flex-1">
                        <label for="user-profile-photo" class="block text-sm font-semibold text-slate-800">
                            Profile photo
                        </label>
                        <p class="mt-1 text-xs leading-5 text-slate-500">
                            JPEG, PNG, GIF, or WEBP. Maximum size: 2 MB.
                        </p>
                        <div class="mt-3 flex flex-wrap gap-2">
                            <label
                                for="user-profile-photo"
                                class="cursor-pointer rounded-lg border border-blue-900/20 bg-white px-3 py-2 text-xs font-semibold text-blue-950 transition hover:bg-blue-50"
                            >
                                {{ photoPreview || props.form.profile_photo_url ? 'Choose another photo' : 'Choose photo' }}
                            </label>
                            <button
                                v-if="props.form.profile_photo_url && !props.form.profile_photo_remove"
                                type="button"
                                class="cursor-pointer rounded-lg px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-50"
                                @click="removeProfilePhoto"
                            >
                                Remove photo
                            </button>
                        </div>
                        <input
                            id="user-profile-photo"
                            type="file"
                            accept="image/jpeg,image/png,image/gif,image/webp"
                            class="sr-only"
                            @change="handleProfilePhotoChange"
                        />
                    </div>
                </div>

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
                            New Password
                        </label>

                        <input
                            v-model="props.form.password"
                            type="password"
                            placeholder="Leave blank to keep current password"
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
                                {{ roleDisplayName(role.name) }}
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

                <section class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <p class="text-sm font-semibold text-slate-800">Account access</p>
                            <p class="mt-1 text-xs leading-5 text-slate-500">
                                {{ props.form.status === 'active'
                                    ? 'This user can currently sign in.'
                                    : 'This user is inactive and cannot sign in.' }}
                            </p>
                        </div>
                        <button
                            v-if="!props.isCurrentUser"
                            type="button"
                            :disabled="props.updating"
                            @click="emit('status-toggle')"
                            :class="props.form.status === 'active'
                                ? 'border-red-200 bg-white text-red-700 hover:bg-red-50'
                                : 'border-green-200 bg-white text-green-700 hover:bg-green-50'"
                            class="cursor-pointer rounded-lg border px-4 py-2.5 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{ props.form.status === 'active' ? 'Deactivate User' : 'Activate User' }}
                        </button>
                        <span v-else class="rounded-full bg-blue-100 px-3 py-1.5 text-xs font-semibold text-blue-800">
                            Signed-in account
                        </span>
                    </div>
                </section>

                <div
                    class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end"
                >

                    <button
                        type="button"
                        @click="emit('close')"
                        :disabled="props.updating"
                        class="cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        Cancel
                    </button>

                    <button
                        type="submit"
                        :disabled="props.updating"
                        class="w-full cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50 sm:w-auto"
                    >
                        {{
                            props.updating
                                ? 'Saving...'
                                : 'Save Changes'
                        }}
                    </button>

                </div>

            </form>
        </div>

        <ConfirmActionModal
            :show="showSaveConfirmation"
            title="Save user changes?"
            :message="`Save the updated account details for ${[props.form.first_name, props.form.last_name].filter(Boolean).join(' ') || props.form.username || 'this user'}?`"
            confirm-label="Save changes"
            :loading="props.updating"
            @cancel="showSaveConfirmation = false"
            @confirm="confirmSubmit"
        />
    </div>
</template>
