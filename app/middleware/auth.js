export default defineNuxtRouteMiddleware(async () => {
  try {
    const headers = import.meta.server
      ? useRequestHeaders(['cookie'])
      : undefined

    await $fetch('/api/auth/me', {
      headers
    })
  } catch (error) {
    return navigateTo('/login')
  }
})