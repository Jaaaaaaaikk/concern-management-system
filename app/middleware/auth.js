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
      const statusMessage = error?.data?.statusMessage ?? error?.statusMessage

      if (import.meta.client && statusMessage === 'SESSION_REVOKED') {
        await $fetch('/api/auth/logout', { method: 'POST' }).catch(() => {})
      }

      const revokedQuery = statusMessage === 'SESSION_REVOKED' ? '?revoked=1' : ''

      return navigateTo(`/login${revokedQuery}`)
    }

    throw error
  }
})