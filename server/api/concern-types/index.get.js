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
      category.id,
      category.name,
      category.description,
      category.status,
      category.created_at,
      category.assigned_organization_id,
      receiver.name AS assigned_organization_name,
      receiver.status AS assigned_organization_status,
      receiver.organization_type AS assigned_organization_type
    FROM concern_types category
    LEFT JOIN organizations receiver
      ON receiver.id = category.assigned_organization_id
     AND receiver.deleted_at IS NULL
    WHERE (? = 1 OR category.status = 'active')
    ORDER BY category.name ASC
  `, [includeInactive ? 1 : 0])

  const [legacyAssignmentRows] = await db.query(`
    SELECT
      legacy_assignment.concern_type_id,
      organizations.id AS organization_id,
      organizations.name AS organization_name,
      organizations.status AS organization_status,
      organizations.organization_type
    FROM organization_concern_types legacy_assignment
    INNER JOIN concern_types category
      ON category.id = legacy_assignment.concern_type_id
     AND category.assigned_organization_id IS NULL
    INNER JOIN organizations
      ON organizations.id = legacy_assignment.organization_id
    WHERE organizations.deleted_at IS NULL
    ORDER BY organizations.name ASC
  `)

  const legacyOrganizationsByConcernType = new Map()

  for (const assignment of legacyAssignmentRows) {
    const assignedOrganizations = legacyOrganizationsByConcernType.get(assignment.concern_type_id) || []
    assignedOrganizations.push({
      id: assignment.organization_id,
      name: assignment.organization_name,
      status: assignment.organization_status,
      organization_type: assignment.organization_type
    })
    legacyOrganizationsByConcernType.set(assignment.concern_type_id, assignedOrganizations)
  }

  const concernTypes = rows.map(concernType => ({
    ...concernType,
    assigned_organizations: concernType.assigned_organization_id && concernType.assigned_organization_name
      ? [{
          id: concernType.assigned_organization_id,
          name: concernType.assigned_organization_name,
          status: concernType.assigned_organization_status,
          organization_type: concernType.assigned_organization_type
        }]
      : legacyOrganizationsByConcernType.get(concernType.id) || []
  }))

  return {
    success: true,
    concernTypes
  }
})