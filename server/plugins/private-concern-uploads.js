import { migratePublicConcernUploads } from '../utils/concern-uploads.js'
import { migratePublicProfilePhotos } from '../utils/profile-photos.js'

export default defineNitroPlugin(async () => {
  await migratePublicConcernUploads()
  await migratePublicProfilePhotos()
})
