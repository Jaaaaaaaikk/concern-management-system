<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

const props = defineProps({
    length: {
        type: Number,
        default: 8
    }
})

const characters = '01ABCDEF#$%&*<>?!'
const symbols = ref(Array.from(
    { length: props.length },
    (_, index) => characters[(index * 7 + 3) % characters.length]
))
let symbolTimer = null

function changeSymbols() {
    const nextSymbols = [...symbols.value]

    for (let change = 0; change < 4; change++) {
        const index = Math.floor(Math.random() * nextSymbols.length)
        nextSymbols[index] = characters[Math.floor(Math.random() * characters.length)]
    }

    symbols.value = nextSymbols
}

onMounted(() => {
    if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        symbolTimer = setInterval(changeSymbols, 65)
    }
})

onBeforeUnmount(() => {
    if (symbolTimer) {
        clearInterval(symbolTimer)
    }
})
</script>

<template>
    <div class="code-skeleton" aria-hidden="true">
        <span v-for="(symbol, index) in symbols" :key="index" class="code-skeleton__character">
            {{ symbol }}
        </span>
    </div>
</template>

<style scoped>
.code-skeleton {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.04rem;
    overflow: hidden;
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    font-size: 0.75rem;
    font-weight: 800;
    line-height: 1;
    white-space: nowrap;
}

.code-skeleton__character {
    display: inline-block;
    background: linear-gradient(100deg, #94a3b8 0%, #64748b 42%, #f8fafc 50%, #64748b 58%, #94a3b8 100%);
    background-size: 200% 100%;
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    animation:
        code-skeleton-shimmer 0.65s linear infinite,
        code-skeleton-pulse 0.55s ease-in-out infinite;
}

@keyframes code-skeleton-shimmer {
    from {
        background-position: 100% 50%;
    }

    to {
        background-position: -100% 50%;
    }
}

@keyframes code-skeleton-pulse {
    0%,
    100% {
        opacity: 0.65;
    }

    50% {
        opacity: 1;
    }
}

@media (prefers-reduced-motion: reduce) {
    .code-skeleton__character {
        animation: none;
        opacity: 1;
    }
}
</style>
