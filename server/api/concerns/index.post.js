import db from "../../utils/db.js";
import { requireRole } from "../../utils/require-auth.js";

export default defineEventHandler(async (event) => {
  const currentUser = await requireRole(event, ["admin", "user"]);

  const body = await readBody(event);

  const title = body?.title?.trim();
  const description = body?.description?.trim();
  const concernTypeId = body?.concern_type_id;
  const assignedOrganizationId = body?.assigned_organization_id;
  const priority = body?.priority || "medium";

  if (!title) {
    throw createError({
      statusCode: 400,
      statusMessage: "Concern title is required.",
    });
  }

  if (!description) {
    throw createError({
      statusCode: 400,
      statusMessage: "Concern description is required.",
    });
  }

  if (!concernTypeId) {
    throw createError({
      statusCode: 400,
      statusMessage: "Concern type is required.",
    });
  }

  const validPriorities = ["low", "medium", "high", "urgent"];

  if (!validPriorities.includes(priority)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid priority.",
    });
  }

  if (!assignedOrganizationId || Number.isNaN(Number(assignedOrganizationId))) {
    throw createError({
      statusCode: 400,
      statusMessage: "Assigned organization is required.",
    });
  }

  // Verify concern type exists and is active.
  const [concernTypeRows] = await db.query(
    `
    SELECT
      id
    FROM concern_types
    WHERE id = ?
      AND status = 'active'
    LIMIT 1
    `,
    [Number(concernTypeId)],
  );

  if (concernTypeRows.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid or inactive concern type.",
    });
  }

  // Verify organization exists and is active.
  const [organizationRows] = await db.query(
    `
    SELECT
      id
    FROM organizations
    WHERE id = ?
      AND status = 'active'
      AND deleted_at IS NULL
    LIMIT 1
    `,
    [Number(assignedOrganizationId)],
  );

  if (organizationRows.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid or inactive organization.",
    });
  }

  // Generate concern number.
  const currentYear = new Date().getFullYear();

  const [latestRows] = await db.query(
    `
    SELECT
      concern_number
    FROM concerns
    WHERE concern_number LIKE ?
    ORDER BY id DESC
    LIMIT 1
    `,
    [`CON-${currentYear}-%`],
  );

  let nextNumber = 1;

  if (latestRows.length > 0) {
    const latestNumber = latestRows[0].concern_number.split("-").pop();

    const parsedNumber = Number(latestNumber);

    if (!Number.isNaN(parsedNumber)) {
      nextNumber = parsedNumber + 1;
    }
  }

  const concernNumber = `CON-${currentYear}-${String(nextNumber).padStart(5, "0")}`;

  try {
    const [result] = await db.query(
      `
      INSERT INTO concerns (
        concern_number,
        title,
        description,
        concern_type_id,
        created_by,
        assigned_organization_id,
        status,
        priority
      )
      VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
      `,
      [
        concernNumber,
        title,
        description,
        Number(concernTypeId),
        currentUser.id,
        Number(assignedOrganizationId),
        priority,
      ],
    );

    return {
      success: true,
      message: "Concern created successfully.",
      concernId: result.insertId,
      concernNumber,
    };
  } catch (error) {
    console.error("Concern creation error:", error);

    throw createError({
      statusCode: 500,
      statusMessage: "Failed to create concern.",
    });
  }
});
