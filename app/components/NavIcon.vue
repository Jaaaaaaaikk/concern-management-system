<script setup>
defineProps({
    name: {
        type: String,
        required: true
    }
})
</script>

<template>
    <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.7"
        stroke="currentColor"
        class="h-5 w-5 shrink-0"
        aria-hidden="true"
    >
        <path
            v-if="name === 'dashboard'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M3.75 3.75h6.5v6.5h-6.5v-6.5Zm10 0h6.5v6.5h-6.5v-6.5Zm-10 10h6.5v6.5h-6.5v-6.5Zm10 0h6.5v6.5h-6.5v-6.5Z"
        />
        <path
            v-else-if="name === 'organizations'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M3.75 20.25h16.5M5.25 20.25V5.5L12 3.25v17m0-12.75 6.75-2.25v15M8.25 8.25v.01M8.25 11.25v.01M8.25 14.25v.01M14.25 9.75v.01M17.25 8.75v.01M14.25 12.75v.01M17.25 11.75v.01M14.25 15.75v.01M17.25 14.75v.01"
        />
        <path
            v-else-if="name === 'users'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M15 19.5v-1.125a3.375 3.375 0 0 0-3.375-3.375h-5.25A3.375 3.375 0 0 0 3 18.375V19.5m14.25-4.5a3.375 3.375 0 0 1 3.375 3.375V19.5M12.375 7.875a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm6 1.125a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
        />
        <path
            v-else-if="name === 'history'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 6.75v5.25l3.75 2.25M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
        />
        <path
            v-else
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 3.75 3.75 7.5v5.25c0 4.2 3.52 7.1 8.25 7.5 4.73-.4 8.25-3.3 8.25-7.5V7.5L12 3.75Zm0 5.25v4.5m0 3h.008"
        />
    </svg>
</template>
