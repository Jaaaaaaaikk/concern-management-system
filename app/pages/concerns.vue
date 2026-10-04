<script setup>
definePageMeta({
    middleware: 'auth'
})

let successTimeout = null
let errorTimeout = null

const concerns = ref([])
const concernTypes = ref([])
const organizations = ref([])
const currentUser = ref(null)

const loading = ref(true)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const showModal = ref(false)
const search = ref('')
const statusFilter = ref('')
const priorityFilter = ref('')

/*
 * Original concern attachments.
 * Multiple images are supported.
 */
const selectedImages = ref([])
const imagePreviews = ref([])

/*
 * View Concern modal.
 */
const showViewModal = ref(false)
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

/*
 * Status-change evidence images.
 * Used when the assigned recipient changes
 * the concern to Resolved.
 */
const selectedStatusImages = ref([])
const statusImagePreviews = ref([])
const statusImageInput = ref(null)

/*
 * Comment image attachments.
 * Multiple images can be selected for one comment.
 */
const selectedCommentImages = ref([])
const commentImagePreviews = ref([])
const commentImageInput = ref(null)

/*
 * Full image viewer.
 */
const showImageViewer = ref(false)
const selectedViewerImage = ref(null)

/*
 * Original attachment editing.
 */
const editingAttachmentId = ref(null)
const replacingAttachmentId = ref(null)
const deletingAttachmentId = ref(null)
const replacementInput = ref(null)
const addingAttachments = ref(false)
const additionalAttachmentInput = ref(null)
const selectedAdditionalImages = ref([])
const additionalImagePreviews = ref([])

/*
 * Current time used for the live concern handling duration.
 */
const currentTime = ref(new Date())
let durationTimer = null

const form = ref({
    title: '',
    description: '',
    concern_type_id: '',
    assigned_organization_id: '',
    priority: 'medium'
})

/*
 * Organizations available in the Create Concern form.
 *
 * Admin:
 * - Cannot assign a concern to their own organization.
 *
 * Regular User:
 * - Can select all organizations.
 *
 * Superadmin:
 * - Cannot create concerns, so this is not used.
 */
const availableOrganizations = computed(() => {
    if (!currentUser.value) {
        return []
    }

    if (currentUser.value.role_name === 'admin') {
        return organizations.value.filter(
            organization =>
                Number(organization.id) !==
                Number(currentUser.value.organization_id)
        )
    }

    return organizations.value
})

const filteredConcerns = computed(() => {
    const searchText = search.value.trim().toLowerCase()

    return concerns.value.filter((concern) => {
        const matchesSearch =
            !searchText ||
            concern.concern_number?.toLowerCase().includes(searchText) ||
            concern.title?.toLowerCase().includes(searchText) ||
            concern.description?.toLowerCase().includes(searchText)

        const matchesStatus =
            !statusFilter.value ||
            concern.status === statusFilter.value

        const matchesPriority =
            !priorityFilter.value ||
            concern.priority === priorityFilter.value

        return matchesSearch && matchesStatus && matchesPriority
    })
})

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
    if (!value) return '-'

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
    if (!value) return null

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

    const difference = end.getTime() - start.getTime()

    if (difference < 0) {
        return '-'
    }

    const totalMinutes = Math.floor(difference / 60000)
    const days = Math.floor(totalMinutes / 1440)
    const hours = Math.floor((totalMinutes % 1440) / 60)
    const minutes = totalMinutes % 60

    const parts = []

    if (days > 0) {
        parts.push(`${days}d`)
    }

    if (hours > 0) {
        parts.push(`${hours}h`)
    }

    if (minutes > 0 || parts.length === 0) {
        parts.push(`${minutes}m`)
    }

    return parts.join(' ')
}

function attachmentUrl(path) {
    if (!path) return ''

    if (
        path.startsWith('http://') ||
        path.startsWith('https://')
    ) {
        return path
    }

    return path.startsWith('/') ? path : `/${path}`
}

/*
 * ---------------------------------------------------------
 * ALERT MESSAGES
 * ---------------------------------------------------------
 */

function showSuccessMessage(message) {
    successMessage.value = message

    if (successTimeout) {
        clearTimeout(successTimeout)
    }

    successTimeout = setTimeout(() => {
        successMessage.value = ''
    }, 3000)
}

function showErrorMessage(message) {
    errorMessage.value = message

    if (errorTimeout) {
        clearTimeout(errorTimeout)
    }

    errorTimeout = setTimeout(() => {
        errorMessage.value = ''
    }, 5000)
}

/*
 * ---------------------------------------------------------
 * CREATE CONCERN
 * ---------------------------------------------------------
 */

function resetOriginalImages() {
    for (const preview of imagePreviews.value) {
        if (preview?.url) {
            URL.revokeObjectURL(preview.url)
        }
    }

    selectedImages.value = []
    imagePreviews.value = []
}

function handleImageChange(event) {
    const files = Array.from(event.target.files || [])

    if (!files.length) {
        return
    }

    const allowedTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    for (const file of files) {
        if (!allowedTypes.includes(file.type)) {
            showErrorMessage(
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`
            )
            continue
        }

        if (file.size > 5 * 1024 * 1024) {
            showErrorMessage(`${file.name} is larger than 5MB.`)
            continue
        }

        selectedImages.value.push(file)

        const previewUrl = URL.createObjectURL(file)

        imagePreviews.value.push({
            file,
            url: previewUrl
        })
    }

    event.target.value = ''
}

function removeImage(index) {
    const preview = imagePreviews.value[index]

    if (preview?.url) {
        URL.revokeObjectURL(preview.url)
    }

    selectedImages.value.splice(index, 1)
    imagePreviews.value.splice(index, 1)
}

function openCreateModal() {
    errorMessage.value = ''

    form.value = {
        title: '',
        description: '',
        concern_type_id: '',
        assigned_organization_id: '',
        priority: 'medium'
    }

    resetOriginalImages()
    showModal.value = true
}

function closeModal() {
    if (saving.value) {
        return
    }

    showModal.value = false
    resetOriginalImages()
    errorMessage.value = ''
}

async function createConcern() {
    errorMessage.value = ''

    if (!form.value.title.trim()) {
        showErrorMessage('Please enter a concern title.')
        return
    }

    if (!form.value.description.trim()) {
        showErrorMessage('Please enter a concern description.')
        return
    }

    if (!form.value.concern_type_id) {
        showErrorMessage('Please select a concern type.')
        return
    }

    if (!form.value.assigned_organization_id) {
        showErrorMessage('Please select an organization.')
        return
    }

    /*
     * Frontend protection:
     * Admin cannot assign a concern to their own organization.
     */
    if (
        currentUser.value?.role_name === 'admin' &&
        Number(form.value.assigned_organization_id) ===
        Number(currentUser.value.organization_id)
    ) {
        showErrorMessage(
            'You cannot assign a concern to your own organization.'
        )
        return
    }

    saving.value = true

    try {
        const formData = new FormData()

        formData.append('title', form.value.title.trim())
        formData.append(
            'description',
            form.value.description.trim()
        )
        formData.append(
            'concern_type_id',
            form.value.concern_type_id
        )
        formData.append(
            'assigned_organization_id',
            form.value.assigned_organization_id
        )
        formData.append('priority', form.value.priority)

        for (const file of selectedImages.value) {
            formData.append('image', file)
        }

        await $fetch('/api/concerns', {
            method: 'POST',
            body: formData
        })

        await loadConcerns()

        showModal.value = false
        resetOriginalImages()

        form.value = {
            title: '',
            description: '',
            concern_type_id: '',
            assigned_organization_id: '',
            priority: 'medium'
        }

        showSuccessMessage('Concern submitted successfully.')
    } catch (error) {
        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to submit concern.'
        )
    } finally {
        saving.value = false
    }
}

/*
 * ---------------------------------------------------------
 * VIEW CONCERN
 * ---------------------------------------------------------
 */

async function viewConcern(concern) {
    errorMessage.value = ''
    showViewModal.value = true
    loadingConcernDetails.value = true

    selectedConcern.value = null
    concernComments.value = []
    concernAttachments.value = []
    concernStatusHistory.value = []
    selectedStatus.value = ''
    statusRemarks.value = ''

    clearCommentImages()
    clearStatusImages()

    try {
        const response = await $fetch(
            `/api/concerns/${concern.id}`,
            {
                cache: 'no-store'
            }
        )

        selectedConcern.value = response.concern
        concernComments.value = response.comments || []
        concernAttachments.value = response.attachments || []
        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern?.status || ''
    } catch (error) {
        showViewModal.value = false

        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load concern details.'
        )
    } finally {
        loadingConcernDetails.value = false
    }
}

function closeViewModal() {
    if (savingComment.value || updatingStatus.value) {
        return
    }

    showViewModal.value = false
    selectedConcern.value = null
    concernComments.value = []
    concernAttachments.value = []
    concernStatusHistory.value = []
    selectedStatus.value = ''
    statusRemarks.value = ''

    clearCommentImages()
    clearStatusImages()
    closeImageViewer()

    errorMessage.value = ''
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
        concernComments.value = response.comments || []
        concernAttachments.value = response.attachments || []
        concernStatusHistory.value =
            response.statusHistory || []

        selectedStatus.value =
            response.concern?.status || ''
    } catch (error) {
        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to refresh concern details.'
        )
    }
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
    const files = Array.from(event.target.files || [])

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
            showErrorMessage(
                `Invalid image format: ${file.name}. Please upload JPG, PNG, GIF, or WEBP.`
            )

            event.target.value = ''
            return
        }

        if (file.size > maxSize) {
            showErrorMessage(
                `Image is too large: ${file.name}. Maximum size is 5 MB.`
            )

            event.target.value = ''
            return
        }
    }

    errorMessage.value = ''

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
    const preview = commentImagePreviews.value[index]

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
    const files = Array.from(event.target.files || [])

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
            showErrorMessage(
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`
            )

            event.target.value = ''
            return
        }

        if (file.size > maxSize) {
            showErrorMessage(
                `${file.name} exceeds the 5 MB limit.`
            )

            event.target.value = ''
            return
        }
    }

    errorMessage.value = ''

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
    const preview = statusImagePreviews.value[index]

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

async function addComment() {
    if (!selectedConcern.value?.id) {
        return
    }

    if (!newComment.value.trim()) {
        showErrorMessage('Please enter a comment.')
        return
    }

    savingComment.value = true
    errorMessage.value = ''

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

        showSuccessMessage('Comment added successfully.')
    } catch (error) {
        showErrorMessage(
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
 * ORIGINAL ATTACHMENT EDIT / DELETE
 * ---------------------------------------------------------
 */

function canEditOriginalAttachments() {
    if (!currentUser.value || !selectedConcern.value) {
        return false
    }

    if (isConcernCompleted()) {
        return false
    }

    return (
        currentUser.value.role_name === 'superadmin' ||
        Number(selectedConcern.value.created_by) ===
        Number(currentUser.value.id)
    )
}

function triggerAttachmentReplace(attachment) {
    if (!canEditOriginalAttachments()) {
        return
    }

    editingAttachmentId.value = attachment.id

    nextTick(() => {
        replacementInput.value?.click()
    })
}

function handleAdditionalAttachments(event) {
    const files = Array.from(event.target.files || [])

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
            showErrorMessage(
                `${file.name} is not a supported image type. Please use JPEG, PNG, GIF, or WEBP.`
            )

            event.target.value = ''
            return
        }

        if (file.size > maxSize) {
            showErrorMessage(
                `${file.name} exceeds the 5 MB limit.`
            )

            event.target.value = ''
            return
        }
    }

    errorMessage.value = ''

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
    const preview = additionalImagePreviews.value[index]

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

    addingAttachments.value = true
    errorMessage.value = ''

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

        showSuccessMessage(
            `${imageCount} image${imageCount === 1 ? '' : 's'} attached successfully.`
        )
    } catch (error) {
        console.error('Add attachments error:', error)

        showErrorMessage(
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

async function handleAttachmentReplacement(event) {
    const file = event.target.files?.[0]

    if (!file || !editingAttachmentId.value) {
        event.target.value = ''
        return
    }

    const validImageTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]

    if (!validImageTypes.includes(file.type)) {
        showErrorMessage(
            'Invalid image format. Please upload JPG, PNG, GIF, or WEBP.'
        )

        event.target.value = ''
        editingAttachmentId.value = null
        return
    }

    if (file.size > 5 * 1024 * 1024) {
        showErrorMessage(
            'Image is too large. Maximum size is 5 MB.'
        )

        event.target.value = ''
        editingAttachmentId.value = null
        return
    }

    replacingAttachmentId.value =
        editingAttachmentId.value

    errorMessage.value = ''

    try {
        const formData = new FormData()

        formData.append(
            'attachment_id',
            String(editingAttachmentId.value)
        )

        formData.append('image', file)

        await $fetch(
            `/api/concerns/${selectedConcern.value.id}/attachments`,
            {
                method: 'PUT',
                body: formData
            }
        )

        await refreshConcernDetails()

        showSuccessMessage(
            'Attachment replaced successfully.'
        )
    } catch (error) {
        showErrorMessage(
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

async function removeOriginalAttachment(attachment) {
    if (!canEditOriginalAttachments()) {
        return
    }

    const confirmed = window.confirm(
        `Remove "${attachment.file_name}" from this concern?`
    )

    if (!confirmed) {
        return
    }

    deletingAttachmentId.value = attachment.id
    errorMessage.value = ''

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

        showSuccessMessage(
            'Attachment removed successfully.'
        )
    } catch (error) {
        showErrorMessage(
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
    if (!currentUser.value || !selectedConcern.value) {
        return false
    }

    return (
        Number(selectedConcern.value.created_by) ===
        Number(currentUser.value.id)
    )
}

function isAssignedAdmin() {
    if (!currentUser.value || !selectedConcern.value) {
        return false
    }

    /*
     * A concern creator must not also be treated as
     * the assigned recipient/admin for the same concern.
     */
    if (isConcernCreator()) {
        return false
    }

    return (
        currentUser.value.role_name === 'admin' &&
        Number(selectedConcern.value.assigned_organization_id) ===
        Number(currentUser.value.organization_id)
    )
}

function canChangeToStatus(newStatus) {
    if (!currentUser.value || !selectedConcern.value) {
        return false
    }

    const currentStatus = selectedConcern.value.status

    if (newStatus === currentStatus) {
        return false
    }

    /*
     * Superadmin can manage any status except changing
     * an already closed concern.
     */
    if (currentUser.value.role_name === 'superadmin') {
        return currentStatus !== 'closed'
    }

    /*
     * Assigned recipient/admin:
     *
     * pending -> in_progress
     * in_progress -> resolved
     */
    if (isAssignedAdmin()) {
        return (
            (currentStatus === 'pending' &&
                newStatus === 'in_progress') ||
            (currentStatus === 'in_progress' &&
                newStatus === 'resolved')
        )
    }

    /*
     * Concern creator:
     *
     * resolved -> closed
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
    if (!currentUser.value || !selectedConcern.value) {
        return false
    }

    /*
     * Superadmin can manage the status.
     */
    if (currentUser.value.role_name === 'superadmin') {
        return selectedConcern.value.status !== 'closed'
    }

    /*
     * Assigned recipient/admin can acknowledge and resolve.
     */
    if (isAssignedAdmin()) {
        return (
            selectedConcern.value.status === 'pending' ||
            selectedConcern.value.status === 'in_progress'
        )
    }

    /*
     * Creator does not use the general Update Status section.
     */
    return false
}

const availableStatusOptions = computed(() => {
    if (!currentUser.value || !selectedConcern.value) {
        return []
    }

    const currentStatus = selectedConcern.value.status

    /*
     * Superadmin can manage all statuses except the
     * current status.
     */
    if (currentUser.value.role_name === 'superadmin') {
        return [
            {
                value: 'pending',
                label: 'Pending'
            },
            {
                value: 'in_progress',
                label: 'In Progress'
            },
            {
                value: 'on_hold',
                label: 'On Hold'
            },
            {
                value: 'resolved',
                label: 'Resolved'
            },
            {
                value: 'closed',
                label: 'Closed'
            },
            {
                value: 'cancelled',
                label: 'Cancelled'
            }
        ].filter(option => option.value !== currentStatus)
    }

    /*
     * Assigned recipient/admin.
     */
    if (isAssignedAdmin()) {
        if (currentStatus === 'pending') {
            return [
                {
                    value: 'in_progress',
                    label: 'In Progress'
                }
            ]
        }

        if (currentStatus === 'in_progress') {
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

    if (!canChangeToStatus(targetStatus)) {
        showErrorMessage(
            'You do not have permission to make this status change.'
        )
        return
    }

    /*
     * Closing is only allowed by the creator.
     */
    if (
        targetStatus === 'closed' &&
        !canCloseConcern()
    ) {
        showErrorMessage(
            'Only the creator can close a resolved concern.'
        )
        return
    }

    /*
     * Determine whether the assigned recipient is
     * resolving the concern.
     */
    const resolvingConcern =
        isAssignedAdmin() &&
        selectedConcern.value.status === 'in_progress' &&
        targetStatus === 'resolved'

    /*
     * Resolving requires remarks.
     */
    if (
        resolvingConcern &&
        !statusRemarks.value.trim()
    ) {
        showErrorMessage(
            'Please enter remarks explaining what was done before marking the concern as resolved.'
        )
        return
    }

    /*
     * Resolving requires at least one evidence image.
     */
    if (
        resolvingConcern &&
        selectedStatusImages.value.length === 0
    ) {
        showErrorMessage(
            'Please attach at least one evidence image before marking the concern as resolved.'
        )
        return
    }

    updatingStatus.value = true
    errorMessage.value = ''

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

        /*
         * Attach all evidence images to the status change.
         */
        for (const file of selectedStatusImages.value) {
            formData.append('images', file)
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
        await loadConcerns()

        showSuccessMessage(
            targetStatus === 'resolved'
                ? 'Concern resolved successfully with evidence.'
                : targetStatus === 'closed'
                    ? 'Concern closed successfully.'
                    : 'Concern status updated successfully.'
        )
    } catch (error) {
        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to update concern status.'
        )
    } finally {
        updatingStatus.value = false
    }
}

function canCloseConcern() {
    return (
        currentUser.value &&
        selectedConcern.value &&
        Number(selectedConcern.value.created_by) ===
        Number(currentUser.value.id) &&
        selectedConcern.value.status === 'resolved'
    )
}

function canCancelConcern() {
    return (
        currentUser.value?.role_name === 'superadmin' &&
        selectedConcern.value &&
        selectedConcern.value.status !== 'closed' &&
        selectedConcern.value.status !== 'cancelled'
    )
}

function canComment() {
    if (!currentUser.value || !selectedConcern.value) {
        return false
    }

    if (isConcernCompleted()) {
        return false
    }

    if (currentUser.value.role_name === 'superadmin') {
        return true
    }

    if (isConcernCreator()) {
        return true
    }

    return isAssignedAdmin()
}

/*
 * ---------------------------------------------------------
 * DATA
 * ---------------------------------------------------------
 */

async function loadCurrentUser() {
    const response = await $fetch('/api/auth/me', {
        cache: 'no-store'
    })

    currentUser.value = response.user
}

async function loadConcerns() {
    const response = await $fetch('/api/concerns', {
        cache: 'no-store'
    })

    concerns.value = response.concerns || []
}

async function loadConcernTypes() {
    const response = await $fetch('/api/concern-types', {
        cache: 'no-store'
    })

    concernTypes.value = response.concernTypes || []
}

async function loadOrganizations() {
    const response = await $fetch('/api/organizations', {
        cache: 'no-store'
    })

    organizations.value = response.organizations || []
}

async function loadData() {
    loading.value = true
    errorMessage.value = ''

    try {
        await Promise.all([
            loadCurrentUser(),
            loadConcerns(),
            loadConcernTypes(),
            loadOrganizations()
        ])
    } catch (error) {
        showErrorMessage(
            error?.data?.statusMessage ||
            error?.statusMessage ||
            'Failed to load concern data.'
        )
    } finally {
        loading.value = false
    }
}

async function logout() {
    try {
        await $fetch('/api/auth/logout', {
            method: 'POST'
        })
    } catch (error) {
        // Continue to login even if logout request fails.
    }

    navigateTo('/login')
}

onMounted(() => {
    loadData()

    durationTimer = setInterval(() => {
        currentTime.value = new Date()
    }, 60000)
})

onUnmounted(() => {
    if (durationTimer) {
        clearInterval(durationTimer)
    }

    if (successTimeout) {
        clearTimeout(successTimeout)
    }

    if (errorTimeout) {
        clearTimeout(errorTimeout)
    }

    resetOriginalImages()
    clearCommentImages()
    clearAdditionalImages()
    clearStatusImages()
})
</script>

<template>
    <div class="min-h-screen bg-slate-100">

        <!-- Success Toast -->
        <Transition enter-active-class="transition duration-200 ease-out" enter-from-class="translate-y-2 opacity-0"
            enter-to-class="translate-y-0 opacity-100" leave-active-class="transition duration-150 ease-in"
            leave-from-class="opacity-100" leave-to-class="opacity-0">
            <div v-if="errorMessage"
                class="fixed right-5 top-5 z-[100] flex max-w-lg items-start gap-3 rounded-xl border border-red-200 bg-white px-5 py-4 text-sm font-medium text-red-700 shadow-lg">
                <span
                    class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-red-100 font-bold text-red-700">
                    !
                </span>

                <span class="flex-1 leading-5">
                    {{ errorMessage }}
                </span>

                <button type="button" @click="errorMessage = ''"
                    class="cursor-pointer text-xl leading-none text-red-400 transition hover:text-red-700">
                    ×
                </button>
            </div>
        </Transition>

        <!-- Sidebar -->
        <aside class="fixed inset-y-0 left-0 z-40 flex w-64 flex-col bg-slate-900 text-white">
            <div class="border-b border-slate-800 px-6 py-5">
                <h1 class="text-lg font-bold">
                    ICT Felcris Centrale
                </h1>

                <p class="mt-1 text-xs text-slate-400">
                    Concern Management System
                </p>
            </div>

            <nav class="flex-1 space-y-1 px-3 py-4">

                <NuxtLink to="/dashboard"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white">
                    <span>▦</span>
                    <span>Dashboard</span>
                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/organizations"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white">
                    <span>▣</span>
                    <span>Manage Organizations</span>
                </NuxtLink>

                <NuxtLink v-if="currentUser?.role_name === 'superadmin'" to="/users"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white">
                    <span>♙</span>
                    <span>Manage Users</span>
                </NuxtLink>

                <NuxtLink to="/concerns"
                    class="flex items-center gap-3 rounded-lg bg-slate-800 px-4 py-3 text-sm font-medium text-white">
                    <span>⚠</span>
                    <span>Manage Concerns</span>
                </NuxtLink>

                <NuxtLink v-if="
                    currentUser?.role_name === 'superadmin' ||
                    currentUser?.role_name === 'admin'
                " to="/reports"
                    class="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white">
                    <span>▤</span>
                    <span>Manage Reports</span>
                </NuxtLink>
            </nav>

            <div class="border-t border-slate-800 p-4">
                <div class="mb-3 rounded-lg bg-slate-800 p-3">
                    <p class="truncate text-sm font-semibold text-white">
                        {{
                            currentUser
                                ? `${currentUser.first_name || ''} ${currentUser.last_name || ''}`.trim()
                                : '-'
                        }}
                    </p>

                    <p class="mt-1 text-xs text-slate-400">
                        {{ currentUser?.role_name || '-' }}
                    </p>

                    <p v-if="currentUser?.organization_name" class="mt-1 truncate text-xs text-slate-500"
                        :title="currentUser.organization_name">
                        {{ currentUser.organization_name }}
                    </p>
                </div>

                <button type="button" @click="logout"
                    class="flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg border border-slate-700 px-4 py-2.5 text-sm font-medium text-slate-300 transition hover:border-red-400 hover:bg-red-500/10 hover:text-red-300">
                    Logout
                </button>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="ml-64 min-h-screen">
            <div class="mx-auto w-full max-w-[1600px] px-6 py-8">

                <!-- Header -->
                <div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                        <h2 class="text-2xl font-bold text-slate-800">
                            Concerns
                        </h2>

                        <p class="mt-1 text-sm text-slate-500">
                            View and manage concerns.
                        </p>
                    </div>

                    <button v-if="
                        currentUser?.role_name === 'admin' ||
                        currentUser?.role_name === 'user'
                    " type="button" @click="openCreateModal"
                        class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-slate-800 hover:shadow-md active:scale-[0.99]">
                        <span class="text-lg leading-none">+</span>
                        Create Concern
                    </button>
                </div>

                <!-- Error -->
                <div v-if="errorMessage"
                    class="mb-5 flex items-start justify-between gap-4 rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700">
                    <p>
                        {{ errorMessage }}
                    </p>

                    <button type="button" @click="errorMessage = ''"
                        class="cursor-pointer text-xl leading-none text-red-400 transition hover:text-red-700">
                        ×
                    </button>
                </div>

                <!-- Filters -->
                <div class="mb-6 rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                    <div class="grid gap-4 md:grid-cols-3">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Search
                            </label>

                            <input v-model="search" type="text"
                                placeholder="Search concern number, title, or description..."
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Status
                            </label>

                            <select v-model="statusFilter"
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">
                                <option value="">
                                    All Statuses
                                </option>

                                <option value="pending">
                                    Pending
                                </option>

                                <option value="in_progress">
                                    In Progress
                                </option>

                                <option value="on_hold">
                                    On Hold
                                </option>

                                <option value="resolved">
                                    Resolved
                                </option>

                                <option value="closed">
                                    Closed
                                </option>

                                <option value="cancelled">
                                    Cancelled
                                </option>
                            </select>
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Priority
                            </label>

                            <select v-model="priorityFilter"
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">
                                <option value="">
                                    All Priorities
                                </option>

                                <option value="low">
                                    Low
                                </option>

                                <option value="medium">
                                    Medium
                                </option>

                                <option value="high">
                                    High
                                </option>

                                <option value="urgent">
                                    Urgent
                                </option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- Concerns Table -->
                <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">

                    <div class="border-b border-slate-200 px-5 py-4">
                        <h3 class="text-base font-semibold text-slate-800">
                            Recent Concerns
                        </h3>

                        <p class="mt-1 text-xs text-slate-500">
                            {{ filteredConcerns.length }} concern{{
                                filteredConcerns.length === 1 ? '' : 's'
                            }}
                        </p>
                    </div>

                    <div v-if="loading" class="p-10 text-center text-sm text-slate-500">
                        Loading concerns...
                    </div>

                    <div v-else-if="filteredConcerns.length === 0" class="p-10 text-center">
                        <p class="text-sm font-medium text-slate-600">
                            No concerns found.
                        </p>

                        <p class="mt-1 text-xs text-slate-400">
                            Try changing your search or filters.
                        </p>
                    </div>

                    <div v-else class="overflow-x-auto">
                        <table class="min-w-[1250px] w-full text-left">
                            <thead class="bg-slate-50">
                                <tr class="border-b border-slate-200">
                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Concern No.
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Title
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Type
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Assigned To
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Priority
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Status
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Created By
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Date
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Duration
                                    </th>

                                    <th
                                        class="whitespace-nowrap px-5 py-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Action
                                    </th>
                                </tr>
                            </thead>

                            <tbody class="divide-y divide-slate-100">
                                <tr v-for="concern in filteredConcerns" :key="concern.id"
                                    class="transition hover:bg-slate-50" :class="concern.status === 'resolved' ||
                                        concern.status === 'closed'
                                        ? 'bg-green-50/40'
                                        : ''
                                        ">
                                    <td class="whitespace-nowrap px-5 py-4 text-sm font-semibold text-slate-700">
                                        {{ concern.concern_number }}
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <div class="block max-w-[260px] truncate text-sm font-semibold text-slate-800"
                                            :title="concern.title">
                                            {{ concern.title }}
                                        </div>

                                        <div class="mt-1 block max-w-[250px] truncate text-xs text-slate-500"
                                            :title="concern.description">
                                            {{ concern.description || '-' }}
                                        </div>
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <div class="block max-w-[180px] truncate text-sm text-slate-600"
                                            :title="concern.concern_type_name || '-'">
                                            {{ concern.concern_type_name || '-' }}
                                        </div>
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <div class="block max-w-[200px] truncate text-sm font-medium text-slate-700"
                                            :title="concern.organization_name || '-'">
                                            {{ concern.organization_name || '-' }}
                                        </div>
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="priorityClass(concern.priority)">
                                            {{ formatPriority(concern.priority) }}
                                        </span>
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <div class="flex items-center gap-2">
                                            <span class="rounded-full px-3 py-1 text-xs font-medium"
                                                :class="statusClass(concern.status)">
                                                {{ formatStatus(concern.status) }}
                                            </span>

                                            <span v-if="concern.status === 'resolved'"
                                                class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-[10px] font-semibold text-green-700">
                                                ✓
                                                Completed
                                            </span>
                                        </div>
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <div class="block max-w-[180px] truncate text-sm text-slate-600"
                                            :title="concern.created_by_name || '-'">
                                            {{ concern.created_by_name || '-' }}
                                        </div>

                                        <div v-if="concern.creator_organization_name"
                                            class="mt-1 block max-w-[180px] truncate text-xs text-slate-400"
                                            :title="concern.creator_organization_name">
                                            {{ concern.creator_organization_name }}
                                        </div>
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4 text-sm text-slate-500">
                                        {{ formatDate(concern.created_at) }}
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4 text-sm font-medium text-slate-700">
                                        {{ getConcernDuration(concern) }}
                                    </td>

                                    <td class="whitespace-nowrap px-5 py-4">
                                        <button type="button" @click="viewConcern(concern)"
                                            class="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:border-slate-400 hover:bg-slate-100 hover:text-slate-900 hover:shadow">
                                            <span>View</span>
                                            <span class="text-xs">→</span>
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="border-t border-slate-200 px-5 py-3">
                        <div class="flex items-center gap-2 text-xs text-slate-500">
                            <span class="h-2.5 w-2.5 rounded-full bg-green-400"></span>
                            Resolved or closed concerns are highlighted.
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- Create Concern Modal -->
        <div v-if="showModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 px-4 py-6 backdrop-blur-[2px]">
            <div class="flex max-h-[92vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl">
                <!-- Header -->
                <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5">
                    <div>
                        <h3 class="text-lg font-bold text-slate-800">
                            Create Concern
                        </h3>

                        <p class="mt-1 text-sm text-slate-500">
                            Submit a new concern for the assigned organization.
                        </p>
                    </div>

                    <button type="button" @click="closeModal" :disabled="saving"
                        class="cursor-pointer rounded-lg p-2 text-2xl leading-none text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-50">
                        ×
                    </button>
                </div>

                <form @submit.prevent="createConcern" class="flex-1 overflow-y-auto">
                    <div class="space-y-5 p-6">

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Concern Title
                            </label>

                            <input v-model="form.title" type="text" required placeholder="Enter concern title"
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100" />
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Description
                            </label>

                            <textarea v-model="form.description" required rows="6" placeholder="Describe the concern..."
                                class="w-full resize-y rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm leading-6 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100"></textarea>
                        </div>

                        <!-- Multiple Original Images -->
                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Attach Images
                                <span class="font-normal text-slate-400">
                                    (Optional)
                                </span>
                            </label>

                            <input id="concern-image" type="file" multiple
                                accept="image/jpeg,image/png,image/gif,image/webp" @change="handleImageChange"
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition file:mr-4 file:cursor-pointer file:rounded-md file:border-0 file:bg-slate-100 file:px-4 file:py-2 file:text-sm file:font-medium file:text-slate-700 hover:border-slate-400 hover:file:bg-slate-200" />

                            <p class="mt-1 text-xs text-slate-500">
                                You can select multiple images. Maximum size: 5 MB per image.
                            </p>

                            <div v-if="imagePreviews.length > 0" class="mt-4">
                                <div class="mb-2 flex items-center justify-between">
                                    <p class="text-sm font-medium text-slate-700">
                                        Selected Images
                                    </p>

                                    <button type="button" @click="resetOriginalImages" :disabled="saving"
                                        class="cursor-pointer text-xs font-medium text-red-600 transition hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50">
                                        Remove All
                                    </button>
                                </div>

                                <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
                                    <div v-for="(preview, index) in imagePreviews" :key="preview.url"
                                        class="group relative overflow-hidden rounded-lg border border-slate-200 bg-slate-50">
                                        <img :src="preview.url" :alt="preview.file.name"
                                            class="h-28 w-full bg-white object-cover transition duration-200 group-hover:scale-105" />

                                        <button type="button" @click="removeImage(index)" :disabled="saving"
                                            class="absolute right-2 top-2 cursor-pointer rounded-md bg-black/70 px-2 py-1 text-xs font-medium text-white opacity-90 transition hover:bg-red-600 hover:opacity-100 disabled:cursor-not-allowed disabled:opacity-50">
                                            Remove
                                        </button>

                                        <div class="border-t border-slate-200 bg-white px-2 py-2">
                                            <p class="truncate text-xs text-slate-500" :title="preview.file.name">
                                                {{ preview.file.name }}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="grid gap-5 sm:grid-cols-2">

                            <div>
                                <label class="mb-2 block text-sm font-medium text-slate-700">
                                    Concern Type
                                </label>

                                <select v-model="form.concern_type_id" required
                                    class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">
                                    <option value="" disabled>
                                        Select concern type
                                    </option>

                                    <option v-for="type in concernTypes" :key="type.id" :value="type.id">
                                        {{ type.name }}
                                    </option>
                                </select>
                            </div>

                            <div>
                                <label class="mb-2 block text-sm font-medium text-slate-700">
                                    Assigned To
                                </label>

                                <select v-model="form.assigned_organization_id" required
                                    class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">
                                    <option value="" disabled>
                                        Select organization
                                    </option>

                                    <option v-for="organization in availableOrganizations" :key="organization.id"
                                        :value="organization.id">
                                        {{ organization.name }}
                                    </option>
                                </select>

                                <p v-if="currentUser?.role_name === 'admin'" class="mt-1 text-xs text-slate-500">
                                    Your own organization is not available for assignment.
                                </p>
                            </div>
                        </div>

                        <div>
                            <label class="mb-2 block text-sm font-medium text-slate-700">
                                Priority
                            </label>

                            <select v-model="form.priority" required
                                class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100">
                                <option value="low">
                                    Low
                                </option>

                                <option value="medium">
                                    Medium
                                </option>

                                <option value="high">
                                    High
                                </option>

                                <option value="urgent">
                                    Urgent
                                </option>
                            </select>
                        </div>

                        <!-- Buttons -->
                        <div class="flex justify-end gap-3 border-t border-slate-200 pt-5">
                            <button type="button" @click="closeModal"
                                class="cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-900">
                                Cancel
                            </button>

                            <button type="submit" :disabled="saving"
                                class="cursor-pointer rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50">
                                {{
                                    saving
                                        ? 'Submitting...'
                                        : 'Submit Concern'
                                }}
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <!-- View Concern Modal -->
        <div v-if="showViewModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 px-4 py-6 backdrop-blur-[2px]">
            <div class="flex max-h-[92vh] w-full max-w-5xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl">
                <!-- Header -->
                <div class="flex shrink-0 items-center justify-between border-b border-slate-200 bg-white px-6 py-5">
                    <div class="min-w-0">
                        <h3 class="text-lg font-bold text-slate-800">
                            View Concern
                        </h3>

                        <p v-if="selectedConcern" class="mt-1 text-sm font-medium text-slate-500">
                            {{ selectedConcern.concern_number }}
                        </p>
                    </div>

                    <button type="button" @click="closeViewModal" :disabled="savingComment || updatingStatus"
                        class="cursor-pointer rounded-lg p-2 text-2xl leading-none text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-50">
                        ×
                    </button>
                </div>

                <!-- Loading -->
                <div v-if="loadingConcernDetails" class="flex flex-1 items-center justify-center p-12">
                    <div class="text-center">
                        <div
                            class="mx-auto mb-4 h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-slate-700">
                        </div>

                        <p class="text-sm text-slate-500">
                            Loading concern details...
                        </p>
                    </div>
                </div>

                <!-- Details -->
                <div v-else-if="selectedConcern" class="min-h-0 flex-1 overflow-y-auto">
                    <div class="mx-auto w-full max-w-4xl space-y-6 p-6 sm:p-7">

                        <!-- Pending Recipient Notice -->
                        <div v-if="
                            selectedConcern.status === 'pending' &&
                            isAssignedAdmin()
                        " class="rounded-xl border border-blue-200 bg-blue-50 p-5">
                            <div class="flex items-start gap-3">
                                <div
                                    class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-100 font-bold text-blue-700">
                                    !
                                </div>

                                <div>
                                    <p class="font-semibold text-blue-800">
                                        This concern is waiting for your acknowledgement.
                                    </p>

                                    <p class="mt-1 text-sm leading-6 text-blue-700">
                                        You are assigned to this concern.
                                        Select
                                        <span class="font-semibold">
                                            In Progress
                                        </span>
                                        below when you start handling it.
                                    </p>

                                    <p class="mt-2 text-xs font-medium text-blue-600">
                                        Acknowledging the concern starts the recipient handling time.
                                    </p>
                                </div>
                            </div>
                        </div>
                        <!-- Creator Close Section -->
                        <div v-if="
                            selectedConcern.status === 'resolved' &&
                            canCloseConcern()
                        " class="rounded-xl border border-green-200 bg-green-50 p-5">
                            <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">

                                <div>
                                    <p class="text-sm font-semibold text-green-800">
                                        Concern resolved
                                    </p>

                                    <p class="mt-1 text-sm leading-6 text-green-700">
                                        The assigned organization has marked this concern as resolved.
                                        Review the remarks and evidence before closing the concern.
                                    </p>
                                </div>

                                <button type="button" @click="
                                    selectedStatus = 'closed';
                                statusRemarks = '';
                                clearStatusImages();
                                updateConcernStatus()
                                    " :disabled="updatingStatus"
                                    class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg bg-green-600 px-5 py-3 text-sm font-semibold text-white transition hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-50">
                                    <span aria-hidden="true">✓</span>

                                    {{
                                        updatingStatus
                                            ? 'Closing...'
                                            : 'Close Concern'
                                    }}
                                </button>

                            </div>
                        </div>

                        <!-- In Progress Recipient Notice -->
                        <div v-if="
                            selectedConcern.status === 'in_progress' &&
                            isAssignedAdmin()
                        " class="rounded-xl border border-blue-200 bg-blue-50 p-5">
                            <div class="flex items-start gap-3">
                                <div
                                    class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-100 font-bold text-blue-700">
                                    •
                                </div>

                                <div>
                                    <p class="font-semibold text-blue-800">
                                        You are currently handling this concern.
                                    </p>

                                    <p class="mt-1 text-sm leading-6 text-blue-700">
                                        When the issue has been addressed,
                                        change the status to
                                        <span class="font-semibold">
                                            Resolved
                                        </span>.
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Resolved Notice -->
                        <div v-if="selectedConcern.status === 'resolved'"
                            class="flex items-start gap-3 rounded-xl border border-green-200 bg-green-50 p-5">
                            <div
                                class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-green-100 text-lg font-bold text-green-700">
                                ✓
                            </div>

                            <div>
                                <p class="font-semibold text-green-800">
                                    Concern Completed
                                </p>

                                <p class="mt-1 text-sm leading-6 text-green-700">
                                    The assigned organization has marked this concern as resolved.
                                    Review the result and close the concern if it is finished.
                                </p>

                                <p v-if="canCloseConcern()" class="mt-2 text-sm font-semibold text-green-700">
                                    You created this concern and can now close it.
                                </p>

                                <p v-else class="mt-2 text-sm font-medium text-green-700">
                                    Only the creator of this concern can close it.
                                </p>
                            </div>
                        </div>

                        <!-- Main Information -->
                        <div class="overflow-hidden rounded-xl border border-slate-200 bg-slate-50">

                            <div class="border-b border-slate-200 bg-white p-5">
                                <div class="flex flex-wrap items-start justify-between gap-4">

                                    <div class="min-w-0 flex-1">
                                        <p class="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Concern Title
                                        </p>

                                        <h4 class="break-words text-xl font-bold text-slate-800">
                                            {{ selectedConcern.title }}
                                        </h4>
                                    </div>

                                    <div class="flex flex-wrap gap-2">
                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="priorityClass(selectedConcern.priority)">
                                            {{ formatPriority(selectedConcern.priority) }}
                                        </span>

                                        <span class="rounded-full px-3 py-1 text-xs font-medium"
                                            :class="statusClass(selectedConcern.status)">
                                            {{ formatStatus(selectedConcern.status) }}
                                        </span>

                                        <span v-if="
                                            selectedConcern.status === 'resolved' ||
                                            selectedConcern.status === 'closed'
                                        "
                                            class="inline-flex items-center gap-1 rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700">
                                            ✓
                                            Completed
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div class="p-5">

                                <!-- Description -->
                                <div class="mb-6">
                                    <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
                                        Description
                                    </p>

                                    <div
                                        class="whitespace-pre-wrap break-words rounded-lg border border-slate-200 bg-white p-4 text-sm leading-6 text-slate-700">
                                        {{ selectedConcern.description }}
                                    </div>
                                </div>

                                <!-- Information -->
                                <div class="grid gap-x-6 gap-y-5 sm:grid-cols-2 lg:grid-cols-3">

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Concern Number
                                        </p>

                                        <p class="mt-1 text-sm font-medium text-slate-800">
                                            {{ selectedConcern.concern_number }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Concern Type
                                        </p>

                                        <p class="mt-1 text-sm text-slate-700">
                                            {{ selectedConcern.concern_type_name || '-' }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Assigned To
                                        </p>

                                        <p class="mt-1 truncate text-sm font-medium text-slate-700"
                                            :title="selectedConcern.organization_name">
                                            {{ selectedConcern.organization_name || '-' }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Created By
                                        </p>

                                        <p class="mt-1 text-sm text-slate-700">
                                            {{ selectedConcern.created_by_name || '-' }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Creator Organization
                                        </p>

                                        <p class="mt-1 truncate text-sm font-medium text-slate-700"
                                            :title="selectedConcern.creator_organization_name">
                                            {{ selectedConcern.creator_organization_name || '-' }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Created At
                                        </p>

                                        <p class="mt-1 text-sm text-slate-700">
                                            {{ formatDate(selectedConcern.created_at) }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Acknowledged At
                                        </p>

                                        <p class="mt-1 text-sm text-slate-700">
                                            {{ formatDate(selectedConcern.acknowledged_at) }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Handling Duration
                                        </p>

                                        <p class="mt-1 text-sm font-semibold text-slate-800">
                                            {{ getConcernDuration(selectedConcern) }}
                                        </p>
                                    </div>

                                    <div>
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Updated At
                                        </p>

                                        <p class="mt-1 text-sm text-slate-700">
                                            {{ formatDate(selectedConcern.updated_at) }}
                                        </p>
                                    </div>

                                    <div v-if="selectedConcern.resolved_at">
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Resolved At
                                        </p>

                                        <p class="mt-1 text-sm text-slate-700">
                                            {{ formatDate(selectedConcern.resolved_at) }}
                                        </p>
                                    </div>

                                    <div v-if="selectedConcern.closed_at">
                                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                                            Closed At
                                        </p>

                                        <p class="mt-1 text-sm text-slate-700">
                                            {{ formatDate(selectedConcern.closed_at) }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Status Update -->
                        <div v-if="canUpdateStatus()" class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">

                            <div class="mb-4">
                                <h4 class="text-base font-semibold text-slate-800">
                                    Update Status
                                </h4>

                                <p class="mt-1 text-sm text-slate-500">

                                    <span v-if="isAssignedAdmin()">

                                        <span v-if="selectedConcern.status === 'pending'">
                                            Acknowledge the concern by changing it to
                                            <span class="font-medium text-slate-700">
                                                In Progress
                                            </span>
                                            when you start handling it.
                                        </span>

                                        <span v-else-if="selectedConcern.status === 'in_progress'">
                                            Mark the concern as
                                            <span class="font-medium text-slate-700">
                                                Resolved
                                            </span>
                                            when the issue has been addressed.
                                            You must provide remarks and evidence images.
                                        </span>

                                    </span>

                                    <span v-else-if="
                                        currentUser?.role_name === 'superadmin'
                                    ">
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

                                    <select v-model="selectedStatus" :disabled="updatingStatus ||
                                        availableStatusOptions.length === 0
                                        "
                                        class="w-full cursor-pointer rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100 disabled:cursor-not-allowed disabled:bg-slate-100">

                                        <option :value="selectedConcern.status">
                                            {{ formatStatus(selectedConcern.status) }}
                                        </option>

                                        <option v-for="option in availableStatusOptions" :key="option.value"
                                            :value="option.value">

                                            {{ option.label }}

                                        </option>
                                    </select>
                                </div>

                                <!-- Remarks -->
                                <div>
                                    <label class="mb-2 block text-sm font-medium text-slate-700">
                                        Remarks

                                        <span v-if="
                                            isAssignedAdmin() &&
                                            selectedConcern.status === 'in_progress' &&
                                            selectedStatus === 'resolved'
                                        " class="font-medium text-red-500">
                                            *
                                        </span>

                                        <span v-else class="font-normal text-slate-400">
                                            (Optional)
                                        </span>
                                    </label>

                                    <textarea v-model="statusRemarks" :disabled="updatingStatus" rows="3" :placeholder="isAssignedAdmin() &&
                                        selectedConcern.status === 'in_progress' &&
                                        selectedStatus === 'resolved'
                                        ? 'Explain what was done to resolve the concern...'
                                        : 'Add remarks about this status change...'
                                        "
                                        class="w-full resize-none rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-100 disabled:cursor-not-allowed disabled:bg-slate-100">
            </textarea>
                                </div>
                            </div>

                            <!-- Recipient Resolution Evidence -->
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

                            <!-- Recipient Acknowledgement -->
                            <div v-if="
                                isAssignedAdmin() &&
                                selectedConcern.status === 'pending'
                            " class="mt-5 rounded-lg border border-blue-200 bg-blue-50 p-4">

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

                                <button type="button" @click="updateConcernStatus" :disabled="updatingStatus ||
                                    selectedStatus === selectedConcern.status
                                    "
                                    class="cursor-pointer rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50">

                                    {{
                                        updatingStatus
                                            ? 'Updating...'
                                            : 'Update Status'
                                    }}

                                </button>

                            </div>
                        </div>

                        <!-- Attachments -->
                        <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
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
                                            concernAttachments.length === 1 ? '' : 's'
                                        }}
                                    </span>

                                    <button v-if="canEditOriginalAttachments()" type="button"
                                        @click="additionalAttachmentInput?.click()" :disabled="addingAttachments"
                                        class="inline-flex cursor-pointer items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-400 hover:bg-slate-50 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">
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

                            <div v-if="concernAttachments.length === 0"
                                class="rounded-lg bg-slate-50 p-5 text-center text-sm text-slate-500">
                                No attachments.
                            </div>

                            <div v-else class="max-h-[520px] overflow-y-auto pr-1">
                                <div v-for="attachment in concernAttachments" :key="attachment.id"
                                    class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
                                    <button type="button" @click="openImageViewer(attachment)"
                                        class="block w-full cursor-pointer text-left"
                                        :title="`View ${attachment.file_name}`">
                                        <div class="relative overflow-hidden bg-white">
                                            <img v-if="
                                                attachment.file_type?.startsWith('image/')
                                            " :src="attachmentUrl(attachment.file_path)" :alt="attachment.file_name"
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
                                            {{ attachment.uploaded_by_name || '-' }}
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
                                                :disabled="replacingAttachmentId === attachment.id ||
                                                    deletingAttachmentId === attachment.id
                                                    "
                                                class="flex-1 cursor-pointer rounded-md border border-slate-300 px-2 py-1.5 text-[11px] font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">
                                                {{
                                                    replacingAttachmentId === attachment.id
                                                        ? 'Replacing...'
                                                        : 'Replace'
                                                }}
                                            </button>

                                            <button type="button" @click="removeOriginalAttachment(attachment)"
                                                :disabled="replacingAttachmentId === attachment.id ||
                                                    deletingAttachmentId === attachment.id
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

                            <input ref="replacementInput" type="file" accept="image/jpeg,image/png,image/gif,image/webp"
                                class="hidden" @change="handleAttachmentReplacement" />
                            <input ref="additionalAttachmentInput" type="file" multiple
                                accept="image/jpeg,image/png,image/gif,image/webp" class="hidden"
                                @change="handleAdditionalAttachments" />
                        </div>

                        <!-- Status History -->
                        <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
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
                                                {{ formatStatus(history.old_status) }}
                                            </span>

                                            <span v-if="history.old_status" class="text-slate-400">
                                                →
                                            </span>

                                            <span class="rounded-full px-3 py-1 text-xs font-medium"
                                                :class="statusClass(history.new_status)">
                                                {{ formatStatus(history.new_status) }}
                                            </span>

                                            <span v-if="
                                                history.new_status === 'resolved' ||
                                                history.new_status === 'closed'
                                            "
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
                                            {{ history.changed_by_name || '-' }}
                                        </span>
                                    </p>

                                    <p v-if="history.remarks"
                                        class="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700">
                                        {{ history.remarks }}
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
                                                {{ history.attachments.length }}
                                                image{{ history.attachments.length === 1 ? '' : 's' }}
                                            </span>
                                        </div>

                                        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
                                            <button v-for="attachment in history.attachments" :key="attachment.id"
                                                type="button" @click="openImageViewer(attachment)"
                                                class="group relative block w-full cursor-pointer overflow-hidden rounded-lg border border-green-200 bg-white text-left transition hover:border-green-400 hover:shadow-md"
                                                :title="`View ${attachment.file_name}`">
                                                <img v-if="attachment.file_type?.startsWith('image/')"
                                                    :src="attachmentUrl(attachment.file_path)"
                                                    :alt="attachment.file_name"
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
                        <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                            <div class="mb-5">
                                <h4 class="text-base font-semibold text-slate-800">
                                    Conversation
                                </h4>

                                <p class="mt-1 text-sm text-slate-500">
                                    Communication between the concern creator and the assigned organization.
                                </p>
                            </div>

                            <!-- No Comments -->
                            <div v-if="concernComments.length === 0" class="rounded-lg bg-slate-50 p-6 text-center">
                                <p class="text-sm text-slate-500">
                                    No conversation yet.
                                </p>

                                <p class="mt-1 text-xs text-slate-400">
                                    Start the conversation by adding a comment below.
                                </p>
                            </div>

                            <!-- Conversation -->
                            <div v-else class="space-y-5">
                                <div v-for="comment in concernComments" :key="comment.id" class="flex" :class="Number(comment.user_id) ===
                                    Number(currentUser?.id)
                                    ? 'justify-end'
                                    : 'justify-start'
                                    ">
                                    <div class="max-w-[90%] sm:max-w-[78%]">

                                        <!-- Sender -->
                                        <div class="mb-1 flex flex-wrap items-center gap-2" :class="Number(comment.user_id) ===
                                            Number(currentUser?.id)
                                            ? 'justify-end'
                                            : 'justify-start'
                                            ">
                                            <p class="text-xs font-semibold text-slate-700">
                                                {{ comment.user_name || '-' }}
                                            </p>

                                            <span
                                                class="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                                                {{ comment.role_name || '-' }}
                                            </span>

                                            <span
                                                class="max-w-[180px] truncate rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                                                {{ comment.organization_name || '-' }}
                                            </span>
                                        </div>

                                        <!-- Message Bubble -->
                                        <div class="rounded-2xl px-4 py-3" :class="Number(comment.user_id) ===
                                            Number(currentUser?.id)
                                            ? 'rounded-br-md bg-slate-900 text-white'
                                            : 'rounded-bl-md bg-slate-100 text-slate-800'
                                            ">
                                            <!-- Comment Text -->
                                            <p v-if="comment.comment"
                                                class="whitespace-pre-wrap break-words text-sm leading-6">
                                                {{ comment.comment }}
                                            </p>

                                            <!-- Comment Attachments -->
                                            <div v-if="
                                                comment.attachments &&
                                                comment.attachments.length > 0
                                            " :class="comment.comment ? 'mt-3' : ''" class="flex flex-wrap gap-2">
                                                <button v-for="attachment in comment.attachments" :key="attachment.id"
                                                    type="button" @click="openImageViewer(attachment)"
                                                    class="group relative block h-20 w-20 cursor-pointer overflow-hidden rounded-lg border border-slate-300 bg-white transition hover:border-slate-500 hover:shadow-md sm:h-24 sm:w-24"
                                                    :title="`View ${attachment.file_name}`">
                                                    <img v-if="
                                                        attachment.file_type?.startsWith('image/')
                                                    " :src="attachmentUrl(attachment.file_path)"
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
                                        <p class="mt-1 text-[11px] text-slate-400" :class="Number(comment.user_id) ===
                                            Number(currentUser?.id)
                                            ? 'text-right'
                                            : 'text-left'
                                            ">
                                            {{ formatDate(comment.created_at) }}
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
                                        {{ currentUser?.role_name || '' }}
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
                                                    {{ preview.file.name }}
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
                                        !newComment.trim()
                                        "
                                        class="cursor-pointer rounded-lg bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-50">
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
                                <p class="text-sm text-slate-400">
                                    You do not have permission to participate in this conversation.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Footer -->
                <div class="flex shrink-0 justify-end border-t border-slate-200 bg-white px-6 py-4">
                    <button type="button" @click="closeViewModal" :disabled="savingComment || updatingStatus"
                        class="cursor-pointer rounded-lg border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50">
                        Close
                    </button>
                </div>
            </div>
        </div>

        <!-- Full Image Viewer -->
        <div v-if="showImageViewer && selectedViewerImage"
            class="fixed inset-0 z-[100] flex items-center justify-center bg-black/85 p-4"
            @click.self="closeImageViewer">
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
    </div>
</template>