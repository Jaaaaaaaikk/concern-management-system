<script setup>
import { toRefs } from 'vue'

const props = defineProps({
    concernStatusHistory: {
        type: Array,
        default: () => []
    },
    visibleStatusHistory: {
        type: Array,
        default: () => []
    },
    showAllStatusHistory: {
        type: Boolean,
        default: false
    },
    formatStatus: {
        type: Function,
        required: true
    },
    statusClass: {
        type: Function,
        required: true
    },
    formatDate: {
        type: Function,
        required: true
    },
    formatDateOnly: {
        type: Function,
        required: true
    },
    commitmentStartFromRemarks: {
        type: Function,
        required: true
    },
    attachmentUrl: {
        type: Function,
        required: true
    }
})

const {
    concernStatusHistory,
    visibleStatusHistory,
    showAllStatusHistory,
    formatStatus,
    statusClass,
    formatDate,
    formatDateOnly,
    commitmentStartFromRemarks,
    attachmentUrl
} = toRefs(props)

const emit = defineEmits(['update:showAllStatusHistory', 'view-image'])

function historyRemarksWithoutCommitmentStart(history) {
    return String(history?.remarks || '')
        .replace(
            /\n?\s*(?:commitment start(?: date)?|scheduled start(?: date(?:\/time)?)?|target resolution date):\s*\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?)?\s*/i,
            ''
        )
        .trim()
}

function toggleHistory() {
    emit('update:showAllStatusHistory', !props.showAllStatusHistory)
}
</script>

<template>
    <div class="view-concern-history rounded-xl border border-emerald-100 bg-white p-5 shadow-lg shadow-emerald-950/5">
        <div class="mb-4 flex items-start justify-between gap-3">
            <div>
                <h4 class="text-base font-semibold text-slate-800">
                    Status History
                </h4>
                <p class="mt-1 text-sm text-slate-500">
                    Record of status changes.
                </p>
            </div>

            <span v-if="concernStatusHistory.length" class="shrink-0 rounded-full bg-slate-100 px-2.5 py-1 text-[10px] font-semibold text-slate-500">
                {{ concernStatusHistory.length }} {{ concernStatusHistory.length === 1 ? 'entry' : 'entries' }}
            </span>
        </div>

        <div v-if="concernStatusHistory.length === 0"
            class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500">
            No status history available.
        </div>

        <div v-else class="space-y-4">
            <div v-for="history in visibleStatusHistory" :key="history.id"
                class="rounded-lg border border-slate-200 bg-slate-50 p-4">
                <div class="flex flex-wrap items-center justify-between gap-3">
                    <div class="flex flex-wrap items-center gap-2">
                        <span v-if="history.old_status"
                            class="rounded-full bg-slate-200 px-3 py-1 text-xs font-medium text-slate-700">
                            {{ formatStatus(history.old_status) }}
                        </span>
                        <span v-if="history.old_status" class="text-slate-400">
                            →
                        </span>
                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                            :class="statusClass(history.new_status)">
                            {{ formatStatus(history.new_status) }}
                        </span>

                        <span v-if="history.old_status === 'resolved' && history.new_status === 'in_progress'"
                            class="inline-flex items-center gap-1 rounded-full border border-amber-200 bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                stroke-width="2" stroke="currentColor" class="h-3.5 w-3.5" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12a7.5 7.5 0 0 1 12.8-5.3L19.5 9m0-4.5V9h-4.5M19.5 12a7.5 7.5 0 0 1-12.8 5.3L4.5 15m0 4.5V15H9" />
                            </svg>
                            Reopened
                        </span>

                        <span v-if="history.new_status === 'closed'"
                            class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-xs font-semibold text-green-700">
                            ✓ Completed
                        </span>
                    </div>

                    <span class="text-xs text-slate-400">
                        {{ formatDate(history.created_at) }}
                    </span>
                </div>

                <p class="mt-3 text-xs text-slate-500">
                    Changed by
                    <span class="font-medium text-slate-700">
                        {{ history.changed_by_name || (history.new_status === 'closed' && history.old_status === 'resolved' ? 'System (automatic closure)' : '-') }}
                    </span>
                </p>

                <p v-if="commitmentStartFromRemarks(history.remarks)"
                    class="mt-3 rounded-lg border border-blue-100 bg-blue-50 px-3 py-2 text-xs font-medium text-blue-800">
                    Committed start:
                    {{ formatDateOnly(commitmentStartFromRemarks(history.remarks)) }}
                </p>

                <p v-if="historyRemarksWithoutCommitmentStart(history)"
                    class="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700">
                    {{ historyRemarksWithoutCommitmentStart(history) }}
                </p>

                <div v-if="history.attachments && history.attachments.length > 0" class="mt-4">
                    <div class="mb-2 flex items-center justify-between">
                        <p class="text-xs font-semibold text-slate-700">
                            {{ history.old_status === 'resolved' && history.new_status === 'in_progress'
                                ? 'Reopening Evidence'
                                : 'Resolution Evidence' }}
                        </p>
                        <span class="text-[11px] text-slate-400">
                            {{ history.attachments.length }} image{{ history.attachments.length === 1 ? '' : 's' }}
                        </span>
                    </div>

                    <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
                        <button v-for="attachment in history.attachments" :key="attachment.id"
                            type="button" @click="emit('view-image', attachment)"
                            class="group relative block w-full cursor-pointer overflow-hidden rounded-lg border border-green-200 bg-white text-left transition hover:border-green-400 hover:shadow-md"
                            :title="`View ${attachment.file_name}`">
                            <img v-if="attachment.file_type?.startsWith('image/')"
                                :src="attachmentUrl(attachment.file_path)" :alt="attachment.file_name"
                                class="h-28 w-full object-cover transition duration-200 group-hover:scale-105" />
                            <div class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20">
                                <span class="rounded-full bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700 opacity-0 shadow transition group-hover:opacity-100">
                                    View
                                </span>
                            </div>
                            <div class="border-t border-green-100 bg-white px-2 py-2">
                                <p class="truncate text-[11px] font-medium text-slate-600" :title="attachment.file_name">
                                    {{ attachment.file_name }}
                                </p>
                                <p class="mt-1 text-[10px] text-slate-400">
                                    Uploaded by {{ attachment.uploaded_by_name || '-' }}
                                </p>
                                <p class="mt-1 text-[10px] text-slate-400">
                                    {{ formatDate(attachment.created_at) }}
                                </p>
                            </div>
                        </button>
                    </div>
                </div>
            </div>

            <button v-if="concernStatusHistory.length > 3" type="button"
                class="w-full cursor-pointer rounded-lg border border-blue-100 bg-blue-50/60 px-3 py-2.5 text-xs font-semibold text-blue-800 transition hover:border-blue-200 hover:bg-blue-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                @click="toggleHistory">
                {{ showAllStatusHistory ? 'Show latest 3 entries' : `Show all ${concernStatusHistory.length} history entries` }}
            </button>
        </div>
    </div>
</template>
