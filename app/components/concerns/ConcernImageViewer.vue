<script setup>
const props = defineProps({
    show: {
        type: Boolean,
        default: false
    },
    image: {
        type: Object,
        default: null
    }
})

const emit = defineEmits(['close'])
</script>

<template>
    <div v-if="show && image" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/85 p-4" @click.self="emit('close')">
        <div class="relative flex max-h-[95vh] max-w-[95vw] flex-col items-center">
            <button type="button" @click="emit('close')"
                aria-label="Close image viewer"
                class="group absolute -right-2 -top-2 z-10 flex h-10 w-10 cursor-pointer items-center justify-center text-3xl leading-none text-red-300 transition-colors duration-200 hover:text-red-400"
                title="Close image">
                <span class="transition-all duration-200 group-hover:-translate-x-1 group-hover:opacity-0">×</span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2"
                    stroke="currentColor" aria-hidden="true"
                    class="absolute h-6 w-6 translate-x-1 opacity-0 transition-all duration-200 group-hover:translate-x-0 group-hover:opacity-100">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14.5 5.5 8 12l6.5 6.5M8.5 12H20" />
                </svg>
            </button>

            <img :src="image.url" :alt="image.name"
                class="max-h-[85vh] max-w-[90vw] rounded-xl bg-white object-contain shadow-2xl" />

            <p class="mt-3 max-w-[90vw] truncate text-center text-sm font-medium text-white"
                :title="image.name">
                {{ image.name }}
            </p>
        </div>
    </div>
</template>
