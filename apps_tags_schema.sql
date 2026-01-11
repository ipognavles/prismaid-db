-- ============================================
-- Prismaid Apps & Tags Feature
-- Version: 1.0
-- Date: January 10, 2026
-- ============================================

-- Add missing primary keys if they don't exist (safety check)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pmd_field_mappings_pk'
    ) THEN
        ALTER TABLE pmd_field_mappings
        ADD CONSTRAINT pmd_field_mappings_pk PRIMARY KEY (pmd_field_mappings_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pmd_schemas_registry_pk'
    ) THEN
        ALTER TABLE pmd_schemas_registry
        ADD CONSTRAINT pmd_schemas_registry_pk PRIMARY KEY (pmd_schemas_registry_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pmd_data_flows_pk'
    ) THEN
        ALTER TABLE pmd_data_flows
        ADD CONSTRAINT pmd_data_flows_pk PRIMARY KEY (pmd_data_flow_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pmd_connections_registry_pk'
    ) THEN
        ALTER TABLE pmd_connections_registry
        ADD CONSTRAINT pmd_connections_registry_pk PRIMARY KEY (pmd_connections_registry_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pmd_vendor_registry_pk'
    ) THEN
        ALTER TABLE pmd_vendor_registry
        ADD CONSTRAINT pmd_vendor_registry_pk PRIMARY KEY (pmd_vendor_registry_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pmd_automation_schedules_pk'
    ) THEN
        ALTER TABLE pmd_automation_schedules
        ADD CONSTRAINT pmd_automation_schedules_pk PRIMARY KEY (pmd_automation_schedule_id);
    END IF;
END $$;

-- Apps table - Primary grouping for artifacts
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

-- Tags table - Secondary flexible grouping
CREATE TABLE IF NOT EXISTS pmd_tags (
  pmd_tag_id SERIAL PRIMARY KEY,
  tag_name VARCHAR(50) NOT NULL UNIQUE,
  tag_color VARCHAR(7) DEFAULT '#6c757d', -- Hex color for tag pills
  tag_description TEXT,
  created_by INT REFERENCES pmd_users(pmd_user_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

-- Schema Tags (many-to-many)
CREATE TABLE IF NOT EXISTS pmd_schema_tags (
  pmd_schemas_registry_id BIGINT REFERENCES pmd_schemas_registry(pmd_schemas_registry_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_schemas_registry_id, pmd_tag_id)
);

-- Mapping Tags (many-to-many)
CREATE TABLE IF NOT EXISTS pmd_mapping_tags (
  pmd_field_mappings_id BIGINT REFERENCES pmd_field_mappings(pmd_field_mappings_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_field_mappings_id, pmd_tag_id)
);

-- Data Flow Tags (many-to-many)
CREATE TABLE IF NOT EXISTS pmd_dataflow_tags (
  pmd_data_flow_id BIGINT REFERENCES pmd_data_flows(pmd_data_flow_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_data_flow_id, pmd_tag_id)
);

-- Connection Tags (many-to-many)
CREATE TABLE IF NOT EXISTS pmd_connection_tags (
  pmd_connections_registry_id BIGINT REFERENCES pmd_connections_registry(pmd_connections_registry_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_connections_registry_id, pmd_tag_id)
);

-- Vendor Tags (many-to-many)
CREATE TABLE IF NOT EXISTS pmd_vendor_tags (
  pmd_vendor_registry_id BIGINT REFERENCES pmd_vendor_registry(pmd_vendor_registry_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_vendor_registry_id, pmd_tag_id)
);

-- Schedule Tags (many-to-many)
CREATE TABLE IF NOT EXISTS pmd_schedule_tags (
  pmd_automation_schedule_id BIGINT REFERENCES pmd_automation_schedules(pmd_automation_schedule_id) ON DELETE CASCADE,
  pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pmd_automation_schedule_id, pmd_tag_id)
);

-- Add app_id to existing artifact tables
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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_schemas_app_id ON pmd_schemas_registry(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_mappings_app_id ON pmd_field_mappings(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_dataflows_app_id ON pmd_data_flows(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_connections_app_id ON pmd_connections_registry(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_vendors_app_id ON pmd_vendor_registry(pmd_app_id);
CREATE INDEX IF NOT EXISTS idx_schedules_app_id ON pmd_automation_schedules(pmd_app_id);

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

-- Insert default "Unassigned" app (optional - for artifacts without an app)
INSERT INTO pmd_apps (app_name, app_description, app_color, app_icon, is_active)
VALUES ('Unassigned', 'Default app for uncategorized artifacts', '#6c757d', 'Inbox', true)
ON CONFLICT (app_name) DO NOTHING;

-- Insert some default tags for common use cases
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

-- Sequences (already created by SERIAL type, but listing for reference)
-- pmd_apps_seq
-- pmd_tags_seq

COMMENT ON TABLE pmd_apps IS 'Apps for primary grouping of artifacts (1-to-1 relationship)';
COMMENT ON TABLE pmd_tags IS 'Tags for flexible cross-cutting categorization (many-to-many)';
COMMENT ON COLUMN pmd_apps.app_color IS 'Hex color code for UI display (e.g., #0066cc)';
COMMENT ON COLUMN pmd_apps.app_icon IS 'Lucide React icon name (e.g., Package, Workflow)';
COMMENT ON COLUMN pmd_tags.tag_color IS 'Hex color code for tag pill display';
