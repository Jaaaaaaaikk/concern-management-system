<script setup>
const currentYear = new Date().getFullYear()
</script>

<template>
    <footer class="border-t border-slate-200 bg-white px-4 py-4 text-center text-xs leading-5 text-slate-500 sm:px-6">
        © {{ currentYear }} Felcris Hotels &amp; Resorts Corporation. All rights reserved.
        <span class="hidden sm:inline"> · </span>
        <span class="block sm:inline">ICT Department</span>
    </footer>
</template>
