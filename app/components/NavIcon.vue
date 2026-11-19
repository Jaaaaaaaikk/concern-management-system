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
            d="M3.75 20.25h16.5M5.25 20.25V6a1.5 1.5 0 0 1 1.5-1.5h10.5A1.5 1.5 0 0 1 18.75 6v14.25M8.25 8.25h.01M11.25 8.25h.01M14.25 8.25h.01M8.25 11.25h.01M11.25 11.25h.01M14.25 11.25h.01M8.25 14.25h.01M11.25 14.25h.01M14.25 14.25h.01M10.5 20.25v-3.75h3v3.75"
        />
        <path
            v-else-if="name === 'users'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M19.5 20.25v-1.5a4.5 4.5 0 0 0-4.5-4.5H9a4.5 4.5 0 0 0-4.5 4.5v1.5m10.5-12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z"
        />
        <path
            v-else-if="name === 'history'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 6.75v5.25l3.75 2.25M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
        />
        <path
            v-else-if="name === 'categories'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M3.75 12.75 11.25 20.25a1.5 1.5 0 0 0 2.12 0l6.88-6.88a1.5 1.5 0 0 0 .44-1.06V5.25A1.5 1.5 0 0 0 19.19 3.75h-7.06a1.5 1.5 0 0 0-1.06.44l-7.32 7.32a.88.88 0 0 0 0 1.24Z"
        />
        <circle
            v-if="name === 'categories'"
            cx="15.75"
            cy="8.25"
            r="1.125"
        />
        <path
            v-if="name === 'concerns'"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 3.75 3.75 7.5v5.25c0 4.2 3.52 7.1 8.25 7.5 4.73-.4 8.25-3.3 8.25-7.5V7.5L12 3.75Zm0 5.25v4.5m0 3h.008"
        />
    </svg>
</template>
