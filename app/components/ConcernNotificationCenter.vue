<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'

const props = defineProps({
    currentUser: {
        type: Object,
        default: null
    }
})

const isOpen = ref(false)
const isLoading = ref(false)
const isMarkingAllRead = ref(false)
const notifications = ref([])
const unreadCount = ref(0)
const loadFailed = ref(false)
const pendingNotificationIds = ref(new Set())
let refreshTimer = null
let requestInProgress = false

async function loadNotifications() {
    if (!props.currentUser?.id || requestInProgress) {
        return
    }

    requestInProgress = true
    isLoading.value = true

    try {
        const response = await $fetch('/api/notifications', {
            cache: 'no-store'
        })

        notifications.value = response.notifications || []
        unreadCount.value = Number(response.unreadCount || 0)
        loadFailed.value = false
    } catch {
        loadFailed.value = true
    } finally {
        isLoading.value = false
        requestInProgress = false
    }
}

function toggleNotifications() {
    isOpen.value = !isOpen.value

    if (isOpen.value) {
        loadNotifications()
    }
}

async function markNotificationRead(notification) {
    if (notification.read_at || pendingNotificationIds.value.has(notification.id)) {
        return
    }

    pendingNotificationIds.value = new Set([
        ...pendingNotificationIds.value,
        notification.id
    ])

    try {
        await $fetch(`/api/notifications/${notification.id}`, {
            method: 'PATCH'
        })
        notification.read_at = new Date().toISOString()
        unreadCount.value = Math.max(0, unreadCount.value - 1)
    } catch {
        // Refresh will reconcile the unread state if the request failed.
    } finally {
        const pending = new Set(pendingNotificationIds.value)
        pending.delete(notification.id)
        pendingNotificationIds.value = pending
    }
}

async function openNotification(notification) {
    await markNotificationRead(notification)
    isOpen.value = false

    if (notification.href) {
        await navigateTo(notification.href)
    }
}

async function markAllAsRead() {
    if (unreadCount.value === 0 || isMarkingAllRead.value) {
        return
    }

    isMarkingAllRead.value = true

    try {
        await $fetch('/api/notifications/read-all', {
            method: 'PATCH'
        })

        const readAt = new Date().toISOString()
        notifications.value = notifications.value.map((notification) => ({
            ...notification,
            read_at: notification.read_at || readAt
        }))
        unreadCount.value = 0
    } catch {
        await loadNotifications()
    } finally {
        isMarkingAllRead.value = false
    }
}

function formatNotificationTime(value) {
    if (!value) return ''

    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return ''

    const elapsedSeconds = Math.max(0, Math.floor((Date.now() - date.getTime()) / 1000))

    if (elapsedSeconds < 60) return 'Just now'
    if (elapsedSeconds < 3600) return `${Math.floor(elapsedSeconds / 60)}m ago`
    if (elapsedSeconds < 86400) return `${Math.floor(elapsedSeconds / 3600)}h ago`
    if (elapsedSeconds < 604800) return `${Math.floor(elapsedSeconds / 86400)}d ago`

    return date.toLocaleDateString('en-PH', {
        month: 'short',
        day: 'numeric'
    })
}

function handleVisibilityChange() {
    if (document.visibilityState === 'visible') {
        loadNotifications()
    }
}

function handleWindowFocus() {
    loadNotifications()
}

watch(
    () => props.currentUser?.id,
    (userId) => {
        notifications.value = []
        unreadCount.value = 0
        isOpen.value = false
        loadFailed.value = false

        if (import.meta.client && userId) {
            loadNotifications()
        }
    },
    { immediate: true }
)

onMounted(() => {
    if (props.currentUser?.id) {
        loadNotifications()
    }

    refreshTimer = window.setInterval(loadNotifications, 30000)
    document.addEventListener('visibilitychange', handleVisibilityChange)
    window.addEventListener('focus', handleWindowFocus)
})

onBeforeUnmount(() => {
    if (refreshTimer) {
        window.clearInterval(refreshTimer)
    }

    document.removeEventListener('visibilitychange', handleVisibilityChange)
    window.removeEventListener('focus', handleWindowFocus)
})
</script>

<template>
    <div v-if="currentUser" class="fixed bottom-5 right-5 z-180">
        <button
            type="button"
            class="relative flex h-12 w-12 cursor-pointer items-center justify-center rounded-full border border-blue-200 bg-white text-blue-900 shadow-lg shadow-blue-950/15 transition hover:-translate-y-0.5 hover:bg-blue-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-700 focus-visible:ring-offset-2"
            :aria-expanded="isOpen"
            aria-controls="in-app-notifications-panel"
            aria-label="Notifications"
            @click="toggleNotifications"
        >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-6 w-6" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14.25 18.75a2.25 2.25 0 0 1-4.5 0m9-2.25H5.25c1.125-1.125 1.5-2.625 1.5-4.5v-1.125a5.25 5.25 0 1 1 10.5 0V12c0 1.875.375 3.375 1.5 4.5Z" />
            </svg>
            <span v-if="unreadCount > 0" class="absolute -right-1 -top-1 flex min-h-5 min-w-5 items-center justify-center rounded-full border-2 border-white bg-red-600 px-1 text-[10px] font-bold leading-none text-white">
                {{ unreadCount > 99 ? '99+' : unreadCount }}
            </span>
        </button>

        <Transition
            enter-active-class="transition duration-150 ease-out"
            enter-from-class="translate-y-2 opacity-0"
            enter-to-class="translate-y-0 opacity-100"
            leave-active-class="transition duration-100 ease-in"
            leave-from-class="translate-y-0 opacity-100"
            leave-to-class="translate-y-2 opacity-0"
        >
            <section
                v-if="isOpen"
                id="in-app-notifications-panel"
                class="absolute bottom-14 right-0 flex max-h-[min(34rem,calc(100dvh-7rem))] w-[min(22rem,calc(100vw-2rem))] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl shadow-slate-950/20"
                aria-label="Notifications"
            >
                <header class="flex items-center justify-between gap-3 border-b border-slate-200 px-4 py-3">
                    <div>
                        <h2 class="text-sm font-bold text-slate-900">Notifications</h2>
                        <p class="mt-0.5 text-[11px] text-slate-500">
                            {{ unreadCount ? `${unreadCount} unread` : 'You’re all caught up' }}
                        </p>
                    </div>
                    <div class="flex items-center gap-2">
                        <button
                            v-if="unreadCount > 0"
                            type="button"
                            :disabled="isMarkingAllRead"
                            class="cursor-pointer text-[11px] font-semibold text-blue-800 hover:text-blue-950 disabled:cursor-not-allowed disabled:opacity-50"
                            @click="markAllAsRead"
                        >
                            {{ isMarkingAllRead ? 'Updating…' : 'Mark all read' }}
                        </button>
                        <button type="button" class="flex h-7 w-7 cursor-pointer items-center justify-center rounded-full text-slate-500 hover:bg-slate-100" aria-label="Close notifications" @click="isOpen = false">
                            <span aria-hidden="true" class="text-xl leading-none">×</span>
                        </button>
                    </div>
                </header>

                <div class="min-h-24 overflow-y-auto">
                    <p v-if="loadFailed" class="px-4 py-8 text-center text-xs leading-5 text-slate-500">
                        Notifications could not be loaded. Please try again.
                    </p>
                    <p v-else-if="isLoading && notifications.length === 0" class="px-4 py-8 text-center text-xs text-slate-500">
                        Loading notifications…
                    </p>
                    <p v-else-if="notifications.length === 0" class="px-4 py-8 text-center text-xs leading-5 text-slate-500">
                        No notifications yet. Concern updates and comments will appear here.
                    </p>
                    <ul v-else class="divide-y divide-slate-100">
                        <li v-for="notification in notifications" :key="notification.id">
                            <button
                                type="button"
                                class="flex w-full cursor-pointer items-start gap-3 px-4 py-3 text-left transition hover:bg-slate-50"
                                :class="notification.read_at ? 'bg-white' : 'bg-blue-50/60'"
                                @click="openNotification(notification)"
                            >
                                <span class="mt-1.5 h-2 w-2 shrink-0 rounded-full" :class="notification.read_at ? 'bg-transparent' : 'bg-blue-700'" aria-hidden="true"></span>
                                <span class="min-w-0 flex-1">
                                    <span class="flex items-start justify-between gap-2">
                                        <span class="text-xs font-bold text-slate-900">{{ notification.title }}</span>
                                        <span class="shrink-0 text-[10px] text-slate-400">{{ formatNotificationTime(notification.created_at) }}</span>
                                    </span>
                                    <span class="mt-1 block text-xs leading-5 text-slate-600">{{ notification.message }}</span>
                                    <span v-if="notification.concern_number" class="mt-1 block text-[10px] font-semibold text-blue-800">
                                        {{ notification.concern_number }} · Open concern
                                    </span>
                                </span>
                            </button>
                        </li>
                    </ul>
                </div>
            </section>
        </Transition>
    </div>
</template>
