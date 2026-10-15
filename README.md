# Nuxt Minimal Starter

Look at the [Nuxt documentation](https://nuxt.com/docs/getting-started/introduction) to learn more.

## Setup

Make sure to install dependencies:

```bash
# npm
npm install

# pnpm
pnpm install

# yarn
yarn install

# bun
bun install
```

### Existing database migration

Before running this version against an existing database, apply
[`database/migrations/20261005_add_user_profile_photo.sql`](./database/migrations/20261005_add_user_profile_photo.sql)
to add the nullable `users.profile_photo` column. Fresh databases created from
`concern_management.sql` already include this column.

## Development Server

Start the development server on `http://localhost:3000`:

```bash
# npm
npm run dev

# pnpm
pnpm dev

# yarn
yarn dev

# bun
bun run dev
```

## Production

Build the application for production:

```bash
# npm
npm run build

# pnpm
pnpm build

# yarn
yarn build

# bun
bun run build
```

### Private concern attachments

Concern images are stored outside Nuxt's public static directory in
`data/uploads/concerns` by default. Keep this directory with the deployed
application data and include it in backups. You can set `CONCERN_UPLOAD_DIR` in
the production environment to an absolute persistent directory outside the
application's `public` folder. On server startup, existing concern images in
`public/uploads/concerns` and `.output/public/uploads/concerns` are migrated to
that private directory. The concern API then serves them only to signed-in users
who are allowed to view that concern.

Do not delete the private upload directory when updating the app. Back it up
alongside the database. User profile photos are also stored privately in
`data/uploads/users` by default (`PROFILE_PHOTO_DIR` can override this location).
Existing profile photos are migrated from the public uploads directories on
startup and are served only to signed-in users.

### Login session retention

Expired or revoked login-session records are permanently deleted after six
months. The server runs this cleanup once at startup and then once per day; active
sessions are excluded. Apply
[`database/migrations/20261015_add_session_retention_index.sql`](./database/migrations/20261015_add_session_retention_index.sql)
to existing databases to support the cleanup query efficiently. Database backups
remain the recovery path for records deleted by retention.

Locally preview production build:

```bash
# npm
npm run preview

# pnpm
pnpm preview

# yarn
yarn preview

# bun
bun run preview
```

Check out the [deployment documentation](https://nuxt.com/docs/getting-started/deployment) for more information.
