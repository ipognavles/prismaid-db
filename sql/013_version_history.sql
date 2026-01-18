-- ============================================================================
-- Prismaid Database - Version History
-- ============================================================================
-- Description: Version history tracking for schemas, mappings, and data flows
--              Implements SharePoint-style version management with:
--              - Full snapshot of entity at each version
--              - Change descriptions (changelog)
--              - Compare and restore capabilities
-- Dependencies: 003_core_etl.sql
-- Tables: pmd_schemas_registry_history, pmd_field_mappings_history,
--         pmd_data_flows_history
-- ============================================================================

-- ============================================================================
-- SCHEMAS VERSION HISTORY
-- ============================================================================

CREATE SEQUENCE IF NOT EXISTS pmd_schemas_registry_history_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_schemas_registry_history (
    pmd_schemas_registry_history_id BIGINT DEFAULT nextval('pmd_schemas_registry_history_seq'::regclass) NOT NULL,
    pmd_schemas_registry_id BIGINT NOT NULL,
    version_number INTEGER NOT NULL,

    -- Snapshot of all entity fields at this version
    schema_name VARCHAR(255) NOT NULL,
    schema_desc TEXT,
    pmd_vendor_registry_id BIGINT,
    schema_type BIGINT,
    schema_source BIGINT,
    schema_format BIGINT,
    schema_definition JSONB NOT NULL,
    raw_content TEXT,
    delimiter VARCHAR(10),
    edi_transaction VARCHAR(50),
    swagger_url TEXT,

    -- Version metadata
    change_description TEXT,
    change_type VARCHAR(20) NOT NULL,  -- 'created', 'updated', 'restored'

    -- Audit fields (who/when created this version)
    created_by BIGINT NOT NULL,
    created_by_name VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_schemas_registry_history_pk PRIMARY KEY (pmd_schemas_registry_history_id),
    CONSTRAINT pmd_schemas_history_parent_fk FOREIGN KEY (pmd_schemas_registry_id)
        REFERENCES pmd_schemas_registry(pmd_schemas_registry_id) ON DELETE CASCADE,
    CONSTRAINT pmd_schemas_history_unique_version UNIQUE (pmd_schemas_registry_id, version_number),
    CONSTRAINT pmd_schemas_history_change_type_chk CHECK (change_type IN ('created', 'updated', 'restored'))
);

CREATE INDEX IF NOT EXISTS idx_schemas_history_parent ON pmd_schemas_registry_history(pmd_schemas_registry_id);
CREATE INDEX IF NOT EXISTS idx_schemas_history_version ON pmd_schemas_registry_history(pmd_schemas_registry_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_schemas_history_created ON pmd_schemas_registry_history(created_at DESC);


-- ============================================================================
-- FIELD MAPPINGS VERSION HISTORY
-- ============================================================================

CREATE SEQUENCE IF NOT EXISTS pmd_field_mappings_history_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_field_mappings_history (
    pmd_field_mappings_history_id BIGINT DEFAULT nextval('pmd_field_mappings_history_seq'::regclass) NOT NULL,
    pmd_field_mappings_id BIGINT NOT NULL,
    version_number INTEGER NOT NULL,

    -- Snapshot of all entity fields at this version
    map_name VARCHAR(255) NOT NULL,
    map_description TEXT,
    source_schema_id BIGINT,
    target_schema_id BIGINT,
    field_mappings JSONB NOT NULL,

    -- Version metadata
    change_description TEXT,
    change_type VARCHAR(20) NOT NULL,  -- 'created', 'updated', 'restored'

    -- Audit fields
    created_by BIGINT NOT NULL,
    created_by_name VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_field_mappings_history_pk PRIMARY KEY (pmd_field_mappings_history_id),
    CONSTRAINT pmd_mappings_history_parent_fk FOREIGN KEY (pmd_field_mappings_id)
        REFERENCES pmd_field_mappings(pmd_field_mappings_id) ON DELETE CASCADE,
    CONSTRAINT pmd_mappings_history_unique_version UNIQUE (pmd_field_mappings_id, version_number),
    CONSTRAINT pmd_mappings_history_change_type_chk CHECK (change_type IN ('created', 'updated', 'restored'))
);

CREATE INDEX IF NOT EXISTS idx_mappings_history_parent ON pmd_field_mappings_history(pmd_field_mappings_id);
CREATE INDEX IF NOT EXISTS idx_mappings_history_version ON pmd_field_mappings_history(pmd_field_mappings_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_mappings_history_created ON pmd_field_mappings_history(created_at DESC);


-- ============================================================================
-- DATA FLOWS VERSION HISTORY
-- ============================================================================

CREATE SEQUENCE IF NOT EXISTS pmd_data_flows_history_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_data_flows_history (
    pmd_data_flows_history_id BIGINT DEFAULT nextval('pmd_data_flows_history_seq'::regclass) NOT NULL,
    pmd_data_flow_id BIGINT NOT NULL,
    version_number INTEGER NOT NULL,

    -- Snapshot of all entity fields at this version
    flow_name VARCHAR(255) NOT NULL,
    flow_desc TEXT,
    flow_definition JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Version metadata
    change_description TEXT,
    change_type VARCHAR(20) NOT NULL,  -- 'created', 'updated', 'restored'

    -- Audit fields
    created_by BIGINT NOT NULL,
    created_by_name VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_data_flows_history_pk PRIMARY KEY (pmd_data_flows_history_id),
    CONSTRAINT pmd_dataflows_history_parent_fk FOREIGN KEY (pmd_data_flow_id)
        REFERENCES pmd_data_flows(pmd_data_flow_id) ON DELETE CASCADE,
    CONSTRAINT pmd_dataflows_history_unique_version UNIQUE (pmd_data_flow_id, version_number),
    CONSTRAINT pmd_dataflows_history_change_type_chk CHECK (change_type IN ('created', 'updated', 'restored'))
);

CREATE INDEX IF NOT EXISTS idx_dataflows_history_parent ON pmd_data_flows_history(pmd_data_flow_id);
CREATE INDEX IF NOT EXISTS idx_dataflows_history_version ON pmd_data_flows_history(pmd_data_flow_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_dataflows_history_created ON pmd_data_flows_history(created_at DESC);


-- ============================================================================
-- ADD CURRENT VERSION COLUMN TO MAIN TABLES
-- ============================================================================

ALTER TABLE pmd_schemas_registry ADD COLUMN IF NOT EXISTS current_version INTEGER DEFAULT 1;
ALTER TABLE pmd_field_mappings ADD COLUMN IF NOT EXISTS current_version INTEGER DEFAULT 1;
ALTER TABLE pmd_data_flows ADD COLUMN IF NOT EXISTS current_version INTEGER DEFAULT 1;


-- ============================================================================
-- MIGRATION: CREATE INITIAL VERSION (v1) FOR EXISTING RECORDS
-- ============================================================================
-- This migration creates version 1 entries for all existing entities
-- that don't already have a version history entry.
-- Run this once after creating the tables.

-- Migrate existing schemas to version history
INSERT INTO pmd_schemas_registry_history (
    pmd_schemas_registry_id,
    version_number,
    schema_name,
    schema_desc,
    pmd_vendor_registry_id,
    schema_type,
    schema_source,
    schema_format,
    schema_definition,
    raw_content,
    delimiter,
    edi_transaction,
    swagger_url,
    change_description,
    change_type,
    created_by,
    created_by_name,
    created_at
)
SELECT
    s.pmd_schemas_registry_id,
    1 AS version_number,
    s.schema_name,
    s.schema_desc,
    s.pmd_vendor_registry_id,
    s.schema_type,
    s.schema_source,
    s.schema_format,
    s.schema_definition,
    s.raw_content,
    s.delimiter,
    s.edi_transaction,
    s.swagger_url,
    'Initial version (migrated from existing data)' AS change_description,
    'created' AS change_type,
    s.created_by,
    s.created_by_name,
    s.created_at
FROM pmd_schemas_registry s
WHERE s.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM pmd_schemas_registry_history h
    WHERE h.pmd_schemas_registry_id = s.pmd_schemas_registry_id
  );

-- Migrate existing mappings to version history
INSERT INTO pmd_field_mappings_history (
    pmd_field_mappings_id,
    version_number,
    map_name,
    map_description,
    source_schema_id,
    target_schema_id,
    field_mappings,
    change_description,
    change_type,
    created_by,
    created_by_name,
    created_at
)
SELECT
    m.pmd_field_mappings_id,
    1 AS version_number,
    m.map_name,
    m.map_description,
    m.source_schema_id,
    m.target_schema_id,
    m.field_mappings,
    'Initial version (migrated from existing data)' AS change_description,
    'created' AS change_type,
    m.created_by,
    m.created_by_name,
    m.created_at
FROM pmd_field_mappings m
WHERE m.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM pmd_field_mappings_history h
    WHERE h.pmd_field_mappings_id = m.pmd_field_mappings_id
  );

-- Migrate existing data flows to version history
INSERT INTO pmd_data_flows_history (
    pmd_data_flow_id,
    version_number,
    flow_name,
    flow_desc,
    flow_definition,
    change_description,
    change_type,
    created_by,
    created_by_name,
    created_at
)
SELECT
    f.pmd_data_flow_id,
    1 AS version_number,
    f.flow_name,
    f.flow_desc,
    f.flow_definition,
    'Initial version (migrated from existing data)' AS change_description,
    'created' AS change_type,
    f.created_by,
    f.created_by_name,
    f.created_at
FROM pmd_data_flows f
WHERE f.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM pmd_data_flows_history h
    WHERE h.pmd_data_flow_id = f.pmd_data_flow_id
  );


-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE pmd_schemas_registry_history IS 'Version history for schema definitions - stores complete snapshots at each version';
COMMENT ON TABLE pmd_field_mappings_history IS 'Version history for field mappings - stores complete snapshots at each version';
COMMENT ON TABLE pmd_data_flows_history IS 'Version history for data flows - stores complete snapshots at each version';

COMMENT ON COLUMN pmd_schemas_registry_history.version_number IS 'Sequential version number starting from 1';
COMMENT ON COLUMN pmd_schemas_registry_history.change_description IS 'Optional user-provided description of what changed in this version';
COMMENT ON COLUMN pmd_schemas_registry_history.change_type IS 'Type of change: created (initial), updated (modified), restored (reverted to previous version)';
