<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'

const props = defineProps({
    steps: { type: Array, default: () => [] },
    active: { type: Boolean, default: false }
})

const emit = defineEmits(['update:active'])
const route = useRoute()
const tourCard = ref(null)
const targetRect = ref(null)
const cardPosition = ref({ left: 16, top: 16, width: 360 })
const stepIndex = ref(0)
const targetMissing = ref(false)
const isBusy = ref(false)
const waitForActionTarget = ref(false)
let retryTimer = null

const tourSteps = computed(() => props.steps || [])

const currentStep = computed(() => tourSteps.value[stepIndex.value])
const progress = computed(() => tourSteps.value.length
    ? Math.round(((stepIndex.value + 1) / tourSteps.value.length) * 100)
    : 0)
const arrowPath = computed(() => {
    if (!targetRect.value || !tourCard.value) return ''

    const targetX = targetRect.value.left + targetRect.value.width / 2
    const targetY = targetRect.value.top + targetRect.value.height / 2
    const card = cardPosition.value
    const cardCenterX = card.left + card.width / 2
    const cardCenterY = card.top + (tourCard.value.offsetHeight || 0) / 2

    if (window.innerWidth < 640) {
        const cardTop = card.top
        const targetBelowCard = targetY > cardTop
        const anchorX = Math.min(Math.max(targetX, card.left + 28), card.left + card.width - 28)
        const anchorY = targetBelowCard ? cardTop + 4 : card.top + (tourCard.value.offsetHeight || 0) - 4
        const bendY = (targetY + anchorY) / 2
        return `M ${anchorX} ${anchorY} Q ${anchorX} ${bendY} ${targetX} ${targetY}`
    }

    const anchorX = cardCenterX > targetX ? card.left : card.left + card.width
    const anchorY = cardCenterY
    const bendX = (targetX + anchorX) / 2
    return `M ${anchorX} ${anchorY} C ${bendX} ${anchorY}, ${bendX} ${targetY}, ${targetX} ${targetY}`
})

function visibleTarget(selector) {
    if (!selector) return null

    return [...document.querySelectorAll(selector)].find((element) => {
        const rect = element.getBoundingClientRect()
        const style = window.getComputedStyle(element)
        return rect.width > 0 && rect.height > 0 && style.visibility !== 'hidden' && style.display !== 'none'
    }) || null
}

async function waitForVisibleTarget(selector, attempts = 30) {
    for (let attempt = 0; attempt < attempts; attempt += 1) {
        const target = visibleTarget(selector)
        if (target) return target

        await new Promise((resolve) => window.setTimeout(resolve, 80))
    }

    return null
}

function updateGeometry() {
    if (!props.active || !currentStep.value) return

    const primaryTarget = visibleTarget(currentStep.value.tourTarget)
    const target = primaryTarget || (!waitForActionTarget.value
        ? visibleTarget(currentStep.value.tourFallbackTarget)
        : null)

    if (primaryTarget) {
        waitForActionTarget.value = false
    }
    if (!target) {
        targetRect.value = null
        targetMissing.value = true
        const width = Math.min(380, window.innerWidth - 32)
        cardPosition.value = {
            left: (window.innerWidth - width) / 2,
            top: Math.max(24, (window.innerHeight - 220) / 2),
            width
        }
        return
    }

    targetMissing.value = false
    const rect = target.getBoundingClientRect()
    const padding = 8
    const left = Math.max(8, rect.left - padding)
    const top = Math.max(8, rect.top - padding)
    targetRect.value = {
        left,
        top,
        width: Math.min(window.innerWidth - left - 8, rect.width + padding * 2),
        height: Math.min(window.innerHeight - top - 8, rect.height + padding * 2)
    }

    target.scrollIntoView({ behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'center', inline: 'nearest' })

    nextTick(() => {
        if (!tourCard.value) return
        const width = Math.min(380, window.innerWidth - 32)
        const height = tourCard.value.offsetHeight
        const mobile = window.innerWidth < 640
        let left
        let top

        if (mobile) {
            left = (window.innerWidth - width) / 2
            top = targetRect.value.top > window.innerHeight * 0.57
                ? 16
                : window.innerHeight - height - 16
        } else {
            const placeRight = rect.left + rect.width / 2 < window.innerWidth / 2
            left = placeRight
                ? Math.min(window.innerWidth - width - 16, rect.right + 28)
                : Math.max(16, rect.left - width - 28)
            top = Math.min(
                window.innerHeight - height - 16,
                Math.max(16, rect.top + rect.height / 2 - height / 2)
            )
        }

        cardPosition.value = { left, top, width }
    })
}

function waitForTarget() {
    window.clearTimeout(retryTimer)
    let attempts = 0

    const check = () => {
        if (!props.active) return
        updateGeometry()
        if (targetMissing.value && attempts < 40) {
            attempts += 1
            retryTimer = window.setTimeout(check, 100)
        } else if (targetMissing.value && waitForActionTarget.value) {
            waitForActionTarget.value = false
            updateGeometry()
        }
    }

    check()
}

async function goToStep(index) {
    if (isBusy.value || index < 0 || index >= tourSteps.value.length) return

    isBusy.value = true
    stepIndex.value = index
    targetRect.value = null
    targetMissing.value = false
    waitForActionTarget.value = false

    try {
        const step = tourSteps.value[index]
        const destination = step.tourRoute || step.to?.split('?')[0] || '/dashboard'
        if (route.fullPath !== destination) {
            await navigateTo(destination)
        }
        await nextTick()

        if (['open-first-concern', 'open-first-concern-conversation'].includes(step.tourAction) && !visibleTarget(step.tourTarget)) {
            const firstConcern = visibleTarget('[data-tour="concern-row"]')
            if (firstConcern) {
                waitForActionTarget.value = true
                firstConcern.click()

                if (step.tourAction === 'open-first-concern-conversation') {
                    const conversationTab = await waitForVisibleTarget('#concern-tab-conversation')
                    conversationTab?.click()
                }
            }
        } else if (step.tourAction === 'open-profile-menu' &&
            !visibleTarget(step.tourTarget)) {
            visibleTarget('[data-tour="profile-menu-toggle"]')?.click()
        } else if (step.tourAction === 'ensure-dashboard-filters' &&
            window.innerWidth < 1024 && !visibleTarget(step.tourTarget)) {
            const filtersToggle = visibleTarget('[data-tour="dashboard-mobile-filters-toggle"]')

            if (filtersToggle?.getAttribute('aria-expanded') !== 'true') {
                filtersToggle?.click()
            }
        }

        waitForTarget()
    } finally {
        isBusy.value = false
    }
}

function closeTour() {
    window.clearTimeout(retryTimer)
    waitForActionTarget.value = false
    targetRect.value = null
    emit('update:active', false)
}

function nextStep() {
    if (stepIndex.value >= tourSteps.value.length - 1) {
        closeTour()
        return
    }
    goToStep(stepIndex.value + 1)
}

function previousStep() {
    goToStep(stepIndex.value - 1)
}

function handleKeydown(event) {
    if (event.key === 'Escape') closeTour()
    if (event.key === 'ArrowRight') nextStep()
    if (event.key === 'ArrowLeft' && stepIndex.value > 0) previousStep()
}

watch(() => props.active, (active) => {
    if (active) {
        stepIndex.value = 0
        nextTick(() => goToStep(0))
        window.addEventListener('resize', updateGeometry)
        window.addEventListener('scroll', updateGeometry, true)
        window.addEventListener('keydown', handleKeydown)
    } else {
        window.clearTimeout(retryTimer)
        window.removeEventListener('resize', updateGeometry)
        window.removeEventListener('scroll', updateGeometry, true)
        window.removeEventListener('keydown', handleKeydown)
        targetRect.value = null
    }
})

watch(() => route.fullPath, () => {
    if (props.active) nextTick(waitForTarget)
})

onBeforeUnmount(() => {
    window.clearTimeout(retryTimer)
    window.removeEventListener('resize', updateGeometry)
    window.removeEventListener('scroll', updateGeometry, true)
    window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
    <Teleport to="body">
        <Transition
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-active-class="transition duration-200 ease-in"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
        >
            <div v-if="active" class="fixed inset-0 z-180" tabindex="-1">
                <div class="tour-shade pointer-events-auto fixed inset-0" aria-hidden="true"></div>

                <div
                    v-if="targetRect"
                    class="tour-spotlight pointer-events-none fixed rounded-2xl border-2 border-cyan-300"
                    :style="{
                        left: `${targetRect.left}px`,
                        top: `${targetRect.top}px`,
                        width: `${targetRect.width}px`,
                        height: `${targetRect.height}px`
                    }"
                    aria-hidden="true"
                >
                    <span class="tour-spotlight-pulse"></span>
                </div>

                <svg v-if="arrowPath && targetRect" class="pointer-events-none fixed inset-0 h-full w-full overflow-visible" aria-hidden="true">
                    <defs>
                        <marker id="tour-arrowhead" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto">
                            <path d="M0,0 L10,5 L0,10 z" fill="#67e8f9" />
                        </marker>
                    </defs>
                    <path :d="arrowPath" fill="none" stroke="#67e8f9" stroke-width="3" stroke-linecap="round" stroke-dasharray="7 7" marker-end="url(#tour-arrowhead)" class="tour-arrow-path" />
                </svg>

                <section
                    ref="tourCard"
                    class="tour-card fixed z-2 max-h-[calc(100dvh-2rem)] overflow-y-auto rounded-2xl border border-white/70 bg-white p-5 shadow-2xl sm:p-6"
                    :style="{ left: `${cardPosition.left}px`, top: `${cardPosition.top}px`, width: `${cardPosition.width}px` }"
                    role="dialog"
                    aria-modal="true"
                    aria-live="polite"
                    :aria-labelledby="`tour-title-${stepIndex}`"
                >
                    <div class="mb-3 flex items-center justify-between gap-3">
                        <span class="rounded-full bg-blue-50 px-3 py-1 text-[11px] font-bold uppercase tracking-wide text-blue-800">Interactive tour</span>
                        <button type="button" class="cursor-pointer rounded-full px-2 py-1 text-xs font-semibold text-slate-500 hover:bg-slate-100 hover:text-slate-900" @click="closeTour">Skip tour</button>
                    </div>

                    <template v-if="currentStep">
                        <p class="text-xs font-semibold uppercase tracking-widest text-slate-400">Step {{ stepIndex + 1 }} of {{ tourSteps.length }}</p>
                        <h2 :id="`tour-title-${stepIndex}`" class="mt-1.5 text-xl font-bold leading-tight text-slate-950">{{ currentStep.title }}</h2>
                        <p class="mt-2 text-sm leading-6 text-slate-600">{{ currentStep.descriptionStart }}<strong class="font-bold text-slate-900">{{ currentStep.emphasis }}</strong>{{ currentStep.descriptionEnd }}</p>
                        <p v-if="currentStep.tip" class="mt-3 rounded-lg border border-blue-100 bg-blue-50 px-3 py-2 text-xs leading-5 text-blue-950/80">{{ currentStep.tip }}</p>
                        <p v-if="targetMissing" class="mt-3 text-xs font-medium text-amber-700">This section is unavailable right now. Continue to another step or go back.</p>
                    </template>

                    <div class="mt-4 h-1.5 overflow-hidden rounded-full bg-slate-100">
                        <div class="h-full rounded-full bg-linear-to-r from-blue-700 via-cyan-500 to-teal-400 transition-[width] duration-500" :style="{ width: `${progress}%` }"></div>
                    </div>

                    <div class="mt-4 flex items-center justify-between gap-2">
                        <button type="button" :disabled="stepIndex === 0 || isBusy" class="cursor-pointer rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40" @click="previousStep">Back</button>
                        <button type="button" :disabled="isBusy" class="group inline-flex cursor-pointer items-center gap-2 rounded-lg bg-blue-900 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-blue-950/20 transition hover:-translate-y-0.5 hover:bg-blue-800 disabled:cursor-wait disabled:opacity-60" @click="nextStep">
                            {{ stepIndex === tourSteps.length - 1 ? 'Finish' : 'Next' }}
                            <svg v-if="stepIndex < tourSteps.length - 1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4 transition-transform group-hover:translate-x-1" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12h15m-6-6 6 6-6 6" /></svg>
                        </button>
                    </div>
                </section>
            </div>
        </Transition>
    </Teleport>
</template>

<style scoped>
.tour-shade {
    background: transparent;
}

.tour-spotlight {
    box-shadow: 0 0 0 9999px rgb(2 6 23 / 72%);
    animation: tour-highlight-in 420ms cubic-bezier(0.2, 0.8, 0.2, 1) both;
}

.tour-spotlight-pulse {
    position: absolute;
    inset: -5px;
    border: 1px solid rgb(103 232 249 / 70%);
    border-radius: inherit;
    animation: tour-pulse 1.8s ease-out infinite;
}

.tour-arrow-path {
    animation: tour-dash 1.2s linear infinite;
}

.tour-card {
    animation: tour-card-in 360ms cubic-bezier(0.2, 0.8, 0.2, 1) both;
}

@keyframes tour-highlight-in {
    from { opacity: 0; transform: scale(0.96); }
    to { opacity: 1; transform: scale(1); }
}

@keyframes tour-pulse {
    0% { opacity: 0.8; transform: scale(1); }
    100% { opacity: 0; transform: scale(1.08); }
}

@keyframes tour-dash {
    to { stroke-dashoffset: -28; }
}

@keyframes tour-card-in {
    from { opacity: 0; transform: translateY(10px) scale(0.98); }
    to { opacity: 1; transform: translateY(0) scale(1); }
}

@media (prefers-reduced-motion: reduce) {
    .tour-spotlight,
    .tour-spotlight-pulse,
    .tour-arrow-path,
    .tour-card {
        animation: none;
    }
}
</style>
