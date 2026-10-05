<script setup>
import { computed, ref, watch } from 'vue'

const props = defineProps({
    name: {
        type: String,
        default: ''
    },
    photoUrl: {
        type: String,
        default: ''
    },
    size: {
        type: String,
        default: 'h-9 w-9'
    }
})

const imageFailed = ref(false)

const initials = computed(() => {
    const letters = props.name
        .trim()
        .split(/\s+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((part) => part.charAt(0))
        .join('')
        .toUpperCase()

    return letters || 'U'
})

watch(
    () => props.photoUrl,
    () => {
        imageFailed.value = false
    }
)
</script>

<template>
    <span
        class="inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full bg-emerald-100 font-semibold text-emerald-900 ring-1 ring-emerald-900/10"
        :class="size"
        :aria-label="`${name || 'User'} profile photo`"
    >
        <img
            v-if="photoUrl && !imageFailed"
            :src="photoUrl"
            :alt="`${name || 'User'} profile photo`"
            class="h-full w-full object-cover"
            @error="imageFailed = true"
        />
        <span v-else aria-hidden="true">{{ initials }}</span>
    </span>
</template>
