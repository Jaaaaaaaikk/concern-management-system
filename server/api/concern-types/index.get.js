import db from '../../utils/db.js'
import { requireAuth } from '../../utils/require-auth.js'

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event)
  const includeInactive = getQuery(event).includeInactive === 'true'

  if (includeInactive && currentUser.role_name !== 'superadmin') {
    throw createError({
      statusCode: 403,
      statusMessage: 'Only superadmins can manage concern categories.'
    })
  }

  const [rows] = await db.query(`
    SELECT
      id,
      name,
      description,
      status,
      created_at
    FROM concern_types
    WHERE (? = 1 OR status = 'active')
    ORDER BY name ASC
  `, [includeInactive ? 1 : 0])

  const [assignmentRows] = await db.query(`
    SELECT
      organization_concern_types.concern_type_id,
      organizations.id AS organization_id,
      organizations.name AS organization_name,
      organizations.status AS organization_status
    FROM organization_concern_types
    INNER JOIN organizations
      ON organizations.id = organization_concern_types.organization_id
    WHERE organizations.deleted_at IS NULL
    ORDER BY organizations.name ASC
  `)

  const organizationsByConcernType = new Map()

  for (const assignment of assignmentRows) {
    const assignedOrganizations = organizationsByConcernType.get(assignment.concern_type_id) || []
    assignedOrganizations.push({
      id: assignment.organization_id,
      name: assignment.organization_name,
      status: assignment.organization_status
    })
    organizationsByConcernType.set(assignment.concern_type_id, assignedOrganizations)
  }

  const concernTypes = rows.map(concernType => ({
    ...concernType,
    assigned_organizations: organizationsByConcernType.get(concernType.id) || []
  }))

  return {
    success: true,
    concernTypes
  }
})