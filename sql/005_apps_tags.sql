-- ============================================================================
-- Prismaid Database - Apps & Tags
-- ============================================================================
-- Description: Hybrid grouping system - Apps for 1-to-1 primary grouping,
--              Tags for flexible many-to-many categorization
-- Dependencies: 002_auth.sql (pmd_users), 003_core_etl.sql, 004_automation.sql
-- Tables: pmd_apps, pmd_tags, pmd_schema_tags, pmd_mapping_tags,
--         pmd_dataflow_tags, pmd_connection_tags, pmd_vendor_tags, pmd_schedule_tags
-- ============================================================================

-- ============================================================================
-- APPS TABLE - Primary Grouping for Artifacts
-- ============================================================================

CREATE TABLE IF NOT EXISTS pmd_apps (
  pmd_app_id SERIAL PRIMARY KEY,
  app_name VARCHAR(100) NOT NULL UNIQUE,
  app_description TEXT,
  app_color VARCHAR(7) DEFAULT '#0066cc', -- Hex color for UI
  app_icon VARCHAR(50) DEFAULT 'Package', -- Lucide icon name
  owner_id INT REFERENCES pmd_users(pmd_user_id) ON DELETE SET NULL,
  created_by INT REFERENCES pmd_users(pmd_user_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

-- ============================================================================
-- TAGS TABLE - Secondary Flexible Grouping
-- ============================================================================

CREATE TABLE IF NOT EXISTS pmd_tags (
  pmd_tag_id SERIAL PRIMARY KEY,
  tag_name VARCHAR(50) NOT NULL UNIQUE,
  tag_color VARCHAR(7) DEFAULT '#6c757d', -- Hex color for tag pills
  tag_description TEXT,
  created_by INT REFERENCES pmd_users(pmd_user_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

-- ============================================================================
-- TAG JUNCTION TABLES (Many-to-Many)
-- ============================================================================

-- Schema Tags
CREATE TABLE IF NOT EXISTS pmd_schema_tags (
  pmd_schemas_registry_id BIGINT REFERENCES pmd_schemas_registry(pmd_schemas_registry_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_schemas_registry_id, pmd_tag_id)
);

-- Mapping Tags
CREATE TABLE IF NOT EXISTS pmd_mapping_tags (
  pmd_field_mappings_id BIGINT REFERENCES pmd_field_mappings(pmd_field_mappings_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_field_mappings_id, pmd_tag_id)
);

-- Data Flow Tags
CREATE TABLE IF NOT EXISTS pmd_dataflow_tags (
  pmd_data_flow_id BIGINT REFERENCES pmd_data_flows(pmd_data_flow_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_data_flow_id, pmd_tag_id)
);

-- Connection Tags
CREATE TABLE IF NOT EXISTS pmd_connection_tags (
  pmd_connections_registry_id BIGINT REFERENCES pmd_connections_registry(pmd_connections_registry_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_connections_registry_id, pmd_tag_id)
);

-- Vendor Tags
CREATE TABLE IF NOT EXISTS pmd_vendor_tags (
  pmd_vendor_registry_id BIGINT REFERENCES pmd_vendor_registry(pmd_vendor_registry_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_vendor_registry_id, pmd_tag_id)
);

-- Schedule Tags
CREATE TABLE IF NOT EXISTS pmd_schedule_tags (
  pmd_automation_schedule_id BIGINT REFERENCES pmd_automation_schedules(pmd_automation_schedule_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_automation_schedule_id, pmd_tag_id)
);

-- ============================================================================
-- ADD APP_ID TO EXISTING ARTIFACT TABLES
-- ============================================================================

ALTER TABLE pmd_schemas_registry
ADD COLUMN IF NOT EXISTS pmd_app_id INT REFERENCES pmd_apps(pmd_app_id) ON DELETE SET NULL;

ALTER TABLE pmd_field_mappings
ADD COLUMN IF NOT EXISTS pmd_app_id INT REFERENCES pmd_apps(pmd_app_id) ON DELETE SET NULL;

ALTER TABLE pmd_data_flows
ADD COLUMN IF NOT EXISTS pmd_app_id INT REFERENCES pmd_apps(pmd_app_id) ON DELETE SET NULL;

ALTER TABLE pmd_connections_registry
ADD COLUMN IF NOT EXISTS pmd_app_id INT REFERENCES pmd_apps(pmd_app_id) ON DELETE SET NULL;

ALTER TABLE pmd_vendor_registry
ADD COLUMN IF NOT EXISTS pmd_app_id INT REFERENCES pmd_apps(pmd_app_id) ON DELETE SET NULL;

ALTER TABLE pmd_automation_schedules
ADD COLUMN IF NOT EXISTS pmd_app_id INT REFERENCES pmd_apps(pmd_app_id) ON DELETE SET NULL;

-- ============================================================================
-- INDEXES
-- ============================================================================

-- App ID indexes on artifact tables
CREATE INDEX IF NOT EXISTS idx_schemas_app_id ON pmd_schemas_registry(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_mappings_app_id ON pmd_field_mappings(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_dataflows_app_id ON pmd_data_flows(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_connections_app_id ON pmd_connections_registry(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_vendors_app_id ON pmd_vendor_registry(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_schedules_app_id ON pmd_automation_schedules(pmd_app_id);

-- Tag junction table indexes
CREATE INDEX IF NOT EXISTS idx_schema_tags_schema ON pmd_schema_tags(pmd_schemas_registry_id);
CREATE INDEX IF NOT EXISTS idx_schema_tags_tag ON pmd_schema_tags(pmd_tag_id);
CREATE INDEX IF NOT EXISTS idx_mapping_tags_mapping ON pmd_mapping_tags(pmd_field_mappings_id);
CREATE INDEX IF NOT EXISTS idx_mapping_tags_tag ON pmd_mapping_tags(pmd_tag_id);
CREATE INDEX IF NOT EXISTS idx_dataflow_tags_dataflow ON pmd_dataflow_tags(pmd_data_flow_id);
CREATE INDEX IF NOT EXISTS idx_dataflow_tags_tag ON pmd_dataflow_tags(pmd_tag_id);
CREATE INDEX IF NOT EXISTS idx_connection_tags_connection ON pmd_connection_tags(pmd_connections_registry_id);
CREATE INDEX IF NOT EXISTS idx_connection_tags_tag ON pmd_connection_tags(pmd_tag_id);
CREATE INDEX IF NOT EXISTS idx_vendor_tags_vendor ON pmd_vendor_tags(pmd_vendor_registry_id);
CREATE INDEX IF NOT EXISTS idx_vendor_tags_tag ON pmd_vendor_tags(pmd_tag_id);
CREATE INDEX IF NOT EXISTS idx_schedule_tags_schedule ON pmd_schedule_tags(pmd_automation_schedule_id);
CREATE INDEX IF NOT EXISTS idx_schedule_tags_tag ON pmd_schedule_tags(pmd_tag_id);

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Default "Unassigned" app for artifacts without an app
INSERT INTO pmd_apps (app_name, app_description, app_color, app_icon, is_active)
VALUES ('Unassigned', 'Default app for uncategorized artifacts', '#6c757d', 'Inbox', true)
ON CONFLICT (app_name) DO NOTHING;

-- Default tags for common use cases
INSERT INTO pmd_tags (tag_name, tag_color, tag_description)
VALUES
  ('production', '#28a745', 'Production-ready artifacts'),
  ('testing', '#ffc107', 'Testing and QA artifacts'),
  ('development', '#17a2b8', 'Development/experimental artifacts'),
  ('deprecated', '#dc3545', 'Deprecated artifacts'),
  ('high-priority', '#ff6b6b', 'High priority items'),
  ('claims', '#0066cc', 'Claims processing related'),
  ('eligibility', '#9c27b0', 'Eligibility related'),
  ('remittance', '#4caf50', 'Remittance/payment related'),
  ('patient-data', '#ff9800', 'Patient/member data related'),
  ('hipaa-sensitive', '#e91e63', 'Contains PHI/sensitive data')
ON CONFLICT (tag_name) DO NOTHING;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE pmd_apps IS 'Apps for primary grouping of artifacts (1-to-1 relationship)';
COMMENT ON TABLE pmd_tags IS 'Tags for flexible cross-cutting categorization (many-to-many)';
COMMENT ON COLUMN pmd_apps.app_color IS 'Hex color code for UI display (e.g., #0066cc)';
COMMENT ON COLUMN pmd_apps.app_icon IS 'Lucide React icon name (e.g., Package, Workflow)';
COMMENT ON COLUMN pmd_tags.tag_color IS 'Hex color code for tag pill display';
