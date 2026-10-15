const TOOLTIP_ID = 'app-interactive-tooltip'
const TOOLTIP_DELAY = 450

const actionTips = {
    'add user': 'Create a new user account.',
    'add organization': 'Register a new organization in the system.',
    'add category': 'Create a category for classifying concerns.',
    'create concern': 'Start a new concern request.',
    'submit concern': 'Submit this concern to the selected organization.',
    filters: 'Choose filters to narrow the concern list.',
    'clear filters': 'Remove all selected concern filters.',
    'clear filter': 'Remove this active filter.',
    export: 'Download the matching concerns as an Excel report.',
    'export excel': 'Download the matching concerns as an Excel report.',
    'view trash': 'View concerns that have been moved to trash.',
    'back to concerns': 'Return to the active concerns list.',
    restore: 'Restore this item so it is active again.',
    'move to trash': 'Move this pending concern to trash. It may be restored before it expires.',
    'permanently delete': 'Permanently delete this concern and its history. This cannot be undone.',
    revoke: 'End this session and sign the user out.',
    remove: 'Remove this item.',
    replace: 'Choose a new image to replace the current one.',
    'save changes': 'Save the changes made to this record.',
    'update status': 'Apply the selected status and update notes.',
    'send comment': 'Share this message with people who can access the concern.',
    'add images': 'Attach additional images to this concern.',
    'view profile': 'Review your account and organization details.',
    'close guide': 'Close the help guide.',
    'close modal': 'Close this window without saving.',
    'close image viewer': 'Close the image preview.',
    'show password': 'Reveal the password you entered.',
    'hide password': 'Hide the password you entered.'
}

function labelFor(element) {
    const explicitTooltip = element.dataset.tooltip || element.getAttribute('title')

    if (explicitTooltip?.trim()) {
        return explicitTooltip.trim()
    }

    const ariaLabel = element.getAttribute('aria-label')?.trim()
    const text = (element.innerText || element.textContent || '').replace(/\s+/g, ' ').trim()
    const label = ariaLabel || text

    if (!label) {
        return ''
    }

    const normalizedLabel = label.toLowerCase()
    const exactTip = actionTips[normalizedLabel]

    if (exactTip) {
        return exactTip
    }

    if (element.matches('[role="combobox"]')) {
        return `Choose ${label.toLowerCase()}.`
    }

    if (element.matches('a[href]')) {
        return `Open ${label}.`
    }

    if (element.matches('button')) {
        return `Click to ${label.charAt(0).toLowerCase()}${label.slice(1)}.`
    }

    return ''
}

export default defineNuxtPlugin((nuxtApp) => {
    let activeElement = null
    let showTimer = null
    let hideTimer = null
    let tooltip = null
    let previousDescribedBy = null
    let previousTitle = null

    function ensureTooltip() {
        if (tooltip?.isConnected) {
            return tooltip
        }

        tooltip = document.createElement('div')
        tooltip.id = TOOLTIP_ID
        tooltip.className = 'app-tooltip'
        tooltip.setAttribute('role', 'tooltip')
        tooltip.hidden = true
        document.body.appendChild(tooltip)

        return tooltip
    }

    function positionTooltip(target) {
        if (!tooltip || !target?.isConnected) {
            return
        }

        const targetRect = target.getBoundingClientRect()
        const tooltipRect = tooltip.getBoundingClientRect()
        const gap = 9
        const margin = 8
        const centeredLeft = targetRect.left + (targetRect.width - tooltipRect.width) / 2
        const left = Math.max(
            margin,
            Math.min(centeredLeft, window.innerWidth - tooltipRect.width - margin)
        )
        const top = targetRect.bottom + gap + tooltipRect.height <= window.innerHeight - margin
            ? targetRect.bottom + gap
            : Math.max(margin, targetRect.top - tooltipRect.height - gap)

        tooltip.style.left = `${left}px`
        tooltip.style.top = `${top}px`
    }

    function hideTooltip() {
        clearTimeout(showTimer)
        clearTimeout(hideTimer)

        if (tooltip) {
            tooltip.hidden = true
            tooltip.classList.remove('app-tooltip-visible')
        }

        if (activeElement) {
            if (previousDescribedBy) {
                activeElement.setAttribute('aria-describedby', previousDescribedBy)
            } else {
                activeElement.removeAttribute('aria-describedby')
            }

            if (previousTitle !== null) {
                activeElement.setAttribute('title', previousTitle)
            }
        }

        activeElement = null
        previousDescribedBy = null
        previousTitle = null
    }

    function showTooltip(target) {
        const content = labelFor(target)

        if (!content || target.matches(':disabled, [aria-disabled="true"]')) {
            return
        }

        clearTimeout(hideTimer)
        clearTimeout(showTimer)

        if (activeElement && activeElement !== target) {
            if (previousDescribedBy) {
                activeElement.setAttribute('aria-describedby', previousDescribedBy)
            } else {
                activeElement.removeAttribute('aria-describedby')
            }
            if (previousTitle !== null) {
                activeElement.setAttribute('title', previousTitle)
            }
            activeElement = null
            previousDescribedBy = null
            previousTitle = null
        }

        activeElement = target

        showTimer = window.setTimeout(() => {
            if (!activeElement?.isConnected) {
                hideTooltip()
                return
            }

            const tooltipElement = ensureTooltip()
            tooltipElement.textContent = content
            tooltipElement.hidden = false
            previousDescribedBy = activeElement.getAttribute('aria-describedby')
            previousTitle = activeElement.getAttribute('title')
            if (previousTitle !== null) {
                activeElement.removeAttribute('title')
            }
            const describedBy = [previousDescribedBy, TOOLTIP_ID].filter(Boolean).join(' ')
            activeElement.setAttribute('aria-describedby', describedBy)

            requestAnimationFrame(() => {
                if (activeElement) {
                    positionTooltip(activeElement)
                    tooltipElement.classList.add('app-tooltip-visible')
                }
            })
        }, TOOLTIP_DELAY)
    }

    function findTooltipTarget(node) {
        return node instanceof Element
            ? node.closest('button, a[href], [role="combobox"], [title], [data-tooltip]')
            : null
    }

    function onPointerOver(event) {
        if (event.pointerType === 'touch') {
            return
        }

        const target = findTooltipTarget(event.target)

        if (target && target !== activeElement) {
            showTooltip(target)
        }
    }

    function onPointerOut(event) {
        const target = findTooltipTarget(event.target)

        if (target && !target.contains(event.relatedTarget)) {
            hideTimer = window.setTimeout(hideTooltip, 100)
        }
    }

    function onFocusIn(event) {
        const target = findTooltipTarget(event.target)

        if (target) {
            showTooltip(target)
        }
    }

    function onFocusOut(event) {
        const target = findTooltipTarget(event.target)

        if (target && !target.contains(event.relatedTarget)) {
            hideTooltip()
        }
    }

    function onViewportChange() {
        if (!tooltip?.hidden && activeElement) {
            positionTooltip(activeElement)
        }
    }

    document.addEventListener('pointerover', onPointerOver)
    document.addEventListener('pointerout', onPointerOut)
    document.addEventListener('focusin', onFocusIn)
    document.addEventListener('focusout', onFocusOut)
    window.addEventListener('resize', onViewportChange)
    window.addEventListener('scroll', onViewportChange, true)

    nuxtApp.hook('app:beforeUnmount', () => {
        hideTooltip()
        tooltip?.remove()
        document.removeEventListener('pointerover', onPointerOver)
        document.removeEventListener('pointerout', onPointerOut)
        document.removeEventListener('focusin', onFocusIn)
        document.removeEventListener('focusout', onFocusOut)
        window.removeEventListener('resize', onViewportChange)
        window.removeEventListener('scroll', onViewportChange, true)
    })
})
