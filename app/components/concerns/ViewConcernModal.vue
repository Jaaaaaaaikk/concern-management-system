<script setup>

import { VueDatePicker } from '@vuepic/vue-datepicker'
import '@vuepic/vue-datepicker/dist/main.css'

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

const { showToast } = useToast()

const emit = defineEmits([
    'close',
    'refresh'
])

const selectedConcern = ref(null)
const concernComments = ref([])
const concernAttachments = ref([])
const concernStatusHistory = ref([])

const loadingConcernDetails = ref(false)
const savingComment = ref(false)
const updatingStatus = ref(false)

const newComment = ref('')
const selectedStatus = ref('')
const statusRemarks = ref('')
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
 * Convert a Date or date value into the local format
 * required by an HTML datetime-local input.
 */
function localDateTimeInputValue(value = new Date()) {
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

    const hours = String(
        date.getHours()
    ).padStart(2, '0')

    const minutes = String(
        date.getMinutes()
    ).padStart(2, '0')

    return `${year}-${month}-${day}T${hours}:${minutes}`
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

    const date = new Date(value)

    if (Number.isNaN(date.getTime())) {
        const stringValue = String(value).trim()
        const match = stringValue.match(/^\d{4}-\d{2}-\d{2}/)

        return match ? match[0] : '—'
    }

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
        /(?:commitment start|scheduled start(?: date\/time)?|target resolution date):\s*(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(?::\d{2})?)/i
    )

    return match ? parseDate(match[1]) : null
}

function historyRemarksWithoutCommitmentStart(history) {
    return String(history?.remarks || '')
        .replace(
            /\n?\s*(?:commitment start|scheduled start(?: date\/time)?|target resolution date):\s*\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(?::\d{2})?\s*/i,
            ''
        )
        .trim()
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
                    history === latestInProgressHistory
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
        elapsedMilliseconds === 0 &&
        (!activeSince || currentTime.value.getTime() < activeSince.getTime())
    ) {
        return 'Not started'
    }

    const totalMinutes =
        Math.floor(
            elapsedMilliseconds / 60000
        )

    const days =
        Math.floor(totalMinutes / 1440)

    const hours =
        Math.floor((totalMinutes % 1440) / 60)

    const minutes =
        totalMinutes % 60

    const parts = []

    if (days > 0) {
        parts.push(`${days}d`)
    }

    if (hours > 0) {
        parts.push(`${hours}h`)
    }

    if (
        minutes > 0 ||
        parts.length === 0
    ) {
        parts.push(`${minutes}m`)
    }

    return parts.join(' ')
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
    return Boolean(
        props.currentUser &&
        selectedConcern.value &&
        props.currentUser.role_name === 'admin' &&
        props.currentUser.organization_id != null &&
        selectedConcern.value.creator_organization_id != null &&
        Number(
            selectedConcern.value.creator_organization_id
        ) ===
        Number(props.currentUser.organization_id)
    )
}

/*
 * User belongs to the organization assigned
 * to handle the concern.
 */
function isAssignedOrganizationMember() {
    return Boolean(
        props.currentUser &&
        selectedConcern.value &&
        ['admin', 'user'].includes(
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
        ['admin', 'user'].includes(
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
        props.currentUser.role_name === 'admin' &&
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

    return (
        props.currentUser.role_name === 'superadmin' ||
        Number(selectedConcern.value.created_by) ===
        Number(props.currentUser.id)
    )
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

    if (props.currentUser.role_name === 'superadmin') {
        return true
    }

    return (
        isCreatorOrganizationMember() ||
        isAssignedOrganizationMember()
    )
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
 *   Resolved -> Closed
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
        props.currentUser.role_name === 'admin' &&
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
    if (!canCloseConcern()) {
        return
    }

    selectedStatus.value = 'closed'

    statusRemarks.value = ''

    clearStatusImages()

    updateConcernStatus()
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

        concernComments.value =
            response.comments || []

        concernAttachments.value =
            response.attachments || []

        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern?.status || ''

        targetCommitmentAt.value =
            mysqlDateTimeToLocalDate(
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

        targetCommitmentAt.value =
            mysqlDateTimeToLocalDate(
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

    selectedStatus.value = ''
    statusRemarks.value = ''
    targetCommitmentAt.value = null
    newComment.value = ''

    editingAttachmentId.value = null

    emit('close')
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

async function addComment() {
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

async function saveAttachmentReplacement() {
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

async function attachAdditionalImages() {
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

async function removeOriginalAttachment(attachment) {
    if (!canEditOriginalAttachments()) {
        return
    }

    if (
        Number(editingAttachmentId.value) ===
        Number(attachment.id)
    ) {
        clearReplacementImage()
    }

    const confirmed = window.confirm(
        `Remove "${attachment.file_name}" from this concern?`
    )

    if (!confirmed) {
        return
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

async function updateConcernStatus() {
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
    * recipient's committed start date and time.
     */
    const movingToInProgress = isAssignedAdmin() &&
        targetStatus === 'in_progress' &&
        selectedConcern.value.status !== 'in_progress'

    if (
        movingToInProgress &&
        !targetCommitmentAt.value
    ) {
        showToast(
            'Please set the committed start date and time before moving the concern to In Progress.',
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
        const selectedDate = localDateTimeInputValue(
            targetCommitmentAt.value
        ).slice(0, 10)

        const today = localDateTimeInputValue(
            minimumCommitmentDate()
        ).slice(0, 10)

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
                localDateTimeInputValue(targetCommitmentAt.value)
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
    () => props.show,
    (visible) => {
        if (visible) {
            loadConcernDetails()
        }
    }
)

watch(
    () => props.concernId,
    (newId, oldId) => {
        if (
            props.show &&
            newId &&
            newId !== oldId
        ) {
            loadConcernDetails()
        }
    }
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

    <div v-if="show"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-950/60 px-2 py-3 backdrop-blur-[2px] sm:items-center sm:px-4 sm:py-6">

        <div
            class="my-auto flex max-h-[calc(100dvh-1.5rem)] w-full max-w-5xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl sm:max-h-[calc(100dvh-3rem)]">

            <!-- Header -->
            <div
                class="flex shrink-0 items-center justify-between border-b border-slate-200 bg-white px-4 py-4 sm:px-6">

                <div>

                    <p class="text-xs font-medium uppercase tracking-wide text-slate-400">
                        Concern Details
                    </p>

                    <h3 class="mt-1 text-lg font-semibold text-slate-800">
                        {{ selectedConcern?.concern_number || 'View Concern' }}
                    </h3>

                </div>

                <button type="button" @click="closeViewModal" :disabled="savingComment ||
                    updatingStatus ||
                    addingAttachments ||
                    replacingAttachmentId
                    "
                    class="flex h-9 w-9 cursor-pointer items-center justify-center rounded-lg text-xl text-slate-500 transition hover:bg-slate-100 hover:text-slate-800 disabled:cursor-not-allowed disabled:opacity-50">
                    ×
                </button>

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

                        <!-- Admin Close Concern -->
                        <div v-if="canCloseConcern()" class="mt-4">

                            <button type="button" @click="closeConcernByAdmin" :disabled="updatingStatus"
                                class="cursor-pointer rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-green-800 disabled:cursor-not-allowed disabled:opacity-50">
                                {{
                                    updatingStatus
                                        ? 'Closing...'
                                        : 'Close Concern'
                                }}
                            </button>

                        </div>

                    </div>

                    <!-- Main Information -->
                    <div class="rounded-xl border border-slate-300 bg-white p-5 shadow-md">

                        <div class="mb-5">

                            <h4 class="text-base font-semibold text-slate-800">
                                Main Information
                            </h4>

                            <p class="mt-1 text-sm text-slate-500">
                                Details of this concern.
                            </p>

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
                                    Committed Start Date &amp; Time
                                </p>

                                <p v-if="selectedConcern.target_commitment_at"
                                    class="text-sm font-medium text-slate-700">
                                    {{ formatDate(selectedConcern.target_commitment_at) }}
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
                    <div v-if="canUpdateStatus()" class="overflow-hidden rounded-xl border border-blue-200 bg-white shadow-md">

                        <div class="border-b border-blue-100 bg-blue-50/70 px-5 py-4">

                            <div class="flex items-start gap-3">

                                <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-blue-100 text-blue-800">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                        stroke-width="1.8" stroke="currentColor" class="h-5 w-5">
                                        <path stroke-linecap="round" stroke-linejoin="round"
                                            d="M12 6v6l4 2m6-2a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z" />
                                    </svg>
                                </span>

                                <div>
                                    <h4 class="text-base font-semibold text-slate-900">
                                        Update Status
                                    </h4>

                                    <p class="mt-1 text-sm leading-5 text-slate-600">
                                        <span v-if="isAssignedAdmin()">
                                            Manage this concern on behalf of the assigned organization.
                                        </span>
                                        <span v-else>
                                            Review the resolution and close the concern for the creator organization.
                                        </span>
                                    </p>
                                </div>

                            </div>

                        </div>

                        <div class="space-y-5 p-5">

                            <div class="grid gap-4 md:grid-cols-2">

                                <!-- Status -->
                                <div>

                                    <label for="concern-status" class="mb-2 block text-sm font-semibold text-slate-700">
                                        New status
                                    </label>

                                    <select id="concern-status" v-model="selectedStatus" :disabled="updatingStatus || availableStatusOptions.length === 0"
                                        class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100 disabled:cursor-not-allowed disabled:bg-slate-100">

                                        <option :value="selectedConcern.status">
                                            {{ formatStatus(selectedConcern.status) }}
                                        </option>

                                        <option v-for="option in availableStatusOptions" :key="option.value" :value="option.value">
                                            {{ option.label }}
                                        </option>

                                    </select>

                                    <p class="mt-2 text-xs text-slate-500">
                                        Choose the next status allowed for your organization.
                                    </p>

                                </div>

                                <!-- Scheduled Handling Start -->
                                <div v-if="isCommitmentDateRequired()" class="rounded-lg border border-blue-200 bg-blue-50/70 p-4">

                                    <label for="target-commitment-at" class="mb-2 block text-sm font-semibold text-blue-900">
                                        Committed start date and time <span class="text-red-500">*</span>
                                    </label>

                                    <VueDatePicker
                                        id="target-commitment-at"
                                        v-model="targetCommitmentAt"
                                        :min-date="minimumCommitmentDate()"
                                        :enable-time-picker="true"
                                        :minutes-increment="1"
                                        :clearable="false"
                                        :disabled="updatingStatus"
                                        :auto-apply="true"
                                        format="MMM d, yyyy h:mm aa"
                                        placeholder="Choose your committed start date and time"
                                        input-class-name="!rounded-lg !border-blue-300 !py-3 !text-sm focus:!border-blue-500"
                                        menu-class-name="rounded-xl border border-slate-200 shadow-xl"
                                        class="w-full"
                                    />

                                    <p class="mt-2 text-xs leading-5 text-blue-800">
                                        This is the date and time your organization commits to begin handling the concern, not a due date. Choose today or a future date. The handling timer begins at this commitment time.
                                    </p>

                                </div>

                            </div>

                            <!-- Remarks -->
                            <div>

                                <label for="status-remarks" class="mb-2 block text-sm font-semibold text-slate-700">
                                    Update notes
                                    <span v-if="isRemarksRequired()" class="text-red-500">*</span>
                                    <span v-else class="font-normal text-slate-400">(Optional)</span>
                                </label>

                                <textarea id="status-remarks" v-model="statusRemarks" :disabled="updatingStatus" rows="3"
                                    :placeholder="isAssignedAdmin() && selectedStatus === 'on_hold'
                                        ? 'Explain why this concern is being placed on hold...'
                                        : isAssignedAdmin() && selectedStatus === 'in_progress'
                                            ? 'Explain what work is starting or continuing...'
                                            : isAssignedAdmin() && selectedConcern.status === 'in_progress' && selectedStatus === 'resolved'
                                                ? 'Explain what was done to resolve the concern...'
                                                : 'Add notes about this status change...'
                                        "
                                    class="w-full resize-y rounded-lg border border-slate-300 px-4 py-3 text-sm leading-6 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100 disabled:cursor-not-allowed disabled:bg-slate-100"></textarea>

                            </div>

                        <!-- Resolution Evidence -->
                        <div v-if="
                            isAssignedAdmin() &&
                            selectedConcern.status === 'in_progress' &&
                            selectedStatus === 'resolved'
                        " class="mt-5 rounded-lg border border-green-200 bg-green-50 p-4">

                            <div class="mb-3">

                                <p class="text-sm font-semibold text-green-800">
                                    Resolution Evidence
                                    <span class="text-red-500">*</span>
                                </p>

                                <p class="mt-1 text-xs leading-5 text-green-700">
                                    Attach one or more images showing the completed work,
                                    repaired issue, or other evidence that the concern has
                                    been resolved.
                                </p>

                            </div>

                            <input ref="statusImageInput" type="file" multiple
                                accept="image/jpeg,image/png,image/gif,image/webp" :disabled="updatingStatus"
                                @change="handleStatusImagesChange"
                                class="w-full cursor-pointer rounded-lg border border-green-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-green-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-green-700 hover:border-green-400 hover:file:bg-green-200 disabled:cursor-not-allowed disabled:bg-slate-100" />

                            <p class="mt-1 text-xs text-slate-500">
                                Multiple images are allowed. Maximum size: 5 MB per image.
                            </p>

                            <!-- Selected Evidence Images -->
                            <div v-if="statusImagePreviews.length > 0" class="mt-4">

                                <div class="mb-2 flex items-center justify-between">

                                    <p class="text-sm font-medium text-slate-700">
                                        Selected Evidence
                                        ({{ statusImagePreviews.length }})
                                    </p>

                                    <button type="button" @click="clearStatusImages" :disabled="updatingStatus"
                                        class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                        Remove All
                                    </button>

                                </div>

                                <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">

                                    <div v-for="(preview, index) in statusImagePreviews" :key="preview.url"
                                        class="group relative overflow-hidden rounded-lg border border-green-200 bg-white">

                                        <img :src="preview.url" :alt="preview.file.name"
                                            class="h-28 w-full object-cover transition duration-200 group-hover:scale-105" />

                                        <button type="button" @click="removeStatusImage(index)"
                                            :disabled="updatingStatus"
                                            class="absolute right-2 top-2 cursor-pointer rounded-md bg-black/70 px-2 py-1 text-xs font-medium text-white transition hover:bg-red-600 disabled:cursor-not-allowed disabled:opacity-50">
                                            Remove
                                        </button>

                                        <div class="border-t border-slate-200 px-2 py-2">

                                            <p class="truncate text-xs text-slate-500" :title="preview.file.name">
                                                {{ preview.file.name }}
                                            </p>

                                        </div>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!-- Update Button -->
                        <div class="flex justify-end border-t border-slate-100 pt-4">

                            <button type="button" @click="updateConcernStatus" :disabled="updatingStatus ||
                                selectedStatus === selectedConcern.status
                                "
                                class="cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50">
                                {{
                                    updatingStatus
                                        ? 'Updating...'
                                        : 'Update Status'
                                }}
                            </button>

                        </div>

                    </div>

                    </div>

                    <!-- Attachments -->
                    <div class="rounded-xl border border-slate-300 bg-white p-5 shadow-md">

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
                                    {{ concernAttachments.length }}
                                    attachment{{
                                        concernAttachments.length === 1
                                            ? ''
                                            : 's'
                                    }}
                                </span>

                                <!-- Add Images -->
                                <button v-if="canEditOriginalAttachments()" type="button"
                                    @click="additionalAttachmentInput?.click()" :disabled="addingAttachments ||
                                        replacingAttachmentId
                                        "
                                    class="inline-flex cursor-pointer items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">

                                    <span class="text-base leading-none">
                                        +
                                    </span>

                                    Add Images

                                </button>

                            </div>

                        </div>

                        <!-- Selected Additional Images -->
                        <div v-if="additionalImagePreviews.length > 0"
                            class="mb-5 rounded-lg border border-blue-200 bg-blue-50 p-4">

                            <div class="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">

                                <div>

                                    <p class="text-sm font-semibold text-blue-900">
                                        Selected Images
                                        ({{ additionalImagePreviews.length }})
                                    </p>

                                    <p class="mt-1 text-xs text-blue-700">
                                        These images have not been saved yet.
                                        Click Save Images to attach them to this concern.
                                    </p>

                                </div>

                                <button type="button" @click="clearAdditionalImages" :disabled="addingAttachments"
                                    class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                    Remove All
                                </button>

                            </div>

                            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">

                                <div v-for="(preview, index) in additionalImagePreviews" :key="preview.url"
                                    class="overflow-hidden rounded-lg border border-blue-200 bg-white">

                                    <div class="relative overflow-hidden">

                                        <img :src="preview.url" :alt="preview.file.name"
                                            class="h-32 w-full object-cover" />

                                        <button type="button" @click="removeAdditionalImage(index)"
                                            :disabled="addingAttachments"
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

                            <!-- Save Images -->
                            <div class="mt-4 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">

                                <button type="button" @click="clearAdditionalImages" :disabled="addingAttachments"
                                    class="cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50">
                                    Cancel
                                </button>

                                <button type="button" @click="attachAdditionalImages" :disabled="addingAttachments ||
                                    selectedAdditionalImages.length === 0
                                    "
                                    class="cursor-pointer rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-50">
                                    {{
                                        addingAttachments
                                            ? 'Saving...'
                                            : `Save Images (${selectedAdditionalImages.length})`
                                    }}
                                </button>

                            </div>

                        </div>

                        <!-- Selected Replacement -->
                        <div v-if="
                            replacementImagePreview &&
                            selectedReplacementImage &&
                            editingAttachmentId
                        " class="mb-5 rounded-lg border border-amber-200 bg-amber-50 p-4">

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

                                <button type="button" @click="clearReplacementImage" :disabled="replacingAttachmentId"
                                    class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                    Cancel
                                </button>

                            </div>

                            <div class="max-w-sm overflow-hidden rounded-lg border border-amber-200 bg-white">

                                <div class="relative overflow-hidden">

                                    <img :src="replacementImagePreview.url" :alt="replacementImagePreview.file.name"
                                        class="h-48 w-full object-cover" />

                                </div>

                                <div class="border-t border-slate-200 p-3">

                                    <p class="truncate text-xs font-medium text-slate-700"
                                        :title="replacementImagePreview.file.name">
                                        {{ replacementImagePreview.file.name }}
                                    </p>

                                    <p class="mt-1 text-[11px] text-slate-400">
                                        Replacement is not saved yet.
                                    </p>

                                </div>

                            </div>

                            <div class="mt-4 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">

                                <button type="button" @click="clearReplacementImage" :disabled="replacingAttachmentId"
                                    class="cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50">
                                    Cancel
                                </button>

                                <button type="button" @click="saveAttachmentReplacement" :disabled="replacingAttachmentId ||
                                    !selectedReplacementImage ||
                                    !editingAttachmentId
                                    "
                                    class="cursor-pointer rounded-lg bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-50">
                                    {{
                                        replacingAttachmentId
                                            ? 'Saving...'
                                            : 'Save Replacement'
                                    }}
                                </button>

                            </div>

                        </div>

                        <!-- No Attachments -->
                        <div v-if="concernAttachments.length === 0"
                            class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500">
                            No attachments.
                        </div>

                        <!-- Existing Attachments -->
                        <div v-else class="max-h-[520px] overflow-y-auto pr-1">

                            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">

                                <div v-for="attachment in concernAttachments" :key="attachment.id"
                                    class="overflow-hidden rounded-lg border border-slate-200 bg-white">

                                    <button type="button" @click="openImageViewer(attachment)"
                                        class="group block w-full cursor-pointer text-left"
                                        :title="`View ${attachment.file_name}`">

                                        <div class="relative overflow-hidden bg-white">

                                            <img v-if="attachment.file_type?.startsWith('image/')"
                                                :src="attachmentUrl(attachment.file_path)" :alt="attachment.file_name"
                                                class="h-32 w-full object-cover transition duration-200 group-hover:scale-105" />

                                            <div v-else
                                                class="flex h-32 items-center justify-center text-xs text-slate-500">
                                                File attachment
                                            </div>

                                            <div
                                                class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20">

                                                <span
                                                    class="rounded-full bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700 opacity-0 shadow transition group-hover:opacity-100">
                                                    View
                                                </span>

                                            </div>

                                        </div>

                                    </button>

                                    <div class="border-t border-slate-200 bg-white p-3">

                                        <div class="mb-2 flex items-center justify-between gap-2">

                                            <span class="rounded-full px-2 py-1 text-[10px] font-semibold" :class="attachment.edited_at
                                                ? 'bg-amber-100 text-amber-700'
                                                : 'bg-slate-100 text-slate-600'
                                                ">
                                                {{
                                                    attachment.edited_at
                                                        ? 'Edited'
                                                        : 'Uploaded'
                                                }}
                                            </span>

                                            <span v-if="canEditOriginalAttachments()"
                                                class="text-[10px] text-slate-400">
                                                Original
                                            </span>

                                        </div>

                                        <p class="truncate text-xs font-medium text-slate-700"
                                            :title="attachment.file_name">
                                            {{ attachment.file_name }}
                                        </p>

                                        <p class="mt-1 truncate text-[11px] text-slate-400">
                                            {{
                                                attachment.uploaded_by_name ||
                                                '-'
                                            }}
                                        </p>

                                        <p class="mt-1 text-[11px] text-slate-400">
                                            {{
                                                attachment.edited_at
                                                    ? `Edited ${formatDate(attachment.edited_at)}`
                                                    : `Uploaded ${formatDate(attachment.created_at)}`
                                            }}
                                        </p>

                                        <div v-if="canEditOriginalAttachments()" class="mt-3 flex gap-2">

                                            <button type="button" @click="triggerAttachmentReplace(attachment)"
                                                :disabled="replacingAttachmentId ||
                                                    deletingAttachmentId === attachment.id ||
                                                    addingAttachments
                                                    "
                                                class="flex-1 cursor-pointer rounded-md border border-slate-300 px-2 py-1.5 text-[11px] font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">
                                                Replace
                                            </button>

                                            <button type="button" @click="removeOriginalAttachment(attachment)"
                                                :disabled="replacingAttachmentId === attachment.id ||
                                                    deletingAttachmentId === attachment.id ||
                                                    addingAttachments
                                                    "
                                                class="cursor-pointer rounded-md border border-red-200 px-2 py-1.5 text-[11px] font-medium text-red-600 transition hover:bg-red-50 hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                                {{
                                                    deletingAttachmentId === attachment.id
                                                        ? '...'
                                                        : 'Remove'
                                                }}
                                            </button>

                                        </div>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!-- Replacement Input -->
                        <input ref="replacementInput" type="file" accept="image/jpeg,image/png,image/gif,image/webp"
                            class="hidden" @change="handleAttachmentReplacement" />

                        <!-- Additional Attachment Input -->
                        <input ref="additionalAttachmentInput" type="file" multiple
                            accept="image/jpeg,image/png,image/gif,image/webp" class="hidden"
                            @change="handleAdditionalAttachments" />

                    </div>

                    <!-- Status History -->
                    <div class="rounded-xl border border-slate-300 bg-white p-5 shadow-md">

                        <div class="mb-4">

                            <h4 class="text-base font-semibold text-slate-800">
                                Status History
                            </h4>

                            <p class="mt-1 text-sm text-slate-500">
                                Record of status changes.
                            </p>

                        </div>

                        <div v-if="concernStatusHistory.length === 0"
                            class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500">
                            No status history available.
                        </div>

                        <div v-else class="space-y-4">

                            <div v-for="history in concernStatusHistory" :key="history.id"
                                class="rounded-lg border border-slate-200 bg-slate-50 p-4">

                                <div class="flex flex-wrap items-center justify-between gap-3">

                                    <div class="flex flex-wrap items-center gap-2">

                                        <span v-if="history.old_status"
                                            class="rounded-full bg-slate-200 px-3 py-1 text-xs font-medium text-slate-700">
                                            {{
                                                formatStatus(
                                                    history.old_status
                                                )
                                            }}
                                        </span>

                                        <span v-if="history.old_status" class="text-slate-400">
                                            →
                                        </span>

                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(history.new_status)">
                                            {{
                                                formatStatus(
                                                    history.new_status
                                                )
                                            }}
                                        </span>

                                        <span v-if="
                                            history.new_status === 'closed'
                                        "
                                            class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-xs font-semibold text-green-700">
                                            ✓ Completed
                                        </span>

                                    </div>

                                    <span class="text-xs text-slate-400">
                                        {{
                                            formatDate(
                                                history.created_at
                                            )
                                        }}
                                    </span>

                                </div>

                                <p class="mt-3 text-xs text-slate-500">

                                    Changed by

                                    <span class="font-medium text-slate-700">
                                        {{
                                            history.changed_by_name ||
                                            '-'
                                        }}
                                    </span>

                                </p>

                                    <p v-if="commitmentStartFromRemarks(history.remarks)"
                                        class="mt-3 rounded-lg border border-blue-100 bg-blue-50 px-3 py-2 text-xs font-medium text-blue-800">
                                        Committed start:
                                        {{ formatDateTime(commitmentStartFromRemarks(history.remarks)) }}
                                    </p>

                                <p v-if="historyRemarksWithoutCommitmentStart(history)"
                                    class="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700">
                                    {{ historyRemarksWithoutCommitmentStart(history) }}
                                </p>

                                <div v-if="
                                    history.attachments &&
                                    history.attachments.length > 0
                                " class="mt-4">

                                    <div class="mb-2 flex items-center justify-between">

                                        <p class="text-xs font-semibold text-slate-700">
                                            Resolution Evidence
                                        </p>

                                        <span class="text-[11px] text-slate-400">
                                            {{
                                                history.attachments.length
                                            }}
                                            image{{
                                                history.attachments.length === 1
                                                    ? ''
                                                    : 's'
                                            }}
                                        </span>

                                    </div>

                                    <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">

                                        <button v-for="attachment in history.attachments" :key="attachment.id"
                                            type="button" @click="openImageViewer(attachment)"
                                            class="group relative block w-full cursor-pointer overflow-hidden rounded-lg border border-green-200 bg-white text-left transition hover:border-green-400 hover:shadow-md"
                                            :title="`View ${attachment.file_name}`">

                                            <img v-if="attachment.file_type?.startsWith('image/')"
                                                :src="attachmentUrl(attachment.file_path)" :alt="attachment.file_name"
                                                class="h-28 w-full object-cover transition duration-200 group-hover:scale-105" />

                                            <div
                                                class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20">

                                                <span
                                                    class="rounded-full bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700 opacity-0 shadow transition group-hover:opacity-100">
                                                    View
                                                </span>

                                            </div>

                                            <div class="border-t border-green-100 bg-white px-2 py-2">

                                                <p class="truncate text-[11px] font-medium text-slate-600"
                                                    :title="attachment.file_name">
                                                    {{
                                                        attachment.file_name
                                                    }}
                                                </p>

                                                <p class="mt-1 text-[10px] text-slate-400">
                                                    Uploaded by
                                                    {{
                                                        attachment.uploaded_by_name ||
                                                        '-'
                                                    }}
                                                </p>

                                                <p class="mt-1 text-[10px] text-slate-400">
                                                    {{
                                                        formatDate(
                                                            attachment.created_at
                                                        )
                                                    }}
                                                </p>

                                            </div>

                                        </button>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                    <!-- Comments -->
                    <div class="rounded-xl border border-slate-300 bg-white p-5 shadow-md">

                        <div class="mb-5">

                            <h4 class="text-base font-semibold text-slate-800">
                                Conversation
                            </h4>

                            <p class="mt-1 text-sm text-slate-500">
                                Communication between members of the creator organization and the assigned organization.
                            </p>

                        </div>

                        <!-- No Comments -->
                        <div v-if="concernComments.length === 0" class="rounded-lg bg-slate-50 p-6 text-center">

                            <p class="text-sm text-slate-500">
                                No conversation yet.
                            </p>

                            <p v-if="canComment()" class="mt-1 text-xs text-slate-400">
                                Start the conversation by adding a comment below.
                            </p>

                        </div>

                        <!-- Conversation -->
                        <div v-else class="space-y-5">

                            <div v-for="comment in concernComments" :key="comment.id" class="flex" :class="Number(comment.user_id) === Number(currentUser?.id)
                                ? 'justify-end'
                                : 'justify-start'
                                ">

                                <div class="max-w-[90%] sm:max-w-[78%]">

                                    <!-- Sender -->
                                    <div class="mb-1 flex flex-wrap items-center gap-2" :class="Number(comment.user_id) === Number(currentUser?.id)
                                        ? 'justify-end'
                                        : 'justify-start'
                                        ">

                                        <UserAvatar :name="comment.user_name || '-'" :photo-url="comment.profile_photo"
                                            size="h-7 w-7 text-[10px]" />

                                        <p class="text-xs font-semibold text-slate-700">
                                            {{
                                                comment.user_name ||
                                                '-'
                                            }}
                                        </p>

                                        <span
                                            class="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                                            {{
                                                comment.role_name ||
                                                '-'
                                            }}
                                        </span>

                                        <span
                                            class="max-w-[180px] truncate rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                                            {{
                                                comment.organization_name ||
                                                '-'
                                            }}
                                        </span>

                                    </div>

                                    <!-- Message Bubble -->
                                    <div class="rounded-2xl px-4 py-3" :class="Number(comment.user_id) === Number(currentUser?.id)
                                        ? 'rounded-br-md bg-blue-900 text-white'
                                        : 'rounded-bl-md bg-slate-100 text-slate-800'
                                        ">

                                        <!-- Comment Text -->
                                        <p v-if="comment.comment"
                                            class="whitespace-pre-wrap break-words text-sm leading-6">
                                            {{
                                                comment.comment
                                            }}
                                        </p>

                                        <!-- Comment Attachments -->
                                        <div v-if="
                                            comment.attachments &&
                                            comment.attachments.length > 0
                                        " :class="comment.comment
                                            ? 'mt-3'
                                            : ''
                                            " class="flex flex-wrap gap-2">

                                            <button v-for="attachment in comment.attachments" :key="attachment.id"
                                                type="button" @click="openImageViewer(attachment)"
                                                class="group relative block h-20 w-20 cursor-pointer overflow-hidden rounded-lg border border-slate-300 bg-white transition hover:border-slate-500 hover:shadow-md sm:h-24 sm:w-24"
                                                :title="`View ${attachment.file_name}`">

                                                <img v-if="attachment.file_type?.startsWith('image/')"
                                                    :src="attachmentUrl(attachment.file_path)"
                                                    :alt="attachment.file_name"
                                                    class="h-full w-full object-cover transition duration-200 group-hover:scale-105" />

                                                <div
                                                    class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20">

                                                    <span
                                                        class="text-xs font-semibold text-white opacity-0 transition group-hover:opacity-100">
                                                        View
                                                    </span>

                                                </div>

                                            </button>

                                        </div>

                                    </div>

                                    <!-- Timestamp -->
                                    <p class="mt-1 text-[11px] text-slate-400" :class="Number(comment.user_id) === Number(currentUser?.id)
                                        ? 'text-right'
                                        : 'text-left'
                                        ">
                                        {{
                                            formatDate(
                                                comment.created_at
                                            )
                                        }}
                                    </p>

                                </div>

                            </div>

                        </div>

                        <!-- Add Comment -->
                        <div v-if="canComment()" class="mt-6 border-t border-slate-200 pt-5">

                            <div class="mb-2 flex items-center justify-between">

                                <label class="block text-sm font-medium text-slate-700">
                                    Add Comment
                                </label>

                                <span class="text-xs text-slate-400">
                                    {{
                                        currentUser?.role_name ||
                                        ''
                                    }}
                                </span>

                            </div>

                            <!-- Message -->
                            <textarea v-model="newComment" :disabled="savingComment" rows="4"
                                placeholder="Write a message..."
                                class="w-full resize-y rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100"></textarea>

                            <!-- Attachment Input -->
                            <div class="mt-3">

                                <label class="mb-2 block text-sm font-medium text-slate-700">

                                    Attach Images

                                    <span class="font-normal text-slate-400">
                                        (Optional)
                                    </span>

                                </label>

                                <input ref="commentImageInput" type="file" multiple
                                    accept="image/jpeg,image/png,image/gif,image/webp" :disabled="savingComment"
                                    @change="handleCommentImagesChange"
                                    class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-slate-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:border-slate-400 hover:file:bg-slate-200 disabled:cursor-not-allowed disabled:bg-slate-100" />

                                <p class="mt-1 text-xs text-slate-500">
                                    You can select multiple images. Maximum size: 5 MB per image.
                                </p>

                            </div>

                            <!-- Selected Comment Images -->
                            <div v-if="commentImagePreviews.length > 0" class="mt-4">

                                <div class="mb-2 flex items-center justify-between">

                                    <p class="text-sm font-medium text-slate-700">
                                        Selected Images
                                    </p>

                                    <button type="button" @click="clearCommentImages" :disabled="savingComment"
                                        class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                        Remove All
                                    </button>

                                </div>

                                <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">

                                    <div v-for="(preview, index) in commentImagePreviews" :key="preview.url"
                                        class="relative overflow-hidden rounded-lg border border-slate-200 bg-slate-50">

                                        <img :src="preview.url" :alt="preview.file.name"
                                            class="h-28 w-full bg-white object-cover" />

                                        <div
                                            class="flex items-center justify-between gap-2 border-t border-slate-200 bg-white p-2">

                                            <p class="min-w-0 flex-1 truncate text-xs text-slate-500"
                                                :title="preview.file.name">
                                                {{
                                                    preview.file.name
                                                }}
                                            </p>

                                            <button type="button" @click="removeCommentImage(index)"
                                                :disabled="savingComment"
                                                class="shrink-0 cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                                Remove
                                            </button>

                                        </div>

                                    </div>

                                </div>

                            </div>

                            <!-- Send -->
                            <div class="mt-3 flex justify-end">

                                <button type="button" @click="addComment" :disabled="savingComment ||
                                    (
                                        !newComment.trim() &&
                                        selectedCommentImages.length === 0
                                    )
                                    "
                                    class="cursor-pointer rounded-lg bg-blue-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-blue-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50">
                                    {{
                                        savingComment
                                            ? 'Sending...'
                                            : 'Send Comment'
                                    }}
                                </button>

                            </div>

                        </div>

                        <!-- No Permission -->
                        <div v-else class="mt-5 border-t border-slate-200 pt-5">

                            <p v-if="isConcernCompleted()" class="text-sm text-slate-400">
                                This concern is already completed. Conversation is closed.
                            </p>

                            <p v-else class="text-sm text-slate-400">
                                You do not have permission to participate in this conversation.
                            </p>

                        </div>

                    </div>

                </div>

            </div>

            <!-- Footer -->
            <div class="flex shrink-0 justify-end border-t border-slate-200 bg-white px-6 py-4">

                <button type="button" @click="closeViewModal" :disabled="savingComment ||
                    updatingStatus ||
                    addingAttachments ||
                    replacingAttachmentId
                    "
                    class="cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">
                    Close
                </button>

            </div>

        </div>

    </div>

    <!-- Full Image Viewer -->
    <div v-if="
        showImageViewer &&
        selectedViewerImage
    " class="fixed inset-0 z-[100] flex items-center justify-center bg-black/85 p-4" @click.self="closeImageViewer">

        <div class="relative flex max-h-[95vh] max-w-[95vw] flex-col items-center">

            <button type="button" @click="closeImageViewer"
                class="absolute -right-2 -top-2 z-10 flex h-10 w-10 cursor-pointer items-center justify-center rounded-full bg-white text-2xl leading-none text-slate-600 shadow-lg transition hover:bg-red-500 hover:text-white"
                title="Close image">
                ×
            </button>

            <img :src="selectedViewerImage.url" :alt="selectedViewerImage.name"
                class="max-h-[85vh] max-w-[90vw] rounded-xl bg-white object-contain shadow-2xl" />

            <p class="mt-3 max-w-[90vw] truncate text-center text-sm font-medium text-white"
                :title="selectedViewerImage.name">
                {{ selectedViewerImage.name }}
            </p>

        </div>

    </div>

</template>