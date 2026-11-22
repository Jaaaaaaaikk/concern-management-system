<script setup>
import { computed } from 'vue'

const props = defineProps({
    category: { type: Object, default: null },
    loading: { type: Boolean, default: false }
})

const emit = defineEmits(['confirm', 'cancel'])

const isActive = computed(() => props.category?.status === 'active')
const title = computed(() => isActive.value ? 'Remove category?' : 'Restore category?')
const message = computed(() => {
    if (!props.category) return ''
    return isActive.value
        ? `“${props.category.name}” will no longer be available for new concerns. Existing concerns will keep this category.`
        : `“${props.category.name}” will become available for new concerns again.`
})
</script>

<template>
    <ConfirmActionModal
        :show="Boolean(props.category)"
        :title="title"
        :message="message"
        :confirm-label="isActive ? 'Remove category' : 'Restore category'"
        :loading="props.loading"
        :tone="isActive ? 'danger' : 'primary'"
        @confirm="emit('confirm')"
        @cancel="emit('cancel')"
    />
</template>
