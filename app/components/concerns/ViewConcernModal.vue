<script setup>

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

const emit = defineEmits([
    'close',
    'success',
    'error',
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

const selectedStatusImages = ref([])
const statusImagePreviews = ref([])
const statusImageInput = ref(null)

const selectedCommentImages = ref([])
const commentImagePreviews = ref([])
const commentImageInput = ref(null)

const editingAttachmentId = ref(null)
const replacingAttachmentId = ref(null)
const deletingAttachmentId = ref(null)
const replacementInput = ref(null)

const addingAttachments = ref(false)
const additionalAttachmentInput = ref(null)
const selectedAdditionalImages = ref([])
const additionalImagePreviews = ref([])

const showImageViewer = ref(false)
const selectedViewerImage = ref(null)

const currentTime = ref(new Date())
let durationTimer = null

function formatStatus(status) {
    const labels = {
        pending: 'Pending',
        in_progress: 'In Progress',
        on_hold: 'On Hold',
        resolved: 'Resolved',
        closed: 'Closed',
        cancelled: 'Cancelled'
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

    return classes[status] || 'bg-slate-100 text-slate-600'
}

function priorityClass(priority) {
    const classes = {
        low: 'bg-slate-100 text-slate-600',
        medium: 'bg-blue-100 text-blue-700',
        high: 'bg-orange-100 text-orange-700',
        urgent: 'bg-red-100 text-red-700'
    }

    return classes[priority] || 'bg-slate-100 text-slate-600'
}

function formatDate(value) {
    if (!value) {
        return '-'
    }

    const date = new Date(value)

    if (Number.isNaN(date.getTime())) {
        return value
    }

    return date.toLocaleString('en-PH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit'
    })
}

function parseDate(value) {
    if (!value) {
        return null
    }

    const date = new Date(value)

    if (Number.isNaN(date.getTime())) {
        return null
    }

    return date
}

function getConcernDuration(concern) {
    if (!concern?.acknowledged_at) {
        return '-'
    }

    const start = parseDate(concern.acknowledged_at)

    if (!start) {
        return '-'
    }

    let end = null

    if (concern.resolved_at) {
        end = parseDate(concern.resolved_at)
    } else if (
        concern.status === 'in_progress' ||
        concern.status === 'on_hold'
    ) {
        end = currentTime.value
    }

    if (!end) {
        return '-'
    }

    const difference =
        end.getTime() - start.getTime()

    if (difference < 0) {
        return '-'
    }

    const totalMinutes =
        Math.floor(difference / 60000)

    const days =
        Math.floor(totalMinutes / 1440)

    const hours =
        Math.floor(
            (totalMinutes % 1440) / 60
        )

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
        selectedConcern.value.status === 'resolved' ||
        selectedConcern.value.status === 'closed' ||
        selectedConcern.value.status === 'cancelled'
    )
}

function isConcernCreator() {
    if (
        !props.currentUser ||
        !selectedConcern.value
    ) {
        return false
    }

    return (
        Number(selectedConcern.value.created_by) ===
        Number(props.currentUser.id)
    )
}

function isAssignedAdmin() {
    if (
        !props.currentUser ||
        !selectedConcern.value
    ) {
        return false
    }

    if (isConcernCreator()) {
        return false
    }

    return (
        props.currentUser.role_name === 'admin' &&
        Number(selectedConcern.value.assigned_organization_id) ===
        Number(props.currentUser.organization_id)
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

    if (
        props.currentUser.role_name ===
        'superadmin'
    ) {
        return true
    }

    if (isConcernCreator()) {
        return true
    }

    return isAssignedAdmin()
}

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
     * Superadmin follows the same valid transition
     * sequence enforced by the backend.
     */
    if (
        props.currentUser.role_name ===
        'superadmin'
    ) {
        const transitions = {
            pending: [
                'in_progress',
                'cancelled'
            ],

            in_progress: [
                'on_hold',
                'resolved',
                'cancelled'
            ],

            on_hold: [
                'in_progress',
                'resolved',
                'cancelled'
            ],

            resolved: [
                'closed'
            ],

            closed: [],

            cancelled: []
        }

        return (
            transitions[currentStatus] || []
        ).includes(newStatus)
    }

    /*
     * Assigned admin:
     *
     * pending -> in_progress
     * in_progress -> resolved
     *
     * The backend currently handles the actual
     * allowed transitions.
     */
    if (isAssignedAdmin()) {
        return (
            (
                currentStatus === 'pending' &&
                newStatus === 'in_progress'
            ) ||
            (
                currentStatus === 'in_progress' &&
                newStatus === 'resolved'
            )
        )
    }

    /*
     * Creator can only close a resolved concern.
     */
    if (isConcernCreator()) {
        return (
            currentStatus === 'resolved' &&
            newStatus === 'closed'
        )
    }

    return false
}

function canUpdateStatus() {
    if (
        !props.currentUser ||
        !selectedConcern.value
    ) {
        return false
    }

    /*
     * Superadmin can manage any concern that
     * has not already been closed.
     */
    if (
        props.currentUser.role_name ===
        'superadmin'
    ) {
        return (
            selectedConcern.value.status !==
            'closed'
        )
    }

    /*
     * Assigned admin can acknowledge and resolve.
     */
    if (isAssignedAdmin()) {
        return (
            selectedConcern.value.status ===
                'pending' ||
            selectedConcern.value.status ===
                'in_progress'
        )
    }

    return false
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
     * Superadmin uses the same transition rules
     * as the backend.
     */
    if (
        props.currentUser.role_name ===
        'superadmin'
    ) {
        const transitions = {
            pending: [
                {
                    value: 'in_progress',
                    label: 'In Progress'
                },
                {
                    value: 'cancelled',
                    label: 'Cancelled'
                }
            ],

            in_progress: [
                {
                    value: 'on_hold',
                    label: 'On Hold'
                },
                {
                    value: 'resolved',
                    label: 'Resolved'
                },
                {
                    value: 'cancelled',
                    label: 'Cancelled'
                }
            ],

            on_hold: [
                {
                    value: 'in_progress',
                    label: 'In Progress'
                },
                {
                    value: 'resolved',
                    label: 'Resolved'
                },
                {
                    value: 'cancelled',
                    label: 'Cancelled'
                }
            ],

            resolved: [
                {
                    value: 'closed',
                    label: 'Closed'
                }
            ],

            closed: [],

            cancelled: []
        }

        return transitions[currentStatus] || []
    }

    if (isAssignedAdmin()) {
        if (currentStatus === 'pending') {
            return [
                {
                    value: 'in_progress',
                    label: 'In Progress'
                }
            ]
        }

        if (
            currentStatus ===
            'in_progress'
        ) {
            return [
                {
                    value: 'resolved',
                    label: 'Resolved'
                }
            ]
        }
    }

    return []
})

function canCloseConcern() {
    return (
        props.currentUser &&
        selectedConcern.value &&
        Number(selectedConcern.value.created_by) ===
        Number(props.currentUser.id) &&
        selectedConcern.value.status ===
            'resolved'
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

        selectedConcern.value =
            response.concern

        concernComments.value =
            response.comments || []

        concernAttachments.value =
            response.attachments || []

        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern?.status || ''

        statusRemarks.value = ''

        clearCommentImages()
        clearStatusImages()
        clearAdditionalImages()

    } catch (error) {
        emit(
            'error',
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load concern details.'
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

        selectedConcern.value =
            response.concern

        concernComments.value =
            response.comments || []

        concernAttachments.value =
            response.attachments || []

        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern?.status || ''

    } catch (error) {
        emit(
            'error',
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to refresh concern details.'
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
        addingAttachments.value
    ) {
        return
    }

    clearCommentImages()
    clearStatusImages()
    clearAdditionalImages()

    closeImageViewer()

    selectedConcern.value = null
    concernComments.value = []
    concernAttachments.value = []
    concernStatusHistory.value = []

    selectedStatus.value = ''
    statusRemarks.value = ''
    newComment.value = ''

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
        url: attachmentUrl(
            attachment.file_path
        ),
        name:
            attachment.file_name ||
            'Image'
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

    const maxSize =
        5 * 1024 * 1024

    for (const file of files) {
        if (
            !validImageTypes.includes(
                file.type
            )
        ) {
            emit(
                'error',
                `Invalid image format: ${file.name}. Please upload JPG, PNG, GIF, or WEBP.`
            )

            event.target.value = ''
            return
        }

        if (file.size > maxSize) {
            emit(
                'error',
                `Image is too large: ${file.name}. Maximum size is 5 MB.`
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
        const previewUrl =
            URL.createObjectURL(file)

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
        URL.revokeObjectURL(
            preview.url
        )
    }

    selectedCommentImages.value.splice(
        index,
        1
    )

    commentImagePreviews.value.splice(
        index,
        1
    )
}

function clearCommentImages() {
    for (
        const preview
        of commentImagePreviews.value
    ) {
        if (preview?.url) {
            URL.revokeObjectURL(
                preview.url
            )
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

    const maxSize =
        5 * 1024 * 1024

    for (const file of files) {
        if (
            !allowedTypes.includes(
                file.type
            )
        ) {
            emit(
                'error',
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`
            )

            event.target.value = ''
            return
        }

        if (file.size > maxSize) {
            emit(
                'error',
                `${file.name} exceeds the 5 MB limit.`
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
        const previewUrl =
            URL.createObjectURL(file)

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
        URL.revokeObjectURL(
            preview.url
        )
    }

    selectedStatusImages.value.splice(
        index,
        1
    )

    statusImagePreviews.value.splice(
        index,
        1
    )
}

function clearStatusImages() {
    for (
        const preview
        of statusImagePreviews.value
    ) {
        if (preview?.url) {
            URL.revokeObjectURL(
                preview.url
            )
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
        emit(
            'error',
            'You do not have permission to comment on this concern.'
        )

        return
    }

    /*
     * The backend allows either:
     * - comment text
     * - image attachment
     * - both
     */
    if (
        !newComment.value.trim() &&
        selectedCommentImages.value.length === 0
    ) {
        emit(
            'error',
            'Please enter a comment or attach at least one image.'
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

        for (
            const file
            of selectedCommentImages.value
        ) {
            formData.append(
                'attachments',
                file
            )
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

        emit(
            'success',
            'Comment added successfully.'
        )

    } catch (error) {
        emit(
            'error',
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to add comment.'
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

function triggerAttachmentReplace(
    attachment
) {
    if (!canEditOriginalAttachments()) {
        return
    }

    editingAttachmentId.value =
        attachment.id

    nextTick(() => {
        replacementInput.value?.click()
    })
}

function handleAdditionalAttachments(
    event
) {
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

    const maxSize =
        5 * 1024 * 1024

    for (const file of files) {
        if (
            !allowedTypes.includes(
                file.type
            )
        ) {
            emit(
                'error',
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`
            )

            event.target.value = ''
            return
        }

        if (file.size > maxSize) {
            emit(
                'error',
                `${file.name} exceeds the 5 MB limit.`
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
        const previewUrl =
            URL.createObjectURL(file)

        additionalImagePreviews.value.push({
            file,
            url: previewUrl
        })
    }

    event.target.value = ''

    /*
     * Existing behavior adds the selected
     * files immediately.
     */
    attachAdditionalImages()
}

function removeAdditionalImage(index) {
    const preview =
        additionalImagePreviews.value[index]

    if (preview?.url) {
        URL.revokeObjectURL(
            preview.url
        )
    }

    selectedAdditionalImages.value.splice(
        index,
        1
    )

    additionalImagePreviews.value.splice(
        index,
        1
    )
}

function clearAdditionalImages() {
    for (
        const preview
        of additionalImagePreviews.value
    ) {
        if (preview?.url) {
            URL.revokeObjectURL(
                preview.url
            )
        }
    }

    selectedAdditionalImages.value = []
    additionalImagePreviews.value = []

    if (
        additionalAttachmentInput.value
    ) {
        additionalAttachmentInput.value.value =
            ''
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
        return
    }

    addingAttachments.value = true

    const imageCount =
        selectedAdditionalImages.value.length

    try {
        const formData = new FormData()

        for (
            const file
            of selectedAdditionalImages.value
        ) {
            formData.append(
                'images',
                file
            )
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

        emit(
            'success',
            `${imageCount} image${imageCount === 1 ? '' : 's'} attached successfully.`
        )

    } catch (error) {
        emit(
            'error',
            error?.data?.statusMessage ||
            error?.data?.message ||
            error?.statusMessage ||
            error?.message ||
            'Failed to add attachments.'
        )
    } finally {
        addingAttachments.value = false
    }
}

async function handleAttachmentReplacement(
    event
) {
    const file =
        event.target.files?.[0]

    if (
        !file ||
        !editingAttachmentId.value
    ) {
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

    if (
        !validImageTypes.includes(
            file.type
        )
    ) {
        emit(
            'error',
            'Invalid image format. Please upload JPG, PNG, GIF, or WEBP.'
        )

        event.target.value = ''
        editingAttachmentId.value = null

        return
    }

    if (file.size > 5 * 1024 * 1024) {
        emit(
            'error',
            'Image is too large. Maximum size is 5 MB.'
        )

        event.target.value = ''
        editingAttachmentId.value = null

        return
    }

    replacingAttachmentId.value =
        editingAttachmentId.value

    try {
        const formData = new FormData()

        formData.append(
            'attachment_id',
            String(
                editingAttachmentId.value
            )
        )

        formData.append(
            'image',
            file
        )

        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/attachments`,
            {
                method: 'PUT',
                body: formData
            }
        )

        await refreshConcernDetails()

        emit('refresh')

        emit(
            'success',
            'Attachment replaced successfully.'
        )

    } catch (error) {
        emit(
            'error',
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to replace attachment.'
        )
    } finally {
        replacingAttachmentId.value = null
        editingAttachmentId.value = null
        event.target.value = ''
    }
}

async function removeOriginalAttachment(
    attachment
) {
    if (!canEditOriginalAttachments()) {
        return
    }

    const confirmed = window.confirm(
        `Remove "${attachment.file_name}" from this concern?`
    )

    if (!confirmed) {
        return
    }

    deletingAttachmentId.value =
        attachment.id

    try {
        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/attachments`,
            {
                method: 'DELETE',
                body: {
                    attachment_id:
                        attachment.id
                }
            }
        )

        await refreshConcernDetails()

        emit('refresh')

        emit(
            'success',
            'Attachment removed successfully.'
        )

    } catch (error) {
        emit(
            'error',
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to remove attachment.'
        )
    } finally {
        deletingAttachmentId.value = null
    }
}

/*
 * ---------------------------------------------------------
 * STATUS
 * ---------------------------------------------------------
 */

async function updateConcernStatus() {
    if (!selectedConcern.value?.id) {
        return
    }

    if (
        !selectedStatus.value ||
        selectedStatus.value ===
            selectedConcern.value.status
    ) {
        return
    }

    const targetStatus =
        selectedStatus.value

    if (!canChangeToStatus(targetStatus)) {
        emit(
            'error',
            'You do not have permission to make this status change.'
        )

        return
    }

    if (
        targetStatus === 'closed' &&
        !canCloseConcern() &&
        props.currentUser?.role_name !==
            'superadmin'
    ) {
        emit(
            'error',
            'Only the creator can close a resolved concern.'
        )

        return
    }

    const resolvingConcern =
        isAssignedAdmin() &&
        selectedConcern.value.status ===
            'in_progress' &&
        targetStatus === 'resolved'

    if (
        resolvingConcern &&
        !statusRemarks.value.trim()
    ) {
        emit(
            'error',
            'Please enter remarks explaining what was done before marking the concern as resolved.'
        )

        return
    }

    if (
        resolvingConcern &&
        selectedStatusImages.value.length === 0
    ) {
        emit(
            'error',
            'Please attach at least one evidence image before marking the concern as resolved.'
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

        for (
            const file
            of selectedStatusImages.value
        ) {
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

        await refreshConcernDetails()

        emit('refresh')

        emit(
            'success',
            targetStatus === 'resolved'
                ? 'Concern resolved successfully with evidence.'
                : targetStatus === 'closed'
                    ? 'Concern closed successfully.'
                    : 'Concern status updated successfully.'
        )

    } catch (error) {
        emit(
            'error',
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to update concern status.'
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
        currentTime.value =
            new Date()
    }, 60000)
})

onUnmounted(() => {
    if (durationTimer) {
        clearInterval(durationTimer)
    }

    clearCommentImages()
    clearStatusImages()
    clearAdditionalImages()
})

</script>

<template>

    <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 px-4 py-6 backdrop-blur-[2px]"
    >

        <div
            class="flex max-h-[92vh] w-full max-w-5xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
        >

            <!-- Header -->
            <div
                class="flex shrink-0 items-center justify-between border-b border-slate-200 bg-white px-6 py-4"
            >

                <div>
                    <p class="text-xs font-medium uppercase tracking-wide text-slate-400">
                        Concern Details
                    </p>

                    <h3 class="mt-1 text-lg font-semibold text-slate-800">
                        {{ selectedConcern?.concern_number || 'View Concern' }}
                    </h3>
                </div>

                <button
                    type="button"
                    @click="closeViewModal"
                    :disabled="
                        savingComment ||
                        updatingStatus ||
                        addingAttachments
                    "
                    class="flex h-9 w-9 cursor-pointer items-center justify-center rounded-lg text-xl text-slate-500 transition hover:bg-slate-100 hover:text-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                >
                    ×
                </button>

            </div>

            <!-- Body -->
            <div class="flex-1 overflow-y-auto bg-slate-50 px-6 py-5">

                <!-- Loading -->
                <div
                    v-if="loadingConcernDetails"
                    class="flex min-h-[300px] items-center justify-center"
                >
                    <div class="text-center">
                        <div class="mx-auto h-8 w-8 animate-spin rounded-full border-2 border-slate-300 border-t-slate-800"></div>

                        <p class="mt-3 text-sm text-slate-500">
                            Loading concern details...
                        </p>
                    </div>
                </div>

                <div
                    v-else-if="selectedConcern"
                    class="space-y-5"
                >

                    <!-- Pending Recipient Notice -->
                    <div
                        v-if="
                            isAssignedAdmin() &&
                            selectedConcern.status === 'pending'
                        "
                        class="rounded-xl border border-blue-200 bg-blue-50 p-4"
                    >
                        <p class="text-sm font-semibold text-blue-800">
                            New concern assigned to your organization
                        </p>

                        <p class="mt-1 text-xs leading-5 text-blue-700">
                            Select
                            <span class="font-semibold">
                                In Progress
                            </span>
                            below to acknowledge the concern and begin handling it.
                        </p>
                    </div>

                    <!-- In Progress Recipient Notice -->
                    <div
                        v-if="
                            isAssignedAdmin() &&
                            selectedConcern.status === 'in_progress'
                        "
                        class="rounded-xl border border-blue-200 bg-blue-50 p-4"
                    >
                        <p class="text-sm font-semibold text-blue-800">
                            You are currently handling this concern
                        </p>

                        <p class="mt-1 text-xs leading-5 text-blue-700">
                            When the work is completed, select
                            <span class="font-semibold">
                                Resolved
                            </span>
                            and provide remarks and at least one evidence image.
                        </p>
                    </div>

                    <!-- Resolved Notice -->
                    <div
                        v-if="selectedConcern.status === 'resolved'"
                        class="rounded-xl border border-green-200 bg-green-50 p-4"
                    >
                        <p class="text-sm font-semibold text-green-800">
                            Concern resolved
                        </p>

                        <p
                            v-if="canCloseConcern()"
                            class="mt-1 text-xs leading-5 text-green-700"
                        >
                            Please review the resolution remarks and evidence below.
                            If the concern has been properly resolved, you can close it.
                        </p>

                        <p
                            v-else
                            class="mt-1 text-xs leading-5 text-green-700"
                        >
                            The assigned organization has marked this concern as resolved.
                        </p>

                        <!-- Creator Close Concern -->
                        <div
                            v-if="canCloseConcern()"
                            class="mt-4"
                        >
                            <button
                                type="button"
                                @click="
                                    selectedStatus = 'closed';
                                    statusRemarks = '';
                                    clearStatusImages();
                                    updateConcernStatus()
                                "
                                :disabled="updatingStatus"
                                class="cursor-pointer rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-green-800 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                {{
                                    updatingStatus
                                        ? 'Closing...'
                                        : 'Close Concern'
                                }}
                            </button>
                        </div>
                    </div>

                    <!-- Main Information -->
                    <div
                        class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                    >

                        <div class="mb-5">
                            <h4 class="text-base font-semibold text-slate-800">
                                Main Information
                            </h4>

                            <p class="mt-1 text-sm text-slate-500">
                                Details of this concern.
                            </p>
                        </div>

                        <div class="grid gap-5 md:grid-cols-2">

                            <div class="md:col-span-2">
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Title
                                </p>

                                <p class="text-sm font-semibold text-slate-800">
                                    {{ selectedConcern.title || '-' }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Priority
                                </p>

                                <span
                                    class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold"
                                    :class="priorityClass(selectedConcern.priority)"
                                >
                                    {{ formatPriority(selectedConcern.priority) }}
                                </span>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Status
                                </p>

                                <span
                                    class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold"
                                    :class="statusClass(selectedConcern.status)"
                                >
                                    {{ formatStatus(selectedConcern.status) }}
                                </span>

                                <span
                                    v-if="
                                        selectedConcern.status === 'resolved' ||
                                        selectedConcern.status === 'closed'
                                    "
                                    class="ml-2 inline-flex items-center gap-1 rounded-full bg-green-100 px-2.5 py-1 text-xs font-semibold text-green-700"
                                >
                                    ✓ Completed
                                </span>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Concern Number
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.concern_number || '-' }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Concern Type
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.concern_type_name || '-' }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Assigned To
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.assigned_organization_name || '-' }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Created By
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.created_by_name || '-' }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Creator Organization
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ selectedConcern.creator_organization_name || '-' }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Created At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.created_at) }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Acknowledged At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.acknowledged_at) }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Handling Duration
                                </p>

                                <p class="text-sm font-medium text-slate-700">
                                    {{ getConcernDuration(selectedConcern) }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Updated At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.updated_at) }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Resolved At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.resolved_at) }}
                                </p>
                            </div>

                            <div>
                                <p class="mb-1 text-xs font-medium uppercase tracking-wide text-slate-400">
                                    Closed At
                                </p>

                                <p class="text-sm text-slate-700">
                                    {{ formatDate(selectedConcern.closed_at) }}
                                </p>
                            </div>

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
                    <div
                        v-if="canUpdateStatus()"
                        class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                    >

                        <div class="mb-4">
                            <h4 class="text-base font-semibold text-slate-800">
                                Update Status
                            </h4>

                            <p class="mt-1 text-sm text-slate-500">

                                <span
                                    v-if="isAssignedAdmin()"
                                >
                                    Update the concern as you handle the work.
                                </span>

                                <span
                                    v-else-if="
                                        currentUser?.role_name === 'superadmin'
                                    "
                                >
                                    Manage the concern status.
                                </span>

                            </p>
                        </div>

                        <div class="grid gap-4 md:grid-cols-2">

                            <!-- Status -->
                            <div>

                                <label class="mb-2 block text-sm font-medium text-slate-700">
                                    Status
                                </label>

                                <select
                                    v-model="selectedStatus"
                                    :disabled="
                                        updatingStatus ||
                                        availableStatusOptions.length === 0
                                    "
                                    class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100 disabled:cursor-not-allowed disabled:bg-slate-100"
                                >

                                    <option
                                        :value="selectedConcern.status"
                                    >
                                        {{ formatStatus(selectedConcern.status) }}
                                    </option>

                                    <option
                                        v-for="option in availableStatusOptions"
                                        :key="option.value"
                                        :value="option.value"
                                    >
                                        {{ option.label }}
                                    </option>

                                </select>

                            </div>

                            <!-- Remarks -->
                            <div>

                                <label class="mb-2 block text-sm font-medium text-slate-700">

                                    Remarks

                                    <span
                                        v-if="
                                            isAssignedAdmin() &&
                                            selectedConcern.status === 'in_progress' &&
                                            selectedStatus === 'resolved'
                                        "
                                        class="font-medium text-red-500"
                                    >
                                        *
                                    </span>

                                    <span
                                        v-else
                                        class="font-normal text-slate-400"
                                    >
                                        (Optional)
                                    </span>

                                </label>

                                <textarea
                                    v-model="statusRemarks"
                                    :disabled="updatingStatus"
                                    rows="3"
                                    :placeholder="
                                        isAssignedAdmin() &&
                                        selectedConcern.status === 'in_progress' &&
                                        selectedStatus === 'resolved'
                                            ? 'Explain what was done to resolve the concern...'
                                            : 'Add remarks about this status change...'
                                    "
                                    class="w-full resize-none rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100 disabled:cursor-not-allowed disabled:bg-slate-100"
                                ></textarea>

                            </div>

                        </div>

                        <!-- Resolution Evidence -->
                        <div
                            v-if="
                                isAssignedAdmin() &&
                                selectedConcern.status === 'in_progress' &&
                                selectedStatus === 'resolved'
                            "
                            class="mt-5 rounded-lg border border-green-200 bg-green-50 p-4"
                        >

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

                            <input
                                ref="statusImageInput"
                                type="file"
                                multiple
                                accept="image/jpeg,image/png,image/gif,image/webp"
                                :disabled="updatingStatus"
                                @change="handleStatusImagesChange"
                                class="w-full cursor-pointer rounded-lg border border-green-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-green-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-green-700 hover:border-green-400 hover:file:bg-green-200 disabled:cursor-not-allowed disabled:bg-slate-100"
                            />

                            <p class="mt-1 text-xs text-slate-500">
                                Multiple images are allowed. Maximum size: 5 MB per image.
                            </p>

                            <!-- Selected Evidence Images -->
                            <div
                                v-if="statusImagePreviews.length > 0"
                                class="mt-4"
                            >

                                <div class="mb-2 flex items-center justify-between">

                                    <p class="text-sm font-medium text-slate-700">
                                        Selected Evidence
                                        ({{ statusImagePreviews.length }})
                                    </p>

                                    <button
                                        type="button"
                                        @click="clearStatusImages"
                                        :disabled="updatingStatus"
                                        class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                                    >
                                        Remove All
                                    </button>

                                </div>

                                <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">

                                    <div
                                        v-for="(preview, index) in statusImagePreviews"
                                        :key="preview.url"
                                        class="group relative overflow-hidden rounded-lg border border-green-200 bg-white"
                                    >

                                        <img
                                            :src="preview.url"
                                            :alt="preview.file.name"
                                            class="h-28 w-full object-cover transition duration-200 group-hover:scale-105"
                                        />

                                        <button
                                            type="button"
                                            @click="removeStatusImage(index)"
                                            :disabled="updatingStatus"
                                            class="absolute right-2 top-2 cursor-pointer rounded-md bg-black/70 px-2 py-1 text-xs font-medium text-white transition hover:bg-red-600 disabled:cursor-not-allowed disabled:opacity-50"
                                        >
                                            Remove
                                        </button>

                                        <div class="border-t border-slate-200 px-2 py-2">
                                            <p
                                                class="truncate text-xs text-slate-500"
                                                :title="preview.file.name"
                                            >
                                                {{ preview.file.name }}
                                            </p>
                                        </div>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!-- Recipient Acknowledgement -->
                        <div
                            v-if="
                                isAssignedAdmin() &&
                                selectedConcern.status === 'pending'
                            "
                            class="mt-5 rounded-lg border border-blue-200 bg-blue-50 p-4"
                        >

                            <p class="text-sm font-semibold text-blue-800">
                                Acknowledge this concern
                            </p>

                            <p class="mt-1 text-xs leading-5 text-blue-700">
                                Selecting
                                <span class="font-semibold">
                                    In Progress
                                </span>
                                and updating the status records the time you started
                                handling this concern.
                            </p>

                        </div>

                        <!-- Update Button -->
                        <div class="mt-4 flex justify-end">

                            <button
                                type="button"
                                @click="updateConcernStatus"
                                :disabled="
                                    updatingStatus ||
                                    selectedStatus === selectedConcern.status
                                "
                                class="cursor-pointer rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                {{
                                    updatingStatus
                                        ? 'Updating...'
                                        : 'Update Status'
                                }}
                            </button>

                        </div>

                    </div>

                    <!-- Attachments -->
                    <div
                        class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                    >

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

                                <span
                                    v-if="concernAttachments.length > 0"
                                    class="text-xs text-slate-400"
                                >
                                    {{ concernAttachments.length }}
                                    attachment{{
                                        concernAttachments.length === 1
                                            ? ''
                                            : 's'
                                    }}
                                </span>

                                <button
                                    v-if="canEditOriginalAttachments()"
                                    type="button"
                                    @click="additionalAttachmentInput?.click()"
                                    :disabled="addingAttachments"
                                    class="inline-flex cursor-pointer items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50"
                                >

                                    <span class="text-base leading-none">
                                        {{ addingAttachments ? '...' : '+' }}
                                    </span>

                                    {{
                                        addingAttachments
                                            ? 'Adding...'
                                            : 'Add Images'
                                    }}

                                </button>

                            </div>

                        </div>

                        <div
                            v-if="concernAttachments.length === 0"
                            class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500"
                        >
                            No attachments.
                        </div>

                        <div
                            v-else
                            class="max-h-[520px] overflow-y-auto pr-1"
                        >

                            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">

                                <div
                                    v-for="attachment in concernAttachments"
                                    :key="attachment.id"
                                    class="overflow-hidden rounded-lg border border-slate-200 bg-white"
                                >

                                    <button
                                        type="button"
                                        @click="openImageViewer(attachment)"
                                        class="group block w-full cursor-pointer text-left"
                                        :title="`View ${attachment.file_name}`"
                                    >

                                        <div class="relative overflow-hidden bg-white">

                                            <img
                                                v-if="
                                                    attachment.file_type?.startsWith('image/')
                                                "
                                                :src="attachmentUrl(attachment.file_path)"
                                                :alt="attachment.file_name"
                                                class="h-32 w-full object-cover transition duration-200 group-hover:scale-105"
                                            />

                                            <div
                                                v-else
                                                class="flex h-32 items-center justify-center text-xs text-slate-500"
                                            >
                                                File attachment
                                            </div>

                                            <div
                                                class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20"
                                            >
                                                <span
                                                    class="rounded-full bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700 opacity-0 shadow transition group-hover:opacity-100"
                                                >
                                                    View
                                                </span>
                                            </div>

                                        </div>

                                    </button>

                                    <div class="border-t border-slate-200 bg-white p-3">

                                        <div class="mb-2 flex items-center justify-between gap-2">

                                            <span
                                                class="rounded-full px-2 py-1 text-[10px] font-semibold"
                                                :class="
                                                    attachment.edited_at
                                                        ? 'bg-amber-100 text-amber-700'
                                                        : 'bg-slate-100 text-slate-600'
                                                "
                                            >
                                                {{
                                                    attachment.edited_at
                                                        ? 'Edited'
                                                        : 'Uploaded'
                                                }}
                                            </span>

                                            <span
                                                v-if="canEditOriginalAttachments()"
                                                class="text-[10px] text-slate-400"
                                            >
                                                Original
                                            </span>

                                        </div>

                                        <p
                                            class="truncate text-xs font-medium text-slate-700"
                                            :title="attachment.file_name"
                                        >
                                            {{ attachment.file_name }}
                                        </p>

                                        <p class="mt-1 truncate text-[11px] text-slate-400">
                                            {{ attachment.uploaded_by_name || '-' }}
                                        </p>

                                        <p class="mt-1 text-[11px] text-slate-400">
                                            {{
                                                attachment.edited_at
                                                    ? `Edited ${formatDate(attachment.edited_at)}`
                                                    : `Uploaded ${formatDate(attachment.created_at)}`
                                            }}
                                        </p>

                                        <div
                                            v-if="canEditOriginalAttachments()"
                                            class="mt-3 flex gap-2"
                                        >

                                            <button
                                                type="button"
                                                @click="triggerAttachmentReplace(attachment)"
                                                :disabled="
                                                    replacingAttachmentId === attachment.id ||
                                                    deletingAttachmentId === attachment.id
                                                "
                                                class="flex-1 cursor-pointer rounded-md border border-slate-300 px-2 py-1.5 text-[11px] font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50"
                                            >
                                                {{
                                                    replacingAttachmentId === attachment.id
                                                        ? 'Replacing...'
                                                        : 'Replace'
                                                }}
                                            </button>

                                            <button
                                                type="button"
                                                @click="removeOriginalAttachment(attachment)"
                                                :disabled="
                                                    replacingAttachmentId === attachment.id ||
                                                    deletingAttachmentId === attachment.id
                                                "
                                                class="cursor-pointer rounded-md border border-red-200 px-2 py-1.5 text-[11px] font-medium text-red-600 transition hover:bg-red-50 hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                                            >
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

                        <input
                            ref="replacementInput"
                            type="file"
                            accept="image/jpeg,image/png,image/gif,image/webp"
                            class="hidden"
                            @change="handleAttachmentReplacement"
                        />

                        <input
                            ref="additionalAttachmentInput"
                            type="file"
                            multiple
                            accept="image/jpeg,image/png,image/gif,image/webp"
                            class="hidden"
                            @change="handleAdditionalAttachments"
                        />

                    </div>

                    <!-- Status History -->
                    <div
                        class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                    >

                        <div class="mb-4">
                            <h4 class="text-base font-semibold text-slate-800">
                                Status History
                            </h4>

                            <p class="mt-1 text-sm text-slate-500">
                                Record of status changes.
                            </p>
                        </div>

                        <div
                            v-if="concernStatusHistory.length === 0"
                            class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500"
                        >
                            No status history available.
                        </div>

                        <div
                            v-else
                            class="space-y-4"
                        >

                            <div
                                v-for="history in concernStatusHistory"
                                :key="history.id"
                                class="rounded-lg border border-slate-200 bg-slate-50 p-4"
                            >

                                <div class="flex flex-wrap items-center justify-between gap-3">

                                    <div class="flex flex-wrap items-center gap-2">

                                        <span
                                            v-if="history.old_status"
                                            class="rounded-full bg-slate-200 px-3 py-1 text-xs font-medium text-slate-700"
                                        >
                                            {{ formatStatus(history.old_status) }}
                                        </span>

                                        <span
                                            v-if="history.old_status"
                                            class="text-slate-400"
                                        >
                                            →
                                        </span>

                                        <span
                                            class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(history.new_status)"
                                        >
                                            {{ formatStatus(history.new_status) }}
                                        </span>

                                        <span
                                            v-if="
                                                history.new_status === 'resolved' ||
                                                history.new_status === 'closed'
                                            "
                                            class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-xs font-semibold text-green-700"
                                        >
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
                                        {{ history.changed_by_name || '-' }}
                                    </span>
                                </p>

                                <p
                                    v-if="history.remarks"
                                    class="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700"
                                >
                                    {{ history.remarks }}
                                </p>

                                <div
                                    v-if="
                                        history.attachments &&
                                        history.attachments.length > 0
                                    "
                                    class="mt-4"
                                >

                                    <div class="mb-2 flex items-center justify-between">

                                        <p class="text-xs font-semibold text-slate-700">
                                            Resolution Evidence
                                        </p>

                                        <span class="text-[11px] text-slate-400">
                                            {{ history.attachments.length }}
                                            image{{
                                                history.attachments.length === 1
                                                    ? ''
                                                    : 's'
                                            }}
                                        </span>

                                    </div>

                                    <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">

                                        <button
                                            v-for="attachment in history.attachments"
                                            :key="attachment.id"
                                            type="button"
                                            @click="openImageViewer(attachment)"
                                            class="group relative block w-full cursor-pointer overflow-hidden rounded-lg border border-green-200 bg-white text-left transition hover:border-green-400 hover:shadow-md"
                                            :title="`View ${attachment.file_name}`"
                                        >

                                            <img
                                                v-if="attachment.file_type?.startsWith('image/')"
                                                :src="attachmentUrl(attachment.file_path)"
                                                :alt="attachment.file_name"
                                                class="h-28 w-full object-cover transition duration-200 group-hover:scale-105"
                                            />

                                            <div
                                                class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20"
                                            >
                                                <span
                                                    class="rounded-full bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700 opacity-0 shadow transition group-hover:opacity-100"
                                                >
                                                    View
                                                </span>
                                            </div>

                                            <div class="border-t border-green-100 bg-white px-2 py-2">

                                                <p
                                                    class="truncate text-[11px] font-medium text-slate-600"
                                                    :title="attachment.file_name"
                                                >
                                                    {{ attachment.file_name }}
                                                </p>

                                                <p class="mt-1 text-[10px] text-slate-400">
                                                    Uploaded by
                                                    {{ attachment.uploaded_by_name || '-' }}
                                                </p>

                                                <p class="mt-1 text-[10px] text-slate-400">
                                                    {{ formatDate(attachment.created_at) }}
                                                </p>

                                            </div>

                                        </button>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                    <!-- Comments -->
                    <div
                        class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                    >

                        <div class="mb-5">

                            <h4 class="text-base font-semibold text-slate-800">
                                Conversation
                            </h4>

                            <p class="mt-1 text-sm text-slate-500">
                                Communication between the concern creator and the assigned organization.
                            </p>

                        </div>

                        <!-- No Comments -->
                        <div
                            v-if="concernComments.length === 0"
                            class="rounded-lg bg-slate-50 p-6 text-center"
                        >

                            <p class="text-sm text-slate-500">
                                No conversation yet.
                            </p>

                            <p
                                v-if="canComment()"
                                class="mt-1 text-xs text-slate-400"
                            >
                                Start the conversation by adding a comment below.
                            </p>

                        </div>

                        <!-- Conversation -->
                        <div
                            v-else
                            class="space-y-5"
                        >

                            <div
                                v-for="comment in concernComments"
                                :key="comment.id"
                                class="flex"
                                :class="
                                    Number(comment.user_id) ===
                                    Number(currentUser?.id)
                                        ? 'justify-end'
                                        : 'justify-start'
                                "
                            >

                                <div class="max-w-[90%] sm:max-w-[78%]">

                                    <!-- Sender -->
                                    <div
                                        class="mb-1 flex flex-wrap items-center gap-2"
                                        :class="
                                            Number(comment.user_id) ===
                                            Number(currentUser?.id)
                                                ? 'justify-end'
                                                : 'justify-start'
                                        "
                                    >

                                        <p class="text-xs font-semibold text-slate-700">
                                            {{ comment.user_name || '-' }}
                                        </p>

                                        <span class="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                                            {{ comment.role_name || '-' }}
                                        </span>

                                        <span class="max-w-[180px] truncate rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                                            {{ comment.organization_name || '-' }}
                                        </span>

                                    </div>

                                    <!-- Message Bubble -->
                                    <div
                                        class="rounded-2xl px-4 py-3"
                                        :class="
                                            Number(comment.user_id) ===
                                            Number(currentUser?.id)
                                                ? 'rounded-br-md bg-slate-900 text-white'
                                                : 'rounded-bl-md bg-slate-100 text-slate-800'
                                        "
                                    >

                                        <!-- Comment Text -->
                                        <p
                                            v-if="comment.comment"
                                            class="whitespace-pre-wrap break-words text-sm leading-6"
                                        >
                                            {{ comment.comment }}
                                        </p>

                                        <!-- Comment Attachments -->
                                        <div
                                            v-if="
                                                comment.attachments &&
                                                comment.attachments.length > 0
                                            "
                                            :class="
                                                comment.comment
                                                    ? 'mt-3'
                                                    : ''
                                            "
                                            class="flex flex-wrap gap-2"
                                        >

                                            <button
                                                v-for="attachment in comment.attachments"
                                                :key="attachment.id"
                                                type="button"
                                                @click="openImageViewer(attachment)"
                                                class="group relative block h-20 w-20 cursor-pointer overflow-hidden rounded-lg border border-slate-300 bg-white transition hover:border-slate-500 hover:shadow-md sm:h-24 sm:w-24"
                                                :title="`View ${attachment.file_name}`"
                                            >

                                                <img
                                                    v-if="
                                                        attachment.file_type?.startsWith('image/')
                                                    "
                                                    :src="attachmentUrl(attachment.file_path)"
                                                    :alt="attachment.file_name"
                                                    class="h-full w-full object-cover transition duration-200 group-hover:scale-105"
                                                />

                                                <div
                                                    class="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/20"
                                                >
                                                    <span
                                                        class="text-xs font-semibold text-white opacity-0 transition group-hover:opacity-100"
                                                    >
                                                        View
                                                    </span>
                                                </div>

                                            </button>

                                        </div>

                                    </div>

                                    <!-- Timestamp -->
                                    <p
                                        class="mt-1 text-[11px] text-slate-400"
                                        :class="
                                            Number(comment.user_id) ===
                                            Number(currentUser?.id)
                                                ? 'text-right'
                                                : 'text-left'
                                        "
                                    >
                                        {{ formatDate(comment.created_at) }}
                                    </p>

                                </div>

                            </div>

                        </div>

                        <!-- Add Comment -->
                        <div
                            v-if="canComment()"
                            class="mt-6 border-t border-slate-200 pt-5"
                        >

                            <div class="mb-2 flex items-center justify-between">

                                <label class="block text-sm font-medium text-slate-700">
                                    Add Comment
                                </label>

                                <span class="text-xs text-slate-400">
                                    {{ currentUser?.role_name || '' }}
                                </span>

                            </div>

                            <!-- Message -->
                            <textarea
                                v-model="newComment"
                                :disabled="savingComment"
                                rows="4"
                                placeholder="Write a message..."
                                class="w-full resize-y rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-slate-500 disabled:cursor-not-allowed disabled:bg-slate-100"
                            ></textarea>

                            <!-- Attachment Input -->
                            <div class="mt-3">

                                <label class="mb-2 block text-sm font-medium text-slate-700">

                                    Attach Images

                                    <span class="font-normal text-slate-400">
                                        (Optional)
                                    </span>

                                </label>

                                <input
                                    ref="commentImageInput"
                                    type="file"
                                    multiple
                                    accept="image/jpeg,image/png,image/gif,image/webp"
                                    :disabled="savingComment"
                                    @change="handleCommentImagesChange"
                                    class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-slate-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:border-slate-400 hover:file:bg-slate-200 disabled:cursor-not-allowed disabled:bg-slate-100"
                                />

                                <p class="mt-1 text-xs text-slate-500">
                                    You can select multiple images. Maximum size: 5 MB per image.
                                </p>

                            </div>

                            <!-- Selected Comment Images -->
                            <div
                                v-if="commentImagePreviews.length > 0"
                                class="mt-4"
                            >

                                <div class="mb-2 flex items-center justify-between">

                                    <p class="text-sm font-medium text-slate-700">
                                        Selected Images
                                    </p>

                                    <button
                                        type="button"
                                        @click="clearCommentImages"
                                        :disabled="savingComment"
                                        class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                                    >
                                        Remove All
                                    </button>

                                </div>

                                <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">

                                    <div
                                        v-for="(preview, index) in commentImagePreviews"
                                        :key="preview.url"
                                        class="relative overflow-hidden rounded-lg border border-slate-200 bg-slate-50"
                                    >

                                        <img
                                            :src="preview.url"
                                            :alt="preview.file.name"
                                            class="h-28 w-full bg-white object-cover"
                                        />

                                        <div class="flex items-center justify-between gap-2 border-t border-slate-200 bg-white p-2">

                                            <p
                                                class="min-w-0 flex-1 truncate text-xs text-slate-500"
                                                :title="preview.file.name"
                                            >
                                                {{ preview.file.name }}
                                            </p>

                                            <button
                                                type="button"
                                                @click="removeCommentImage(index)"
                                                :disabled="savingComment"
                                                class="shrink-0 cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                                            >
                                                Remove
                                            </button>

                                        </div>

                                    </div>

                                </div>

                            </div>

                            <!-- Send -->
                            <div class="mt-3 flex justify-end">

                                <button
                                    type="button"
                                    @click="addComment"
                                    :disabled="
                                        savingComment ||
                                        (
                                            !newComment.trim() &&
                                            selectedCommentImages.length === 0
                                        )
                                    "
                                    class="cursor-pointer rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    {{
                                        savingComment
                                            ? 'Sending...'
                                            : 'Send Comment'
                                    }}
                                </button>

                            </div>

                        </div>

                        <!-- No Permission -->
                        <div
                            v-else
                            class="mt-5 border-t border-slate-200 pt-5"
                        >
                            <p
                                v-if="isConcernCompleted()"
                                class="text-sm text-slate-400"
                            >
                                This concern is already completed. Conversation is closed.
                            </p>

                            <p
                                v-else
                                class="text-sm text-slate-400"
                            >
                                You do not have permission to participate in this conversation.
                            </p>
                        </div>

                    </div>

                </div>

            </div>

            <!-- Footer -->
            <div
                class="flex shrink-0 justify-end border-t border-slate-200 bg-white px-6 py-4"
            >

                <button
                    type="button"
                    @click="closeViewModal"
                    :disabled="
                        savingComment ||
                        updatingStatus ||
                        addingAttachments
                    "
                    class="cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50"
                >
                    Close
                </button>

            </div>

        </div>

    </div>

    <!-- Full Image Viewer -->
    <div
        v-if="
            showImageViewer &&
            selectedViewerImage
        "
        class="fixed inset-0 z-[100] flex items-center justify-center bg-black/85 p-4"
        @click.self="closeImageViewer"
    >

        <div
            class="relative flex max-h-[95vh] max-w-[95vw] flex-col items-center"
        >

            <button
                type="button"
                @click="closeImageViewer"
                class="absolute -right-2 -top-2 z-10 flex h-10 w-10 cursor-pointer items-center justify-center rounded-full bg-white text-2xl leading-none text-slate-600 shadow-lg transition hover:bg-red-500 hover:text-white"
                title="Close image"
            >
                ×
            </button>

            <img
                :src="selectedViewerImage.url"
                :alt="selectedViewerImage.name"
                class="max-h-[85vh] max-w-[90vw] rounded-xl bg-white object-contain shadow-2xl"
            />

            <p
                class="mt-3 max-w-[90vw] truncate text-center text-sm font-medium text-white"
                :title="selectedViewerImage.name"
            >
                {{ selectedViewerImage.name }}
            </p>

        </div>

    </div>

</template>