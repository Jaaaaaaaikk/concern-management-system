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

  const date = String(queryParams.date || "").trim();

  /*
   * WHERE CONDITIONS
   */

  const conditions = [];
  const params = [];

  /*
   * ROLE-BASED VISIBILITY
   *
   * SUPERADMIN
   * Can see all concerns.
   */

  if (currentUser.role_name === "superadmin") {
    // No role-based filter.
  } else if (currentUser.role_name === "admin") {
    /*
     * ADMIN
     *
     * Can see:
     *
     * 1. Concerns they created themselves
     * OR
     * 2. Concerns created by someone in their organization
     * OR
     * 3. Concerns assigned to their organization
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
  } else if (currentUser.role_name === "user") {
    /*
     * REGULAR USER
     *
     * Can see:
     *
     * 1. Concerns they created themselves
     * OR
     * 2. Concerns created by someone in their organization
     *
     * Regular users are NOT treated as the assigned recipient.
     */
    conditions.push(`
            (
                c.created_by = ?
                OR u.organization_id = ?
            )
        `);

    params.push(currentUser.id, currentUser.organization_id);
  } else {
    throw createError({
      statusCode: 403,
      statusMessage: "Invalid user role.",
    });
  }

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
            )
        `);

    params.push(searchValue, searchValue, searchValue);
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

  /*
   * PRIORITY FILTER
   */

  if (priority) {
    conditions.push(`
            c.priority = ?
        `);

    params.push(priority);
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
            c.acknowledged_at,
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

  function getHandlingDuration(concern) {
    if (!concern?.acknowledged_at) {
      return "-";
    }

    const start = new Date(concern.acknowledged_at);

    if (Number.isNaN(start.getTime())) {
      return "-";
    }

    let end = null;

    if (concern.resolved_at) {
      end = new Date(concern.resolved_at);
    } else if (
      concern.status === "in_progress" ||
      concern.status === "on_hold"
    ) {
      end = new Date();
    }

    if (!end || Number.isNaN(end.getTime())) {
      return "-";
    }

    const difference = end.getTime() - start.getTime();

    if (difference < 0) {
      return "-";
    }

    const totalMinutes = Math.floor(difference / 60000);

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

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
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

  worksheet.mergeCells("A1:M1");

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

  worksheet.mergeCells("A2:M2");

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

  if (priority) {
    filterParts.push(`Priority: ${formatPriority(priority)}`);
  }

  if (date === "today") {
    filterParts.push("Date: Today");
  } else if (date === "week") {
    filterParts.push("Date: This Week");
  } else if (date === "month") {
    filterParts.push("Date: This Month");
  } else if (date === "year") {
    filterParts.push("Date: This Year");
  } else {
    filterParts.push("Date: All Dates");
  }

  worksheet.mergeCells("A3:M3");

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
    "Type",
    "Assigned To",
    "Priority",
    "Status",
    "Created By",
    "Creator Organization",
    "Date",
    "Acknowledged At",
    "Resolved At",
    "Handling Duration",
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

  for (let column = 1; column <= 13; column++) {
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
      concern.organization_name || "-",
      formatPriority(concern.priority),
      formatStatus(concern.status),
      concern.created_by_name || "-",
      concern.creator_organization_name || "-",
      concern.created_at ? new Date(concern.created_at) : null,
      concern.acknowledged_at ? new Date(concern.acknowledged_at) : null,
      concern.resolved_at ? new Date(concern.resolved_at) : null,
      getHandlingDuration(concern),
    ]);

    /*
     * DATE CELLS
     */

    row.getCell(10).numFmt = "mmm d, yyyy h:mm AM/PM";

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

    for (let column = 1; column <= 13; column++) {
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
  worksheet.getColumn(6).width = 14;
  worksheet.getColumn(7).width = 16;
  worksheet.getColumn(8).width = 25;
  worksheet.getColumn(9).width = 28;
  worksheet.getColumn(10).width = 24;
  worksheet.getColumn(11).width = 24;
  worksheet.getColumn(12).width = 24;
  worksheet.getColumn(13).width = 20;

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
    to: "M5",
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
