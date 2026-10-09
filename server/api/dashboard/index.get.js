import db from "../../utils/db.js";

import { requireAuth } from "../../utils/require-auth.js";

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event);

  const role = currentUser.role_name;

  const queryParams = getQuery(event);

  const requestedRange = String(queryParams.range || "30d");

  const allowedRanges = ["today", "7d", "30d", "3m", "6m", "year", "all"];

  const range = allowedRanges.includes(requestedRange) ? requestedRange : "30d";

  /*
   * ---------------------------------------------------------
   * Organization filter
   * ---------------------------------------------------------
   *
   * Superadmin:
   * - Can select All Organizations.
   * - Can select one specific organization.
   *
   * Admin/User:
   * - Organization is taken from their authenticated account.
   * - Any organization_id sent by the browser is ignored.
   */

  const requestedOrganizationId = String(queryParams.organization_id || "all");

  let selectedOrganizationId = null;

  if (role === "superadmin") {
    if (requestedOrganizationId !== "all" && requestedOrganizationId !== "") {
      const parsedOrganizationId = Number(requestedOrganizationId);

      if (Number.isInteger(parsedOrganizationId) && parsedOrganizationId > 0) {
        selectedOrganizationId = parsedOrganizationId;
      }
    }
  } else {
    if (currentUser.organization_id) {
      selectedOrganizationId = Number(currentUser.organization_id);
    }
  }

  /*
   * ---------------------------------------------------------
   * Date filter
   * ---------------------------------------------------------
   *
   * The date range is based on concerns.created_at.
   */

  let dateCondition = "";

  if (range === "today") {
    dateCondition = `
            c.created_at >= CURDATE()
        `;
  } else if (range === "7d") {
    dateCondition = `
            c.created_at >= DATE_SUB(
                CURDATE(),
                INTERVAL 6 DAY
            )
        `;
  } else if (range === "30d") {
    dateCondition = `
            c.created_at >= DATE_SUB(
                CURDATE(),
                INTERVAL 29 DAY
            )
        `;
  } else if (range === "3m") {
    dateCondition = `
            c.created_at >= DATE_SUB(
                CURDATE(),
                INTERVAL 3 MONTH
            )
        `;
  } else if (range === "6m") {
    dateCondition = `
            c.created_at >= DATE_SUB(
                CURDATE(),
                INTERVAL 6 MONTH
            )
        `;
  } else if (range === "year") {
    dateCondition = `
            c.created_at >= MAKEDATE(
                YEAR(CURDATE()),
                1
            )
        `;
  }

  /*
   * ---------------------------------------------------------
   * Main concern visibility
   * ---------------------------------------------------------
   *
   * Superadmin:
   * - All concerns.
   * - If an organization is selected:
   *   assigned to that organization OR
   *   created by a member of that organization.
   *
   * Admin/User:
   * - Assigned to their organization OR
   *   created by a member of their organization.
   *
   * This matches the organization-based visibility
   * used by the Concerns page.
   */

  let concernWhere = "";

  const concernParams = [];

  if (role === "superadmin") {
    if (selectedOrganizationId) {
      concernWhere = `
                WHERE (
                    c.assigned_organization_id = ?
                    OR EXISTS (
                        SELECT 1
                        FROM users cu
                        WHERE cu.id = c.created_by
                          AND cu.organization_id = ?
                    )
                )
            `;

      concernParams.push(selectedOrganizationId, selectedOrganizationId);
    }
  } else {
    concernWhere = `
            WHERE (
                c.assigned_organization_id = ?
                OR EXISTS (
                    SELECT 1
                    FROM users cu
                    WHERE cu.id = c.created_by
                      AND cu.organization_id = ?
                )
            )
        `;

    concernParams.push(selectedOrganizationId, selectedOrganizationId);
  }

  /*
   * ---------------------------------------------------------
   * Combine date filtering
   * ---------------------------------------------------------
   */

  if (dateCondition) {
    if (concernWhere) {
      concernWhere += `
                AND ${dateCondition}
            `;
    } else {
      concernWhere = `
                WHERE ${dateCondition}
            `;
    }
  }

  /*
   * ---------------------------------------------------------
   * Status summary
   * ---------------------------------------------------------
   */

  const [statusRows] = await db.query(
    `
            SELECT
                c.status,
                COUNT(*) AS total
            FROM concerns c
            ${concernWhere}
            GROUP BY c.status
            ORDER BY c.status
            `,
    concernParams,
  );

  /*
   * ---------------------------------------------------------
   * Priority summary
   * ---------------------------------------------------------
   */

  const [priorityRows] = await db.query(
    `
            SELECT
                c.priority,
                COUNT(*) AS total
            FROM concerns c
            ${concernWhere}
            GROUP BY c.priority
            ORDER BY c.priority
            `,
    concernParams,
  );

  /*
   * ---------------------------------------------------------
   * Organization options
   * ---------------------------------------------------------
   *
   * Used by the Superadmin Organization dropdown.
   *
   * This always returns all active organizations,
   * regardless of the currently selected organization.
   */

  const [organizationOptionRows] = await db.query(
    `
            SELECT
                o.id,
                o.name
            FROM organizations o
            WHERE o.deleted_at IS NULL
            ORDER BY o.name ASC
            `,
  );

  /*
   * ---------------------------------------------------------
   * Organization summary
   * ---------------------------------------------------------
   *
   * This is the data used by the
   * "Concerns by Organization" chart.
   *
   * Superadmin:
   * - All organizations when no organization is selected.
   * - Selected organization when one is selected.
   *
   * Admin/User:
   * - Their own organization.
   */

  let organizationQuery = "";

  let organizationParams = [];

  if (role === "superadmin") {
    if (selectedOrganizationId) {
      organizationQuery = `
                SELECT
                    o.id,
                    o.name,
                    COUNT(c.id) AS total_concerns
                FROM organizations o
                LEFT JOIN concerns c
                    ON (
                        c.assigned_organization_id = o.id
                        OR EXISTS (
                            SELECT 1
                            FROM users cu
                            WHERE cu.id = c.created_by
                              AND cu.organization_id = o.id
                        )
                    )
                    ${dateCondition ? `AND ${dateCondition}` : ""}
                WHERE o.id = ?
                  AND o.deleted_at IS NULL
                GROUP BY
                    o.id,
                    o.name
                ORDER BY
                    total_concerns DESC,
                    o.name ASC
            `;

      organizationParams.push(selectedOrganizationId);
    } else {
      organizationQuery = `
                SELECT
                    o.id,
                    o.name,
                    COUNT(c.id) AS total_concerns
                FROM organizations o
                LEFT JOIN concerns c
                    ON (
                        c.assigned_organization_id = o.id
                        OR EXISTS (
                            SELECT 1
                            FROM users cu
                            WHERE cu.id = c.created_by
                              AND cu.organization_id = o.id
                        )
                    )
                    ${dateCondition ? `AND ${dateCondition}` : ""}
                WHERE o.deleted_at IS NULL
                GROUP BY
                    o.id,
                    o.name
                ORDER BY
                    total_concerns DESC,
                    o.name ASC
            `;
    }
  } else {
    organizationQuery = `
            SELECT
                o.id,
                o.name,
                COUNT(c.id) AS total_concerns
            FROM organizations o
            LEFT JOIN concerns c
                ON (
                    c.assigned_organization_id = o.id
                    OR EXISTS (
                        SELECT 1
                        FROM users cu
                        WHERE cu.id = c.created_by
                          AND cu.organization_id = o.id
                    )
                )
                ${dateCondition ? `AND ${dateCondition}` : ""}
            WHERE o.id = ?
              AND o.deleted_at IS NULL
            GROUP BY
                o.id,
                o.name
            ORDER BY
                o.name ASC
        `;

    organizationParams.push(selectedOrganizationId);
  }

  const [organizationRows] = await db.query(
    organizationQuery,
    organizationParams,
  );

  /* ---------------------------------------------------------
   * Top Concern Creators
   * ---------------------------------------------------------
   *
   * Shows users who created the most concerns
   * within the selected date range and visibility.
   */

  let creatorCondition = "";
  const creatorParams = [];

  if (role === "superadmin") {
    if (selectedOrganizationId) {
      creatorCondition = `
            EXISTS (
                SELECT 1
                FROM users creator_org
                WHERE creator_org.id = c.created_by
                  AND creator_org.organization_id = ?
            )
        `;

      creatorParams.push(selectedOrganizationId);
    }
  } else {
    creatorCondition = `
        (
            EXISTS (
                SELECT 1
                FROM users creator_org
                WHERE creator_org.id = c.created_by
                  AND creator_org.organization_id = ?
            )
            OR c.assigned_organization_id = ?
        )
    `;

    creatorParams.push(selectedOrganizationId, selectedOrganizationId);
  }

  if (dateCondition) {
    if (creatorCondition) {
      creatorCondition = `
            (
                ${creatorCondition}
            )
            AND ${dateCondition}
        `;
    } else {
      creatorCondition = dateCondition;
    }
  }

  const [topCreatorRows] = await db.query(
    `
        SELECT
            u.id,
            CONCAT_WS(
                ' ',
                u.first_name,
                NULLIF(u.middle_name, ''),
                u.last_name
            ) AS name,
            COUNT(c.id) AS total_concerns

        FROM users u

        INNER JOIN concerns c
            ON c.created_by = u.id

        ${creatorCondition ? `WHERE ${creatorCondition}` : ""}

        GROUP BY
            u.id,
            u.first_name,
            u.middle_name,
            u.last_name

        ORDER BY
            total_concerns DESC,
            name ASC

        LIMIT 10
        `,
    creatorParams,
  );
  /*
   * ---------------------------------------------------------
   * Concerns Created Over Time
   * ---------------------------------------------------------
   *
   * Groups concerns by calendar date.
   */

  const [trendRows] = await db.query(
    `
            SELECT
                DATE(c.created_at) AS date,
                COUNT(*) AS total
            FROM concerns c
            ${concernWhere}
            GROUP BY DATE(c.created_at)
            ORDER BY date ASC
            `,
    concernParams,
  );

  /*
   * ---------------------------------------------------------
   * Recent concerns
   * ---------------------------------------------------------
   *
   * Still limited to 10 records.
   * The selected date range and organization
   * visibility also apply.
   */

  const [recentRows] = await db.query(
    `
            SELECT
                c.id,
                c.concern_number,
                c.title,
                c.status,
                c.priority,
                c.created_at,
                CONCAT_WS(
                    ' ',
                    u.first_name,
                    NULLIF(u.middle_name, ''),
                    u.last_name
                ) AS created_by_name,
                o.name AS organization_name
            FROM concerns c
            INNER JOIN users u
                ON u.id = c.created_by
            LEFT JOIN organizations o
                ON o.id = c.assigned_organization_id
            ${concernWhere}
            ORDER BY c.created_at DESC
            LIMIT 10
            `,
    concernParams,
  );

  /*
   * ---------------------------------------------------------
   * Total concerns
   * ---------------------------------------------------------
   */

  const [totalRows] = await db.query(
    `
            SELECT
                COUNT(*) AS total
            FROM concerns c
            ${concernWhere}
            `,
    concernParams,
  );

  /*
   * ---------------------------------------------------------
   * Response
   * ---------------------------------------------------------
   */

  return {
    success: true,

    range,

    organizationId: selectedOrganizationId,

    summary: {
      total: Number(totalRows[0]?.total || 0),
    },

    status: statusRows.map((row) => ({
      status: row.status,

      total: Number(row.total),
    })),

    priority: priorityRows.map((row) => ({
      priority: row.priority,

      total: Number(row.total),
    })),

    /*
     * Used by the Organization dropdown.
     */
    organizationOptions: organizationOptionRows.map((row) => ({
      id: row.id,

      name: row.name,
    })),

    /*
     * Used by the Organization chart.
     */
    organizations: organizationRows.map((row) => ({
      id: row.id,

      name: row.name,

      total_concerns: Number(row.total_concerns),
    })),

    topCreators: topCreatorRows.map((row) => ({
      id: row.id,

      name: row.name,

      total_concerns: Number(row.total_concerns),
    })),

    trend: trendRows.map((row) => ({
      date: row.date,

      total: Number(row.total),
    })),

    recentConcerns: recentRows,
  };
});
