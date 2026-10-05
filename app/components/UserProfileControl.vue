<script setup>
import { computed, ref } from 'vue'
import { useToast } from '~/composables/useToast'

const props = defineProps({
    currentUser: {
        type: Object,
        default: null
    },
    mobile: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits(['logout', 'profile-updated'])
const { showToast } = useToast()
const uploading = ref(false)
const showRemovePhotoConfirmation = ref(false)
const photoInput = ref(null)

const displayName = computed(() => {
    const name = [
        props.currentUser?.first_name,
        props.currentUser?.last_name
    ].filter(Boolean).join(' ').trim()

    return name || props.currentUser?.username || 'Signed-in user'
})

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
</script>

<template>
    <div
        v-if="currentUser"
        class="min-w-0"
        :class="mobile ? 'flex-1' : 'rounded-xl bg-emerald-900/70 p-3'"
    >
        <div class="flex min-w-0 items-center gap-3">
            <UserAvatar
                :name="displayName"
                :photo-url="currentUser?.profile_photo"
                :size="mobile ? 'h-10 w-10 text-sm' : 'h-11 w-11 text-sm'"
                class="ring-2 ring-white/80"
            />

            <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-semibold" :class="mobile ? 'text-slate-900' : 'text-white'">
                    {{ displayName }}
                </p>
                <p class="truncate text-xs capitalize" :class="mobile ? 'text-slate-500' : 'text-emerald-100/70'">
                    {{ currentUser?.role_name || 'Account' }}
                </p>
                <p
                    v-if="currentUser?.organization_name"
                    class="truncate text-[11px]"
                    :class="mobile ? 'text-slate-500' : 'text-emerald-100/60'"
                    :title="currentUser.organization_name"
                >
                    {{ currentUser.organization_name }}
                </p>
                <div class="mt-1 flex items-center gap-3">
                    <label
                        :for="`profile-photo-${currentUser?.id}`"
                        class="cursor-pointer text-[11px] font-semibold transition"
                        :class="mobile ? 'text-emerald-800 hover:text-emerald-950' : 'text-emerald-200 hover:text-white'"
                    >
                        {{ uploading ? 'Saving...' : currentUser?.profile_photo ? 'Change photo' : 'Add photo' }}
                    </label>
                    <button
                        v-if="currentUser?.profile_photo"
                        type="button"
                        :disabled="uploading"
                        class="cursor-pointer text-[11px] font-medium transition disabled:cursor-not-allowed disabled:opacity-50"
                        :class="mobile ? 'text-red-700 hover:text-red-900' : 'text-red-300 hover:text-red-200'"
                        @click="showRemovePhotoConfirmation = true"
                    >
                        Remove
                    </button>
                </div>
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

        <button
            v-if="!mobile"
            type="button"
            class="mt-3 flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg border border-emerald-100/20 px-3 py-2 text-xs font-semibold text-emerald-100 transition hover:border-red-300/50 hover:bg-red-500/10 hover:text-white"
            @click="emit('logout')"
        >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6A2.25 2.25 0 0 0 5.25 5.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3-3H9m0 0 3-3m-3 3 3 3" />
            </svg>
            Logout
        </button>

        <Teleport to="body">
            <div
                v-if="showRemovePhotoConfirmation"
                class="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-[2px]"
                @click.self="showRemovePhotoConfirmation = false"
                @keydown.esc="showRemovePhotoConfirmation = false"
            >
                <section
                    role="dialog"
                    aria-modal="true"
                    aria-labelledby="remove-profile-photo-title"
                    aria-describedby="remove-profile-photo-description"
                    class="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl"
                >
                    <div class="flex items-start gap-3">
                        <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-50 text-red-700">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6 7h12m-10 0 .6 12h6.8L16 7m-6 0V4.75h4V7m-3 3v5m2-5v5" />
                            </svg>
                        </div>
                        <div>
                            <h2 id="remove-profile-photo-title" class="text-base font-bold text-slate-900">
                                Remove profile photo?
                            </h2>
                            <p id="remove-profile-photo-description" class="mt-1 text-sm leading-5 text-slate-600">
                                Your profile will show your initials instead. You can add a new photo at any time.
                            </p>
                        </div>
                    </div>

                    <div class="mt-6 flex justify-end gap-2">
                        <button
                            type="button"
                            class="cursor-pointer rounded-lg border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                            @click="showRemovePhotoConfirmation = false"
                        >
                            Keep photo
                        </button>
                        <button
                            type="button"
                            class="cursor-pointer rounded-lg bg-red-700 px-4 py-2 text-sm font-semibold text-white transition hover:bg-red-800 disabled:cursor-not-allowed disabled:opacity-60"
                            :disabled="uploading"
                            @click="confirmPhotoRemoval"
                        >
                            Remove photo
                        </button>
                    </div>
                </section>
            </div>
        </Teleport>
    </div>
</template>
