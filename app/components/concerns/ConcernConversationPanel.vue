<script setup>
import { toRefs } from 'vue'
import UserAvatar from '~/components/UserAvatar.vue'

const props = defineProps({
    concernComments: {
        type: Array,
        default: () => []
    },
    visibleComments: {
        type: Array,
        default: () => []
    },
    visibleCommentCount: {
        type: Number,
        default: 10
    },
    currentUser: {
        type: Object,
        default: null
    },
    canComment: {
        type: Boolean,
        default: false
    },
    concernCompleted: {
        type: Boolean,
        default: false
    },
    newComment: {
        type: String,
        default: ''
    },
    savingComment: {
        type: Boolean,
        default: false
    },
    selectedCommentImages: {
        type: Array,
        default: () => []
    },
    commentImagePreviews: {
        type: Array,
        default: () => []
    },
    formatDate: {
        type: Function,
        required: true
    },
    roleDisplayName: {
        type: Function,
        required: true
    },
    attachmentUrl: {
        type: Function,
        required: true
    },
    setCommentImageInput: {
        type: Function,
        required: true
    }
})

const {
    concernComments,
    visibleComments,
    visibleCommentCount,
    currentUser,
    canComment,
    concernCompleted,
    newComment,
    savingComment,
    selectedCommentImages,
    commentImagePreviews,
    formatDate,
    roleDisplayName,
    attachmentUrl,
    setCommentImageInput
} = toRefs(props)

const emit = defineEmits([
    'update:visibleCommentCount',
    'update:newComment',
    'open-profile-photo',
    'open-image',
    'comment-images-change',
    'clear-comment-images',
    'remove-comment-image',
    'add-comment'
])

function loadEarlierComments() {
    emit(
        'update:visibleCommentCount',
        Math.min(props.visibleCommentCount + 10, props.concernComments.length)
    )
}
</script>

<template>
    <div id="concern-panel-conversation" role="tabpanel" aria-labelledby="concern-tab-conversation" data-tour="view-comments" class="rounded-xl border border-slate-200 bg-white p-5 shadow-lg shadow-blue-950/5">
        <div class="mb-5">
            <h4 class="flex items-center gap-2 text-base font-semibold text-blue-950">
                <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 text-blue-800" aria-hidden="true">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3.75h6m-9.75 7.5 2.6-3.12a2.25 2.25 0 0 1 1.73-.81h9.17A2.25 2.25 0 0 0 19.5 13.3V5.25A2.25 2.25 0 0 0 17.25 3h-10.5A2.25 2.25 0 0 0 4.5 5.25v14.25Z" />
                    </svg>
                </span>
                Conversation
            </h4>
            <p class="mt-1 text-sm text-slate-500">
                Communication between members of the creator organization and the assigned organization.
            </p>
        </div>

        <div v-if="concernComments.length === 0" class="rounded-lg bg-slate-50 p-6 text-center">
            <p class="text-sm text-slate-500">
                No conversation yet.
            </p>
            <p v-if="canComment" class="mt-1 text-xs text-slate-400">
                Start the conversation by adding a comment below.
            </p>
        </div>

        <div v-else class="space-y-5">
            <button
                v-if="visibleCommentCount < concernComments.length"
                type="button"
                class="w-full cursor-pointer rounded-lg border border-blue-100 bg-blue-50/60 px-3 py-2.5 text-xs font-semibold text-blue-800 transition hover:border-blue-200 hover:bg-blue-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-700"
                @click="loadEarlierComments"
            >
                Load {{ Math.min(10, concernComments.length - visibleCommentCount) }} earlier {{ concernComments.length - visibleCommentCount === 1 ? 'comment' : 'comments' }}
                <span class="ml-1 font-medium text-blue-600">({{ concernComments.length - visibleCommentCount }} remaining)</span>
            </button>

            <article
                v-for="comment in visibleComments"
                :key="comment.id"
                class="flex items-start gap-3"
                :class="Number(comment.user_id) === Number(currentUser?.id) ? 'flex-row-reverse' : 'flex-row'"
            >
                <button
                    v-if="comment.profile_photo"
                    type="button"
                    class="mt-1 shrink-0 cursor-zoom-in rounded-full focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-600 focus-visible:ring-offset-2"
                    :aria-label="`View ${comment.user_name || 'user'} profile photo`"
                    :title="`View ${comment.user_name || 'user'} profile photo`"
                    @click="emit('open-profile-photo', comment)"
                >
                    <UserAvatar
                        :name="comment.user_name || '-'"
                        :photo-url="comment.profile_photo"
                        size="h-10 w-10 text-xs"
                        class="ring-2 ring-white shadow-sm"
                    />
                </button>
                <UserAvatar
                    v-else
                    :name="comment.user_name || '-'"
                    size="h-10 w-10 text-xs"
                    class="mt-1 ring-2 ring-white shadow-sm"
                />

                <div
                    class="min-w-0 max-w-[88%] overflow-hidden rounded-2xl border shadow-sm transition-shadow hover:shadow-md sm:max-w-[78%]"
                    :class="Number(comment.user_id) === Number(currentUser?.id)
                        ? 'border-blue-200 bg-blue-50/70'
                        : 'border-slate-200 bg-white'"
                >
                    <div class="flex flex-wrap items-center gap-x-2 gap-y-1 border-b px-3 py-2"
                        :class="Number(comment.user_id) === Number(currentUser?.id)
                            ? 'border-blue-100 bg-blue-100/60'
                            : 'border-slate-100 bg-slate-50'">
                        <span class="text-[10px] font-medium text-slate-500">{{ formatDate(comment.created_at) }}</span>
                        <span class="text-slate-300" aria-hidden="true">·</span>
                        <span class="text-[11px] font-bold text-blue-950">{{ comment.user_name || '-' }}</span>
                        <span class="rounded-full bg-white/90 px-2 py-0.5 text-[9px] font-semibold text-blue-800 ring-1 ring-blue-100">
                            {{ roleDisplayName(comment.role_name) }}
                        </span>
                        <span v-if="comment.organization_name" class="max-w-40 truncate rounded-full bg-white/90 px-2 py-0.5 text-[9px] font-medium text-slate-600 ring-1 ring-slate-200" :title="comment.organization_name">
                            {{ comment.organization_name }}
                        </span>
                        <template v-if="comment.updated_at && comment.updated_at !== comment.created_at">
                            <span class="text-slate-300" aria-hidden="true">·</span>
                            <span class="text-[10px] font-semibold text-slate-500">Edited {{ formatDate(comment.updated_at) }}</span>
                        </template>
                    </div>

                    <div class="px-3 py-3 sm:px-4">
                        <p v-if="comment.comment" class="whitespace-pre-wrap break-words text-sm leading-6 text-slate-800">{{ comment.comment }}</p>
                        <div v-if="comment.attachments?.length" :class="comment.comment ? 'mt-3' : ''" class="flex flex-wrap gap-2">
                            <button
                                v-for="attachment in comment.attachments"
                                :key="attachment.id"
                                type="button"
                                @click="emit('open-image', attachment)"
                                class="group relative block h-20 w-20 cursor-pointer overflow-hidden rounded-lg border border-slate-200 bg-white transition hover:border-blue-400 hover:shadow-md sm:h-24 sm:w-24"
                                :title="`View ${attachment.file_name}`"
                            >
                                <img v-if="attachment.file_type?.startsWith('image/')" :src="attachmentUrl(attachment.file_path)" :alt="attachment.file_name" class="h-full w-full object-cover transition duration-200 group-hover:scale-105" />
                                <span class="absolute inset-0 flex items-center justify-center bg-black/0 text-xs font-semibold text-white opacity-0 transition group-hover:bg-black/25 group-hover:opacity-100">View</span>
                            </button>
                        </div>
                    </div>
                </div>
            </article>
        </div>

        <div v-if="canComment" class="mt-6 border-t border-slate-200 pt-5">
            <div class="mb-2 flex items-center justify-between">
                <label class="block text-sm font-medium text-slate-700">
                    Add Comment
                </label>
                <span class="text-xs text-slate-400">
                    {{ roleDisplayName(currentUser?.role_name) }}
                </span>
            </div>

            <textarea :value="newComment" :disabled="savingComment" rows="4"
                placeholder="Write a message..."
                @input="emit('update:newComment', $event.target.value)"
                class="w-full resize-y rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100"></textarea>

            <div class="mt-3">
                <label class="mb-2 block text-sm font-medium text-slate-700">
                    Attach Images for Comment
                    <span class="font-normal text-slate-400">(Optional)</span>
                </label>
                <input :ref="setCommentImageInput" type="file" multiple
                    accept="image/jpeg,image/png,image/gif,image/webp" :disabled="savingComment"
                    @change="emit('comment-images-change', $event)"
                    class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-slate-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:border-slate-400 hover:file:bg-slate-200 disabled:cursor-not-allowed disabled:bg-slate-100" />
                <p class="mt-1 text-xs text-slate-500">
                    You can select multiple images. Maximum size: 5 MB per image.
                </p>
            </div>

            <div v-if="commentImagePreviews.length > 0" class="mt-4">
                <div class="mb-2 flex items-center justify-between">
                    <p class="text-sm font-medium text-slate-700">
                        Selected Images
                    </p>
                    <button type="button" @click="emit('clear-comment-images')" :disabled="savingComment"
                        class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                        Remove All
                    </button>
                </div>

                <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
                    <div v-for="(preview, index) in commentImagePreviews" :key="preview.url"
                        class="relative overflow-hidden rounded-lg border border-slate-200 bg-slate-50">
                        <img :src="preview.url" :alt="preview.file.name"
                            class="h-28 w-full bg-white object-cover" />
                        <div class="flex items-center justify-between gap-2 border-t border-slate-200 bg-white p-2">
                            <p class="min-w-0 flex-1 truncate text-xs text-slate-500"
                                :title="preview.file.name">
                                {{ preview.file.name }}
                            </p>
                            <button type="button" @click="emit('remove-comment-image', index)"
                                :disabled="savingComment"
                                class="shrink-0 cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                Remove
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <div class="mt-3 flex justify-end">
                <button type="button" @click="emit('add-comment')" :disabled="savingComment || (!newComment.trim() && selectedCommentImages.length === 0)"
                    class="primary-action-button cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50">
                    {{ savingComment ? 'Sending...' : 'Send Comment' }}
                </button>
            </div>
        </div>

        <div v-else class="mt-5 border-t border-slate-200 pt-5">
            <p v-if="concernCompleted" class="text-sm text-slate-400">
                This concern is already completed. Conversation is closed.
            </p>
            <p v-else class="text-sm text-slate-400">
                You do not have permission to participate in this conversation.
            </p>
        </div>
    </div>
</template>
