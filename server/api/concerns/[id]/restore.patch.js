import db from "../../../utils/db.js";
import { requireAuth } from "../../../utils/require-auth.js";

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event);

  const concernId = Number(getRouterParam(event, "id"));

  if (!Number.isInteger(concernId) || concernId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern ID.",
    });
  }

  const [rows] = await db.query(
    `
      SELECT
        c.id,
        c.created_by,
        c.status,
        creator.organization_id AS creator_organization_id
      FROM concerns c
      INNER JOIN users creator ON creator.id = c.created_by
      WHERE c.id = ? AND c.deleted_at IS NOT NULL
      LIMIT 1
    `,
    [concernId],
  );

  if (rows.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: "Trashed concern not found.",
    });
  }

  const concern = rows[0];
  const isSuperadmin = currentUser.role_name === "superadmin";
  const isCreatorOrganizationAdmin =
    currentUser.role_name === "admin" &&
    currentUser.organization_id != null &&
    Number(currentUser.organization_id) === Number(concern.creator_organization_id);
  const isCreator =
    currentUser.role_name === "user" &&
    Number(currentUser.id) === Number(concern.created_by);

  if (!isSuperadmin && !isCreatorOrganizationAdmin && !isCreator) {
    throw createError({
      statusCode: 403,
      statusMessage: "You do not have permission to restore this concern.",
    });
  }

  if (!isSuperadmin && concern.status !== "pending") {
    throw createError({
      statusCode: 409,
      statusMessage: "Only pending concerns can be restored by organization members.",
    });
  }

  const [result] = await db.query(
    `
      UPDATE concerns
      SET deleted_at = NULL, deleted_by = NULL
      WHERE id = ? AND deleted_at IS NOT NULL
    `,
    [concernId],
  );

  if (result.affectedRows !== 1) {
    throw createError({
      statusCode: 409,
      statusMessage: "The concern changed before it could be restored. Refresh and try again.",
    });
  }

  return {
    success: true,
    message: "Concern restored successfully.",
  };
});
