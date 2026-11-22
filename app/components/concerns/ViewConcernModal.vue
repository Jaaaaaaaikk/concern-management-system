<script setup>

import ConfirmActionModal from '~/components/ConfirmActionModal.vue'
import ConcernAttachmentsPanel from '~/components/concerns/ConcernAttachmentsPanel.vue'
import ConcernConversationPanel from '~/components/concerns/ConcernConversationPanel.vue'
import ConcernImageViewer from '~/components/concerns/ConcernImageViewer.vue'
import ConcernStatusUpdatePanel from '~/components/concerns/ConcernStatusUpdatePanel.vue'
import ConcernStatusHistory from '~/components/concerns/ConcernStatusHistory.vue'
import { useBodyScrollLock } from '~/composables/useBodyScrollLock'
import { roleDisplayName } from '~/composables/useRoleLabel'

const props = defineProps({
    show: {
        type: Boolean,
        default: false
    },

    concernId: {
        type: [Number, String],
        default: null
    },

    currentUser: {
        type: Object,
        default: null
    }
})

useBodyScrollLock(() => props.show)

const { showToast } = useToast()

const emit = defineEmits([
    'close',
    'refresh'
])

const selectedConcern = ref(null)
const concernComments = ref([])
const concernAttachments = ref([])
const concernStatusHistory = ref([])
const activeConcernTab = ref('overview')
const visibleCommentCount = ref(10)
const showAllStatusHistory = ref(false)

const visibleComments = computed(() =>
    concernComments.value.slice(-visibleCommentCount.value)
)

const visibleStatusHistory = computed(() => {
    const latestFirst = concernStatusHistory.value
        .slice()
        .sort((left, right) => {
            const leftTime = parseDate(left.created_at)?.getTime() || 0
            const rightTime = parseDate(right.created_at)?.getTime() || 0

            return rightTime - leftTime
        })

    return showAllStatusHistory.value
        ? latestFirst
        : latestFirst.slice(0, 3)
})

const loadingConcernDetails = ref(false)
const savingComment = ref(false)
const updatingStatus = ref(false)
const updatingTrash = ref(false)
const trashConfirmation = ref('')
const pendingConfirmation = ref(null)

const newComment = ref('')
const selectedStatus = ref('')
const statusRemarks = ref('')
const statusSelectorSection = ref(null)
const targetCommitmentAt = ref(null)

const selectedStatusImages = ref([])
const statusImagePreviews = ref([])
const statusImageInput = ref(null)

const selectedCommentImages = ref([])
const commentImagePreviews = ref([])
const commentImageInput = ref(null)

/*
 * ---------------------------------------------------------
 * ATTACHMENT REPLACEMENT
 * ---------------------------------------------------------
 */

const editingAttachmentId = ref(null)
const replacingAttachmentId = ref(null)
const deletingAttachmentId = ref(null)

const replacementInput = ref(null)
const selectedReplacementImage = ref(null)
const replacementImagePreview = ref(null)

/*
 * ---------------------------------------------------------
 * ADDITIONAL ATTACHMENTS
 * ---------------------------------------------------------
 */

const addingAttachments = ref(false)
const additionalAttachmentInput = ref(null)
const selectedAdditionalImages = ref([])
const additionalImagePreviews = ref([])

const showImageViewer = ref(false)
const selectedViewerImage = ref(null)

const currentTime = ref(new Date())
let durationTimer = null

const confirmationDetails = computed(() => {
    const action = pendingConfirmation.value

    if (!action) {
        return {
            title: '',
            message: '',
            confirmLabel: 'Confirm',
            tone: 'primary'
        }
    }

    const details = {
        comment: {
            title: 'Send this comment?',
            message: 'Your comment and any selected images will be shared with people who can access this concern.',
            confirmLabel: 'Send comment',
            tone: 'primary'
        },
        status: {
            title: 'Confirm status update?',
            message: `This will change the concern status to ${formatStatus(selectedStatus.value)} and share your update notes${selectedStatusImages.value.length ? ' and evidence images' : ''}.`,
            confirmLabel: 'Update status',
            tone: 'primary'
        },
        replaceAttachment: {
            title: 'Replace this attachment?',
            message: `The selected image will replace the current attachment${selectedReplacementImage.value?.name ? ` with “${selectedReplacementImage.value.name}”` : ''}.`,
            confirmLabel: 'Replace image',
            tone: 'primary'
        },
        addAttachments: {
            title: 'Attach these images?',
            message: `${selectedAdditionalImages.value.length} image${selectedAdditionalImages.value.length === 1 ? '' : 's'} will be added to this concern.`,
            confirmLabel: 'Attach images',
            tone: 'primary'
        },
        removeAttachment: {
            title: 'Remove this attachment?',
            message: `“${action.attachment?.file_name || 'This image'}” will be removed from the concern.`,
            confirmLabel: 'Remove image',
            tone: 'danger'
        }
    }

    return details[action.type] || details.comment
})

const confirmationLoading = computed(() => {
    const type = pendingConfirmation.value?.type

    return type === 'comment'
        ? savingComment.value
        : type === 'status'
            ? updatingStatus.value
            : type === 'replaceAttachment'
                ? Boolean(replacingAttachmentId.value)
                : type === 'addAttachments'
                    ? addingAttachments.value
                    : type === 'removeAttachment'
                        ? Boolean(deletingAttachmentId.value)
                        : false
})

function requestConfirmation(type, details = {}) {
    if (!confirmationLoading.value) {
        pendingConfirmation.value = { type, ...details }
    }
}

function cancelPendingConfirmation() {
    if (!confirmationLoading.value) {
        pendingConfirmation.value = null
    }
}

async function confirmPendingAction() {
    if (!pendingConfirmation.value || confirmationLoading.value) {
        return
    }

    const action = pendingConfirmation.value
    pendingConfirmation.value = null

    if (action.type === 'comment') {
        await addComment(true)
    } else if (action.type === 'status') {
        await updateConcernStatus(true)
    } else if (action.type === 'replaceAttachment') {
        await saveAttachmentReplacement(true)
    } else if (action.type === 'addAttachments') {
        await attachAdditionalImages(true)
    } else if (action.type === 'removeAttachment') {
        await removeOriginalAttachment(action.attachment, true)
    }
}

/*
 * ---------------------------------------------------------
 * DATE / TIME HELPERS
 * ---------------------------------------------------------
 */

function mysqlDateTimeToLocalDate(value) {
    if (!value) {
        return null
    }

    if (value instanceof Date) {
        return Number.isNaN(value.getTime())
            ? null
            : new Date(value.getTime())
    }

    const stringValue = String(value).trim()

    if (!stringValue) {
        return null
    }

    if (
        stringValue.includes('Z') ||
        /[+-]\d{2}:\d{2}$/.test(stringValue)
    ) {
        const date = new Date(stringValue)

        return Number.isNaN(date.getTime())
            ? null
            : date
    }

    const normalized = stringValue
        .replace(' ', 'T')
        .slice(0, 19)

    const [datePart, timePart = '00:00:00'] =
        normalized.split('T')

    const dateParts = datePart
        .split('-')
        .map(Number)

    const timeParts = timePart
        .split(':')
        .map(Number)

    if (
        dateParts.length !== 3 ||
        dateParts.some(Number.isNaN)
    ) {
        return null
    }

    const [
        year,
        month,
        day
    ] = dateParts

    const [
        hour = 0,
        minute = 0,
        second = 0
    ] = timeParts.map((value) =>
        Number.isNaN(value) ? 0 : value
    )

    const date = new Date(
        year,
        month - 1,
        day,
        hour,
        minute,
        second
    )

    return Number.isNaN(date.getTime())
        ? null
        : date
}

/*
 * Convert a Date or date value into a local YYYY-MM-DD value.
 */
function localDateInputValue(value = new Date()) {
    if (typeof value === 'string') {
        const dateOnlyMatch = value.trim().match(/^(\d{4}-\d{2}-\d{2})/)

        if (dateOnlyMatch) {
            return dateOnlyMatch[1]
        }
    }

    const date = value instanceof Date
        ? value
        : new Date(value)

    if (Number.isNaN(date.getTime())) {
        return ''
    }

    const year = date.getFullYear()

    const month = String(
        date.getMonth() + 1
    ).padStart(2, '0')

    const day = String(
        date.getDate()
    ).padStart(2, '0')

    return `${year}-${month}-${day}`
}

/*
 * The assigned organization can schedule the start for today
 * or a later date. Earlier calendar days are unavailable.
 */
function minimumCommitmentDate() {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    return today
}

function formatDateTime(value) {
    if (!value) {
        return '-'
    }

    const date = mysqlDateTimeToLocalDate(value)

    if (!date) {
        return String(value)
    }

    return date.toLocaleString('en-PH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit'
    })
}

function formatDateOnly(value) {
    if (!value) return '—'

    const date = mysqlDateTimeToLocalDate(value)

    if (!date) return '—'

    return date.toLocaleDateString('en-PH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    })
}

function formatStatus(status) {
    const labels = {
        pending: 'Pending',
        in_progress: 'In Progress',
        on_hold: 'On Hold',
        resolved: 'Resolved',
        closed: 'Closed'
    }

    return labels[status] || status || '-'
}

function formatPriority(priority) {
    const labels = {
        low: 'Low',
        medium: 'Medium',
        high: 'High',
        urgent: 'Urgent'
    }

    return labels[priority] || priority || '-'
}

function statusClass(status) {
    const classes = {
        pending: 'bg-amber-100 text-amber-700',
        in_progress: 'bg-blue-100 text-blue-700',
        on_hold: 'bg-orange-100 text-orange-700',
        resolved: 'bg-green-100 text-green-700',
        closed: 'bg-slate-200 text-slate-700',
        cancelled: 'bg-red-100 text-red-700'
    }

    return classes[status] ||
        'bg-slate-100 text-slate-600'
}

function priorityClass(priority) {
    const classes = {
        low: 'bg-slate-100 text-slate-600',
        medium: 'bg-blue-100 text-blue-700',
        high: 'bg-orange-100 text-orange-700',
        urgent: 'bg-red-100 text-red-700'
    }

    return classes[priority] ||
        'bg-slate-100 text-slate-600'
}

function formatDate(value) {
    if (!value) {
        return '-'
    }

    const stringValue = String(value)

    if (
        !stringValue.includes('Z') &&
        !/[+-]\d{2}:\d{2}$/.test(stringValue)
    ) {
        const localDate =
            mysqlDateTimeToLocalDate(stringValue)

        if (localDate) {
            return localDate.toLocaleString(
                'en-PH',
                {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: 'numeric',
                    minute: '2-digit'
                }
            )
        }
    }

    const date = new Date(value)

    if (Number.isNaN(date.getTime())) {
        return value
    }

    return date.toLocaleString(
        'en-PH',
        {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        }
    )
}

function parseDate(value) {
    if (!value) {
        return null
    }

    return mysqlDateTimeToLocalDate(value)
}

function commitmentStartFromRemarks(remarks) {
    const match = String(remarks || '').match(
        /(?:commitment start(?: date)?|scheduled start(?: date(?:\/time)?)?|target resolution date):\s*(\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?)?)/i
    )

    return match ? parseDate(match[1]) : null
}

function getConcernDuration(concern) {
    if (!concern) {
        return 'Not started'
    }

    const histories =
        concernStatusHistory.value
            .slice()
            .sort((left, right) =>
                new Date(left.created_at) -
                new Date(right.created_at)
            )

    let elapsedMilliseconds = 0
    let activeSince = null
    const latestInProgressHistory = [...histories]
        .reverse()
        .find((history) => history.new_status === 'in_progress')
    const latestInProgressAt = parseDate(latestInProgressHistory?.created_at)
    const reopenedAfterResolution = Boolean(
        latestInProgressAt && histories.some((history) =>
            history.new_status === 'resolved' &&
            parseDate(history.created_at)?.getTime() < latestInProgressAt.getTime()
        )
    )

    for (const history of histories) {
        const changedAt =
            parseDate(history.created_at)

        if (!changedAt) {
            continue
        }

        if (
            history.new_status ===
            'in_progress'
        ) {
            activeSince =
                commitmentStartFromRemarks(history.remarks) ||
                (
                    history === latestInProgressHistory && !reopenedAfterResolution
                        ? parseDate(concern.target_commitment_at)
                        : null
                ) ||
                changedAt

        } else if (
            [
                'on_hold',
                'resolved',
                'closed',
                'cancelled'
            ].includes(history.new_status) &&
            activeSince
        ) {
            elapsedMilliseconds += Math.max(
                0,
                changedAt.getTime() -
                activeSince.getTime()
            )

            activeSince = null
        }
    }

    if (
        activeSince &&
        concern.status === 'in_progress'
    ) {
        elapsedMilliseconds += Math.max(
            0,
            currentTime.value.getTime() -
            activeSince.getTime()
        )
    }

    if (histories.length === 0) {
        const legacyStart = parseDate(concern.target_commitment_at)

        if (!legacyStart) {
            return 'Not started'
        }

        const end = concern.resolved_at
            ? parseDate(concern.resolved_at)
            : concern.status === 'in_progress'
                ? currentTime.value
                : null

        if (!end) {
            return 'Not started'
        }

        elapsedMilliseconds = Math.max(
            0,
            end.getTime() -
            legacyStart.getTime()
        )
    }

    if (
        elapsedMilliseconds <= 0 &&
        (!activeSince || currentTime.value.getTime() < activeSince.getTime())
    ) {
        return 'Not started'
    }

    if (elapsedMilliseconds <= 0) {
        return 'Not started'
    }

    const days = Math.floor(elapsedMilliseconds / 86400000)
    return `${days} day${days === 1 ? '' : 's'}`
}

function attachmentUrl(path) {
    if (!path) {
        return ''
    }

    if (
        path.startsWith('http://') ||
        path.startsWith('https://')
    ) {
        return path
    }

    return path.startsWith('/')
        ? path
        : `/${path}`
}

/*
 * ---------------------------------------------------------
 * PERMISSIONS
 * ---------------------------------------------------------
 */

function isConcernCompleted() {
    if (!selectedConcern.value) {
        return false
    }

    return (
        selectedConcern.value.status === 'closed' ||
        selectedConcern.value.status === 'cancelled'
    )
}

/*
 * Admin belongs to the organization that created
 * the concern.
 *
 * This admin is responsible for closing a concern
 * after the assigned organization resolves it.
 */
function isCreatorOrganizationAdmin() {
    if (!props.currentUser || !selectedConcern.value) return false

    return props.currentUser.role_name === 'concern_handler' &&
        props.currentUser.organization_id != null &&
        selectedConcern.value.creator_organization_id != null &&
        Number(props.currentUser.organization_id) === Number(selectedConcern.value.creator_organization_id)
}

/*
 * User belongs to the organization assigned
 * to handle the concern.
 */
function isAssignedOrganizationMember() {
    return Boolean(
        props.currentUser &&
        selectedConcern.value &&
        ['concern_handler', 'requestor'].includes(
            props.currentUser.role_name
        ) &&
        props.currentUser.organization_id != null &&
        selectedConcern.value.assigned_organization_id != null &&
        Number(
            selectedConcern.value.assigned_organization_id
        ) ===
        Number(props.currentUser.organization_id)
    )
}

/*
 * User belongs to the creator organization.
 *
 * Used for conversation access.
 */
function isCreatorOrganizationMember() {
    return Boolean(
        props.currentUser &&
        selectedConcern.value &&
        ['concern_handler', 'requestor'].includes(
            props.currentUser.role_name
        ) &&
        props.currentUser.organization_id != null &&
        selectedConcern.value.creator_organization_id != null &&
        Number(
            selectedConcern.value.creator_organization_id
        ) ===
        Number(props.currentUser.organization_id)
    )
}

function isAssignedAdmin() {
    return Boolean(
        props.currentUser &&
        selectedConcern.value &&
        props.currentUser.role_name === 'concern_handler' &&
        props.currentUser.organization_id != null &&
        selectedConcern.value.assigned_organization_id != null &&
        Number(props.currentUser.organization_id) ===
        Number(selectedConcern.value.assigned_organization_id)
    )
}

function canEditOriginalAttachments() {
    if (
        !props.currentUser ||
        !selectedConcern.value
    ) {
        return false
    }

    if (isConcernCompleted()) {
        return false
    }

    if (selectedConcern.value.deleted_at) {
        return false
    }

    return props.currentUser.role_name === 'superadmin' ||
        Number(selectedConcern.value.created_by) === Number(props.currentUser.id)
}

function canComment() {
    if (
        !props.currentUser ||
        !selectedConcern.value
    ) {
        return false
    }

    if (isConcernCompleted()) {
        return false
    }

    if (selectedConcern.value.deleted_at) {
        return false
    }

    if (['superadmin', 'system_admin', 'system_monitor'].includes(props.currentUser.role_name)) {
        return true
    }

    return (
        isCreatorOrganizationMember() ||
        isAssignedOrganizationMember()
    )
}

function canTrashConcern() {
    if (
        !props.currentUser ||
        !selectedConcern.value ||
        selectedConcern.value.status !== 'pending' ||
        selectedConcern.value.deleted_at
    ) {
        return false
    }

    if (props.currentUser.role_name === 'requestor') {
        return Number(selectedConcern.value.created_by) === Number(props.currentUser.id)
    }

    return isCreatorOrganizationAdmin()
}

function isTrashedConcern() {
    return Boolean(selectedConcern.value?.deleted_at)
}

function canRestoreTrashedConcern() {
    if (
        !selectedConcern.value ||
        !isTrashedConcern()
    ) {
        return false
    }

    if (['superadmin', 'system_admin'].includes(props.currentUser?.role_name)) {
        return true
    }

    if (selectedConcern.value.status !== 'pending') {
        return false
    }

    if (props.currentUser?.role_name === 'concern_handler') {
        return Number(props.currentUser.organization_id) ===
            Number(selectedConcern.value.creator_organization_id)
    }

    return props.currentUser?.role_name === 'requestor' &&
        Number(props.currentUser.id) === Number(selectedConcern.value.created_by)
}

function requestTrashConfirmation(action) {
    trashConfirmation.value = action
}

function cancelTrashConfirmation() {
    if (!updatingTrash.value) {
        trashConfirmation.value = ''
    }
}

async function confirmTrashAction() {
    const action = trashConfirmation.value

    if (!action || updatingTrash.value) {
        return
    }

    if (action === 'trash') {
        await trashConcern()
    } else if (action === 'restore') {
        await restoreConcern()
    } else if (action === 'purge') {
        await permanentlyDeleteConcern()
    }

    trashConfirmation.value = ''
}

async function trashConcern() {
    if (!canTrashConcern() || updatingTrash.value) {
        return
    }

    updatingTrash.value = true

    try {
        await $fetch(`/api/concerns/${selectedConcern.value.id}/trash`, {
            method: 'PATCH'
        })

        showToast('Concern moved to trash.', 'success')
        emit('refresh')
        emit('close')
    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            'Failed to move concern to trash.',
            'error'
        )
    } finally {
        updatingTrash.value = false
    }
}

async function restoreConcern() {
    if (
        !canRestoreTrashedConcern() ||
        updatingTrash.value
    ) {
        return
    }

    updatingTrash.value = true

    try {
        await $fetch(`/api/concerns/${selectedConcern.value.id}/restore`, {
            method: 'PATCH'
        })

        showToast('Concern restored successfully.', 'success')
        emit('refresh')
        emit('close')
    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            'Failed to restore concern.',
            'error'
        )
    } finally {
        updatingTrash.value = false
    }
}

async function permanentlyDeleteConcern() {
    if (
        !['superadmin', 'system_admin'].includes(props.currentUser?.role_name) ||
        !isTrashedConcern() ||
        updatingTrash.value
    ) {
        return
    }

    updatingTrash.value = true

    try {
        await $fetch(`/api/concerns/${selectedConcern.value.id}/purge`, {
            method: 'DELETE'
        })

        showToast('Concern permanently deleted.', 'success')
        emit('refresh')
        emit('close')
    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            'Failed to permanently delete concern.',
            'error'
        )
    } finally {
        updatingTrash.value = false
    }
}

/*
 * ---------------------------------------------------------
 * STATUS PERMISSIONS
 * ---------------------------------------------------------
 *
 * Assigned organization admin:
 *   Pending -> In Progress / On Hold
 *   In Progress -> Resolved
 *   On Hold -> In Progress
 *
 * Creator organization admin:
 *   Resolved -> In Progress (reopen) / Closed
 *
 * Regular users:
 *   No status changes.
 *
 * Cancellation is preserved in the backend, but it is
 * intentionally not exposed in this modal because the
 * existing UI did not provide a Cancel option.
 */

function canChangeToStatus(newStatus) {
    if (
        !props.currentUser ||
        !selectedConcern.value
    ) {
        return false
    }

    const currentStatus =
        selectedConcern.value.status

    if (newStatus === currentStatus) {
        return false
    }

    /*
     * Closing is only allowed for an admin
     * from the creator organization.
     */
    if (newStatus === 'closed') {
        return canCloseConcern()
    }

    if (
        newStatus === 'in_progress' &&
        isCreatorOrganizationAdmin() &&
        currentStatus === 'resolved'
    ) {
        return true
    }

    if (isAssignedAdmin()) {
        const transitions = {
            pending: ['in_progress', 'on_hold'],
            in_progress: ['resolved'],
            on_hold: ['in_progress'],
            resolved: [],
            closed: [],
            cancelled: []
        }

        return (
            transitions[currentStatus] || []
        ).includes(newStatus)
    }

    return false
}

function canUpdateStatus() {
    return (
        availableStatusOptions.value.length > 0
    )
}

const availableStatusOptions = computed(() => {
    if (
        !props.currentUser ||
        !selectedConcern.value
    ) {
        return []
    }

    const currentStatus =
        selectedConcern.value.status

    /*
     * Assigned organization admin.
     */
    if (isAssignedAdmin()) {
        const transitions = {
            pending: [
                { value: 'in_progress', label: 'In Progress' },
                { value: 'on_hold', label: 'On Hold' }
            ],

            in_progress: [
                { value: 'resolved', label: 'Resolved' }
            ],

            on_hold: [
                { value: 'in_progress', label: 'In Progress' }
            ]
        }

        return transitions[currentStatus] || []
    }

    /*
     * Creator organization admin can close
     * a resolved concern.
     */
    if (
        isCreatorOrganizationAdmin() &&
        currentStatus === 'resolved'
    ) {
        return [
            {
                value: 'in_progress',
                label: 'Reopen · In Progress'
            },
            {
                value: 'closed',
                label: 'Closed'
            }
        ]
    }

    return []
})

watch(selectedStatus, (status) => {
    if (
        status === 'in_progress' &&
        selectedConcern.value?.status !== 'in_progress'
    ) {
        targetCommitmentAt.value = null
    }
})

function canCloseConcern() {
    return Boolean(
        props.currentUser &&
        selectedConcern.value &&
        props.currentUser.role_name === 'concern_handler' &&
        selectedConcern.value.status === 'resolved' &&
        isCreatorOrganizationAdmin()
    )
}

/*
 * ---------------------------------------------------------
 * CREATOR ORGANIZATION ADMIN CLOSE
 * ---------------------------------------------------------
 */

function closeConcernByAdmin() {
    if (!canCloseConcern() || updatingStatus.value) {
        return
    }

    // Guide the admin to the existing status selector.
    // The concern is not closed until they select Closed
    // and submit the normal Update Status confirmation.
    nextTick(() => {
        statusSelectorSection.value?.scrollIntoView({
            behavior: 'smooth',
            block: 'center'
        })

        window.setTimeout(() => {
            const statusSelector = document.getElementById('concern-status')
            statusSelector?.focus()
        }, 450)
    })
}

/*
 * ---------------------------------------------------------
 * STATUS FIELD RULES
 * ---------------------------------------------------------
 */

function canSetCommitmentForStatusChange() {
    return isAssignedAdmin()
}

function isCommitmentDateRequired() {
    return (
        canSetCommitmentForStatusChange() &&
        selectedStatus.value === 'in_progress' &&
        selectedConcern.value?.status !== 'in_progress'
    )
}

function isRemarksRequired() {
    if (!selectedConcern.value) {
        return false
    }

    if (
        isCreatorOrganizationAdmin() &&
        selectedConcern.value.status === 'resolved' &&
        selectedStatus.value === 'in_progress'
    ) {
        return true
    }

    const canManageInProgress =
        canSetCommitmentForStatusChange()

    if (!canManageInProgress) {
        return false
    }

    return (
        selectedStatus.value === 'in_progress' ||

        (
            isAssignedAdmin() &&
            selectedStatus.value === 'on_hold'
        ) ||

        (
            isAssignedAdmin() &&
            selectedConcern.value.status === 'in_progress' &&
            selectedStatus.value === 'resolved'
        )
    )
}

function statusRemarksPlaceholder() {
    if (isAssignedAdmin() && selectedStatus.value === 'on_hold') {
        return 'Explain why this concern is being placed on hold...'
    }

    if (
        isCreatorOrganizationAdmin() &&
        selectedConcern.value?.status === 'resolved' &&
        selectedStatus.value === 'in_progress'
    ) {
        return 'Explain why the reported resolution is rejected and what work remains...'
    }

    if (isAssignedAdmin() && selectedStatus.value === 'in_progress') {
        return 'Explain what work is starting or continuing...'
    }

    if (
        isAssignedAdmin() &&
        selectedConcern.value?.status === 'in_progress' &&
        selectedStatus.value === 'resolved'
    ) {
        return 'Explain what was done to resolve the concern...'
    }

    return 'Add notes about this status change...'
}

/*
 * ---------------------------------------------------------
 * LOAD CONCERN
 * ---------------------------------------------------------
 */

async function loadConcernDetails() {
    if (!props.concernId) {
        return
    }

    loadingConcernDetails.value = true

    try {
        const response = await $fetch(
            `/api/concerns/${props.concernId}`,
            {
                cache: 'no-store'
            }
        )

        selectedConcern.value = response.concern
        activeConcernTab.value = 'overview'
        visibleCommentCount.value = 10
        showAllStatusHistory.value = false

        concernComments.value =
            response.comments || []

        concernAttachments.value =
            response.attachments || []

        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern?.status || ''

        targetCommitmentAt.value = mysqlDateTimeToLocalDate(
            response.concern?.target_commitment_at
        )

        statusRemarks.value = ''

        clearCommentImages()
        clearStatusImages()
        clearAdditionalImages()
        clearReplacementImage()

    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load concern details.',
            'error'
        )

        emit('close')

    } finally {
        loadingConcernDetails.value = false
    }
}

async function refreshConcernDetails() {
    if (!selectedConcern.value?.id) {
        return
    }

    try {
        const response = await $fetch(
            `/api/concerns/${selectedConcern.value.id}`,
            {
                cache: 'no-store'
            }
        )

        selectedConcern.value = response.concern

        concernComments.value =
            response.comments || []

        concernAttachments.value =
            response.attachments || []

        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern?.status || ''

        targetCommitmentAt.value = mysqlDateTimeToLocalDate(
            response.concern?.target_commitment_at
        )

    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to refresh concern details.',
            'error'
        )
    }
}

/*
 * ---------------------------------------------------------
 * CLOSE MODAL
 * ---------------------------------------------------------
 */

function closeViewModal() {
    if (
        savingComment.value ||
        updatingStatus.value ||
        updatingTrash.value ||
        addingAttachments.value ||
        replacingAttachmentId.value
    ) {
        return
    }

    clearCommentImages()
    clearStatusImages()
    clearAdditionalImages()
    clearReplacementImage()

    closeImageViewer()

    selectedConcern.value = null
    concernComments.value = []
    concernAttachments.value = []
    concernStatusHistory.value = []
    activeConcernTab.value = 'overview'
    visibleCommentCount.value = 10
    showAllStatusHistory.value = false

    selectedStatus.value = ''
    statusRemarks.value = ''
    targetCommitmentAt.value = null
    newComment.value = ''
    trashConfirmation.value = ''

    editingAttachmentId.value = null

    emit('close')
}

function handleConcernTabKeydown(event) {
    if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) {
        return
    }

    event.preventDefault()
    activeConcernTab.value = event.key === 'ArrowLeft' || event.key === 'Home'
        ? 'overview'
        : 'conversation'

    nextTick(() => {
        document.getElementById(`concern-tab-${activeConcernTab.value}`)?.focus()
    })
}

/*
 * ---------------------------------------------------------
 * IMAGE VIEWER
 * ---------------------------------------------------------
 */


function openImageViewer(attachment) {
    if (!attachment?.file_path) {
        return
    }

    selectedViewerImage.value = {
        url: attachmentUrl(attachment.file_path),
        name: attachment.file_name || 'Image'
    }

    showImageViewer.value = true
}

function openProfilePhotoViewer(comment) {
    if (!comment?.profile_photo) {
        return
    }

    selectedViewerImage.value = {
        url: comment.profile_photo,
        name: `${comment.user_name || 'User'} profile photo`
    }

    showImageViewer.value = true
}

function closeImageViewer() {
    showImageViewer.value = false
    selectedViewerImage.value = null
}

/*
 * ---------------------------------------------------------
 * COMMENT IMAGES
 * ---------------------------------------------------------
 */

function handleCommentImagesChange(event) {
    const files = Array.from(
        event.target.files || []
    )

    if (files.length === 0) {
        return
    }

    const validImageTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    const maxSize = 5 * 1024 * 1024

    for (const file of files) {
        if (!validImageTypes.includes(file.type)) {
            showToast(
                `Invalid image format: ${file.name}. Please upload JPG, PNG, GIF, or WEBP.`,
                'error'
            )

            event.target.value = ''

            return
        }

        if (file.size > maxSize) {
            showToast(
                `Image is too large: ${file.name}. Maximum size is 5 MB.`,
                'error'
            )

            event.target.value = ''

            return
        }
    }

    selectedCommentImages.value = [
        ...selectedCommentImages.value,
        ...files
    ]

    for (const file of files) {
        const previewUrl = URL.createObjectURL(file)

        commentImagePreviews.value.push({
            file,
            url: previewUrl
        })
    }

    event.target.value = ''
}

function removeCommentImage(index) {
    const preview =
        commentImagePreviews.value[index]

    if (preview?.url) {
        URL.revokeObjectURL(preview.url)
    }

    selectedCommentImages.value.splice(index, 1)
    commentImagePreviews.value.splice(index, 1)
}

function clearCommentImages() {
    for (const preview of commentImagePreviews.value) {
        if (preview?.url) {
            URL.revokeObjectURL(preview.url)
        }
    }

    selectedCommentImages.value = []
    commentImagePreviews.value = []

    if (commentImageInput.value) {
        commentImageInput.value.value = ''
    }
}

function setCommentImageInput(element) {
    commentImageInput.value = element
}

function setReplacementInput(element) {
    replacementInput.value = element
}

function setAdditionalAttachmentInput(element) {
    additionalAttachmentInput.value = element
}

function setStatusImageInput(element) {
    statusImageInput.value = element
}

function setStatusSelectorSection(element) {
    statusSelectorSection.value = element
}

function triggerAdditionalAttachmentSelection() {
    additionalAttachmentInput.value?.click()
}

/*
 * ---------------------------------------------------------
 * STATUS EVIDENCE IMAGES
 * ---------------------------------------------------------
 */

function handleStatusImagesChange(event) {
    const files = Array.from(
        event.target.files || []
    )

    if (files.length === 0) {
        return
    }

    const allowedTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    const maxSize = 5 * 1024 * 1024

    for (const file of files) {
        if (!allowedTypes.includes(file.type)) {
            showToast(
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`,
                'error'
            )

            event.target.value = ''

            return
        }

        if (file.size > maxSize) {
            showToast(
                `${file.name} exceeds the 5 MB limit.`,
                'error'
            )

            event.target.value = ''

            return
        }
    }

    selectedStatusImages.value = [
        ...selectedStatusImages.value,
        ...files
    ]

    for (const file of files) {
        const previewUrl = URL.createObjectURL(file)

        statusImagePreviews.value.push({
            file,
            url: previewUrl
        })
    }

    event.target.value = ''
}

function removeStatusImage(index) {
    const preview =
        statusImagePreviews.value[index]

    if (preview?.url) {
        URL.revokeObjectURL(preview.url)
    }

    selectedStatusImages.value.splice(index, 1)
    statusImagePreviews.value.splice(index, 1)
}

function clearStatusImages() {
    for (const preview of statusImagePreviews.value) {
        if (preview?.url) {
            URL.revokeObjectURL(preview.url)
        }
    }

    selectedStatusImages.value = []
    statusImagePreviews.value = []

    if (statusImageInput.value) {
        statusImageInput.value.value = ''
    }
}

/*
 * ---------------------------------------------------------
 * COMMENTS
 * ---------------------------------------------------------
 */

async function addComment(confirmed = false) {
    if (!selectedConcern.value?.id) {
        return
    }

    if (!canComment()) {
        showToast(
            'You do not have permission to comment on this concern.',
            'error'
        )

        return
    }

    if (
        !newComment.value.trim() &&
        selectedCommentImages.value.length === 0
    ) {
        showToast(
            'Please enter a comment or attach at least one image.',
            'error'
        )

        return
    }

    if (!confirmed) {
        requestConfirmation('comment')
        return
    }

    savingComment.value = true

    try {
        const formData = new FormData()

        formData.append(
            'comment',
            newComment.value.trim()
        )

        for (const file of selectedCommentImages.value) {
            formData.append('attachments', file)
        }

        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/comments`,
            {
                method: 'POST',
                body: formData
            }
        )

        newComment.value = ''

        clearCommentImages()

        await refreshConcernDetails()

        emit('refresh')

        showToast(
            'Comment added successfully.',
            'success'
        )

    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to add comment.',
            'error'
        )

    } finally {
        savingComment.value = false
    }
}

/*
 * ---------------------------------------------------------
 * ORIGINAL ATTACHMENTS
 * ---------------------------------------------------------
 */

function triggerAttachmentReplace(attachment) {
    if (!canEditOriginalAttachments()) {
        return
    }

    if (
        replacingAttachmentId.value ||
        addingAttachments.value
    ) {
        return
    }

    clearReplacementImage()

    editingAttachmentId.value = attachment.id

    nextTick(() => {
        replacementInput.value?.click()
    })
}

function handleAttachmentReplacement(event) {
    const file = event.target.files?.[0]

    if (!file) {
        event.target.value = ''
        return
    }

    if (!editingAttachmentId.value) {
        event.target.value = ''
        return
    }

    if (!canEditOriginalAttachments()) {
        event.target.value = ''
        editingAttachmentId.value = null

        return
    }

    const validImageTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    const maxSize = 5 * 1024 * 1024

    if (!validImageTypes.includes(file.type)) {
        showToast(
            'Invalid image format. Please upload JPG, PNG, GIF, or WEBP.',
            'error'
        )

        event.target.value = ''

        return
    }

    if (file.size > maxSize) {
        showToast(
            'Image is too large. Maximum size is 5 MB.',
            'error'
        )

        event.target.value = ''

        return
    }

    clearReplacementPreviewOnly()

    selectedReplacementImage.value = file

    replacementImagePreview.value = {
        file,
        url: URL.createObjectURL(file)
    }

    /*
     * No API request is made here.
     * The image is only staged until the user
     * clicks Save Replacement.
     */

    event.target.value = ''
}

function clearReplacementPreviewOnly() {
    if (replacementImagePreview.value?.url) {
        URL.revokeObjectURL(
            replacementImagePreview.value.url
        )
    }

    selectedReplacementImage.value = null
    replacementImagePreview.value = null
}

function clearReplacementImage() {
    clearReplacementPreviewOnly()

    editingAttachmentId.value = null

    if (replacementInput.value) {
        replacementInput.value.value = ''
    }
}

async function saveAttachmentReplacement(confirmed = false) {
    if (
        !selectedConcern.value?.id ||
        !editingAttachmentId.value ||
        !selectedReplacementImage.value
    ) {
        return
    }

    if (!canEditOriginalAttachments()) {
        clearReplacementImage()

        showToast(
            'You do not have permission to replace attachments on this concern.',
            'error'
        )

        return
    }

    if (!confirmed) {
        requestConfirmation('replaceAttachment')
        return
    }

    replacingAttachmentId.value =
        editingAttachmentId.value

    try {
        const formData = new FormData()

        formData.append(
            'attachment_id',
            String(editingAttachmentId.value)
        )

        formData.append(
            'image',
            selectedReplacementImage.value
        )

        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/attachments`,
            {
                method: 'PUT',
                body: formData
            }
        )

        clearReplacementImage()

        await refreshConcernDetails()

        emit('refresh')

        showToast(
            'Attachment replaced successfully.',
            'success'
        )

    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to replace attachment.',
            'error'
        )

    } finally {
        replacingAttachmentId.value = null
    }
}

/*
 * ---------------------------------------------------------
 * ADDITIONAL ATTACHMENTS
 * ---------------------------------------------------------
 */

function handleAdditionalAttachments(event) {
    if (!canEditOriginalAttachments()) {
        event.target.value = ''
        return
    }

    const files = Array.from(
        event.target.files || []
    )

    if (files.length === 0) {
        event.target.value = ''
        return
    }

    const allowedTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    const maxSize = 5 * 1024 * 1024

    for (const file of files) {
        if (!allowedTypes.includes(file.type)) {
            showToast(
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`,
                'error'
            )

            event.target.value = ''

            return
        }

        if (file.size > maxSize) {
            showToast(
                `${file.name} exceeds the 5 MB limit.`,
                'error'
            )

            event.target.value = ''

            return
        }
    }

    selectedAdditionalImages.value = [
        ...selectedAdditionalImages.value,
        ...files
    ]

    for (const file of files) {
        const previewUrl = URL.createObjectURL(file)

        additionalImagePreviews.value.push({
            file,
            url: previewUrl
        })
    }

    event.target.value = ''
}

function removeAdditionalImage(index) {
    const preview =
        additionalImagePreviews.value[index]

    if (preview?.url) {
        URL.revokeObjectURL(preview.url)
    }

    selectedAdditionalImages.value.splice(index, 1)
    additionalImagePreviews.value.splice(index, 1)
}

function clearAdditionalImages() {
    for (const preview of additionalImagePreviews.value) {
        if (preview?.url) {
            URL.revokeObjectURL(preview.url)
        }
    }

    selectedAdditionalImages.value = []
    additionalImagePreviews.value = []

    if (additionalAttachmentInput.value) {
        additionalAttachmentInput.value.value = ''
    }
}

async function attachAdditionalImages(confirmed = false) {
    if (
        !selectedConcern.value?.id ||
        selectedAdditionalImages.value.length === 0
    ) {
        return
    }

    if (!canEditOriginalAttachments()) {
        clearAdditionalImages()

        showToast(
            'You do not have permission to add attachments to this concern.',
            'error'
        )

        return
    }

    if (!confirmed) {
        requestConfirmation('addAttachments')
        return
    }

    addingAttachments.value = true

    const imageCount =
        selectedAdditionalImages.value.length

    try {
        const formData = new FormData()

        for (const file of selectedAdditionalImages.value) {
            formData.append('images', file)
        }

        const response = await $fetch(
            `/api/concerns/${selectedConcern.value.id}/attachments`,
            {
                method: 'POST',
                body: formData
            }
        )

        if (!response?.success) {
            throw new Error(
                response?.message ||
                'Failed to add attachments.'
            )
        }

        clearAdditionalImages()

        await refreshConcernDetails()

        emit('refresh')

        showToast(
            `${imageCount} image${imageCount === 1 ? '' : 's'} attached successfully.`,
            'success'
        )

    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.data?.message ||
            error?.statusMessage ||
            error?.message ||
            'Failed to add attachments.',
            'error'
        )

    } finally {
        addingAttachments.value = false
    }
}

/*
 * ---------------------------------------------------------
 * REMOVE ORIGINAL ATTACHMENT
 * ---------------------------------------------------------
 */

async function removeOriginalAttachment(attachment, confirmed = false) {
    if (!canEditOriginalAttachments()) {
        return
    }

    if (!confirmed) {
        requestConfirmation('removeAttachment', { attachment })
        return
    }

    if (
        Number(editingAttachmentId.value) ===
        Number(attachment.id)
    ) {
        clearReplacementImage()
    }

    deletingAttachmentId.value = attachment.id

    try {
        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/attachments`,
            {
                method: 'DELETE',
                body: {
                    attachment_id: attachment.id
                }
            }
        )

        await refreshConcernDetails()

        emit('refresh')

        showToast(
            'Attachment removed successfully.',
            'success'
        )

    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to remove attachment.',
            'error'
        )

    } finally {
        deletingAttachmentId.value = null
    }
}

/*
 * ---------------------------------------------------------
 * UPDATE CONCERN STATUS
 * ---------------------------------------------------------
 */

async function updateConcernStatus(confirmed = false) {
    if (!selectedConcern.value?.id) {
        return
    }

    if (
        !selectedStatus.value ||
        selectedStatus.value === selectedConcern.value.status
    ) {
        return
    }

    const targetStatus = selectedStatus.value

    /*
     * Frontend permission check.
     */
    if (!canChangeToStatus(targetStatus)) {
        showToast(
            'You do not have permission to make this status change.',
            'error'
        )

        return
    }

    /*
     * Closed concerns can only be closed by
     * an admin from the creator organization
     * after the concern is resolved.
     */
    if (
        targetStatus === 'closed' &&
        !canCloseConcern()
    ) {
        showToast(
            'Only an admin in the concern creator’s organization can close a resolved concern.',
            'error'
        )

        return
    }

    /*
     * Moving into In Progress requires a
    * recipient's committed start date.
     */
    const movingToInProgress = isAssignedAdmin() &&
        targetStatus === 'in_progress' &&
        selectedConcern.value.status !== 'in_progress'

    if (
        movingToInProgress &&
        !targetCommitmentAt.value
    ) {
        showToast(
            'Please set the committed start date before moving the concern to In Progress.',
            'error'
        )

        return
    }

    /*
    * Do not allow a commitment date before today.
     */
    if (
        movingToInProgress &&
        targetCommitmentAt.value
    ) {
        const selectedDate = localDateInputValue(targetCommitmentAt.value)

        const today = localDateInputValue(
            minimumCommitmentDate()
        )

        if (selectedDate < today) {
            showToast(
                'The commitment date cannot be before today.',
                'error'
            )

            return
        }
    }

    /*
     * Required remarks.
     */
    if (
        isRemarksRequired() &&
        !statusRemarks.value.trim()
    ) {
        showToast(
            targetStatus === 'on_hold'
                ? 'Please explain why the concern is being placed on hold.'
                : 'Please enter remarks for this status change.',
            'error'
        )

        return
    }

    /*
     * Resolution requires remarks.
     */
    const resolvingConcern =
        isAssignedAdmin() &&
        selectedConcern.value.status === 'in_progress' &&
        targetStatus === 'resolved'

    if (
        resolvingConcern &&
        !statusRemarks.value.trim()
    ) {
        showToast(
            'Please enter remarks explaining what was done before marking the concern as resolved.',
            'error'
        )

        return
    }

    /*
     * Resolution requires at least one evidence image.
     */
    if (
        resolvingConcern &&
        selectedStatusImages.value.length === 0
    ) {
        showToast(
            'Please attach at least one evidence image before marking the concern as resolved.',
            'error'
        )

        return
    }

    if (!confirmed) {
        requestConfirmation('status')
        return
    }

    updatingStatus.value = true

    try {
        const formData = new FormData()

        formData.append(
            'status',
            targetStatus
        )

        formData.append(
            'remarks',
            statusRemarks.value.trim()
        )

        if (movingToInProgress) {
            formData.append(
                'target_commitment_at',
                localDateInputValue(targetCommitmentAt.value)
            )
        }

        /*
         * Send all selected evidence images.
         */
        for (const file of selectedStatusImages.value) {
            formData.append(
                'images',
                file
            )
        }

        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/status`,
            {
                method: 'PUT',
                body: formData
            }
        )

        statusRemarks.value = ''

        clearStatusImages()

        /*
         * Reload the concern from the database
         * after the status update.
         *
         * This ensures the modal displays the
         * actual saved status and datetime.
         */
        await refreshConcernDetails()

        emit('refresh')

        showToast(
            targetStatus === 'resolved'
                ? 'Concern resolved successfully with evidence.'
                : targetStatus === 'closed'
                    ? 'Concern closed successfully.'
                    : 'Concern status updated successfully.',
            'success'
        )

    } catch (error) {
        showToast(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to update concern status.',
            'error'
        )

    } finally {
        updatingStatus.value = false
    }
}

/*
 * ---------------------------------------------------------
 * LIFECYCLE
 * ---------------------------------------------------------
 */

watch(
    [
        () => props.show,
        () => props.concernId
    ],
    ([visible, concernId]) => {
        if (visible && concernId) {
            loadConcernDetails()
        }
    },
    { immediate: true }
)

onMounted(() => {
    durationTimer = setInterval(() => {
        currentTime.value = new Date()
    }, 60000)
})

onUnmounted(() => {
    if (durationTimer) {
        clearInterval(durationTimer)
    }

    clearCommentImages()
    clearStatusImages()
    clearAdditionalImages()
    clearReplacementImage()
})

</script>


<template>

    <ConfirmActionModal
        :show="Boolean(pendingConfirmation)"
        :title="confirmationDetails.title"
        :message="confirmationDetails.message"
        :confirm-label="confirmationDetails.confirmLabel"
        :tone="confirmationDetails.tone"
        :loading="confirmationLoading"
        @confirm="confirmPendingAction"
        @cancel="cancelPendingConfirmation"
    />

    <div v-if="show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 px-2 py-3 backdrop-blur-[2px] sm:items-center sm:px-4 sm:py-6">

        <div
            class="modal-height-adaptive my-auto flex max-h-[calc(100dvh-1.5rem)] w-full max-w-7xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-3rem)]">

            <!-- Header -->
            <div
                class="modal-header-adaptive flex shrink-0 items-center justify-between gap-3 border-b border-slate-200 bg-white px-4 py-4 sm:px-6 sm:py-5">

                <div>

                    <p class="text-xs font-semibold uppercase tracking-[0.16em] text-blue-700">
                        Concern Workspace
                    </p>

                    <h3 class="mt-1 text-xl font-semibold text-slate-900">
                        {{ selectedConcern?.title || 'Concern Details' }}
                    </h3>

                    <p class="mt-1 text-sm text-slate-500">
                        {{ selectedConcern?.concern_number || 'Ticket' }}
                    </p>

                    <div v-if="selectedConcern" class="mt-2 flex flex-wrap gap-2">
                        <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-700">
                            {{ formatStatus(selectedConcern.status) }}
                        </span>
                        <span class="rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-semibold text-amber-800">
                            {{ formatPriority(selectedConcern.priority) }} priority
                        </span>
                    </div>

                </div>

                <button type="button" @click="closeViewModal" :disabled="savingComment || updatingStatus || updatingTrash || addingAttachments || replacingAttachmentId"
                    aria-label="Close modal"
                    class="group relative flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center text-3xl leading-none text-red-700 transition-colors duration-200 hover:text-red-800 disabled:cursor-not-allowed disabled:opacity-50">
                    <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                        stroke="currentColor" aria-hidden="true"
                        class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                    </svg>
                </button>

            </div>

            <div v-if="selectedConcern" class="shrink-0 border-b border-slate-200 bg-white px-4 py-2 sm:px-6">
                <div
                    class="flex overflow-hidden rounded-xl border border-slate-200 bg-slate-100 shadow-sm"
                    role="tablist"
                    aria-label="Concern sections"
                    @keydown="handleConcernTabKeydown"
                >
                    <button
                        id="concern-tab-overview"
                        type="button"
                        role="tab"
                        aria-controls="concern-panel-overview"
                        :aria-selected="activeConcernTab === 'overview'"
                        :tabindex="activeConcernTab === 'overview' ? 0 : -1"
                        class="flex min-h-10 flex-1 cursor-pointer items-center justify-center gap-2 rounded-l-xl px-3 py-2 text-sm font-semibold transition focus:z-10 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-inset"
                        :class="activeConcernTab === 'overview'
                            ? 'bg-blue-900 text-white shadow-sm'
                            : 'text-slate-600 hover:bg-slate-50 hover:text-blue-900'"
                        @click="activeConcernTab = 'overview'"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 5.25A1.5 1.5 0 0 1 5.25 3.75h5.25v7.5H3.75v-6Zm9.75-1.5h5.25a1.5 1.5 0 0 1 1.5 1.5v3a1.5 1.5 0 0 1-1.5 1.5H13.5v-6Zm-9.75 10.5h5.25v6H5.25a1.5 1.5 0 0 1-1.5-1.5v-4.5Zm9.75 0h6.75v4.5a1.5 1.5 0 0 1-1.5 1.5H13.5v-6Z" />
                        </svg>
                        Overview
                    </button>
                    <button
                        id="concern-tab-conversation"
                        type="button"
                        role="tab"
                        aria-controls="concern-panel-conversation"
                        :aria-selected="activeConcernTab === 'conversation'"
                        :tabindex="activeConcernTab === 'conversation' ? 0 : -1"
                        class="flex min-h-10 flex-1 cursor-pointer items-center justify-center gap-2 rounded-r-xl px-3 py-2 text-sm font-semibold transition focus:z-10 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-inset"
                        :class="activeConcernTab === 'conversation'
                            ? 'bg-blue-900 text-white shadow-sm'
                            : 'text-slate-600 hover:bg-slate-50 hover:text-blue-900'"
                        @click="activeConcernTab = 'conversation'"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3.75h6m-9.75 7.5 2.6-3.12a2.25 2.25 0 0 1 1.73-.81h9.17A2.25 2.25 0 0 0 19.5 13.3V5.25A2.25 2.25 0 0 0 17.25 3h-10.5A2.25 2.25 0 0 0 4.5 5.25v14.25Z" />
                        </svg>
                        Conversation
                        <span
                            class="rounded-full px-2 py-0.5 text-[10px] font-bold tabular-nums"
                            :class="activeConcernTab === 'conversation' ? 'bg-white/15 text-white' : 'bg-slate-100 text-slate-600'"
                        >
                            {{ concernComments.length }}
                        </span>
                    </button>
                </div>
            </div>

            <!-- Body -->
            <div class="flex-1 overflow-y-auto bg-slate-50 px-3 py-4 sm:px-6 sm:py-5">

                <!-- Loading -->
                <div v-if="loadingConcernDetails" class="flex min-h-[300px] items-center justify-center">

                    <div class="text-center">

                        <div
                            class="mx-auto h-8 w-8 animate-spin rounded-full border-2 border-slate-300 border-t-slate-800">
                        </div>

                        <p class="mt-3 text-sm text-slate-500">
                            Loading concern details...
                        </p>

                    </div>

                </div>

                <div v-else-if="selectedConcern" class="space-y-5">

                    <div v-if="activeConcernTab === 'overview'" id="concern-panel-overview" role="tabpanel" aria-labelledby="concern-tab-overview" class="space-y-5">

                    <!-- Pending Recipient Notice -->
                    <div v-if="
                        isAssignedAdmin() &&
                        selectedConcern.status === 'pending'
                    " class="rounded-xl border border-blue-200 bg-blue-50 p-4">

                        <p class="text-sm font-semibold text-blue-800">
                            New concern assigned to your organization
                        </p>

                        <p class="mt-1 text-xs leading-5 text-blue-700">
                            Select
                            <span class="font-semibold">
                                In Progress
                            </span>
                            to set when your team will begin handling the concern and add an update, or select
                            <span class="font-semibold">
                                On Hold
                            </span>
                            with a reason if work cannot start yet.
                        </p>

                    </div>

                    <!-- In Progress Recipient Notice -->
                    <div v-if="
                        isAssignedAdmin() &&
                        selectedConcern.status === 'in_progress'
                    " class="rounded-xl border border-blue-200 bg-blue-50 p-4">

                        <p class="text-sm font-semibold text-blue-800">
                            You are currently handling this concern
                        </p>

                        <p class="mt-1 text-xs leading-5 text-blue-700">
                            Handling duration counts while the concern is In Progress and pauses while it is On Hold.
                            When the work is completed, select
                            <span class="font-semibold">
                                Resolved
                            </span>
                            and provide remarks and at least one evidence image.
                        </p>

                    </div>

                    <!-- On Hold Recipient Notice -->
                    <div v-if="
                        isAssignedAdmin() &&
                        selectedConcern.status === 'on_hold'
                    " class="rounded-xl border border-orange-200 bg-orange-50 p-4">

                        <p class="text-sm font-semibold text-orange-800">
                            This concern is currently on hold
                        </p>

                        <p class="mt-1 text-xs leading-5 text-orange-700">
                            When work can continue, select
                            <span class="font-semibold">
                                In Progress
                            </span>
                            and set when your team will resume handling the concern.
                        </p>

                    </div>

                    <!-- Resolved Notice -->
                    <div v-if="selectedConcern.status === 'resolved'"
                        class="rounded-xl border border-green-200 bg-green-50 p-4">

                        <p class="text-sm font-semibold text-green-800">
                            Concern resolved
                        </p>

                        <p v-if="canCloseConcern()" class="mt-1 text-xs leading-5 text-green-700">
                            Please review the resolution remarks and evidence below.
                            If the concern has been properly resolved, you can close it.
                        </p>

                        <p v-else class="mt-1 text-xs leading-5 text-green-700">
                            The assigned organization has marked this concern as resolved.
                        </p>

                        <!-- Guide creator admin to the status selector -->
                        <div v-if="canCloseConcern()" class="mt-4">

                            <button type="button" @click="closeConcernByAdmin" :disabled="updatingStatus"
                                class="inline-flex cursor-pointer items-center gap-2 rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-green-800 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke-width="2" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M7 7h10v10M17 7l-10 10" />
                                </svg>
                                Review &amp; Close Concern
                            </button>

                            <p class="mt-2 text-xs text-green-700">
                                You will be directed to the status selector to choose Closed and submit the update.
                            </p>

                        </div>

                    </div>

                    <!-- Trashed Concern Controls -->
                    <div v-if="isTrashedConcern() && (currentUser?.role_name === 'superadmin' || canRestoreTrashedConcern())"
                        class="flex flex-col gap-3 rounded-xl border border-red-200 bg-red-50 p-4 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <p class="text-sm font-semibold text-red-900">This concern is in trash</p>
                            <p class="mt-1 text-xs text-red-700">
                                Trashed {{ formatDate(selectedConcern.deleted_at) }}
                                <span v-if="selectedConcern.deleted_by_name">by {{ selectedConcern.deleted_by_name }}</span>.
                                Restore this pending concern before its 30-day retention period ends. Expired trash is permanently deleted automatically; superadmins can delete it sooner.
                            </p>
                        </div>
                        <div class="flex shrink-0 gap-2">
                            <button v-if="canRestoreTrashedConcern()" type="button" @click="requestTrashConfirmation('restore')" :disabled="updatingTrash"
                                class="secondary-hover-button cursor-pointer rounded-lg border border-green-300 bg-white px-3 py-2 text-xs font-semibold text-green-800 transition hover:bg-green-50 disabled:opacity-50">
                                Restore
                            </button>
                            <button v-if="currentUser?.role_name === 'superadmin'" type="button" @click="requestTrashConfirmation('purge')" :disabled="updatingTrash"
                                class="cursor-pointer rounded-lg bg-red-700 px-3 py-2 text-xs font-semibold text-white transition hover:bg-red-800 disabled:opacity-50">
                                Permanently Delete
                            </button>
                        </div>

                        <div v-if="trashConfirmation" class="w-full rounded-lg border border-red-200 bg-white p-4 sm:col-span-2">
                            <p class="text-sm font-semibold text-slate-800">
                                {{ trashConfirmation === 'restore'
                                    ? 'Restore this pending concern?'
                                    : 'Permanently delete this concern and its attachments, comments, and history? This cannot be undone.' }}
                            </p>
                            <div class="mt-3 flex justify-end gap-2">
                                <button type="button" @click="cancelTrashConfirmation" :disabled="updatingTrash"
                                    class="secondary-hover-button cursor-pointer rounded-lg border border-slate-300 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50">
                                    Cancel
                                </button>
                                <button type="button" @click="confirmTrashAction" :disabled="updatingTrash"
                                    class="cursor-pointer rounded-lg bg-red-700 px-3 py-2 text-xs font-semibold text-white hover:bg-red-800 disabled:opacity-50">
                                    {{ updatingTrash ? 'Working...' : 'Confirm' }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <div v-if="trashConfirmation === 'trash'" class="rounded-xl border border-red-200 bg-red-50 p-4">
                        <p class="text-sm font-semibold text-red-900">
                            Move this pending concern to trash?
                        </p>
                        <p class="mt-1 text-xs leading-5 text-red-700">
                            Authorized organization members can restore it while it remains pending.
                        </p>
                        <div class="mt-3 flex justify-end gap-2">
                            <button type="button" @click="cancelTrashConfirmation" :disabled="updatingTrash"
                                    class="secondary-hover-button cursor-pointer rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50">
                                Cancel
                            </button>
                            <button type="button" @click="confirmTrashAction" :disabled="updatingTrash"
                                class="cursor-pointer rounded-lg bg-red-700 px-3 py-2 text-xs font-semibold text-white hover:bg-red-800 disabled:opacity-50">
                                {{ updatingTrash ? 'Moving...' : 'Move to Trash' }}
                            </button>
                        </div>
                    </div>

                    <div class="view-concern-sections grid gap-5 lg:grid-cols-2">

                    <!-- Main Information -->
                    <div class="view-concern-main overflow-hidden rounded-xl border border-blue-100 bg-white p-5 shadow-lg shadow-blue-950/5">

                        <div class="mb-5 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">

                            <div>
                                <h4 class="text-base font-semibold text-slate-800">
                                    Main Information
                                </h4>

                                <p class="mt-1 text-sm text-slate-500">
                                    Details of this concern.
                                </p>
                            </div>

                            <button v-if="canTrashConcern()" type="button" @click="requestTrashConfirmation('trash')"
                                :disabled="updatingTrash"
                                class="inline-flex cursor-pointer items-center justify-center gap-2 self-start rounded-lg border border-red-200 bg-white px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-50">
                                <span aria-hidden="true">♲</span>
                                {{ updatingTrash ? 'Moving...' : 'Move to Trash' }}
                            </button>

                        </div>

                        <div class="grid gap-5 md:grid-cols-2">

                            <!-- Title -->
                            <div class="md:col-span-2">

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Title
                                </p>

                                <p class="text-sm font-semibold text-slate-800">
                                    {{ selectedConcern.title || '-' }}
                                </p>

                            </div>

                            <!-- Priority -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Priority
                                </p>

                                <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold"
                                    :class="priorityClass(selectedConcern.priority)">
                                    {{
                                        formatPriority(
                                            selectedConcern.priority
                                        )
                                    }}
                                </span>

                            </div>

                            <!-- Status -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Status
                                </p>

                                <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold"
                                    :class="statusClass(selectedConcern.status)">
                                    {{
                                        formatStatus(
                                            selectedConcern.status
                                        )
                                    }}
                                </span>

                                <span v-if="
                                    selectedConcern.status === 'closed'
                                "
                                    class="ml-2 inline-flex items-center gap-1 rounded-full bg-green-100 px-2.5 py-1 text-xs font-semibold text-green-700">
                                    ✓ Completed
                                </span>

                            </div>

                            <!-- Concern Number -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Concern Number
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.concern_number || '-' }}
                                </p>

                            </div>

                            <!-- Concern Type -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Concern Type
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.concern_type_name || '-' }}
                                </p>

                            </div>

                            <!-- Assigned To -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Assigned To
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{
                                        selectedConcern.organization_name ||
                                        selectedConcern.assigned_organization_name ||
                                        '-'
                                    }}
                                </p>

                            </div>

                            <!-- Created By -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Created By
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.created_by_name || '-' }}
                                </p>

                            </div>

                            <!-- Creator Organization -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Creator Organization
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.creator_organization_name || '-' }}
                                </p>

                            </div>

                            <!-- Created At -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Created At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.created_at) }}
                                </p>

                            </div>

                            <!-- Scheduled Handling Start -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Committed Start Date
                                </p>

                                <p v-if="selectedConcern.target_commitment_at"
                                    class="text-sm font-medium text-slate-700">
                                    {{ formatDateOnly(selectedConcern.target_commitment_at) }}
                                </p>

                                <p v-else class="text-sm text-slate-400">
                                    Not set
                                </p>

                            </div>

                            <!-- Handling Duration -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Handling Duration
                                </p>

                                <p class="text-sm font-medium" :class="getConcernDuration(selectedConcern) === 'Not started'
                                    ? 'text-slate-400'
                                    : 'text-slate-700'
                                    ">
                                    {{
                                        getConcernDuration(
                                            selectedConcern
                                        )
                                    }}
                                </p>

                            </div>

                            <!-- Updated At -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Updated At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.updated_at) }}
                                </p>

                            </div>

                            <!-- Resolved At -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Resolved At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.resolved_at) }}
                                </p>

                            </div>

                            <!-- Closed At -->
                            <div>

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Closed At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.closed_at) }}
                                </p>

                            </div>

                            <!-- Description -->
                            <div class="md:col-span-2">

                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Description
                                </p>

                                <p class="whitespace-pre-wrap break-words text-sm leading-6 text-slate-700">
                                    {{ selectedConcern.description || '-' }}
                                </p>

                            </div>

                        </div>

                    </div>

                    <!-- Status Update -->
                    <ConcernStatusUpdatePanel
                        v-if="canUpdateStatus()"
                        :set-status-selector-section="setStatusSelectorSection"
                        v-model:selected-status="selectedStatus"
                        :current-status="selectedConcern.status"
                        :current-status-label="formatStatus(selectedConcern.status)"
                        :available-status-options="availableStatusOptions"
                        :assigned-admin="isAssignedAdmin()"
                        :creator-organization-admin="isCreatorOrganizationAdmin()"
                        :commitment-date-required="isCommitmentDateRequired()"
                        v-model:target-commitment-at="targetCommitmentAt"
                        :minimum-commitment-date="minimumCommitmentDate"
                        :updating-status="updatingStatus"
                        v-model:status-remarks="statusRemarks"
                        :remarks-required="isRemarksRequired()"
                        :status-remarks-placeholder="statusRemarksPlaceholder()"
                        :status-evidence-required="isAssignedAdmin() && selectedConcern.status === 'in_progress' && selectedStatus === 'resolved'"
                        :status-image-previews="statusImagePreviews"
                        :set-status-image-input="setStatusImageInput"
                        @status-images-change="handleStatusImagesChange"
                        @clear-status-images="clearStatusImages"
                        @remove-status-image="removeStatusImage"
                        @update-status="updateConcernStatus"
                    />

                    <!-- Attachments -->
                    <ConcernAttachmentsPanel
                        :concern-attachments="concernAttachments"
                        :can-edit-original-attachments="canEditOriginalAttachments()"
                        :adding-attachments="addingAttachments"
                        :replacing-attachment-id="replacingAttachmentId"
                        :deleting-attachment-id="deletingAttachmentId"
                        :additional-image-previews="additionalImagePreviews"
                        :selected-additional-images="selectedAdditionalImages"
                        :replacement-image-preview="replacementImagePreview"
                        :selected-replacement-image="selectedReplacementImage"
                        :editing-attachment-id="editingAttachmentId"
                        :format-date="formatDate"
                        :attachment-url="attachmentUrl"
                        :set-replacement-input="setReplacementInput"
                        :set-additional-attachment-input="setAdditionalAttachmentInput"
                        @select-additional-images="triggerAdditionalAttachmentSelection"
                        @clear-additional-images="clearAdditionalImages"
                        @remove-additional-image="removeAdditionalImage"
                        @attach-additional-images="attachAdditionalImages"
                        @clear-replacement-image="clearReplacementImage"
                        @save-attachment-replacement="saveAttachmentReplacement"
                        @open-image="openImageViewer"
                        @trigger-attachment-replace="triggerAttachmentReplace"
                        @remove-original-attachment="removeOriginalAttachment"
                        @attachment-replacement-change="handleAttachmentReplacement"
                        @additional-attachments-change="handleAdditionalAttachments"
                    />

                    <ConcernStatusHistory
                        :concern-status-history="concernStatusHistory"
                        :visible-status-history="visibleStatusHistory"
                        v-model:show-all-status-history="showAllStatusHistory"
                        :format-status="formatStatus"
                        :status-class="statusClass"
                        :format-date="formatDate"
                        :format-date-only="formatDateOnly"
                        :commitment-start-from-remarks="commitmentStartFromRemarks"
                        :attachment-url="attachmentUrl"
                        @view-image="openImageViewer"
                    />

                    </div>

                    </div>

                    <!-- Conversation -->
                    <ConcernConversationPanel
                        v-if="activeConcernTab !== 'overview'"
                        :concern-comments="concernComments"
                        :visible-comments="visibleComments"
                        v-model:visible-comment-count="visibleCommentCount"
                        :current-user="currentUser"
                        :can-comment="canComment()"
                        :concern-completed="isConcernCompleted()"
                        v-model:new-comment="newComment"
                        :saving-comment="savingComment"
                        :selected-comment-images="selectedCommentImages"
                        :comment-image-previews="commentImagePreviews"
                        :format-date="formatDate"
                        :role-display-name="roleDisplayName"
                        :attachment-url="attachmentUrl"
                        :set-comment-image-input="setCommentImageInput"
                        @open-profile-photo="openProfilePhotoViewer"
                        @open-image="openImageViewer"
                        @comment-images-change="handleCommentImagesChange"
                        @clear-comment-images="clearCommentImages"
                        @remove-comment-image="removeCommentImage"
                        @add-comment="addComment"
                    />

                </div>

            </div>

        </div>

    </div>

    <!-- Full Image Viewer -->
    <ConcernImageViewer
        :show="showImageViewer"
        :image="selectedViewerImage"
        @close="closeImageViewer"
    />

</template>

<style scoped>
@media (min-width: 1024px) {
    .view-concern-sections {
        align-items: start;
        grid-template-areas:
            'main history'
            'status status'
            'attachments attachments';
    }

    .view-concern-main {
        grid-area: main;
    }

    .view-concern-history {
        grid-area: history;
    }

    .view-concern-status {
        grid-area: status;
    }

    .view-concern-attachments {
        grid-area: attachments;
    }
}
</style>