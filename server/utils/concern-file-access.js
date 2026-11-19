const GLOBAL_VIEWER_ROLES = ['superadmin', 'system_admin', 'system_monitor']
const ORGANIZATION_VIEWER_ROLES = ['concern_handler', 'requestor']

export function canReadConcernFile(user, concern) {
  if (GLOBAL_VIEWER_ROLES.includes(user?.role_name)) return true

  const userId = Number(user?.id)
  const creatorId = Number(concern?.created_by)
  const userOrganizationId = user?.organization_id == null
    ? null
    : Number(user.organization_id)
  const creatorOrganizationId = concern?.creator_organization_id == null
    ? null
    : Number(concern.creator_organization_id)
  const assignedOrganizationId = concern?.assigned_organization_id == null
    ? null
    : Number(concern.assigned_organization_id)

  if (concern?.deleted_at) {
    return (
      (user?.role_name === 'concern_handler' &&
        userOrganizationId !== null &&
        userOrganizationId === creatorOrganizationId) ||
      (user?.role_name === 'requestor' && userId === creatorId)
    )
  }

  if (!ORGANIZATION_VIEWER_ROLES.includes(user?.role_name)) return false

  const isCreator = userId === creatorId
  const isCreatorOrganization =
    userOrganizationId !== null && userOrganizationId === creatorOrganizationId
  const isAssignedOrganization =
    userOrganizationId !== null && userOrganizationId === assignedOrganizationId

  if (!isCreator && !isCreatorOrganization && !isAssignedOrganization) return false

  if (
    user?.role_name !== 'superadmin' &&
    ((creatorOrganizationId !== null && concern.creator_organization_deleted_at) ||
      (assignedOrganizationId !== null && concern.assigned_organization_deleted_at))
  ) {
    return false
  }

  return true
}
