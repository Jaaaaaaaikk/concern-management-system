<script setup>
import { computed, ref, watch } from 'vue'
import { useBodyScrollLock } from '~/composables/useBodyScrollLock'

const props = defineProps({
    show: { type: Boolean, default: false },
    form: { type: Object, required: true },
    saving: { type: Boolean, default: false }
})

const emit = defineEmits(['close', 'submit'])
const showConfirmation = ref(false)
useBodyScrollLock(() => props.show)

const confirmationMessage = computed(() =>
    `Create “${props.form.name?.trim() || 'this category'}” and make it available for new concerns?`
)

function requestSubmit() {
    if (!props.saving) showConfirmation.value = true
}

function cancelConfirmation() {
    if (!props.saving) showConfirmation.value = false
}

function confirmSubmit() {
    if (props.saving) return
    showConfirmation.value = false
    emit('submit')
}

watch(() => props.show, (isShown) => {
    if (!isShown) showConfirmation.value = false
})
</script>

<template>
    <div
        v-if="props.show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 p-4 backdrop-blur-sm sm:items-center"
        @click.self="!props.saving && emit('close')"
    >
        <form
            class="my-auto w-full max-w-lg rounded-2xl border border-white/60 bg-white p-6 shadow-2xl sm:p-8"
            @submit.prevent="requestSubmit"
        >
            <div class="mb-6 flex items-start justify-between gap-4">
                <div>
                    <p class="text-xs font-bold uppercase tracking-[0.16em] text-blue-700">Category setup</p>
                    <h3 class="mt-1 text-xl font-semibold text-slate-900">Add concern category</h3>
                    <p class="mt-1 text-sm text-slate-500">Create a label for classifying incoming concerns.</p>
                </div>
                <button
                    type="button"
                    class="cursor-pointer rounded-lg p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 disabled:cursor-not-allowed"
                    aria-label="Close"
                    :disabled="props.saving"
                    @click="emit('close')"
                >×</button>
            </div>

            <label for="category-name" class="mb-1.5 block text-sm font-medium text-slate-700">
                Category name <span class="text-red-500">*</span>
            </label>
            <input
                id="category-name"
                v-model="props.form.name"
                required
                maxlength="100"
                autofocus
                class="mb-4 w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm outline-none transition focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15"
                placeholder="e.g. Facilities"
            >

            <label for="category-description" class="mb-1.5 block text-sm font-medium text-slate-700">
                Description <span class="text-slate-400">(optional)</span>
            </label>
            <textarea
                id="category-description"
                v-model="props.form.description"
                maxlength="255"
                rows="3"
                class="w-full resize-y rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm outline-none transition focus:border-blue-700 focus:ring-2 focus:ring-blue-700/15"
                placeholder="Briefly describe what belongs in this category."
            />

            <div class="mt-7 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <button
                    type="button"
                    class="cursor-pointer rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                    :disabled="props.saving"
                    @click="emit('close')"
                >Cancel</button>
                <button
                    type="submit"
                    class="cursor-pointer rounded-lg bg-blue-900 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 disabled:cursor-wait disabled:opacity-60"
                    :disabled="props.saving"
                >{{ props.saving ? 'Creating…' : 'Create category' }}</button>
            </div>
        </form>

        <ConfirmActionModal
            :show="showConfirmation"
            title="Create concern category?"
            :message="confirmationMessage"
            confirm-label="Create category"
            :loading="props.saving"
            @cancel="cancelConfirmation"
            @confirm="confirmSubmit"
        />
    </div>
</template>
