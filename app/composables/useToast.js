export function useToast() {
    const toast = useState('app-toast', () => ({
        id: 0,
        type: 'success',
        message: ''
    }))

    function showToast(message, type = 'success') {
        toast.value = {
            id: toast.value.id + 1,
            type,
            message
        }
    }

    function dismissToast(id) {
        if (toast.value.id === id) {
            toast.value = {
                ...toast.value,
                message: ''
            }
        }
    }

    return {
        toast,
        showToast,
        dismissToast
    }
}
