<script setup>
const currentUser = useState('current-user', () => null)

const teamMembers = [
    {
        name: 'Jaikhene Joel F. Villar',
        role: 'Main Programmer',
        initials: 'JV',
        accent: 'from-blue-700 to-indigo-600',
        description: 'Leads the application development, turning the system requirements into reliable features and workflows.'
    },
    {
        name: 'Jerick John S Espina',
        role: 'UI/UX',
        initials: 'JE',
        accent: 'from-violet-600 to-fuchsia-500',
        description: 'Shapes the user experience and interface, helping make the system clear, approachable, and easy to use.'
    },
    {
        name: 'Laimar Agulay',
        role: 'Planner',
        initials: 'LA',
        accent: 'from-teal-600 to-emerald-500',
        description: 'Organizes project goals, priorities, and coordination to keep the team focused on the work ahead.'
    },
    {
        name: 'Mark Famador',
        role: 'Deployment Specialist',
        initials: 'MF',
        accent: 'from-amber-500 to-orange-500',
        description: 'Coordinates deployment and release activities to help deliver the system smoothly into its environment.'
    },
    {
        name: 'Ronnie Aton',
        role: 'ICT Staff',
        initials: 'RA',
        accent: 'from-cyan-600 to-blue-600',
        description: 'Provides ICT support and practical guidance that helps the team deliver a solution for the organization.'
    }
]
</script>

<template>
    <main class="relative isolate min-h-screen overflow-hidden bg-slate-50 text-slate-900">
        <div class="pointer-events-none absolute inset-x-0 top-0 -z-10 h-112 bg-linear-to-br from-blue-950 via-blue-900 to-teal-700"></div>
        <div class="pointer-events-none absolute -right-28 top-20 -z-10 h-80 w-80 rounded-full bg-cyan-300/15 blur-3xl"></div>
        <div class="pointer-events-none absolute -left-32 top-64 -z-10 h-80 w-80 rounded-full bg-blue-300/15 blur-3xl"></div>

        <header class="mx-auto flex w-full max-w-7xl items-center justify-between px-4 py-5 text-white sm:px-6 lg:px-8">
            <NuxtLink :to="currentUser ? '/dashboard' : '/login'" class="group inline-flex items-center gap-3 rounded-lg transition duration-200 hover:scale-[1.02] focus:outline-none focus-visible:ring-2 focus-visible:ring-white motion-reduce:transition-none motion-reduce:hover:scale-100">
                <span class="flex h-10 w-10 items-center justify-center rounded-xl border border-white/20 bg-white/10 shadow-lg backdrop-blur">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="h-6 w-6" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 20.25h16.5M5.25 20.25V5.5L12 3.25v17m0-12.75 6.75-2.25v15M8.25 8.25v.01M8.25 11.25v.01M8.25 14.25v.01M14.25 9.75v.01M17.25 8.75v.01M14.25 12.75v.01M17.25 11.75v.01M14.25 15.75v.01M17.25 14.75v.01" />
                    </svg>
                </span>
                <span>
                    <span class="block text-sm font-bold tracking-wide">Felcris Centrale</span>
                    <span class="block text-xs text-blue-100/80">Concern Management System</span>
                </span>
            </NuxtLink>

            <NuxtLink :to="currentUser ? '/dashboard' : '/login'" class="inline-flex items-center gap-2 rounded-lg border border-white/20 bg-white/10 px-3.5 py-2 text-sm font-semibold text-white shadow-sm backdrop-blur transition duration-200 hover:scale-[1.03] hover:bg-white/20 focus:outline-none focus-visible:ring-2 focus-visible:ring-white motion-reduce:transition-none motion-reduce:hover:scale-100">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="h-4 w-4" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
                </svg>
                {{ currentUser ? 'Back to dashboard' : 'Sign in' }}
            </NuxtLink>
        </header>

        <section class="mx-auto w-full max-w-7xl px-4 pb-14 pt-10 sm:px-6 sm:pb-20 sm:pt-16 lg:px-8">
            <div class="mx-auto max-w-3xl text-center text-white">
                <span class="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3.5 py-1.5 text-xs font-semibold uppercase tracking-[0.16em] text-cyan-100 shadow-sm backdrop-blur">
                    <span class="h-1.5 w-1.5 rounded-full bg-teal-300"></span>
                    Meet the team
                </span>
                <h1 class="mt-5 text-3xl font-bold tracking-tight sm:text-4xl lg:text-5xl">The ICT Department</h1>
                <p class="mx-auto mt-4 max-w-2xl text-sm leading-6 text-blue-100 sm:text-base sm:leading-7">
                    Meet the five team members behind the Concern Management System, bringing together planning, design, development, deployment, and ICT support.
                </p>
            </div>

            <div class="mx-auto mt-10 grid max-w-6xl gap-4 sm:mt-14 sm:grid-cols-2 sm:gap-5 lg:grid-cols-3">
                <article
                    v-for="(member, index) in teamMembers"
                    :key="member.name"
                    class="group relative overflow-hidden rounded-2xl border border-slate-200/80 bg-white p-5 shadow-lg shadow-slate-900/5 transition duration-200 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-900/10 sm:p-6"
                    :class="index === 0 && teamMembers.length % 3 === 2 ? 'lg:col-start-1' : ''"
                >
                    <div class="absolute inset-x-0 top-0 h-1 bg-linear-to-r" :class="member.accent"></div>
                    <div class="flex items-start gap-4">
                        <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-linear-to-br text-base font-bold text-white shadow-md ring-4 ring-slate-50 transition duration-200 group-hover:scale-105" :class="member.accent" aria-hidden="true">
                            {{ member.initials }}
                        </div>
                        <div class="min-w-0 pt-0.5">
                            <p class="text-[11px] font-bold uppercase tracking-[0.14em] text-teal-700">{{ member.role }}</p>
                            <h2 class="mt-1.5 text-lg font-bold leading-snug text-slate-900">{{ member.name }}</h2>
                        </div>
                    </div>
                    <p class="mt-5 text-sm leading-6 text-slate-600">{{ member.description }}</p>
                    <div class="mt-5 flex items-center gap-2 border-t border-slate-100 pt-4 text-xs font-medium text-slate-400">
                        <span class="h-1.5 w-1.5 rounded-full bg-teal-500"></span>
                        Felcris Centrale · ICT
                    </div>
                </article>
            </div>

            <div class="mx-auto mt-10 max-w-4xl rounded-2xl border border-blue-100 bg-white/90 p-5 text-center shadow-lg shadow-slate-900/5 backdrop-blur sm:mt-12 sm:p-7">
                <p class="text-xs font-bold uppercase tracking-[0.16em] text-blue-800">Working together</p>
                <p class="mt-2 text-sm leading-6 text-slate-600 sm:text-base">
                    This team brings the Concern Management System from planning and design through development, deployment, and ongoing ICT support.
                </p>
            </div>
        </section>

        <AppFooter :show-ict-team-link="false" />
    </main>
</template>
