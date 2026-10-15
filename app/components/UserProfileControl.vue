<script setup>
import { computed, ref } from 'vue'
import ProfileActionsModal from '~/components/ProfileActionsModal.vue'
import { useToast } from '~/composables/useToast'
import { roleDisplayName } from '~/composables/useRoleLabel'

const props = defineProps({
    currentUser: {
        type: Object,
        default: null
    },
    mobile: {
        type: Boolean,
        default: false
    },
    showAvatar: {
        type: Boolean,
        default: true
    },
    showOrganization: {
        type: Boolean,
        default: true
    }
})

const emit = defineEmits(['logout', 'profile-updated'])
const { showToast } = useToast()
const uploading = ref(false)
const showRemovePhotoConfirmation = ref(false)
const showChangePassword = ref(false)
const showProfileDetails = ref(false)
const isExpanded = ref(false)
const changingPassword = ref(false)
const passwordForm = ref({
    current: '',
    next: '',
    confirm: ''
})
const photoInput = ref(null)

const displayName = computed(() => {
    const name = [
        props.currentUser?.first_name,
        props.currentUser?.last_name
    ].filter(Boolean).join(' ').trim()

    return name || props.currentUser?.username || 'Signed-in user'
})

const canChangePassword = computed(() =>
    ['concern_handler', 'system_monitor', 'requestor'].includes(props.currentUser?.role_name)
)

async function updatePhoto(file, remove = false) {
    if (uploading.value) {
        return
    }

    if (!remove) {
        const allowedTypes = [
            'image/jpeg',
            'image/png',
            'image/gif',
            'image/webp'
        ]

        if (!allowedTypes.includes(file.type)) {
            showToast('Choose a JPEG, PNG, GIF, or WEBP image.', 'error')
            return
        }

        if (file.size > 2 * 1024 * 1024) {
            showToast('Profile photos must be 2 MB or smaller.', 'error')
            return
        }
    }

    uploading.value = true
    const formData = new FormData()

    if (remove) {
        formData.append('remove', 'true')
    } else {
        formData.append('photo', file)
    }

    try {
        const response = await $fetch(
            `/api/users/${props.currentUser.id}/profile-photo`,
            {
                method: 'PUT',
                body: formData
            }
        )

        emit('profile-updated', response.profile_photo || '')
        showToast(response.message || 'Profile photo updated successfully.')
    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to update profile photo.',
            'error'
        )
    } finally {
        uploading.value = false
        if (photoInput.value) {
            photoInput.value.value = ''
        }
    }
}

function handlePhotoChange(event) {
    const file = event.target.files?.[0]

    if (file) {
        updatePhoto(file)
    }
}

function confirmPhotoRemoval() {
    showRemovePhotoConfirmation.value = false
    updatePhoto(null, true)
}

function openPasswordForm() {
    if (!canChangePassword.value) return

    passwordForm.value = { current: '', next: '', confirm: '' }
    showChangePassword.value = true
}

function closePasswordForm() {
    if (changingPassword.value) return
    showChangePassword.value = false
    passwordForm.value = { current: '', next: '', confirm: '' }
}

async function changePassword() {
    if (changingPassword.value) return

    if (passwordForm.value.next.length < 8) {
        showToast('New password must be at least 8 characters long.', 'error')
        return
    }

    if (passwordForm.value.next !== passwordForm.value.confirm) {
        showToast('The new password and confirmation do not match.', 'error')
        return
    }

    changingPassword.value = true

    try {
        const response = await $fetch('/api/auth/password', {
            method: 'PUT',
            body: {
                current_password: passwordForm.value.current,
                new_password: passwordForm.value.next
            }
        })

        changingPassword.value = false
        closePasswordForm()
        showToast(response.message || 'Password changed successfully.')
    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to change password.',
            'error'
        )
    } finally {
        changingPassword.value = false
    }
}
</script>

<template>
    <div v-if="currentUser && mobile" class="w-full rounded-lg bg-white p-1.5">
        <div class="flex flex-col">
            <label :for="`profile-photo-${currentUser?.id}`" class="flex min-h-9 cursor-pointer items-center gap-2 rounded-md px-2 text-left text-xs font-semibold text-blue-800 transition hover:bg-blue-50">
                <span>{{ uploading ? 'Saving photo…' : currentUser?.profile_photo ? 'Change photo' : 'Add photo' }}</span>
            </label>
            <button v-if="canChangePassword" type="button" class="flex min-h-9 cursor-pointer items-center gap-2 rounded-md px-2 text-left text-xs font-semibold text-blue-800 transition hover:bg-blue-50" @click="openPasswordForm">
                Change password
            </button>
            <button v-if="currentUser?.profile_photo" type="button" :disabled="uploading" class="secondary-hover-button flex min-h-9 cursor-pointer items-center gap-2 rounded-md px-2 text-left text-xs font-medium text-red-700 transition hover:bg-red-50 disabled:opacity-50" @click="showRemovePhotoConfirmation = true">
                Remove photo
            </button>
            <button type="button" class="mt-1 flex min-h-9 w-full items-center gap-2 border-t border-slate-100 px-2 pt-1 text-left text-xs font-semibold text-red-700 transition hover:bg-red-50 hover:text-red-900" @click="emit('logout')">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6A2.25 2.25 0 0 0 5.25 5.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3-3H9m0 0 3-3m-3 3 3 3" />
                </svg>
                Logout
            </button>
        </div>

        <input
            :id="`profile-photo-${currentUser?.id}`"
            ref="photoInput"
            type="file"
            accept="image/jpeg,image/png,image/gif,image/webp"
            class="sr-only"
            :disabled="uploading"
            @change="handlePhotoChange"
        />
    </div>

    <div
        v-else-if="currentUser"
        class="profile-control-frame relative isolate min-w-0 overflow-hidden rounded-xl p-0.5"
    >
        <span class="profile-control-edge" aria-hidden="true"></span>
        <div class="relative z-10 min-w-0 overflow-hidden rounded-[10px] bg-blue-950 shadow-2xl shadow-black/45">
        <button
            type="button"
            data-tour="profile-menu-toggle"
            class="group flex w-full cursor-pointer items-center gap-2.5 bg-linear-to-r from-blue-800 via-blue-900 to-blue-950 px-3 py-3 text-left transition hover:brightness-110 focus:outline-none sm:px-3.5 sm:py-3"
            :aria-expanded="isExpanded"
            @click="isExpanded = !isExpanded"
        >
            <span class="relative shrink-0 rounded-full group-focus-visible:ring-2 group-focus-visible:ring-blue-300 group-focus-visible:ring-offset-2 group-focus-visible:ring-offset-blue-900">
                <UserAvatar
                    v-if="props.showAvatar"
                    :name="displayName"
                    :photo-url="currentUser?.profile_photo"
                    size="h-11 w-11 text-sm"
                        class="ring-2 ring-white/70"
                />
                <span v-if="props.showAvatar" class="absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-blue-900 bg-emerald-400"></span>
            </span>

            <span class="min-w-0 flex-1">
                <span class="line-clamp-2 whitespace-normal wrap-break-word text-xs font-bold leading-tight text-white sm:text-sm">{{ displayName }}</span>
                <span class="mt-0.5 block truncate text-[11px] font-semibold text-blue-200 sm:text-xs">{{ roleDisplayName(currentUser?.role_name) }}</span>
                <span v-if="props.showOrganization && currentUser?.organization_name" class="mt-0.5 block truncate text-[10px] text-blue-100/75 sm:text-[11px]" :title="currentUser.organization_name">{{ currentUser.organization_name }}</span>
            </span>

            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.4" stroke="currentColor" class="h-5 w-5 shrink-0 text-blue-100 transition-transform duration-200" :class="isExpanded ? 'rotate-180' : ''" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="m6 9 6 6 6-6" />
            </svg>
        </button>

        <Transition
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="-translate-y-1 opacity-0"
            enter-to-class="translate-y-0 opacity-100"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="translate-y-0 opacity-100"
            leave-to-class="-translate-y-1 opacity-0"
        >
            <div v-if="isExpanded" class="space-y-0.5 bg-blue-950 px-2 py-2 sm:px-2.5 sm:py-2.5">
                <button
                    type="button"
                    data-tour="profile-menu-item"
                    class="group flex w-full cursor-pointer items-center gap-2.5 rounded-lg px-2.5 py-2 text-left transition hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-slate-300"
                    @click="showProfileDetails = true"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5 shrink-0 text-blue-200" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6.75a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.5 20.25a7.5 7.5 0 0 1 15 0v.75h-15v-.75Z" />
                    </svg>
                    <span class="min-w-0 flex-1">
                        <span class="block truncate text-[11px] font-semibold text-blue-50 sm:text-xs">View Profile</span>
                        <span class="mt-0.5 block truncate text-[9px] text-blue-200/75 sm:text-[10px]">Manage your account information</span>
                    </span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4 shrink-0 text-blue-200 transition-transform group-hover:translate-x-0.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="m9 5 7 7-7 7" /></svg>
                </button>

                <label
                    :for="`profile-photo-${currentUser?.id}`"
                    class="group flex cursor-pointer items-center gap-2.5 rounded-lg px-2.5 py-2 transition hover:bg-white/10 focus-within:ring-2 focus-within:ring-blue-300"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5 shrink-0 text-blue-200" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3 7.5A1.5 1.5 0 0 1 4.5 6h2.379a1.5 1.5 0 0 0 1.06-.44l.622-.62A1.5 1.5 0 0 1 9.621 4.5h4.758a1.5 1.5 0 0 1 1.06.44l.622.62a1.5 1.5 0 0 0 1.06.44H19.5A1.5 1.5 0 0 1 21 7.5v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-10Z" />
                        <circle cx="12" cy="12" r="3.25" />
                    </svg>
                    <span class="min-w-0 flex-1">
                        <span class="block truncate text-[11px] font-semibold text-blue-50 sm:text-xs">{{ currentUser?.profile_photo ? 'Change Profile Photo' : 'Add Profile Photo' }}</span>
                        <span class="mt-0.5 block truncate text-[9px] text-blue-200/75 sm:text-[10px]">{{ uploading ? 'Updating your picture…' : 'Update your profile picture' }}</span>
                    </span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4 shrink-0 text-blue-200 transition-transform group-hover:translate-x-0.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="m9 5 7 7-7 7" /></svg>
                </label>

                <button
                    v-if="canChangePassword"
                    type="button"
                    class="group flex w-full cursor-pointer items-center gap-2.5 rounded-lg px-2.5 py-2 text-left transition hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-blue-300"
                    @click="openPasswordForm"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5 shrink-0 text-blue-200" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V7.875a4.5 4.5 0 0 0-9 0V10.5m-1.125 0h11.25A1.875 1.875 0 0 1 19.5 12.375v6.75A1.875 1.875 0 0 1 17.625 21h-11.25A1.875 1.875 0 0 1 4.5 19.125v-6.75A1.875 1.875 0 0 1 6.375 10.5Zm5.625 4.125v2.25" />
                    </svg>
                    <span class="min-w-0 flex-1">
                        <span class="block truncate text-[11px] font-semibold text-blue-50 sm:text-xs">Change Password</span>
                        <span class="mt-0.5 block truncate text-[9px] text-blue-200/75 sm:text-[10px]">Keep your account secure</span>
                    </span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4 shrink-0 text-blue-200 transition-transform group-hover:translate-x-0.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="m9 5 7 7-7 7" /></svg>
                </button>

                <button
                    v-if="currentUser?.profile_photo"
                    type="button"
                    :disabled="uploading"
                    class="secondary-hover-button w-full cursor-pointer rounded-lg px-2.5 py-1 text-left text-[9px] font-medium text-rose-200 transition hover:bg-rose-500/10 hover:text-rose-100 disabled:cursor-not-allowed disabled:opacity-50"
                    @click="showRemovePhotoConfirmation = true"
                >
                    Remove profile photo
                </button>

                <div class="my-1.5 border-t border-blue-300/15"></div>

                <button
                    type="button"
                    class="group flex w-full cursor-pointer items-center gap-2.5 rounded-lg border border-rose-500/40 bg-rose-500/10 px-2.5 py-2 text-left transition hover:border-rose-400/70 hover:bg-rose-500/20 focus:outline-none focus:ring-2 focus:ring-rose-300"
                    @click="emit('logout')"
                >
                    <span class="relative h-5 w-5 shrink-0 text-rose-400" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="absolute inset-0 h-5 w-5 transition duration-200 group-hover:scale-75 group-hover:opacity-0">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6A2.25 2.25 0 0 0 5.25 5.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3-3H9m0 0 3-3m-3 3 3 3" />
                        </svg>
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" class="absolute inset-0 h-5 w-5 scale-75 opacity-0 transition duration-200 group-hover:scale-100 group-hover:opacity-100">
                            <g transform="translate(24 0) scale(-1 1)">
                                <g class="logout-runner-body">
                                    <circle cx="16" cy="5" r="2" />
                                    <path d="m14.5 8-3 5 4 1.5 2.5-3" />
                                </g>
                                <path class="logout-runner-arm logout-runner-arm-front" d="m13 9 4 1.5 2-2" />
                                <path class="logout-runner-arm logout-runner-arm-back" d="m13 9-3-1.5-2 2" />
                                <path class="logout-runner-leg logout-runner-leg-front" d="m12 13-2 4 4 2" />
                                <path class="logout-runner-leg logout-runner-leg-back" d="m12 13-4 2-2 3" />
                            </g>
                        </svg>
                    </span>
                    <span class="min-w-0 flex-1">
                        <span class="block text-[11px] font-semibold text-rose-300 sm:text-xs">Logout</span>
                        <span class="mt-0.5 block text-[9px] text-blue-200/75 sm:text-[10px]">Sign out from your account</span>
                    </span>
                </button>
            </div>
        </Transition>
        </div>

        <input
            :id="`profile-photo-${currentUser?.id}`"
            ref="photoInput"
            type="file"
            accept="image/jpeg,image/png,image/gif,image/webp"
            class="sr-only"
            :disabled="uploading"
            @change="handlePhotoChange"
        />

        <ProfileActionsModal
            :current-user="currentUser"
            :show-profile="showProfileDetails"
            :show-password="showChangePassword"
            :show-remove-photo="showRemovePhotoConfirmation"
            :password-form="passwordForm"
            :changing-password="changingPassword"
            :uploading="uploading"
            @close-profile="showProfileDetails = false"
            @submit-password="changePassword"
            @cancel-password="closePasswordForm"
            @confirm-remove-photo="confirmPhotoRemoval"
            @cancel-remove-photo="showRemovePhotoConfirmation = false"
        />
    </div>
</template>

<style scoped>
@keyframes logout-runner-leg-stride {
    0%,
    100% {
        transform: rotate(-42deg);
    }

    50% {
        transform: rotate(42deg);
    }
}

@keyframes logout-runner-arm-stride {
    0%,
    100% {
        transform: rotate(34deg);
    }

    50% {
        transform: rotate(-34deg);
    }
}

@keyframes logout-runner-bounce {
    0%,
    100% {
        transform: translateY(0);
    }

    50% {
        transform: translateY(-1.2px);
    }
}

.logout-runner-body {
    transform-box: view-box;
    transform-origin: 15px 13px;
    animation: logout-runner-bounce 0.32s ease-in-out infinite;
}

.logout-runner-leg {
    transform-box: view-box;
    animation: logout-runner-leg-stride 0.32s ease-in-out infinite;
}

.logout-runner-arm {
    transform-box: view-box;
    animation: logout-runner-arm-stride 0.32s ease-in-out infinite;
}

.logout-runner-leg-front {
    transform-origin: 12px 13px;
}

.logout-runner-leg-back {
    transform-origin: 12px 13px;
    animation-delay: -0.16s;
}

.logout-runner-arm-front,
.logout-runner-arm-back {
    transform-origin: 13px 9px;
}

.logout-runner-arm-back {
    animation-delay: -0.16s;
}

@media (prefers-reduced-motion: reduce) {
    .logout-runner-body,
    .logout-runner-leg,
    .logout-runner-arm {
        animation: none;
    }
}

.profile-control-frame {
    background-color: #0f172a;
}

.profile-control-edge {
    position: absolute;
    inset: 0;
    z-index: 0;
    border-radius: inherit;
    background: conic-gradient(
        from 0deg,
        transparent 0deg 270deg,
        rgb(255 255 255 / 45%) 292deg,
        rgb(103 232 249 / 95%) 312deg,
        #fff 326deg,
        transparent 346deg 360deg
    );
    animation: profile-control-edge-spin 3s linear infinite;
    pointer-events: none;
}

@keyframes profile-control-edge-spin {
    to {
        transform: rotate(1turn);
    }
}

@media (prefers-reduced-motion: reduce) {
    .profile-control-edge {
        animation: none;
    }
}
</style>
