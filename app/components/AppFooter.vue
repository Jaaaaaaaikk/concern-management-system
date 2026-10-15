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
            class="block rounded-sm font-medium text-blue-800 transition-colors hover:text-teal-700 hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-teal-600 sm:inline"
        >
            ICT Department
        </NuxtLink>
        <span v-else class="block sm:inline">ICT Department</span>
    </footer>
</template>
