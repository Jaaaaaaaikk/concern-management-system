import db from "../../utils/db.js";

import { requireAuth } from "../../utils/require-auth.js";

export default defineEventHandler(async (event) => {
  const currentUser = await requireAuth(event);

  const concernId = Number(getRouterParam(event, "id"));

  if (!concernId || Number.isNaN(concernId)) {
    throw createError({
      statusCode: 400,
      statusMessage: "Invalid concern ID.",
    });
  }

  /*
   * Get concern information.
   */
  const [concernRows] = await db.query(
    `
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

            assigned_org.name AS assigned_organization_name,

            c.status,
            c.priority,
            c.created_at,
            c.target_commitment_at,
            c.updated_at,
            c.resolved_at,
            c.closed_at,
            c.deleted_at,
            c.deleted_by,
            CONCAT(deleted_user.first_name, ' ', deleted_user.last_name) AS deleted_by_name,
            creator_org.deleted_at AS creator_organization_deleted_at,
            assigned_org.deleted_at AS assigned_organization_deleted_at

        FROM concerns c

        LEFT JOIN concern_types ct
            ON ct.id = c.concern_type_id

        INNER JOIN users u
            ON u.id = c.created_by

        LEFT JOIN organizations creator_org
            ON creator_org.id = u.organization_id

        LEFT JOIN organizations assigned_org
            ON assigned_org.id = c.assigned_organization_id

        LEFT JOIN users deleted_user
          ON deleted_user.id = c.deleted_by

        WHERE c.id = ?

        LIMIT 1
        `,
    [concernId],
  );

  if (concernRows.length === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: "Concern not found.",
    });
  }

  const concern = concernRows[0];

  if (concern.deleted_at && currentUser.role_name !== "superadmin") {
    const isAuthorizedAdmin =
      currentUser.role_name === "admin" &&
      currentUser.organization_id != null &&
      Number(currentUser.organization_id) === Number(concern.creator_organization_id);

    const isAuthorizedUser =
      currentUser.role_name === "user" &&
      Number(currentUser.id) === Number(concern.created_by);

    if (!isAuthorizedAdmin && !isAuthorizedUser) {
      throw createError({
        statusCode: 404,
        statusMessage: "Concern not found.",
      });
    }
  }

  /*
   * Check whether the current user is allowed
   * to view this concern.
   */

  /*
   * SUPERADMIN
   *
   * Can view every concern.
   */
  if (currentUser.role_name === "superadmin") {
    // Allowed.
  } else if (currentUser.role_name === "admin") {
    /*
     * ADMIN
     *
     * Admin can view the concern if:
     *
     * 1. They created it themselves
     *
     * OR
     *
     * 2. The creator belongs to their organization
     *
     * OR
     *
     * 3. The concern is assigned to their organization
     */
    const createdByCurrentUser =
      Number(concern.created_by) === Number(currentUser.id);

    const creatorSameOrganization =
      Number(concern.creator_organization_id) ===
      Number(currentUser.organization_id);

    const assignedToCurrentOrganization =
      Number(concern.assigned_organization_id) ===
      Number(currentUser.organization_id);

    if (
      !createdByCurrentUser &&
      !creatorSameOrganization &&
      !assignedToCurrentOrganization
    ) {
      throw createError({
        statusCode: 403,
        statusMessage: "You do not have permission to view this concern.",
      });
    }
  } else if (currentUser.role_name === "user") {
    /*
     * REGULAR USER
     *
     * Regular users can view:
     *
     * 1. Concerns they created themselves
     *
     * OR
     *
     * 2. Concerns created by someone in their organization
     *
     * OR
     *
     * 3. Concerns assigned to their organization
     */
    const createdByCurrentUser =
      Number(concern.created_by) === Number(currentUser.id);

    const creatorSameOrganization =
      Number(concern.creator_organization_id) ===
      Number(currentUser.organization_id);

    const assignedToCurrentOrganization =
      Number(concern.assigned_organization_id) ===
      Number(currentUser.organization_id);

    if (
      !createdByCurrentUser &&
      !creatorSameOrganization &&
      !assignedToCurrentOrganization
    ) {
      throw createError({
        statusCode: 403,
        statusMessage: "You do not have permission to view this concern.",
      });
    }
  } else {
    throw createError({
      statusCode: 403,
      statusMessage: "Invalid user role.",
    });
  }

  if (
    currentUser.role_name !== "superadmin" &&
    (
      (concern.creator_organization_id != null &&
        concern.creator_organization_deleted_at != null) ||
      (concern.assigned_organization_id != null &&
        concern.assigned_organization_deleted_at != null)
    )
  ) {
    throw createError({
      statusCode: 404,
      statusMessage: "Concern not found.",
    });
  }

  /*
   * Get original concern attachments.
   *
   * comment_id IS NULL means the attachment
   * belongs directly to the concern.
   *
   * deleted_at IS NULL means the attachment
   * has not been soft-deleted.
   */
  const [attachments] = await db.query(
    `
        SELECT
            ca.id,
            ca.file_name,
            ca.file_path,
            ca.file_type,
            ca.file_size,
            ca.created_at,
            ca.uploaded_by,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS uploaded_by_name

        FROM concern_attachments ca

        INNER JOIN users u
            ON u.id = ca.uploaded_by

        WHERE ca.concern_id = ?
          AND ca.comment_id IS NULL
          AND ca.deleted_at IS NULL

        ORDER BY ca.created_at ASC
        `,
    [concernId],
  );

  /*
   * Get comments.
   */
  const [comments] = await db.query(
    `
        SELECT
            cc.id,
            cc.comment,
            cc.created_at,
            cc.updated_at,
            cc.user_id,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS user_name,

            u.profile_photo,

            r.name AS role_name,

            o.name AS organization_name

        FROM concern_comments cc

        INNER JOIN users u
            ON u.id = cc.user_id

        LEFT JOIN roles r
            ON r.id = u.role_id

        LEFT JOIN organizations o
            ON o.id = u.organization_id

        WHERE cc.concern_id = ?

        ORDER BY cc.created_at ASC
        `,
    [concernId],
  );

  /*
   * Get attachments belonging to comments.
   */
  const [commentAttachments] = await db.query(
    `
        SELECT
            ca.id,
            ca.comment_id,
            ca.file_name,
            ca.file_path,
            ca.file_type,
            ca.file_size,
            ca.created_at,
            ca.edited_at,
            ca.uploaded_by,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS uploaded_by_name

        FROM concern_attachments ca

        INNER JOIN users u
            ON u.id = ca.uploaded_by

        WHERE ca.concern_id = ?
          AND ca.comment_id IS NOT NULL
          AND ca.deleted_at IS NULL

        ORDER BY ca.created_at ASC
        `,
    [concernId],
  );

  /*
   * Attach images to their corresponding comments.
   */
  const commentsWithAttachments = comments.map((comment) => {
    const attachmentsForComment = commentAttachments.filter(
      (attachment) => Number(attachment.comment_id) === Number(comment.id),
    );

    return {
      ...comment,
      attachments: attachmentsForComment,
    };
  });

  /*
   * Get status history.
   */
  const [statusHistoryRows] = await db.query(
    `
        SELECT
            csh.id,
            csh.old_status,
            csh.new_status,
            csh.remarks,
            csh.created_at,
            csh.changed_by,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS changed_by_name

        FROM concern_status_history csh

        INNER JOIN users u
            ON u.id = csh.changed_by

        WHERE csh.concern_id = ?

        ORDER BY csh.created_at ASC
        `,
    [concernId],
  );

  /*
   * Get resolution/status evidence.
   *
   * These attachments are separate from:
   *
   * - original concern attachments
   * - comment attachments
   */
  const [statusAttachments] = await db.query(
    `
        SELECT
            csa.id,
            csa.status_history_id,
            csa.concern_id,
            csa.uploaded_by,
            csa.file_name,
            csa.file_path,
            csa.file_type,
            csa.file_size,
            csa.created_at,

            CONCAT(
                u.first_name,
                ' ',
                u.last_name
            ) AS uploaded_by_name

        FROM concern_status_attachments csa

        INNER JOIN users u
            ON u.id = csa.uploaded_by

        WHERE csa.concern_id = ?

        ORDER BY csa.created_at ASC
        `,
    [concernId],
  );

  /*
   * Attach status evidence to the corresponding
   * status history record.
   */
  const statusHistory = statusHistoryRows.map((history) => {
    const attachmentsForHistory = statusAttachments.filter(
      (attachment) =>
        Number(attachment.status_history_id) === Number(history.id),
    );

    return {
      ...history,
      attachments: attachmentsForHistory,
    };
  });

  return {
    success: true,
    concern,
    attachments,
    comments: commentsWithAttachments,
    statusHistory,
  };
});
