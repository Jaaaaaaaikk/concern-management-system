<script setup>
import { computed } from 'vue'

const props = defineProps({
    currentUser: {
        type: Object,
        default: null
    }
})

const emit = defineEmits(['logout', 'profile-updated'])
const route = useRoute()

const links = computed(() => [
    { label: 'Dashboard', to: '/dashboard', icon: 'dashboard' },
    ...(props.currentUser?.role_name === 'superadmin'
        ? [
            { label: 'Organizations', to: '/organizations', icon: 'organizations' },
            { label: 'Users', to: '/users', icon: 'users' },
            { label: 'Login History', to: '/login-history', icon: 'history' }
        ]
        : []),
    { label: 'Concerns', to: '/concerns', icon: 'concerns' }
])
</script>

<template>
    <header class="sticky top-0 z-40 border-b border-emerald-900/10 bg-white/95 shadow-sm backdrop-blur lg:hidden">
        <div class="flex items-center gap-3 px-4 py-3">
            <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-bold tracking-wide text-emerald-950">Felcris Centrale</p>
                <p class="text-xs text-slate-500">Concern Management System</p>
            </div>
            <button
                type="button"
                class="shrink-0 cursor-pointer rounded-lg border border-emerald-900/20 px-3 py-2 text-xs font-semibold text-emerald-950 transition hover:bg-emerald-50"
                @click="emit('logout')"
            >
                Logout
            </button>
        </div>

        <div v-if="currentUser" class="border-y border-slate-100 bg-slate-50/80 px-4 py-2.5">
            <UserProfileControl
                :current-user="currentUser"
                mobile
                @profile-updated="emit('profile-updated', $event)"
            />
        </div>

        <nav aria-label="Main navigation" class="flex gap-1 overflow-x-auto px-3 pb-3">
            <NuxtLink
                v-for="link in links"
                :key="link.to"
                :to="link.to"
                :aria-current="route.path === link.to ? 'page' : undefined"
                class="flex shrink-0 items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition"
                :class="route.path === link.to
                    ? 'bg-emerald-900 text-white'
                    : 'text-slate-600 hover:bg-emerald-50 hover:text-emerald-950'"
            >
                <NavIcon :name="link.icon" />
                <span>{{ link.label }}</span>
            </NuxtLink>
        </nav>
    </header>
</template>
