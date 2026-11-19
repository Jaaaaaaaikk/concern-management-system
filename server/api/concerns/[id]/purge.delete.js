import { requireRole } from "../../../utils/require-auth.js";
import { permanentlyDeleteTrashedConcern } from "../../../utils/purge-concern.js";

export default defineEventHandler(async (event) => {
  await requireRole(event, ["superadmin"]);

  const concernId = Number(getRouterParam(event, "id"));

  if (!Number.isInteger(concernId) || concernId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern ID.",
    });
  }

  try {
    const deleted = await permanentlyDeleteTrashedConcern(concernId);

    if (!deleted) {
      throw createError({
        statusCode: 404,
        statusMessage: "Trashed concern not found.",
      });
    }
  } catch (error) {
    if (error?.statusCode) {
      throw error;
    }

    console.error("Permanent concern deletion error:", error);
    throw createError({
      statusCode: 500,
      statusMessage: "Failed to permanently delete concern.",
    });
  }

  return {
    success: true,
    message: "Concern permanently deleted.",
  };
});
