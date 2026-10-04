import db from "../../utils/db.js";
import { requireAuth } from "../../utils/require-auth.js";

export default defineEventHandler(async (event) => {
  await requireAuth(event);

  const [rows] = await db.query(
    `
        SELECT
            id,
            name,
            description,
            address,
            status,
            created_at
        FROM organizations
        WHERE status = 'active'
          AND deleted_at IS NULL
        ORDER BY name ASC
        `,
  );

  return {
    success: true,
    organizations: rows,
  };
});
