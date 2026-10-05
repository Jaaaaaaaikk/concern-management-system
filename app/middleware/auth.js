export default defineNuxtRouteMiddleware(async () => {
  const currentUser = useState('current-user', () => null)

  try {
    const headers = import.meta.server
      ? useRequestHeaders(['cookie'])
      : undefined

    const response = await $fetch('/api/auth/me', {
      headers,
      cache: 'no-store'
    })

    currentUser.value = response.user
  } catch (error) {
    const statusCode = error?.statusCode ?? error?.response?.status

    if (statusCode === 401) {
      currentUser.value = null
      return navigateTo('/login')
    }

    throw error
  }
})