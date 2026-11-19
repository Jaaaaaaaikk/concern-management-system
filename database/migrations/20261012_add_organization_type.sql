ALTER TABLE organizations
  ADD COLUMN organization_type ENUM('bpo', 'tenant', 'admin_facilities') NOT NULL DEFAULT 'tenant'
  AFTER name;

-- Classify current organizations; any unmapped existing organizations remain tenants.
UPDATE organizations
SET organization_type = CASE
  WHEN LOWER(name) IN ('it department', 'engineering department') THEN 'admin_facilities'
  WHEN LOWER(COALESCE(description, '')) LIKE '%bpo%' THEN 'bpo'
  ELSE 'tenant'
END;
