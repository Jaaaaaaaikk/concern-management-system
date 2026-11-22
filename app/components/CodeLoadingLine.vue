<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

const props = defineProps({
    label: {
        type: String,
        default: 'Loading...'
    }
})

const code = ref('01 A7# 10B::SYSTEM_LOAD::0F%01')
const codeCharacters = '01ABCDEF#$%&*<>?!'
let codeTimer = null

function changeCodeCharacters() {
    const characters = code.value.split('')
    const editableIndexes = characters
        .map((character, index) => character === ' ' ? -1 : index)
        .filter(index => index !== -1)

    for (let changes = 0; changes < 7; changes++) {
        const index = editableIndexes[Math.floor(Math.random() * editableIndexes.length)]
        characters[index] = codeCharacters[Math.floor(Math.random() * codeCharacters.length)]
    }

    code.value = characters.join('')
}

onMounted(() => {
    if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        codeTimer = setInterval(changeCodeCharacters, 55)
    }
})

onBeforeUnmount(() => {
    if (codeTimer) {
        clearInterval(codeTimer)
    }
})
</script>

<template>
    <span class="code-loading-status" role="status" aria-live="polite" :aria-label="props.label">
        <span class="code-loading-line" aria-hidden="true">
            <span
                v-for="(character, index) in code"
                :key="index"
                class="code-loading-character"
            >{{ character === ' ' ? '\u00a0' : character }}</span>
        </span>
    </span>
</template>

<style scoped>
.code-loading-status {
    display: inline-block;
    max-width: 100%;
    vertical-align: middle;
}

.code-loading-line {
    display: inline-block;
    max-width: 100%;
    overflow: hidden;
    color: #94a3b8;
    background: linear-gradient(100deg, #64748b 0%, #cbd5e1 38%, #f8fafc 50%, #cbd5e1 62%, #64748b 100%);
    background-size: 200% 100%;
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 0.12em;
    white-space: nowrap;
    animation:
        code-loading-shimmer 0.65s linear infinite,
        code-loading-pulse 0.55s ease-in-out infinite;
}

.code-loading-character {
    display: inline-block;
    min-width: 0.62em;
}

@keyframes code-loading-shimmer {
    from {
        background-position: 100% 50%;
    }

    to {
        background-position: -100% 50%;
    }
}

@keyframes code-loading-pulse {
    0%,
    100% {
        opacity: 0.72;
        transform: scale(0.99);
    }

    50% {
        opacity: 1;
        transform: scale(1.03);
    }
}

@media (prefers-reduced-motion: reduce) {
    .code-loading-line {
        animation: none;
        opacity: 1;
    }
}
</style>
