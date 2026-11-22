<script setup>
import { toRefs } from 'vue'

const props = defineProps({
    concernAttachments: {
        type: Array,
        default: () => []
    },
    canEditOriginalAttachments: {
        type: Boolean,
        default: false
    },
    addingAttachments: {
        type: Boolean,
        default: false
    },
    replacingAttachmentId: {
        type: [Number, String, Boolean],
        default: null
    },
    deletingAttachmentId: {
        type: [Number, String],
        default: null
    },
    additionalImagePreviews: {
        type: Array,
        default: () => []
    },
    selectedAdditionalImages: {
        type: Array,
        default: () => []
    },
    replacementImagePreview: {
        type: Object,
        default: null
    },
    selectedReplacementImage: {
        type: Object,
        default: null
    },
    editingAttachmentId: {
        type: [Number, String],
        default: null
    },
    formatDate: {
        type: Function,
        required: true
    },
    attachmentUrl: {
        type: Function,
        required: true
    },
    setReplacementInput: {
        type: Function,
        required: true
    },
    setAdditionalAttachmentInput: {
        type: Function,
        required: true
    }
})

const {
    concernAttachments,
    canEditOriginalAttachments,
    addingAttachments,
    replacingAttachmentId,
    deletingAttachmentId,
    additionalImagePreviews,
    selectedAdditionalImages,
    replacementImagePreview,
    selectedReplacementImage,
    editingAttachmentId,
    formatDate,
    attachmentUrl,
    setReplacementInput,
    setAdditionalAttachmentInput
} = toRefs(props)

const emit = defineEmits([
    'select-additional-images',
    'clear-additional-images',
    'remove-additional-image',
    'attach-additional-images',
    'clear-replacement-image',
    'save-attachment-replacement',
    'open-image',
    'trigger-attachment-replace',
    'remove-original-attachment',
    'attachment-replacement-change',
    'additional-attachments-change'
])
</script>

<template>
    <div data-tour="view-attachments" class="view-concern-attachments rounded-xl border border-violet-100 bg-white p-5 shadow-lg shadow-violet-950/5">
        <div class="mb-4 flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
            <div>
                <h4 class="text-base font-semibold text-slate-800">
                    Attachments
                </h4>
                <p class="mt-1 text-sm text-slate-500">
                    Images attached to this concern.
                </p>
            </div>

            <div class="flex items-center gap-3">
                <span v-if="concernAttachments.length > 0" class="text-xs text-slate-400">
                    {{ concernAttachments.length }} attachment{{ concernAttachments.length === 1 ? '' : 's' }}
                </span>
                <button v-if="canEditOriginalAttachments" type="button"
                    @click="emit('select-additional-images')" :disabled="addingAttachments || replacingAttachmentId"
                    class="inline-flex cursor-pointer items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">
                    <span class="text-base leading-none">+</span>
                    Add Images
                </button>
            </div>
        </div>

        <div v-if="additionalImagePreviews.length > 0" class="mb-5 rounded-lg border border-blue-200 bg-blue-50 p-4">
            <div class="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <p class="text-sm font-semibold text-blue-900">
                        Selected Images ({{ additionalImagePreviews.length }})
                    </p>
                    <p class="mt-1 text-xs text-blue-700">
                        These images have not been saved yet.
                        Click Save Images to attach them to this concern.
                    </p>
                </div>
                <button type="button" @click="emit('clear-additional-images')" :disabled="addingAttachments"
                    class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                    Remove All
                </button>
            </div>

            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
                <div v-for="(preview, index) in additionalImagePreviews" :key="preview.url"
                    class="overflow-hidden rounded-lg border border-blue-200 bg-white">
                    <div class="relative overflow-hidden">
                        <img :src="preview.url" :alt="preview.file.name" class="h-32 w-full object-cover" />
                        <button type="button" @click="emit('remove-additional-image', index)" :disabled="addingAttachments"
                            class="absolute right-2 top-2 cursor-pointer rounded-md bg-black/70 px-2 py-1 text-xs font-medium text-white transition hover:bg-red-600 disabled:cursor-not-allowed disabled:opacity-50">
                            Remove
                        </button>
                    </div>
                    <div class="border-t border-slate-200 px-2 py-2">
                        <p class="truncate text-xs text-slate-500" :title="preview.file.name">
                            {{ preview.file.name }}
                        </p>
                    </div>
                </div>
            </div>

            <div class="mt-4 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                <button type="button" @click="emit('clear-additional-images')" :disabled="addingAttachments"
                    class="secondary-hover-button cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50">
                    Cancel
                </button>
                <button type="button" @click="emit('attach-additional-images')" :disabled="addingAttachments || selectedAdditionalImages.length === 0"
                    class="primary-action-button cursor-pointer rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50">
                    {{ addingAttachments ? 'Saving...' : `Save Images (${selectedAdditionalImages.length})` }}
                </button>
            </div>
        </div>

        <div v-if="replacementImagePreview && selectedReplacementImage && editingAttachmentId"
            class="mb-5 rounded-lg border border-amber-200 bg-amber-50 p-4">
            <div class="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <p class="text-sm font-semibold text-amber-900">
                        Selected Replacement
                    </p>
                    <p class="mt-1 text-xs leading-5 text-amber-700">
                        This replacement has not been saved yet.
                        Click Save Replacement to replace the existing attachment.
                    </p>
                </div>
                <button type="button" @click="emit('clear-replacement-image')" :disabled="replacingAttachmentId"
                    class="secondary-hover-button cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                    Cancel
                </button>
            </div>

            <div class="max-w-sm overflow-hidden rounded-lg border border-amber-200 bg-white">
                <div class="relative overflow-hidden">
                    <img :src="replacementImagePreview.url" :alt="replacementImagePreview.file.name" class="h-48 w-full object-cover" />
                </div>
                <div class="border-t border-slate-200 p-3">
                    <p class="truncate text-xs font-medium text-slate-700" :title="replacementImagePreview.file.name">
                        {{ replacementImagePreview.file.name }}
                    </p>
                    <p class="mt-1 text-[11px] text-slate-400">
                        Replacement is not saved yet.
                    </p>
                </div>
            </div>

            <div class="mt-4 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                <button type="button" @click="emit('clear-replacement-image')" :disabled="replacingAttachmentId"
                    class="secondary-hover-button cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50">
                    Cancel
                </button>
                <button type="button" @click="emit('save-attachment-replacement')" :disabled="replacingAttachmentId || !selectedReplacementImage || !editingAttachmentId"
                    class="cursor-pointer rounded-lg bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-50">
                    {{ replacingAttachmentId ? 'Saving...' : 'Save Replacement' }}
                </button>
            </div>
        </div>

        <div v-if="concernAttachments.length === 0" class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500">
            No attachments.
        </div>
        <div v-else class="max-h-[520px] overflow-y-auto pr-1">
            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
                <div v-for="attachment in concernAttachments" :key="attachment.id"
                    class="overflow-hidden rounded-lg border border-slate-200 bg-white">
                    <button type="button" @click="emit('open-image', attachment)"
                        class="group block w-full cursor-pointer text-left"
                        :title="`View ${attachment.file_name}`">
                        <div class="relative overflow-hidden bg-white">
                            <img v-if="attachment.file_type?.startsWith('image/')"
                                :src="attachmentUrl(attachment.file_path)" :alt="attachment.file_name"
                                class="h-32 w-full object-cover transition duration-200 group-hover:scale-105" />
                            <div v-else class="flex h-32 items-center justify-center text-xs text-slate-500">
                                File attachment
                            </div>
                            <div class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20">
                                <span class="rounded-full bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700 opacity-0 shadow transition group-hover:opacity-100">
                                    View
                                </span>
                            </div>
                        </div>
                    </button>

                    <div class="border-t border-slate-200 bg-white p-3">
                        <div class="mb-2 flex items-center justify-between gap-2">
                            <span class="rounded-full px-2 py-1 text-[10px] font-semibold"
                                :class="attachment.edited_at ? 'bg-amber-100 text-amber-700' : 'bg-slate-100 text-slate-600'">
                                {{ attachment.edited_at ? 'Edited' : 'Uploaded' }}
                            </span>
                            <span v-if="canEditOriginalAttachments" class="text-[10px] text-slate-400">
                                Original
                            </span>
                        </div>

                        <p class="truncate text-xs font-medium text-slate-700" :title="attachment.file_name">
                            {{ attachment.file_name }}
                        </p>
                        <p class="mt-1 truncate text-[11px] text-slate-400">
                            {{ attachment.uploaded_by_name || '-' }}
                        </p>
                        <p class="mt-1 text-[11px] text-slate-400">
                            {{ attachment.edited_at ? `Edited ${formatDate(attachment.edited_at)}` : `Uploaded ${formatDate(attachment.created_at)}` }}
                        </p>

                        <div v-if="canEditOriginalAttachments" class="mt-3 flex gap-2">
                            <button type="button" @click="emit('trigger-attachment-replace', attachment)"
                                :disabled="replacingAttachmentId || deletingAttachmentId === attachment.id || addingAttachments"
                                class="secondary-hover-button flex-1 cursor-pointer rounded-md border border-slate-300 px-2 py-1.5 text-[11px] font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">
                                Replace
                            </button>
                            <button type="button" @click="emit('remove-original-attachment', attachment)"
                                :disabled="replacingAttachmentId === attachment.id || deletingAttachmentId === attachment.id || addingAttachments"
                                class="secondary-hover-button cursor-pointer rounded-md border border-red-200 px-2 py-1.5 text-[11px] font-medium text-red-600 transition hover:bg-red-50 hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                {{ deletingAttachmentId === attachment.id ? '...' : 'Remove' }}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <input :ref="setReplacementInput" type="file" accept="image/jpeg,image/png,image/gif,image/webp"
            class="hidden" @change="emit('attachment-replacement-change', $event)" />
        <input :ref="setAdditionalAttachmentInput" type="file" multiple
            accept="image/jpeg,image/png,image/gif,image/webp" class="hidden"
            @change="emit('additional-attachments-change', $event)" />
    </div>
</template>
