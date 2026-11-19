export function normalizeConcernTypeIds(value) {
  if (!Array.isArray(value)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Concern type assignments must be a list.",
    });
  }

  const ids = value.map(Number);

  if (ids.some((id) => !Number.isInteger(id) || id <= 0)) {
    throw createError({
      statusCode: 400,
      statusMessage: "One or more concern type assignments are invalid.",
    });
  }

  return [...new Set(ids)];
}

export async function assertConcernTypesExist(connection, concernTypeIds) {
  if (concernTypeIds.length === 0) return;

  const [rows] = await connection.query(
    "SELECT id FROM concern_types WHERE id IN (?)",
    [concernTypeIds],
  );

  if (rows.length !== concernTypeIds.length) {
    throw createError({
      statusCode: 400,
      statusMessage: "One or more selected concern types do not exist.",
    });
  }
}

export async function replaceOrganizationConcernTypes(
  connection,
  organizationId,
  concernTypeIds,
) {
  await connection.query(
    "DELETE FROM organization_concern_types WHERE organization_id = ?",
    [organizationId],
  );

  if (concernTypeIds.length === 0) return;

  const values = concernTypeIds.map(() => "(?, ?)").join(", ");
  const parameters = concernTypeIds.flatMap((concernTypeId) => [
    organizationId,
    concernTypeId,
  ]);

  await connection.query(
    `INSERT INTO organization_concern_types (organization_id, concern_type_id) VALUES ${values}`,
    parameters,
  );
}