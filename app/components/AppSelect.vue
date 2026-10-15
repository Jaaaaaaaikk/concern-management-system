<script setup>
import { computed } from 'vue'
import {
    SelectContent,
    SelectItem,
    SelectItemIndicator,
    SelectItemText,
    SelectPortal,
    SelectRoot,
    SelectTrigger,
    SelectValue,
    SelectViewport
} from 'reka-ui'

defineOptions({ inheritAttrs: false })

const EMPTY_OPTION_VALUE = '__reka_select_empty_option__'

const props = defineProps({
    modelValue: {
        type: [String, Number],
        default: ''
    },
    options: {
        type: Array,
        default: () => []
    },
    placeholder: {
        type: String,
        default: 'Select an option'
    },
    name: {
        type: String,
        default: undefined
    },
    id: {
        type: String,
        default: undefined
    },
    required: {
        type: Boolean,
        default: false
    },
    disabled: {
        type: Boolean,
        default: false
    },
    compact: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits(['update:modelValue', 'change'])

const normalizedOptions = computed(() => props.options.map((option) => ({
    label: String(option.label ?? ''),
    value: String(option.value ?? '') === ''
        ? EMPTY_OPTION_VALUE
        : String(option.value),
    disabled: Boolean(option.disabled)
})))

const selectedValue = computed({
    get() {
        return props.modelValue === '' || props.modelValue === null || props.modelValue === undefined
            ? null
            : String(props.modelValue)
    },
    set(value) {
        const nextValue = value === EMPTY_OPTION_VALUE
            ? ''
            : String(value ?? '')

        emit('update:modelValue', nextValue)
        emit('change', { target: { value: nextValue } })
    }
})
</script>

<template>
    <SelectRoot
        v-model="selectedValue"
        :name="props.name"
        :required="props.required"
        :disabled="props.disabled"
    >
        <SelectTrigger
            v-bind="$attrs"
            :id="props.id"
            :disabled="props.disabled"
            class="group inline-flex cursor-pointer items-center justify-between gap-3 rounded-lg text-left text-sm font-medium text-slate-700 outline-none transition duration-150 data-placeholder:text-slate-400 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
            :class="props.compact
                ? 'min-h-0 min-w-0 flex-1 border-0 bg-transparent px-0 py-1 shadow-none hover:border-transparent focus:border-transparent focus:ring-0'
                : 'min-h-11 w-full border border-slate-300 bg-white px-3.5 py-2.5 shadow-sm hover:border-teal-400 focus:border-teal-600 focus:ring-4 focus:ring-teal-500/15 disabled:bg-slate-100 disabled:shadow-none'"
        >
            <SelectValue :placeholder="props.placeholder" class="min-w-0 flex-1 truncate" />
            <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.8"
                stroke="currentColor"
                class="h-4 w-4 shrink-0 text-slate-400 transition-transform duration-150 group-data-[state=open]:rotate-180 group-data-[state=open]:text-teal-700"
                aria-hidden="true"
            >
                <path stroke-linecap="round" stroke-linejoin="round" d="m6 9 6 6 6-6" />
            </svg>
        </SelectTrigger>

        <SelectPortal>
            <SelectContent
                position="popper"
                side="bottom"
                :side-offset="6"
                align="start"
                :collision-padding="8"
                class="z-200 overflow-hidden rounded-xl border border-slate-200 bg-white py-1 shadow-xl shadow-slate-950/15 outline-none"
                :style="{ minWidth: 'var(--reka-select-trigger-width)' }"
            >
                <SelectViewport class="max-h-72 overflow-y-auto p-1">
                    <SelectItem
                        v-for="option in normalizedOptions"
                        :key="option.value"
                        :value="option.value"
                        :disabled="option.disabled"
                        :text-value="option.label"
                        class="relative flex min-h-9 cursor-pointer select-none items-center justify-between gap-3 rounded-lg px-3 py-2 text-sm text-slate-700 outline-none transition-colors data-highlighted:bg-teal-50 data-highlighted:text-teal-950 data-[state=checked]:bg-teal-700 data-[state=checked]:font-semibold data-[state=checked]:text-white data-disabled:pointer-events-none data-disabled:text-slate-400"
                    >
                        <SelectItemText class="min-w-0 flex-1 truncate">
                            {{ option.label }}
                        </SelectItemText>
                        <SelectItemIndicator class="shrink-0 text-current" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.4" stroke="currentColor" class="h-4 w-4">
                                <path stroke-linecap="round" stroke-linejoin="round" d="m5 12 4 4L19 6" />
                            </svg>
                        </SelectItemIndicator>
                    </SelectItem>
                </SelectViewport>
            </SelectContent>
        </SelectPortal>
    </SelectRoot>
</template>
