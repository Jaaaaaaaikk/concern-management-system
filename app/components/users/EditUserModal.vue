<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'

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
    updating: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits([
    'close',
    'submit',
    'role-change'
])

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
        <div class="my-auto max-h-[calc(100dvh-1rem)] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-2rem)]">

            <div
                class="flex items-center justify-between border-b border-slate-200 px-4 py-4 sm:px-6 sm:py-5"
            >
                <div>
                    <h3 class="text-lg font-semibold text-slate-800">
                        Edit User
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        Update the selected user's information.
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
                                class="rounded-lg px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-50"
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
    </div>
</template>
