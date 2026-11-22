<script setup>
import { computed, ref, watch } from 'vue'
import { roleDisplayName } from '~/composables/useRoleLabel'
import { useBodyScrollLock } from '~/composables/useBodyScrollLock'

const props = defineProps({
    currentUser: {
        type: Object,
        default: null
    }
})

const isOpen = ref(false)
const activeStep = ref(0)
const isInteractiveTourActive = ref(false)
const route = useRoute()
useBodyScrollLock(() => isOpen.value)

const isHelpAvailable = computed(() =>
    Boolean(props.currentUser) && !['/login', '/account-deactivated', '/ict-team'].includes(route.path)
)

const roleName = computed(() => props.currentUser?.role_name || 'requestor')
const roleLabel = computed(() => roleDisplayName(roleName.value))

const guideSteps = computed(() => {
    const canCreateConcerns = ['concern_handler', 'requestor'].includes(roleName.value)
    const isPrivilegedViewer = ['superadmin', 'system_admin', 'system_monitor'].includes(roleName.value)
    const steps = [
        {
            title: 'Your workspace at a glance',
            descriptionStart: 'Start on the ',
            emphasis: 'Dashboard',
            descriptionEnd: ' for a quick overview of concern activity. Use the date-range selector and, when available to your role, the organization dropdown to filter the charts and totals.',
            art: 'dashboard',
            tip: roleName.value === 'system_monitor'
                ? 'System Monitors can view dashboard data, change the date range, and select organizations.'
                : 'Dashboard data and available filters follow your account permissions.',
            to: '/dashboard',
            actionLabel: 'Go to Dashboard'
        },
        {
            title: 'Find and follow concerns',
            descriptionStart: 'Open ',
            emphasis: 'Manage Concerns',
            descriptionEnd: ' to search, filter, and sort the concern list. Select a concern to inspect its details and history; System Monitors can view and comment but cannot create tickets or change status.',
            art: 'concerns',
            tip: 'Export to Excel is available to all roles. Exports include matching concerns your role is allowed to see, not just the visible page.',
            to: '/concerns',
            actionLabel: 'Go to Manage Concerns'
        },
        {
            title: canCreateConcerns ? 'Create and route a concern' : 'Concern request access',
            descriptionStart: canCreateConcerns
                ? 'Choose '
                : `As a ${roleLabel.value}, you can view and comment on concerns, but you cannot create a request. `,
            emphasis: canCreateConcerns ? 'Create Concern' : 'View and comment',
            descriptionEnd: canCreateConcerns
                ? ' and enter a clear title and description, choose a category and destination, then submit. BPO and Tenant organizations can route only to Admin Facilities; Admin Facilities can route to any other organization, not themselves.'
                : isPrivilegedViewer
                    ? ' on concerns. Concern creation is reserved for Concern Handler and Requestor accounts.'
                    : ' on concerns. Ask your Concern Handler if a request needs to be created for you.',
            art: 'create',
            tip: canCreateConcerns
                ? 'Include the location, impact, and useful supporting details. Add images in the form when they help explain the issue.'
                : 'Use the concern comments to provide context or ask for an update.',
            to: canCreateConcerns ? '/concerns?guideAction=create' : '/concerns',
            actionLabel: canCreateConcerns ? 'Go to Add Concern' : 'Go to Manage Concerns'
        },
        {
            title: 'Comments and status workflow',
            descriptionStart: roleName.value === 'concern_handler'
                ? 'The receiver-side '
                : isPrivilegedViewer
                    ? `As a ${roleLabel.value}, you can `
                    : 'As a Requestor, you can ',
            emphasis: roleName.value === 'concern_handler'
                ? 'Concern Handler'
                : isPrivilegedViewer
                    ? 'view and comment'
                    : 'view and comment',
            descriptionEnd: roleName.value === 'concern_handler'
                ? ' can move Pending to In Progress or On Hold, move On Hold back to In Progress, and mark In Progress as Resolved. The creator-side handler can return a Resolved concern to In Progress when work is incomplete, or close it.'
                : isPrivilegedViewer
                    ? ' on concerns, but cannot change concern status. Concern Handler accounts manage status according to whether their organization created or received the concern.'
                    : ' on concerns, but cannot change concern status. Concern Handlers manage the work and status from their organization side.',
            art: 'workflow',
            tip: 'Write comments that make the next action and responsible team clear. Completed or trashed concerns may have limited actions.',
            to: '/concerns',
            actionLabel: 'Go to Manage Concerns'
        }
    ]

    steps.splice(4, 0, {
        title: 'Add and manage concern images',
        descriptionStart: roleName.value === 'superadmin'
            ? 'A '
            : roleName.value === 'system_monitor'
                ? 'As a System Monitor, '
                : 'When you created a concern, ',
        emphasis: roleName.value === 'superadmin'
            ? 'Superadmin'
            : roleName.value === 'system_monitor'
                ? 'you cannot create tickets or edit original concern images'
                : 'the original creator',
        descriptionEnd: roleName.value === 'superadmin'
            ? ' can add, replace, or remove original concern images while the concern is active. Superadmins can also view and comment, but cannot change status.'
            : roleName.value === 'system_monitor'
                ? '. You can view concerns and add images to your comments, but original attachments cannot be added, replaced, or removed by you.'
                : ' can add, replace, or remove its original images until it is resolved or closed. You can also attach images to comments when permitted.',
        art: 'security',
        tip: roleName.value === 'system_monitor'
            ? 'To share an image, attach it to a comment on the concern.'
            : 'Original-image controls are unavailable on completed or trashed concerns.',
        to: '/concerns',
        actionLabel: 'Go to Manage Concerns'
    })

    if (['superadmin', 'system_admin'].includes(roleName.value)) {
        steps.splice(4, 0, {
            title: 'Manage user accounts',
            descriptionStart: 'Open ',
            emphasis: 'Manage Users',
            descriptionEnd: roleName.value === 'superadmin'
                ? ' to maintain accounts and roles. Superadmin is reserved and cannot be assigned to another account.'
                : ' to create Concern Handler and Requestor accounts. You may edit your own profile, but cannot edit other privileged accounts.',
            art: 'team',
            tip: 'Choose the least-privileged role that fits each user and keep access appropriate to their job.',
            to: '/users',
            actionLabel: 'Go to Manage Users'
        })

        steps.splice(5, 0, {
            title: 'Manage organizations',
            descriptionStart: 'Open ',
            emphasis: 'Manage Organizations',
            descriptionEnd: ' to maintain participating departments, tenants, and BPO organizations.',
            art: 'team',
            tip: 'Keep organization names and types accurate because they control concern routing and visibility.',
            to: '/organizations',
            actionLabel: 'Go to Manage Organizations'
        })
    }

    if (roleName.value === 'superadmin') {
        steps.splice(6, 0, {
            title: 'Organize concern categories',
            descriptionStart: 'Use ',
            emphasis: 'Concern Categories',
            descriptionEnd: ' to maintain the categories available when users create concern requests.',
            art: 'team',
            tip: 'Keep category names clear so users can route and report concerns consistently.',
            to: '/concern-categories',
            actionLabel: 'Go to Concern Categories'
        })
        steps.splice(7, 0, {
            title: 'Review and revoke sessions',
            descriptionStart: 'Open ',
            emphasis: 'Login History',
            descriptionEnd: ' to review active sessions. Revoke a session when necessary; only the affected user is signed out and returned to the login screen.',
            art: 'security',
            tip: 'Revocation ends only the selected session. It does not sign out the superadmin performing the action.',
            to: '/login-history',
            actionLabel: 'Go to Login History'
        })
    }

    if (roleName.value === 'system_monitor') {
        steps[0].art = 'monitor'
        steps[2] = {
            ...steps[2],
            title: 'Monitor-only concern access',
            descriptionStart: 'As a System Monitor, you can ',
            emphasis: 'view and comment',
            descriptionEnd: ' on concerns. You cannot create concern tickets, update status, or manage original concern images. Open a concern row to inspect its details and add a comment when appropriate.',
            tip: 'Use the list sorting and filters to find work. Contact a Superadmin or System Administrator if an account or data change is required.',
            to: '/concerns',
            actionLabel: 'Go to Manage Concerns'
        }
    }

    steps.push({
        title: 'Update your account and profile',
        descriptionStart: 'Open your account menu to ',
        emphasis: 'change your password or profile photo',
        descriptionEnd: '. Confirm your current password before setting a new one. You can also add, change, or remove your profile photo.',
        art: 'profile',
        tip: 'Choose a unique password and sign out when using a shared device.',
        to: '/dashboard',
        actionLabel: 'Go to Dashboard and open your account menu'
    })

    const mappedSteps = steps.map((step) => {
        const title = step.title
        let tourTarget = '[data-tour="concern-list"]'
        let fallbackTarget = ''
        let tourRoute = step.to?.split('?')[0] || '/dashboard'
        let tourAction = ''

        if (title === 'Your workspace at a glance') {
            tourTarget = '[data-tour="dashboard-range"]'
            tourRoute = '/dashboard'
            tourAction = 'ensure-dashboard-filters'
        } else if (title === 'Find and follow concerns') {
            tourTarget = '[data-tour="concern-search"]'
            tourRoute = '/concerns'
        } else if (title === 'Create and route a concern') {
            tourTarget = '[data-tour="create-concern"]'
            tourRoute = '/concerns'
        } else if (title === 'Concern request access' || title === 'Monitor-only concern access') {
            tourTarget = '[data-tour="view-comments"]'
            fallbackTarget = '[data-tour="concern-list"]'
            tourRoute = '/concerns'
            tourAction = 'open-first-concern-conversation'
        } else if (title === 'Comments and status workflow') {
            tourTarget = roleName.value === 'concern_handler'
                ? '[data-tour="view-status"], [data-tour="view-comments"]'
                : '[data-tour="view-comments"]'
            if (roleName.value === 'concern_handler') {
                fallbackTarget = '[data-tour="concern-list"]'
            } else {
                tourAction = 'open-first-concern-conversation'
            }
            tourRoute = '/concerns'
        } else if (title === 'Add and manage concern images') {
            tourTarget = '[data-tour="view-attachments"]'
            fallbackTarget = '[data-tour="concern-list"]'
            tourRoute = '/concerns'
            tourAction = 'open-first-concern'
        } else if (title === 'Manage user accounts') {
            tourTarget = '[data-tour="users-list"]'
            tourRoute = '/users'
        } else if (title === 'Manage organizations') {
            tourTarget = '[data-tour="organizations-list"]'
            tourRoute = '/organizations'
        } else if (title === 'Organize concern categories') {
            tourTarget = '[data-tour="categories-list"]'
            tourRoute = '/concern-categories'
        } else if (title === 'Review and revoke sessions') {
            tourTarget = '[data-tour="login-history-sessions"]'
            tourRoute = '/login-history'
        } else if (title === 'Update your account and profile') {
            tourTarget = '[data-tour="profile-menu-item"], [data-tour="profile-menu-mobile"]'
            tourRoute = '/dashboard'
            tourAction = 'open-profile-menu'
        }

        return {
            ...step,
            tourTarget,
            tourFallbackTarget: fallbackTarget,
            tourRoute,
            tourAction
        }
    })

    const dashboardStepIndex = mappedSteps.findIndex(
        (step) => step.title === 'Your workspace at a glance'
    )

    if (dashboardStepIndex !== -1 && ['superadmin', 'system_admin', 'system_monitor'].includes(roleName.value)) {
        mappedSteps.splice(dashboardStepIndex + 1, 0, {
            ...mappedSteps[dashboardStepIndex],
            title: 'Filter dashboard by organization',
            descriptionStart: 'When available to your role, use the ',
            emphasis: 'organization filter',
            descriptionEnd: ' to focus dashboard totals and charts on one participating organization or compare all organizations.',
            tip: 'On phones and small screens, tap Filters to reveal the date-range and organization controls.',
            tourTarget: '[data-tour="dashboard-organization"]',
            tourFallbackTarget: '',
            tourRoute: '/dashboard',
            tourAction: 'ensure-dashboard-filters'
        })
    }

    return mappedSteps
})

const currentStep = computed(() => guideSteps.value[activeStep.value] || guideSteps.value[0])
const progress = computed(() => guideSteps.value.length
    ? Math.round(((activeStep.value + 1) / guideSteps.value.length) * 100)
    : 0)
const isLastStep = computed(() => activeStep.value === guideSteps.value.length - 1)

function openGuide() {
    activeStep.value = 0
    isOpen.value = true
}

function closeGuide() {
    isOpen.value = false
}

function startInteractiveTour() {
    isOpen.value = false
    isInteractiveTourActive.value = true
}

async function goToCurrentStep() {
    const destination = currentStep.value?.to

    if (!destination) {
        return
    }

    closeGuide()
    await navigateTo(destination)
}

function nextStep() {
    if (isLastStep.value) {
        closeGuide()
        return
    }

    activeStep.value += 1
}

function previousStep() {
    activeStep.value = Math.max(0, activeStep.value - 1)
}

function handleKeydown(event) {
    if (event.key === 'Escape') {
        closeGuide()
    } else if (event.key === 'ArrowRight') {
        nextStep()
    } else if (event.key === 'ArrowLeft') {
        previousStep()
    }
}

watch(guideSteps, (steps) => {
    activeStep.value = Math.min(activeStep.value, Math.max(steps.length - 1, 0))
})

watch(isHelpAvailable, (available) => {
    if (!available) {
        isOpen.value = false
    }
})
</script>

<template>
    <div class="contents">
        <InteractiveHelpTour
            v-model:active="isInteractiveTourActive"
            :current-user="props.currentUser"
            :steps="guideSteps"
        />

        <button
            v-if="isHelpAvailable"
            type="button"
            class="help-guide-launcher fixed bottom-5 right-5 z-40 inline-flex h-12 w-12 items-center justify-center rounded-full border border-transparent bg-blue-950 p-0 text-sm font-semibold text-white shadow-xl shadow-blue-950/25 transition duration-200 hover:-translate-y-1 hover:bg-blue-900 focus:outline-none focus:ring-4 focus:ring-blue-300/70 sm:bottom-7 sm:right-7 sm:h-auto sm:w-auto sm:gap-2 sm:px-4 sm:py-3"
            aria-label="Open help guide"
            @click="openGuide"
        >
            <span class="help-guide-border-spin" aria-hidden="true"></span>
            <span class="help-guide-border-core" aria-hidden="true"></span>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="relative z-10 h-5 w-5" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 9a2.25 2.25 0 1 1 3.9 1.54c-.9.92-1.65 1.36-1.65 2.71m.01 3h-.02M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
            </svg>
            <span class="relative z-10 hidden sm:inline">Help guide</span>
        </button>

        <Teleport to="body">
            <Transition
                enter-active-class="transition duration-300 ease-out"
                enter-from-class="opacity-0"
                enter-to-class="opacity-100"
                leave-active-class="transition duration-200 ease-in"
                leave-from-class="opacity-100"
                leave-to-class="opacity-0"
            >
                <div
                    v-if="isOpen && currentStep"
                    class="fixed inset-0 z-100 flex items-center justify-center overflow-y-auto bg-slate-950/65 p-3 backdrop-blur-sm sm:p-6"
                    @click.self="closeGuide"
                    @keydown="handleKeydown"
                >
                    <section
                        role="dialog"
                        aria-modal="true"
                        aria-labelledby="help-guide-title"
                        class="help-guide-panel relative grid max-h-[calc(100dvh-1.5rem)] w-full max-w-4xl grid-rows-[auto_1fr] overflow-y-auto rounded-2xl border border-transparent bg-white shadow-2xl sm:rounded-3xl md:min-h-122.5 md:grid-cols-[0.95fr_1.05fr] md:grid-rows-1 md:overflow-hidden"
                    >
                        <button
                            type="button"
                            aria-label="Close help guide"
                            class="group absolute right-3 top-3 z-50 flex h-10 w-10 cursor-pointer items-center justify-center rounded-full border border-blue-900/15 bg-blue-950 text-3xl leading-none text-white shadow-lg transition hover:bg-blue-900 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:ring-offset-2"
                            @click="closeGuide"
                        >
                            <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                                stroke="currentColor" aria-hidden="true"
                                class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                            </svg>
                        </button>
                        <div class="relative flex min-h-0 flex-col items-center justify-center gap-3 overflow-hidden bg-linear-to-br from-blue-950 via-blue-900 to-cyan-800 p-3 sm:min-h-52 sm:gap-5 sm:p-6 md:min-h-full md:p-8">
                            <div class="pointer-events-none absolute -left-16 -top-20 h-56 w-56 rounded-full bg-cyan-300/15 blur-3xl"></div>
                            <div class="pointer-events-none absolute -bottom-20 -right-10 h-56 w-56 rounded-full bg-blue-300/20 blur-3xl"></div>
                            <div class="guide-illustration relative z-10 w-full max-w-sm rounded-xl border border-white/20 bg-white/95 p-2.5 shadow-2xl sm:rounded-2xl sm:p-4 md:p-6" :key="currentStep.art">
                                <div class="mb-2 flex items-center gap-1.5 border-b border-slate-100 pb-2 sm:mb-5 sm:gap-2 sm:pb-3">
                                    <span class="h-2 w-2 rounded-full bg-red-400 sm:h-2.5 sm:w-2.5"></span>
                                    <span class="h-2 w-2 rounded-full bg-amber-400 sm:h-2.5 sm:w-2.5"></span>
                                    <span class="h-2 w-2 rounded-full bg-emerald-400 sm:h-2.5 sm:w-2.5"></span>
                                    <span class="ml-auto rounded-full bg-blue-50 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wide text-blue-800">{{ currentStep.art }}</span>
                                </div>

                                <svg v-if="currentStep.art === 'dashboard' || currentStep.art === 'monitor'" viewBox="0 0 360 220" class="max-h-28 w-full object-contain sm:max-h-none" role="img" :aria-label="`${currentStep.title} illustration`">
                                    <rect x="8" y="8" width="344" height="204" rx="14" fill="#f8fafc" />
                                    <rect x="22" y="23" width="316" height="26" rx="7" fill="#dbeafe" />
                                    <rect x="33" y="32" width="70" height="8" rx="4" fill="#1e3a8a" />
                                    <rect x="22" y="62" width="92" height="48" rx="9" fill="#fff" stroke="#e2e8f0" />
                                    <rect x="128" y="62" width="92" height="48" rx="9" fill="#fff" stroke="#e2e8f0" />
                                    <rect x="234" y="62" width="92" height="48" rx="9" fill="#fff" stroke="#e2e8f0" />
                                    <rect x="33" y="74" width="35" height="5" rx="2.5" fill="#94a3b8" />
                                    <rect x="33" y="87" width="48" height="12" rx="5" fill="#2563eb" />
                                    <rect x="139" y="74" width="35" height="5" rx="2.5" fill="#94a3b8" />
                                    <rect x="139" y="87" width="30" height="12" rx="5" fill="#f59e0b" />
                                    <rect x="245" y="74" width="35" height="5" rx="2.5" fill="#94a3b8" />
                                    <rect x="245" y="87" width="42" height="12" rx="5" fill="#10b981" />
                                    <rect x="22" y="123" width="194" height="72" rx="9" fill="#fff" stroke="#e2e8f0" />
                                    <path d="M38 177 72 157l31 10 39-29 27 18 27-24" fill="none" stroke="#2563eb" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" />
                                    <rect x="230" y="123" width="96" height="72" rx="9" fill="#fff" stroke="#e2e8f0" />
                                    <circle cx="278" cy="158" r="23" fill="none" stroke="#dbeafe" stroke-width="10" />
                                    <path d="M278 135a23 23 0 0 1 21 32" fill="none" stroke="#2563eb" stroke-width="10" stroke-linecap="round" />
                                </svg>

                                <svg v-else-if="currentStep.art === 'concerns' || currentStep.art === 'workflow'" viewBox="0 0 360 220" class="max-h-28 w-full object-contain sm:max-h-none" role="img" :aria-label="`${currentStep.title} illustration`">
                                    <rect x="8" y="8" width="344" height="204" rx="14" fill="#f8fafc" />
                                    <rect x="22" y="22" width="316" height="30" rx="8" fill="#dbeafe" />
                                    <rect x="33" y="33" width="85" height="8" rx="4" fill="#1e3a8a" />
                                    <rect x="242" y="29" width="82" height="16" rx="8" fill="#fff" stroke="#bfdbfe" />
                                    <rect x="22" y="64" width="316" height="38" rx="7" fill="#fff" stroke="#e2e8f0" />
                                    <circle cx="41" cy="83" r="7" fill="#fbbf24" />
                                    <rect x="57" y="77" width="122" height="6" rx="3" fill="#475569" />
                                    <rect x="57" y="88" width="81" height="5" rx="2.5" fill="#cbd5e1" />
                                    <rect x="260" y="76" width="60" height="15" rx="7" fill="#fef3c7" />
                                    <rect x="22" y="111" width="316" height="38" rx="7" fill="#fff" stroke="#e2e8f0" />
                                    <circle cx="41" cy="130" r="7" fill="#3b82f6" />
                                    <rect x="57" y="124" width="146" height="6" rx="3" fill="#475569" />
                                    <rect x="57" y="135" width="96" height="5" rx="2.5" fill="#cbd5e1" />
                                    <rect x="260" y="123" width="60" height="15" rx="7" fill="#dbeafe" />
                                    <rect x="22" y="158" width="316" height="38" rx="7" fill="#fff" stroke="#e2e8f0" />
                                    <circle cx="41" cy="177" r="7" fill="#34d399" />
                                    <rect x="57" y="171" width="104" height="6" rx="3" fill="#475569" />
                                    <rect x="57" y="182" width="133" height="5" rx="2.5" fill="#cbd5e1" />
                                    <rect x="260" y="170" width="60" height="15" rx="7" fill="#dcfce7" />
                                </svg>

                                <svg v-else-if="currentStep.art === 'create'" viewBox="0 0 360 220" class="max-h-28 w-full object-contain sm:max-h-none" role="img" :aria-label="`${currentStep.title} illustration`">
                                    <rect x="8" y="8" width="344" height="204" rx="14" fill="#f8fafc" />
                                    <rect x="24" y="22" width="312" height="176" rx="11" fill="#fff" stroke="#e2e8f0" />
                                    <rect x="42" y="39" width="120" height="8" rx="4" fill="#1e3a8a" />
                                    <rect x="42" y="59" width="276" height="27" rx="6" fill="#f8fafc" stroke="#cbd5e1" />
                                    <rect x="42" y="98" width="276" height="52" rx="6" fill="#f8fafc" stroke="#cbd5e1" />
                                    <rect x="42" y="162" width="91" height="23" rx="6" fill="#eff6ff" stroke="#bfdbfe" />
                                    <rect x="145" y="162" width="78" height="23" rx="6" fill="#eff6ff" stroke="#bfdbfe" />
                                    <rect x="263" y="162" width="55" height="23" rx="6" fill="#1e3a8a" />
                                    <path d="M283 173h15m-7-7 7 7-7 7" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                                </svg>

                                <svg v-else-if="currentStep.art === 'team'" viewBox="0 0 360 220" class="max-h-28 w-full object-contain sm:max-h-none" role="img" :aria-label="`${currentStep.title} illustration`">
                                    <rect x="8" y="8" width="344" height="204" rx="14" fill="#f8fafc" />
                                    <rect x="22" y="23" width="316" height="30" rx="8" fill="#dbeafe" />
                                    <rect x="34" y="34" width="105" height="8" rx="4" fill="#1e3a8a" />
                                    <rect x="22" y="66" width="316" height="38" rx="7" fill="#fff" stroke="#e2e8f0" />
                                    <circle cx="45" cy="85" r="11" fill="#bfdbfe" />
                                    <circle cx="45" cy="82" r="4" fill="#1e3a8a" />
                                    <path d="M37 94a8 8 0 0 1 16 0" fill="#1e3a8a" />
                                    <rect x="67" y="78" width="94" height="6" rx="3" fill="#475569" />
                                    <rect x="67" y="89" width="60" height="5" rx="2.5" fill="#cbd5e1" />
                                    <rect x="254" y="77" width="68" height="16" rx="8" fill="#dcfce7" />
                                    <rect x="22" y="112" width="316" height="38" rx="7" fill="#fff" stroke="#e2e8f0" />
                                    <circle cx="45" cy="131" r="11" fill="#ddd6fe" />
                                    <circle cx="45" cy="128" r="4" fill="#6d28d9" />
                                    <path d="M37 140a8 8 0 0 1 16 0" fill="#6d28d9" />
                                    <rect x="67" y="124" width="114" height="6" rx="3" fill="#475569" />
                                    <rect x="67" y="135" width="76" height="5" rx="2.5" fill="#cbd5e1" />
                                    <rect x="254" y="123" width="68" height="16" rx="8" fill="#f1f5f9" />
                                    <rect x="22" y="158" width="110" height="34" rx="8" fill="#1e3a8a" />
                                    <path d="M39 175h75" stroke="#fff" stroke-width="5" stroke-linecap="round" />
                                </svg>

                                <svg v-else-if="currentStep.art === 'security'" viewBox="0 0 360 220" class="max-h-28 w-full object-contain sm:max-h-none" role="img" :aria-label="`${currentStep.title} illustration`">
                                    <rect x="8" y="8" width="344" height="204" rx="14" fill="#f8fafc" />
                                    <rect x="23" y="24" width="205" height="168" rx="10" fill="#fff" stroke="#e2e8f0" />
                                    <rect x="39" y="40" width="112" height="7" rx="3.5" fill="#1e3a8a" />
                                    <rect x="39" y="61" width="173" height="27" rx="6" fill="#f8fafc" />
                                    <circle cx="54" cy="74" r="6" fill="#34d399" />
                                    <rect x="69" y="70" width="70" height="6" rx="3" fill="#475569" />
                                    <rect x="39" y="96" width="173" height="27" rx="6" fill="#fff1f2" />
                                    <circle cx="54" cy="109" r="6" fill="#ef4444" />
                                    <rect x="69" y="105" width="89" height="6" rx="3" fill="#475569" />
                                    <path d="M277 65 320 82v31c0 30-18 48-43 60-25-12-43-30-43-60V82l43-17Z" fill="#dbeafe" />
                                    <path d="m258 109 13 13 25-29" fill="none" stroke="#1e3a8a" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" />
                                </svg>

                                <svg v-else viewBox="0 0 360 220" class="max-h-28 w-full object-contain sm:max-h-none" role="img" :aria-label="`${currentStep.title} illustration`">
                                    <rect x="8" y="8" width="344" height="204" rx="14" fill="#f8fafc" />
                                    <circle cx="180" cy="90" r="43" fill="#dbeafe" />
                                    <circle cx="180" cy="79" r="15" fill="#1e3a8a" />
                                    <path d="M148 119a32 32 0 0 1 64 0" fill="#1e3a8a" />
                                    <rect x="77" y="146" width="206" height="13" rx="6.5" fill="#cbd5e1" />
                                    <rect x="112" y="169" width="136" height="20" rx="10" fill="#1e3a8a" />
                                </svg>
                            </div>

                            <button
                                type="button"
                                class="group relative z-10 inline-flex min-h-10 w-full max-w-sm cursor-pointer items-center justify-between gap-2 rounded-lg border border-white/25 bg-white/10 px-3 py-2 text-left text-xs font-semibold text-white shadow-lg backdrop-blur transition duration-200 hover:-translate-y-0.5 hover:border-white/50 hover:bg-white/15 focus:outline-none focus:ring-2 focus:ring-white/80 sm:min-h-12 sm:gap-3 sm:rounded-xl sm:px-4 sm:py-3 sm:text-sm"
                                @click="goToCurrentStep"
                            >
                                <span>
                                    <span class="block text-[9px] font-medium uppercase tracking-[0.12em] text-blue-100/80 sm:text-[10px] sm:tracking-[0.16em]">Go to this section</span>
                                    <span class="mt-0.5 block">{{ currentStep.actionLabel }}</span>
                                </span>
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-5 w-5 shrink-0 transition-transform group-hover:translate-x-1" aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12h15m-6-6 6 6-6 6" />
                                </svg>
                            </button>
                        </div>

                        <div class="flex flex-col justify-between p-4 sm:p-7 md:p-9">
                            <div>
                                <div class="mb-3 flex items-center gap-2 text-[10px] font-bold uppercase tracking-[0.12em] text-blue-800 sm:mb-5 sm:text-xs sm:tracking-[0.16em]">
                                    <span class="flex h-7 w-7 items-center justify-center rounded-lg bg-blue-50 sm:h-8 sm:w-8 sm:rounded-xl">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 18h.008v.008H12V18Zm0-2.25c0-3.75 3.75-3 3.75-6A3.75 3.75 0 0 0 8.4 8.1M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                                        </svg>
                                    </span>
                                    {{ roleLabel }} quick guide
                                </div>

                                <Transition name="guide-step" mode="out-in">
                                    <div :key="activeStep">
                                        <p class="text-[10px] font-semibold uppercase tracking-[0.16em] text-slate-400 sm:text-xs sm:tracking-[0.18em]">Step {{ activeStep + 1 }} of {{ guideSteps.length }}</p>
                                        <h2 id="help-guide-title" class="mt-1.5 text-xl font-bold leading-tight tracking-tight text-slate-950 sm:mt-2 sm:text-2xl md:text-3xl">{{ currentStep.title }}</h2>
                                        <p class="mt-2 text-xs leading-5 text-slate-600 sm:mt-4 sm:text-sm sm:leading-7">{{ currentStep.descriptionStart }}<strong class="font-bold text-slate-900">{{ currentStep.emphasis }}</strong>{{ currentStep.descriptionEnd }}</p>
                                        <div class="mt-3 rounded-lg border border-blue-100 bg-blue-50/80 p-3 sm:mt-5 sm:rounded-xl sm:p-4">
                                            <p class="text-xs font-bold uppercase tracking-wide text-blue-900">Helpful tip</p>
                                            <p class="mt-1 text-xs leading-5 text-blue-950/80 sm:text-sm sm:leading-6">{{ currentStep.tip }}</p>
                                        </div>
                                    </div>
                                </Transition>
                            </div>

                            <div class="mt-4 sm:mt-7">
                                <button
                                    type="button"
                                    class="group mb-4 inline-flex w-full cursor-pointer items-center justify-center gap-2 rounded-xl bg-cyan-50 px-4 py-3 text-sm font-bold text-blue-950 ring-1 ring-cyan-200 transition hover:-translate-y-0.5 hover:bg-cyan-100 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:ring-offset-2"
                                    @click="startInteractiveTour"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-5 w-5 transition-transform group-hover:rotate-12" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-6.364-2.636 1.591-1.591M5.25 12H3m2.636-6.364 1.591 1.591M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />
                                    </svg>
                                    Start animated walkthrough
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4 transition-transform group-hover:translate-x-1" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12h15m-6-6 6 6-6 6" />
                                    </svg>
                                </button>

                                <div class="mb-3 flex items-center justify-between gap-3 sm:mb-4">
                                    <div class="flex gap-1.5" role="group" aria-label="Guide steps">
                                        <button
                                            v-for="(_, index) in guideSteps"
                                            :key="index"
                                            type="button"
                                            class="h-2 cursor-pointer rounded-full transition-all duration-300"
                                            :class="activeStep === index ? 'w-7 bg-blue-900' : 'w-2 bg-slate-200 hover:bg-slate-400'"
                                            :aria-label="`Go to step ${index + 1}`"
                                            :aria-current="activeStep === index ? 'step' : undefined"
                                            @click="activeStep = index"
                                        ></button>
                                    </div>
                                    <span class="text-xs font-semibold tabular-nums text-slate-400">{{ progress }}%</span>
                                </div>
                                <div class="flex items-center justify-between gap-2 border-t border-slate-100 pt-3 sm:gap-3 sm:pt-4">
                                    <div class="flex gap-2">
                                        <button
                                            v-if="activeStep > 0"
                                            type="button"
                                            class="cursor-pointer rounded-lg border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                                            @click="previousStep"
                                        >
                                            Back
                                        </button>
                                        <button
                                            type="button"
                                            class="inline-flex cursor-pointer items-center gap-2 rounded-lg bg-blue-950 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-900 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:ring-offset-2"
                                            @click="nextStep"
                                        >
                                            {{ isLastStep ? 'Finish' : 'Next' }}
                                            <svg v-if="!isLastStep" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5.25 15.75 12 9 18.75M4.5 12h11.25" /></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>
                </div>
            </Transition>
        </Teleport>
    </div>
</template>

<style scoped>
.help-guide-panel {
    background-image:
        linear-gradient(#fff, #fff),
        linear-gradient(
            115deg,
            rgb(34 211 238 / 35%),
            rgb(255 255 255 / 95%),
            rgb(34 211 238 / 95%),
            rgb(59 130 246 / 85%),
            rgb(255 255 255 / 95%)
        );
    background-origin: border-box;
    background-clip: padding-box, border-box;
    background-size: 100% 100%, 300% 300%;
    background-position: 0 0, 0% 50%;
    animation: help-guide-border-shine 4.5s ease-in-out infinite;
}

.help-guide-launcher {
    isolation: isolate;
    overflow: hidden;
}

.help-guide-border-spin {
    position: absolute;
    inset: 0;
    z-index: 0;
    pointer-events: none;
    background: conic-gradient(
        from 0deg,
        transparent 0deg 270deg,
        rgb(255 255 255 / 45%) 292deg,
        rgb(103 232 249 / 95%) 312deg,
        #fff 326deg,
        transparent 346deg 360deg
    );
    animation: help-guide-edge-spin 3s linear infinite;
}

.help-guide-border-core {
    position: absolute;
    inset: 2px;
    z-index: 1;
    border-radius: inherit;
    background-color: inherit;
    pointer-events: none;
}

.guide-illustration {
    animation: guide-float-in 480ms cubic-bezier(0.2, 0.8, 0.2, 1) both;
}

.guide-step-enter-active,
.guide-step-leave-active {
    transition: opacity 160ms ease, transform 160ms ease;
}

.guide-step-enter-from {
    opacity: 0;
    transform: translateY(8px);
}

.guide-step-leave-to {
    opacity: 0;
    transform: translateY(-8px);
}

@keyframes guide-float-in {
    from {
        opacity: 0;
        transform: translateY(12px) scale(0.97);
    }
    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
}

@keyframes help-guide-edge-spin {
    to {
        transform: rotate(1turn);
    }
}

@keyframes help-guide-border-shine {
    0%, 100% {
        background-position: 0 0, 0% 50%;
    }
    50% {
        background-position: 0 0, 100% 50%;
    }
}

@media (prefers-reduced-motion: reduce) {
    .help-guide-panel {
        animation: none;
    }

    .help-guide-border-spin {
        animation: none;
    }

    .guide-illustration {
        animation: none;
    }

    .guide-step-enter-active,
    .guide-step-leave-active {
        transition: none;
    }
}
</style>
