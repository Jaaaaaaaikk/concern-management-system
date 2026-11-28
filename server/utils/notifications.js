const ORGANIZATION_ROLES = ['concern_handler', 'requestor']
const GLOBAL_ROLES = ['superadmin', 'system_admin', 'system_monitor']

/**
 * Creates notifications for active members of the concern's creator and
 * assigned organizations. Active system monitors also receive new-concern
 * notifications; other global-role users are notified after participating.
 */
export async function notifyConcernParticipants(executor, {
  concernId,
  actorUserId,
  eventType,
  title,
  message
}) {
  try {
    await executor.query(
    `
      INSERT INTO in_app_notifications (
        user_id,
        event_type,
        concern_id,
        actor_user_id,
        title,
        message
      )
      SELECT DISTINCT
        recipient.id,
        ?,
        concern.id,
        ?,
        ?,
        ?
      FROM concerns concern
      INNER JOIN users creator
        ON creator.id = concern.created_by
      INNER JOIN users recipient
        ON recipient.id <> COALESCE(?, 0)
       AND recipient.deleted_at IS NULL
       AND recipient.status = 'active'
      INNER JOIN roles recipient_role
        ON recipient_role.id = recipient.role_id
      WHERE concern.id = ?
        AND (
          (
            recipient_role.name IN ('concern_handler', 'requestor')
            AND recipient.organization_id IN (
              creator.organization_id,
              concern.assigned_organization_id
            )
          )
          OR (
            recipient_role.name IN ('superadmin', 'system_admin', 'system_monitor')
            AND EXISTS (
              SELECT 1
              FROM concern_comments participant_comment
              WHERE participant_comment.concern_id = concern.id
                AND participant_comment.user_id = recipient.id
            )
          )
          OR (
            recipient_role.name = 'system_monitor'
            AND ? = 'concern_created'
          )
        )
      `,
      [eventType, actorUserId, title, message, actorUserId, concernId, eventType]
    )
  } catch (error) {
    console.error('Failed to create concern notifications:', error)
  }
}

/** Notify active superadmins about create/edit operations performed by a System Administrator. */
export async function notifySuperadminsOfSystemAdminAction(executor, {
  actorUserId,
  actorRole,
  eventType,
  title,
  message
}) {
  if (actorRole !== 'system_admin') {
    return
  }

  try {
    await executor.query(
    `
      INSERT INTO in_app_notifications (
        user_id,
        event_type,
        actor_user_id,
        title,
        message
      )
      SELECT
        recipient.id,
        ?,
        ?,
        ?,
        ?
      FROM users recipient
      INNER JOIN roles recipient_role
        ON recipient_role.id = recipient.role_id
      WHERE recipient_role.name = 'superadmin'
        AND recipient.deleted_at IS NULL
        AND recipient.status = 'active'
        AND recipient.id <> ?
    `,
      [eventType, actorUserId, title, message, actorUserId]
    )
  } catch (error) {
    console.error('Failed to create Superadmin notification:', error)
  }
}

export const GLOBAL_NOTIFICATION_ROLES = GLOBAL_ROLES
export const ORGANIZATION_NOTIFICATION_ROLES = ORGANIZATION_ROLES

export function formatActorDisplayName(actor = {}) {
  const name = [actor.first_name, actor.last_name]
    .map(value => String(value || '').trim())
    .filter(Boolean)
    .join(' ') || String(actor.username || '').trim()
  const roleLabels = {
    system_admin: 'System Administrator',
    system_monitor: 'System Monitor',
    concern_handler: 'Concern Handler',
    requestor: 'Requestor'
  }
  const roleName = String(actor.role_name || '').toLowerCase()

  if (roleName === 'superadmin') {
    return 'Superadmin'
  }

  if (['concern_handler', 'requestor'].includes(roleName)) {
    const organizationName = String(actor.organization_name || '').trim()
    const identity = name || roleLabels[roleName]
    return organizationName
      ? `${identity} — ${organizationName}`
      : `${identity} (${roleLabels[roleName]})`
  }

  const roleLabel = roleLabels[roleName]
  if (roleLabel) {
    return name ? `${name} (${roleLabel})` : roleLabel
  }

  return name || String(actor.name || 'A user').trim()
}
