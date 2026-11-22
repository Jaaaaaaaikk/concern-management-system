<script setup>
import { computed, watch } from 'vue'
import { roleDisplayName } from '~/composables/useRoleLabel'

const props = defineProps({
    currentUser: {
        type: Object,
        default: null
    }
})

const emit = defineEmits(['logout', 'profile-updated'])
const route = useRoute()
const isProfileExpanded = ref(false)
const navigationScroller = ref(null)
const savedNavigationScroll = useState('mobile-navigation-scroll-left', () => 0)

const links = computed(() => [
    { label: 'Dashboard', to: '/dashboard', icon: 'dashboard' },
    ...(['superadmin', 'system_admin'].includes(props.currentUser?.role_name)
        ? [
            { label: 'Manage Users', to: '/users', icon: 'users' },
            { label: 'Manage Organizations', to: '/organizations', icon: 'organizations' }
        ]
        : []),
    { label: 'Manage Concerns', to: '/concerns', icon: 'concerns' },
    ...(props.currentUser?.role_name === 'superadmin'
        ? [
            { label: 'Concern Categories', to: '/concern-categories', icon: 'categories' },
            { label: 'Login History', to: '/login-history', icon: 'history' }
        ]
        : [])
])

function saveNavigationScroll() {
    if (navigationScroller.value) {
        savedNavigationScroll.value = navigationScroller.value.scrollLeft
    }
}

function scrollActiveLinkIntoView(behavior = 'smooth') {
    const scroller = navigationScroller.value

    if (!scroller) {
        return
    }

    const activeLink = scroller.querySelector('[aria-current="page"]')

    if (!activeLink) {
        scroller.scrollLeft = savedNavigationScroll.value
        return
    }

    const scrollerBounds = scroller.getBoundingClientRect()
    const linkBounds = activeLink.getBoundingClientRect()
    const linkLeft = linkBounds.left - scrollerBounds.left + scroller.scrollLeft
    const centeredScrollLeft = linkLeft - (scroller.clientWidth - activeLink.clientWidth) / 2

    scroller.scrollTo({
        left: Math.max(0, centeredScrollLeft),
        behavior: behavior === 'smooth' && window.matchMedia('(prefers-reduced-motion: reduce)').matches
            ? 'auto'
            : behavior
    })
}

watch(() => route.path, async () => {
    await nextTick()
    scrollActiveLinkIntoView()
})

onMounted(async () => {
    await nextTick()
    scrollActiveLinkIntoView('auto')
})
</script>

<template>
    <header class="sticky top-0 z-40 border-b border-blue-900/10 bg-white/95 shadow-sm backdrop-blur lg:hidden">
        <div class="flex items-center gap-3 px-4 py-3">
            <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-bold tracking-wide text-blue-950">Felcris Centrale</p>
                <p class="text-xs text-slate-500">Concern Management System</p>
            </div>
            <div v-if="currentUser" class="relative shrink-0" @keydown.esc="isProfileExpanded = false">
                <button
                    type="button"
                    data-tour="profile-menu-toggle"
                    class="group flex cursor-pointer items-center rounded-full focus:outline-none"
                    :aria-expanded="isProfileExpanded"
                    aria-controls="mobile-profile-details"
                    aria-haspopup="true"
                    :aria-label="isProfileExpanded ? 'Close profile menu' : 'Open profile menu'"
                    @click="isProfileExpanded = !isProfileExpanded"
                >
                    <span class="flex min-w-0 items-center gap-2">
                        <span class="min-w-0 text-right">
                            <span class="block max-w-32 truncate text-xs font-semibold text-slate-900">{{ [currentUser.first_name, currentUser.last_name].filter(Boolean).join(' ') || currentUser.username }}</span>
                            <span class="block max-w-32 truncate text-[10px] text-slate-500">{{ roleDisplayName(currentUser.role_name) }}</span>
                        </span>
                        <span class="rounded-full transition-transform duration-150 active:scale-95 group-focus-visible:ring-2 group-focus-visible:ring-blue-600 group-focus-visible:ring-offset-2">
                            <UserAvatar
                                :name="[currentUser.first_name, currentUser.last_name].filter(Boolean).join(' ') || currentUser.username"
                                :photo-url="currentUser.profile_photo"
                                size="h-10 w-10 text-sm"
                            />
                        </span>
                    </span>
                </button>

                <Transition
                    enter-active-class="transition duration-200 ease-out"
                    enter-from-class="translate-y-2 scale-95 opacity-0"
                    enter-to-class="translate-y-0 scale-100 opacity-100"
                    leave-active-class="transition duration-150 ease-in"
                    leave-from-class="translate-y-0 scale-100 opacity-100"
                    leave-to-class="translate-y-1 scale-[0.98] opacity-0"
                >
                    <div
                        v-if="isProfileExpanded"
                        data-tour="profile-menu-mobile"
                        id="mobile-profile-details"
                        class="absolute right-0 top-full z-50 mt-2 w-44 max-w-[calc(100vw-1.5rem)] origin-top-right rounded-xl border border-slate-200 bg-white p-2 shadow-xl sm:w-60"
                    >
                        <UserProfileControl
                            :current-user="currentUser"
                            mobile
                            :show-avatar="true"
                            :show-organization="true"
                            @logout="emit('logout')"
                            @profile-updated="emit('profile-updated', $event)"
                        />
                    </div>
                </Transition>
            </div>
        </div>

        <nav
            ref="navigationScroller"
            aria-label="Main navigation"
            class="mobile-navigation flex gap-1 overflow-x-auto px-3 pb-3"
            @scroll.passive="saveNavigationScroll"
        >
            <NuxtLink
                v-for="link in links"
                :key="link.to"
                :to="link.to"
                :aria-current="route.path === link.to ? 'page' : undefined"
                class="flex shrink-0 items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition"
                :class="route.path === link.to
                    ? 'bg-blue-900 text-white'
                    : 'text-slate-600 hover:bg-blue-50 hover:text-blue-950'"
            >
                <NavIcon :name="link.icon" />
                <span>{{ link.label }}</span>
            </NuxtLink>
        </nav>
    </header>
</template>
