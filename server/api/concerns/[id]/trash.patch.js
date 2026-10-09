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

  if (!["admin", "user"].includes(currentUser.role_name)) {
    throw createError({
      statusCode: 403,
      statusMessage: "Only organization admins or users can trash concerns.",
    });
  }

  const [rows] = await db.query(
    `
      SELECT
        c.id,
        c.created_by,
        c.status,
        u.organization_id AS creator_organization_id
      FROM concerns c
      INNER JOIN users u ON u.id = c.created_by
      WHERE c.id = ?
        AND c.deleted_at IS NULL
      LIMIT 1
    `,
    [concernId],
  );

  if (rows.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: "Concern not found.",
    });
  }

  const concern = rows[0];
  const isCreator = Number(concern.created_by) === Number(currentUser.id);
  const isCreatorOrganizationAdmin =
    currentUser.role_name === "admin" &&
    currentUser.organization_id != null &&
    Number(currentUser.organization_id) === Number(concern.creator_organization_id);

  if (!isCreator && !isCreatorOrganizationAdmin) {
    throw createError({
      statusCode: 403,
      statusMessage: "You can only trash concerns created by you or your organization.",
    });
  }

  if (concern.status !== "pending") {
    throw createError({
      statusCode: 409,
      statusMessage: "Only pending concerns can be moved to trash.",
    });
  }

  const [result] = await db.query(
    `
      UPDATE concerns
      SET deleted_at = NOW(), deleted_by = ?
      WHERE id = ?
        AND status = 'pending'
        AND deleted_at IS NULL
    `,
    [currentUser.id, concernId],
  );

  if (result.affectedRows !== 1) {
    throw createError({
      statusCode: 409,
      statusMessage: "The concern changed before it could be moved to trash. Refresh and try again.",
    });
  }

  return {
    success: true,
    message: "Concern moved to trash.",
  };
});
