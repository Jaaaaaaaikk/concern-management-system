import db from "../../../utils/db.js";
import { requireAuth } from "../../../utils/require-auth.js";
export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event);
  const concernId = Number(getRouterParam(event, "id"));
  if (!concernId || Number.isNaN(concernId)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern ID.",
    });
  }
  const body = await readBody(event);
  const comment = body?.comment?.trim();
  if (!comment) {
    throw createError({
      statusCode: 400,
      statusMessage: "Comment is required.",
    });
  }
  /* * Get concern. */ const [concernRows] = await db.query(
    ` SELECT id, created_by, assigned_organization_id FROM concerns WHERE id = ? LIMIT 1 `,
    [concernId],
  );
  if (concernRows.length === 0) {
    throw createError({ statusCode: 404, statusMessage: "Concern not found." });
  }
  const concern = concernRows[0];
  /* * Check permission. */
  if (currentUser.role_name === "admin") {
    if (
      Number(concern.assigned_organization_id) !==
      Number(currentUser.organization_id)
    ) {
      throw createError({
        statusCode: 403,
        statusMessage: "You do not have permission to comment on this concern.",
      });
    }
  }
  if (currentUser.role_name === "user") {
    if (Number(concern.created_by) !== Number(currentUser.id)) {
      throw createError({
        statusCode: 403,
        statusMessage: "You do not have permission to comment on this concern.",
      });
    }
  }
  /* * Insert comment. */ const [result] = await db.query(
    ` INSERT INTO concern_comments ( concern_id, user_id, comment ) VALUES (?, ?, ?) `,
    [concernId, currentUser.id, comment],
  );
  return {
    success: true,
    message: "Comment added successfully.",
    commentId: result.insertId,
  };
});
