import db from "../../utils/db.js";

import { requireAuth } from "../../utils/require-auth.js";

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event);

  const queryParams = getQuery(event);

  /*
   * FILTERS
   */

  const search = String(queryParams.search || "").trim();

  const status = String(queryParams.status || "").trim();

  const priority = String(queryParams.priority || "").trim();

  const scope = String(queryParams.scope || "all").trim();

  const senderDepartment = Number(queryParams.sender_department || 0);

  const department = Number(queryParams.department || 0);

  const date = String(queryParams.date || "").trim();

  const dateFrom = String(queryParams.date_from || "").trim();

  const dateTo = String(queryParams.date_to || "").trim();

  const targetDate = String(queryParams.target_date || "").trim();

  const lateResponseFilter = String(queryParams.late_response || "").trim() === "1";

  /*
   * WHERE CONDITIONS
   */

  const conditions = [];
  const params = [];

  const isValidCalendarDate = (value) => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      return false;
    }

    const parsedDate = new Date(`${value}T00:00:00.000Z`);
    return !Number.isNaN(parsedDate.getTime()) && parsedDate.toISOString().slice(0, 10) === value;
  };

  if ((dateFrom && !isValidCalendarDate(dateFrom)) || (dateTo && !isValidCalendarDate(dateTo))) {
    throw createError({
      statusCode: 400,
      statusMessage: "Enter valid created-date range values.",
    });
  }

  if (dateFrom && dateTo && dateFrom > dateTo) {
    throw createError({
      statusCode: 400,
      statusMessage: "The created-date start must be on or before the end date.",
    });
  }

  /*
   * ROLE-BASED VISIBILITY
   *
   * SUPERADMIN
   * Can see all concerns.
   */

  if (["superadmin", "system_admin", "system_monitor"].includes(currentUser.role_name)) {
    // Global roles can see all concerns.
  } else if (currentUser.role_name === "concern_handler") {
    /*
     * Concern handlers can see concerns they created, concerns from their
     * organization, and concerns assigned to their organization.
     */
    conditions.push(`
            (
                c.created_by = ?
                OR u.organization_id = ?
                OR c.assigned_organization_id = ?
            )
        `);

    params.push(
      currentUser.id,
      currentUser.organization_id,
      currentUser.organization_id,
    );
  } else if (currentUser.role_name === "requestor") {
    /* Requestors have the same organization-based view, without status management. */
    conditions.push(`
            (
                c.created_by = ?
                OR u.organization_id = ?
                OR c.assigned_organization_id = ?
            )
        `);

    params.push(
      currentUser.id,
      currentUser.organization_id,
      currentUser.organization_id,
    );
  } else {
    throw createError({
      statusCode: 403,
      statusMessage: "Invalid user role.",
    });
  }

  conditions.push("c.deleted_at IS NULL");
  conditions.push(`
    (
      u.organization_id IS NULL
      OR (creator_org.id IS NOT NULL AND creator_org.deleted_at IS NULL)
    )
    AND (
      c.assigned_organization_id IS NULL
      OR (assigned_org.id IS NOT NULL AND assigned_org.deleted_at IS NULL)
    )
  `);

  /*
   * SEARCH FILTER
   */

  if (search) {
    const searchValue = `%${search}%`;

    conditions.push(`
            (
                c.concern_number LIKE ?
                OR c.title LIKE ?
                OR c.description LIKE ?
                OR CONCAT(u.first_name, ' ', u.last_name) LIKE ?
                OR creator_org.name LIKE ?
                OR assigned_org.name LIKE ?
                OR ct.name LIKE ?
            )
        `);

    params.push(
      searchValue,
      searchValue,
      searchValue,
      searchValue,
      searchValue,
      searchValue,
      searchValue,
    );
  }

  /*
   * STATUS FILTER
   */

  if (status) {
    conditions.push(`
            c.status = ?
        `);

    params.push(status);
  }

  if (lateResponseFilter) {
    conditions.push(`
      c.status = 'pending'
      AND c.created_at < DATE_SUB(NOW(), INTERVAL 4 HOUR)
      AND NOT EXISTS (
        SELECT 1
        FROM concern_status_history response_status
        INNER JOIN users response_user
          ON response_user.id = response_status.changed_by
        WHERE response_status.concern_id = c.id
          AND response_status.new_status <> 'pending'
          AND response_user.organization_id = c.assigned_organization_id
          AND response_status.created_at <= DATE_ADD(c.created_at, INTERVAL 4 HOUR)
      )
      AND NOT EXISTS (
        SELECT 1
        FROM concern_comments response_comment
        INNER JOIN users response_user
          ON response_user.id = response_comment.user_id
        WHERE response_comment.concern_id = c.id
          AND response_user.organization_id = c.assigned_organization_id
          AND response_comment.created_at <= DATE_ADD(c.created_at, INTERVAL 4 HOUR)
      )
    `);
  }

  /*
   * PRIORITY FILTER
   */

  if (priority) {
    conditions.push(`
            c.priority = ?
        `);

    params.push(priority);
  }

  if (Number.isInteger(department) && department > 0) {
    conditions.push("c.assigned_organization_id = ?");
    params.push(department);
  }

  if (targetDate === "set") {
    conditions.push("c.target_commitment_at IS NOT NULL");
  } else if (targetDate === "none") {
    conditions.push("c.target_commitment_at IS NULL");
  } else if (targetDate === "past") {
    conditions.push("c.target_commitment_at IS NOT NULL AND DATE(c.target_commitment_at) < CURDATE()");
  } else if (targetDate) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid target date filter.",
    });
  }

  /*
   * DATE FILTER
   *
   * The date filter only affects
   * the Excel export.
   *
   * The concern table pagination
   * remains unchanged.
   */
  if (date === "today") {
    conditions.push(`
        c.created_at >= CURDATE()
        AND c.created_at < DATE_ADD(
            CURDATE(),
            INTERVAL 1 DAY
        )
    `);
  } else if (date === "week") {
    conditions.push(`
        c.created_at >= DATE_SUB(
            CURDATE(),
            INTERVAL WEEKDAY(CURDATE()) DAY
        )
        AND c.created_at < DATE_ADD(
            DATE_SUB(
                CURDATE(),
                INTERVAL WEEKDAY(CURDATE()) DAY
            ),
            INTERVAL 7 DAY
        )
    `);
  } else if (date === "month") {
    conditions.push(`
        c.created_at >= DATE_FORMAT(
            CURDATE(),
            '%Y-%m-01'
        )
        AND c.created_at < DATE_ADD(
            DATE_FORMAT(
                CURDATE(),
                '%Y-%m-01'
            ),
            INTERVAL 1 MONTH
        )
    `);
  } else if (date === "year") {
    conditions.push(`
        c.created_at >= DATE_FORMAT(
            CURDATE(),
            '%Y-01-01'
        )
        AND c.created_at < DATE_ADD(
            DATE_FORMAT(
                CURDATE(),
                '%Y-01-01'
            ),
            INTERVAL 1 YEAR
        )
    `);
  }

  if (dateFrom) {
    conditions.push("c.created_at >= ?");
    params.push(dateFrom);
  }

  if (dateTo) {
    conditions.push("c.created_at < DATE_ADD(?, INTERVAL 1 DAY)");
    params.push(dateTo);
  }

  /*
   * SCOPE AND ORGANIZATION FILTERS
   */

  if (!['all', 'submitted', 'assigned'].includes(scope)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid concern scope.',
    });
  }

  if (['concern_handler', 'requestor'].includes(currentUser.role_name)) {
    if (scope === 'submitted') {
      conditions.push('u.organization_id = ?');
      params.push(currentUser.organization_id);
    } else if (scope === 'assigned') {
      conditions.push('c.assigned_organization_id = ?');
      params.push(currentUser.organization_id);
    }
  } else if (scope === 'submitted') {
    conditions.push('u.organization_id IS NOT NULL');
  } else if (scope === 'assigned') {
    conditions.push('c.assigned_organization_id IS NOT NULL');
  }

  if (Number.isInteger(senderDepartment) && senderDepartment > 0) {
    conditions.push('u.organization_id = ?');
    params.push(senderDepartment);
  }

  /*
   * BUILD WHERE CLAUSE
   */

  const whereClause = conditions.length
    ? `WHERE ${conditions.join(" AND ")}`
    : "";

  /*
   * GET ALL MATCHING CONCERNS
   *
   * IMPORTANT:
   *
   * There is NO LIMIT.
   * There is NO OFFSET.
   *
   * Therefore the Excel export contains
   * every concern matching the filters.
   */

  const query = `
        SELECT
            c.id,
            c.concern_number,
            c.title,
            c.description,
            c.concern_type_id,
            ct.name AS concern_type_name,
            c.created_by,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS created_by_name,

            u.organization_id AS creator_organization_id,

            creator_org.name AS creator_organization_name,

            c.assigned_organization_id,

            assigned_org.name AS organization_name,

            c.status,
            c.priority,
            c.created_at,
            c.target_commitment_at,
            c.updated_at,
            c.resolved_at,
            c.closed_at

        FROM concerns c

        LEFT JOIN concern_types ct
            ON ct.id = c.concern_type_id

        INNER JOIN users u
            ON u.id = c.created_by

        LEFT JOIN organizations creator_org
            ON creator_org.id = u.organization_id

        LEFT JOIN organizations assigned_org
            ON assigned_org.id = c.assigned_organization_id

        ${whereClause}

        ORDER BY c.created_at DESC
    `;

  const [rows] = await db.query(query, params);

  if (rows.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: "No concerns match the selected filters. Nothing was exported.",
    });
  }

  const filterOrganizationIds = [senderDepartment, department]
    .filter((id) => Number.isInteger(id) && id > 0);
  const organizationNameById = new Map();

  if (filterOrganizationIds.length > 0) {
    const placeholders = filterOrganizationIds.map(() => "?").join(", ");
    const [organizationRows] = await db.query(
      `SELECT id, name FROM organizations WHERE id IN (${placeholders})`,
      filterOrganizationIds,
    );

    for (const organization of organizationRows) {
      organizationNameById.set(Number(organization.id), organization.name);
    }
  }

  const statusHistoryByConcern = new Map();
  const concernIds = rows.map((row) => row.id);

  for (let startIndex = 0; startIndex < concernIds.length; startIndex += 500) {
    const concernIdBatch = concernIds.slice(startIndex, startIndex + 500);
    const placeholders = concernIdBatch.map(() => "?").join(", ");

    const [historyRows] = await db.query(
      `
        SELECT concern_id, new_status, remarks, created_at
        FROM concern_status_history
        WHERE concern_id IN (${placeholders})
        ORDER BY created_at ASC
      `,
      concernIdBatch,
    );

    for (const history of historyRows) {
      const historyForConcern = statusHistoryByConcern.get(Number(history.concern_id)) || [];
      historyForConcern.push(history);
      statusHistoryByConcern.set(Number(history.concern_id), historyForConcern);
    }
  }

  for (const concern of rows) {
    concern.statusHistory = statusHistoryByConcern.get(Number(concern.id)) || [];
  }

  /*
   * EXCEL HELPERS
   */

  function formatStatus(status) {
    const labels = {
      pending: "Pending",
      in_progress: "In Progress",
      on_hold: "On Hold",
      resolved: "Resolved",
      closed: "Closed"
    };

    return labels[status] || status || "-";
  }

  function formatPriority(priority) {
    const labels = {
      low: "Low",
      medium: "Medium",
      high: "High",
      urgent: "Urgent",
    };

    return labels[priority] || priority || "-";
  }

  function parseLocalDateTime(value) {
    if (!value) {
      return null;
    }

    if (value instanceof Date) {
      return Number.isNaN(value.getTime()) ? null : value;
    }

    const text = String(value).trim();

    if (!text) {
      return null;
    }

    if (text.includes("Z") || /[+-]\d{2}:\d{2}$/.test(text)) {
      const date = new Date(text);
      return Number.isNaN(date.getTime()) ? null : date;
    }

    const match = text.match(
      /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$/,
    );

    if (!match) {
      const date = new Date(text);
      return Number.isNaN(date.getTime()) ? null : date;
    }

    const [, year, month, day, hour, minute, second = "0"] = match;
    const date = new Date(
      Number(year),
      Number(month) - 1,
      Number(day),
      Number(hour),
      Number(minute),
      Number(second),
    );

    return Number.isNaN(date.getTime()) ? null : date;
  }

  function getCommitmentStartFromRemarks(remarks) {
    const match = String(remarks || "").match(
      /(?:commitment start|scheduled start(?: date\/time)?|target resolution date):\s*(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(?::\d{2})?)/i,
    );

    return match ? parseLocalDateTime(match[1]) : null;
  }

  function getHandlingDuration(concern) {
    const histories = concern.statusHistory || [];
    let elapsedMilliseconds = 0;
    let activeSince = null;
    const latestInProgress = [...histories]
      .reverse()
      .find((history) => history.new_status === "in_progress");
    const latestInProgressAt = parseLocalDateTime(latestInProgress?.created_at);
    const reopenedAfterResolution = Boolean(
      latestInProgressAt && histories.some((history) =>
        history.new_status === "resolved" &&
        parseLocalDateTime(history.created_at)?.getTime() < latestInProgressAt.getTime()
      ),
    );

    for (const history of histories) {
      const changedAt = parseLocalDateTime(history.created_at);

      if (!changedAt) {
        continue;
      }

      if (history.new_status === "in_progress") {
        activeSince =
          getCommitmentStartFromRemarks(history.remarks) ||
          (history === latestInProgress && !reopenedAfterResolution
            ? parseLocalDateTime(concern.target_commitment_at)
            : null) ||
          changedAt;
      } else if (
        ["on_hold", "resolved", "closed", "cancelled"].includes(history.new_status) &&
        activeSince
      ) {
        elapsedMilliseconds += Math.max(
          0,
          changedAt.getTime() - activeSince.getTime(),
        );
        activeSince = null;
      }
    }

    if (activeSince && concern.status === "in_progress") {
      elapsedMilliseconds += Math.max(
        0,
        Date.now() - activeSince.getTime(),
      );
    }

    if (histories.length === 0 && concern.target_commitment_at) {
      const start = parseLocalDateTime(concern.target_commitment_at);
      const end = concern.resolved_at
        ? parseLocalDateTime(concern.resolved_at)
        : concern.status === "in_progress"
          ? new Date()
          : null;

      if (start && end) {
        elapsedMilliseconds = Math.max(0, end.getTime() - start.getTime());
      }
    }

    if (!activeSince && elapsedMilliseconds === 0) {
      return "Not started";
    }

    if (activeSince && Date.now() < activeSince.getTime() && elapsedMilliseconds === 0) {
      return "Not started";
    }

    const totalMinutes = Math.floor(elapsedMilliseconds / 60000);

    const days = Math.floor(totalMinutes / 1440);

    const hours = Math.floor((totalMinutes % 1440) / 60);

    const minutes = totalMinutes % 60;

    const parts = [];

    if (days > 0) {
      parts.push(`${days}d`);
    }

    if (hours > 0) {
      parts.push(`${hours}h`);
    }

    if (minutes > 0 || parts.length === 0) {
      parts.push(`${minutes}m`);
    }

    return parts.join(" ");
  }

  function formatDateForDisplay(value) {
    if (!value) {
      return "-";
    }

    const date = parseLocalDateTime(value);

    if (!date) {
      return "-";
    }

    return date.toLocaleString("en-PH", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
    });
  }

  /*
   * CREATE EXCEL WORKBOOK
   */

  const ExcelJSModule = await import("exceljs");

  const ExcelJS = ExcelJSModule.default || ExcelJSModule;

  const workbook = new ExcelJS.Workbook();

  workbook.creator = "Concern Management System";

  workbook.created = new Date();

  const worksheet = workbook.addWorksheet("Concerns");

  /*
   * REPORT TITLE
   */

  worksheet.mergeCells("A1:L1");

  worksheet.getCell("A1").value = "Concern Management System - Concern Report";

  worksheet.getCell("A1").font = {
    bold: true,
    size: 16,
  };

  worksheet.getCell("A1").alignment = {
    horizontal: "center",
    vertical: "middle",
  };

  worksheet.getRow(1).height = 28;

  /*
   * GENERATED DATE
   */

  worksheet.mergeCells("A2:L2");

  worksheet.getCell("A2").value =
    `Generated: ${formatDateForDisplay(new Date())}`;

  worksheet.getCell("A2").font = {
    italic: true,
    size: 10,
  };

  worksheet.getCell("A2").alignment = {
    horizontal: "center",
    vertical: "middle",
  };

  /*
   * FILTER INFORMATION
   */

  const filterParts = [];

  if (search) {
    filterParts.push(`Search: ${search}`);
  }

  if (status) {
    filterParts.push(`Status: ${formatStatus(status)}`);
  }

  if (lateResponseFilter) {
    filterParts.push("Late Response: No response within 4 hours");
  }

  if (priority) {
    filterParts.push(`Priority: ${formatPriority(priority)}`);
  }

  if (scope === "submitted") {
    filterParts.push("Scope: Submitted by my organization");
  } else if (scope === "assigned") {
    filterParts.push("Scope: Assigned to my organization");
  }

  if (Number.isInteger(senderDepartment) && senderDepartment > 0) {
    filterParts.push(`Requesting Department: ${organizationNameById.get(senderDepartment) || "Unknown organization"}`);
  }

  if (Number.isInteger(department) && department > 0) {
    filterParts.push(`Receiving Department: ${organizationNameById.get(department) || "Unknown organization"}`);
  }

  if (targetDate === "set") {
    filterParts.push("Committed Start Date: Set");
  } else if (targetDate === "none") {
    filterParts.push("Committed Start Date: Not Set");
  } else if (targetDate === "past") {
    filterParts.push("Committed Start Date: Passed");
  }

  if (dateFrom || dateTo) {
    filterParts.push(`Created Date: ${dateFrom || "Any date"} to ${dateTo || "Any date"}`);
  } else if (date === "today") {
    filterParts.push("Created Date: Today");
  } else if (date === "week") {
    filterParts.push("Created Date: This Week");
  } else if (date === "month") {
    filterParts.push("Created Date: This Month");
  } else if (date === "year") {
    filterParts.push("Created Date: This Year");
  } else {
    filterParts.push("Created Date: All Years");
  }

  worksheet.mergeCells("A3:L3");

  worksheet.getCell("A3").value = filterParts.length
    ? `Filters: ${filterParts.join(" | ")}`
    : "Filters: None";

  worksheet.getCell("A3").font = {
    size: 10,
  };

  worksheet.getCell("A3").alignment = {
    wrapText: true,
    vertical: "middle",
  };

  worksheet.getRow(3).height = 30;

  /*
   * EMPTY SPACER ROW
   */

  worksheet.getRow(4).height = 8;

  /*
   * HEADERS
   */

  const headers = [
    "Concern No.",
    "Title",
    "Description",
    "Concern Type",
    "Creator Organization",
    "Assigned To",
    "Priority",
    "Status",
    "Committed Start",
    "Handling Duration",
    "Resolved At",
    "Date",
  ];

  const headerRow = worksheet.getRow(5);

  headerRow.values = headers;

  headerRow.font = {
    bold: true,
    size: 10,
  };

  headerRow.alignment = {
    horizontal: "center",
    vertical: "middle",
    wrapText: true,
  };

  headerRow.height = 30;

  /*
   * HEADER BORDERS
   */

  for (let column = 1; column <= 12; column++) {
    const cell = headerRow.getCell(column);

    cell.border = {
      top: {
        style: "thin",
      },
      left: {
        style: "thin",
      },
      bottom: {
        style: "thin",
      },
      right: {
        style: "thin",
      },
    };
  }

  /*
   * DATA ROWS
   */

  rows.forEach((concern) => {
    const row = worksheet.addRow([
      concern.concern_number || "-",
      concern.title || "-",
      concern.description || "-",
      concern.concern_type_name || "-",
      concern.creator_organization_name || "-",
      concern.organization_name || "-",
      formatPriority(concern.priority),
      formatStatus(concern.status),
      concern.target_commitment_at ? parseLocalDateTime(concern.target_commitment_at) : null,
      getHandlingDuration(concern),
      concern.resolved_at ? new Date(concern.resolved_at) : null,
      concern.created_at ? new Date(concern.created_at) : null,
    ]);

    /*
     * DATE CELLS
     */

    row.getCell(9).numFmt = "mmm d, yyyy h:mm AM/PM";

    row.getCell(11).numFmt = "mmm d, yyyy h:mm AM/PM";

    row.getCell(12).numFmt = "mmm d, yyyy h:mm AM/PM";

    /*
     * ALIGNMENT
     */

    row.alignment = {
      vertical: "top",
      wrapText: true,
    };

    /*
     * BORDERS
     */

    for (let column = 1; column <= 12; column++) {
      const cell = row.getCell(column);

      cell.border = {
        top: {
          style: "thin",
        },
        left: {
          style: "thin",
        },
        bottom: {
          style: "thin",
        },
        right: {
          style: "thin",
        },
      };
    }
  });

  /*
   * COLUMN WIDTHS
   */

  worksheet.getColumn(1).width = 18;
  worksheet.getColumn(2).width = 30;
  worksheet.getColumn(3).width = 45;
  worksheet.getColumn(4).width = 24;
  worksheet.getColumn(5).width = 28;
  worksheet.getColumn(6).width = 28;
  worksheet.getColumn(7).width = 14;
  worksheet.getColumn(8).width = 16;
  worksheet.getColumn(9).width = 24;
  worksheet.getColumn(10).width = 20;
  worksheet.getColumn(11).width = 24;
  worksheet.getColumn(12).width = 24;

  /*
   * FREEZE HEADER
   */

  worksheet.views = [
    {
      state: "frozen",
      ySplit: 5,
    },
  ];

  /*
   * AUTO FILTER
   */

  worksheet.autoFilter = {
    from: "A5",
    to: "L5",
  };

  /*
   * CREATE XLSX BUFFER
   */

  const buffer = await workbook.xlsx.writeBuffer();

  /*
   * RESPONSE
   */

  setHeader(
    event,
    "Content-Type",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  );

  setHeader(
    event,
    "Content-Disposition",
    `attachment; filename="concerns-report-${new Date().toISOString().slice(0, 10)}.xlsx"`,
  );

  setHeader(event, "Cache-Control", "no-store");

  return buffer;
});
