<script setup>
const currentYear = new Date().getFullYear()

defineProps({
    showIctTeamLink: {
        type: Boolean,
        default: true
    }
})
</script>

<template>
    <footer class="border-t border-slate-200 bg-white px-4 py-4 text-center text-xs leading-5 text-slate-500 sm:px-6">
        © {{ currentYear }} Felcris Hotels &amp; Resorts Corporation. All rights reserved.
        <span class="hidden sm:inline"> · </span>
        <NuxtLink
            v-if="showIctTeamLink"
            to="/ict-team"
            aria-label="ICT Department team"
            class="group relative inline-block rounded-sm text-slate-500 outline-none after:absolute after:inset-x-0 after:-bottom-0.5 after:h-px after:origin-left after:scale-x-0 after:bg-slate-400 after:transition-transform after:duration-200 hover:text-slate-700 hover:after:scale-x-100 focus-visible:text-slate-700 focus-visible:ring-2 focus-visible:ring-slate-400/50"
        >
            <span aria-hidden="true">ICT Department</span>
        </NuxtLink>
        <span v-else class="block sm:inline">ICT Department</span>
    </footer>
</template>
