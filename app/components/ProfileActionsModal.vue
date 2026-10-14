<script setup>
import { ref } from 'vue'
import { roleDisplayName } from '~/composables/useRoleLabel'

const props = defineProps({
    currentUser: { type: Object, default: null },
    showProfile: { type: Boolean, default: false },
    showPassword: { type: Boolean, default: false },
    showRemovePhoto: { type: Boolean, default: false },
    passwordForm: { type: Object, required: true },
    changingPassword: { type: Boolean, default: false },
    uploading: { type: Boolean, default: false }
})

const emit = defineEmits([
    'close-profile',
    'submit-password',
    'cancel-password',
    'confirm-remove-photo',
    'cancel-remove-photo'
])

const showPasswordConfirmation = ref(false)

function requestPasswordConfirmation() {
    showPasswordConfirmation.value = true
}

function cancelPasswordConfirmation() {
    if (!props.changingPassword) {
        showPasswordConfirmation.value = false
    }
}

function confirmPasswordChange() {
    if (props.changingPassword) return

    showPasswordConfirmation.value = false
    emit('submit-password')
}
</script>

<template>
    <Teleport to="body">
        <div
            v-if="props.showProfile"
            class="fixed inset-0 z-100 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-[2px]"
            @keydown.esc="emit('close-profile')"
        >
            <section
                class="w-full max-w-md overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl"
                role="dialog"
                aria-modal="true"
                aria-labelledby="profile-details-title"
            >
                <div class="flex items-center gap-4 bg-gradient-to-r from-blue-950 to-blue-800 px-5 py-5 sm:px-6">
                    <UserAvatar
                        :name="[props.currentUser?.first_name, props.currentUser?.last_name].filter(Boolean).join(' ') || props.currentUser?.username"
                        :photo-url="props.currentUser?.profile_photo"
                        size="h-14 w-14 text-base"
                        class="ring-2 ring-white/80"
                    />
                    <div class="min-w-0 flex-1 text-white">
                        <h2 id="profile-details-title" class="truncate text-lg font-bold">
                            {{ [props.currentUser?.first_name, props.currentUser?.last_name].filter(Boolean).join(' ') || props.currentUser?.username || 'Your profile' }}
                        </h2>
                        <p class="mt-0.5 truncate text-sm text-blue-100">{{ roleDisplayName(props.currentUser?.role_name) }}</p>
                    </div>
                </div>

                <dl class="space-y-4 px-5 py-5 sm:px-6">
                    <div>
                        <dt class="text-[11px] font-semibold uppercase tracking-wide text-slate-400">Username</dt>
                        <dd class="mt-1 break-all text-sm font-medium text-slate-800">{{ props.currentUser?.username || '—' }}</dd>
                    </div>
                    <div>
                        <dt class="text-[11px] font-semibold uppercase tracking-wide text-slate-400">Full name</dt>
                        <dd class="mt-1 text-sm font-medium text-slate-800">{{ [props.currentUser?.first_name, props.currentUser?.middle_name, props.currentUser?.last_name].filter(Boolean).join(' ') || '—' }}</dd>
                    </div>
                    <div>
                        <dt class="text-[11px] font-semibold uppercase tracking-wide text-slate-400">Organization</dt>
                        <dd class="mt-1 text-sm font-medium text-slate-800">{{ props.currentUser?.organization_name || 'Not assigned' }}</dd>
                    </div>
                </dl>

                <div class="flex justify-end border-t border-slate-100 bg-slate-50 px-5 py-4 sm:px-6">
                    <button type="button" class="cursor-pointer rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800" @click="emit('close-profile')">Close</button>
                </div>
            </section>
        </div>

        <div
            v-if="props.showPassword"
            class="fixed inset-0 z-100 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-[2px]"
            @keydown.esc="emit('cancel-password')"
        >
            <form
                class="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl sm:p-6"
                role="dialog"
                aria-modal="true"
                aria-labelledby="change-password-title"
                @submit.prevent="requestPasswordConfirmation"
            >
                <h2 id="change-password-title" class="text-lg font-bold text-slate-900">Change your password</h2>
                <p class="mt-1 text-sm leading-5 text-slate-500">Confirm your current password, then choose a new one with at least 8 characters.</p>

                <label for="current-account-password" class="mt-5 block text-xs font-semibold text-slate-700">Current password</label>
                <input id="current-account-password" v-model="props.passwordForm.current" type="password" autocomplete="current-password" placeholder="Enter your current password" required class="mt-1 w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm outline-none placeholder:text-slate-400 focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15">

                <label for="new-account-password" class="mt-4 block text-xs font-semibold text-slate-700">New password</label>
                <input id="new-account-password" v-model="props.passwordForm.next" type="password" autocomplete="new-password" minlength="8" maxlength="72" placeholder="Enter a new password (at least 8 characters)" required class="mt-1 w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm outline-none placeholder:text-slate-400 focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15">

                <label for="confirm-account-password" class="mt-4 block text-xs font-semibold text-slate-700">Confirm new password</label>
                <input id="confirm-account-password" v-model="props.passwordForm.confirm" type="password" autocomplete="new-password" minlength="8" maxlength="72" placeholder="Re-enter your new password" required class="mt-1 w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm outline-none placeholder:text-slate-400 focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15">

                <div class="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                    <button type="button" :disabled="props.changingPassword" class="cursor-pointer rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:opacity-50" @click="emit('cancel-password')">Cancel</button>
                    <button type="submit" :disabled="props.changingPassword" class="cursor-pointer rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 disabled:cursor-wait disabled:opacity-60">{{ props.changingPassword ? 'Saving…' : 'Update password' }}</button>
                </div>
            </form>
        </div>

        <div
            v-if="props.showPassword && showPasswordConfirmation"
            class="fixed inset-0 z-110 flex items-center justify-center bg-slate-950/70 p-4 backdrop-blur-sm"
            @keydown.esc="cancelPasswordConfirmation"
        >
            <section
                class="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl"
                role="alertdialog"
                aria-modal="true"
                aria-labelledby="confirm-password-change-title"
                aria-describedby="confirm-password-change-description"
            >
                <div class="flex items-start gap-3">
                    <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-50 text-amber-700" aria-hidden="true">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m0 3.75h.008v.008H12v-.008ZM10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z" />
                        </svg>
                    </span>
                    <div>
                        <h2 id="confirm-password-change-title" class="text-base font-bold text-slate-900">Confirm password change</h2>
                        <p id="confirm-password-change-description" class="mt-1 text-sm leading-5 text-slate-600">Are you sure you want to update your account password?</p>
                    </div>
                </div>
                <div class="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                    <button type="button" :disabled="props.changingPassword" class="cursor-pointer rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:opacity-50" @click="cancelPasswordConfirmation">Go back</button>
                    <button type="button" :disabled="props.changingPassword" class="cursor-pointer rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 disabled:cursor-wait disabled:opacity-60" @click="confirmPasswordChange">{{ props.changingPassword ? 'Updating…' : 'Confirm change' }}</button>
                </div>
            </section>
        </div>

        <div
            v-if="props.showRemovePhoto"
            class="fixed inset-0 z-100 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-[2px]"
            @keydown.esc="emit('cancel-remove-photo')"
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
                        <h2 id="remove-profile-photo-title" class="text-base font-bold text-slate-900">Remove profile photo?</h2>
                        <p id="remove-profile-photo-description" class="mt-1 text-sm leading-5 text-slate-600">Your profile will show your initials instead. You can add a new photo at any time.</p>
                    </div>
                </div>

                <div class="mt-6 flex justify-end gap-2">
                    <button type="button" class="cursor-pointer rounded-lg border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50" @click="emit('cancel-remove-photo')">Keep photo</button>
                    <button type="button" :disabled="props.uploading" class="cursor-pointer rounded-lg bg-red-700 px-4 py-2 text-sm font-semibold text-white transition hover:bg-red-800 disabled:cursor-not-allowed disabled:opacity-60" @click="emit('confirm-remove-photo')">Remove photo</button>
                </div>
            </section>
        </div>
    </Teleport>
</template>
