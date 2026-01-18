-- ============================================================================
-- Prismaid Database - Core ETL
-- ============================================================================
-- Description: Core ETL entities - vendors, schemas, mappings, connections, flows
-- Dependencies: 001_reference_data.sql
-- Tables: pmd_vendor_registry, pmd_schemas_registry, pmd_field_mappings,
--         pmd_connections_registry, pmd_data_flows, pmd_data_flow_runs
-- ============================================================================

-- ============================================================================
-- VENDOR REGISTRY
-- ============================================================================

CREATE SEQUENCE pmd_vendor_registry_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_vendor_registry (
    pmd_vendor_registry_id BIGINT DEFAULT nextval('pmd_vendor_registry_seq'::regclass) NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    vendor_desc TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_vendor_registry_pk PRIMARY KEY (pmd_vendor_registry_id)
);


-- ============================================================================
-- SCHEMA REGISTRY
-- ============================================================================

CREATE SEQUENCE pmd_schemas_registry_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_schemas_registry (
    pmd_schemas_registry_id BIGINT DEFAULT nextval('pmd_schemas_registry_seq'::regclass) NOT NULL,
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
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_schemas_registry_pk PRIMARY KEY (pmd_schemas_registry_id),
    CONSTRAINT pmd_schemas_vendor_fk FOREIGN KEY (pmd_vendor_registry_id)
        REFERENCES pmd_vendor_registry(pmd_vendor_registry_id),
    CONSTRAINT pmd_schemas_type_fk FOREIGN KEY (schema_type)
        REFERENCES pmd_reference_value(pmd_reference_value_id),
    CONSTRAINT pmd_schemas_source_fk FOREIGN KEY (schema_source)
        REFERENCES pmd_reference_value(pmd_reference_value_id),
    CONSTRAINT pmd_schemas_format_fk FOREIGN KEY (schema_format)
        REFERENCES pmd_reference_value(pmd_reference_value_id)
);

-- Versioning columns for schema version management
ALTER TABLE pmd_schemas_registry ADD COLUMN IF NOT EXISTS version_number INTEGER DEFAULT 1;
ALTER TABLE pmd_schemas_registry ADD COLUMN IF NOT EXISTS parent_schema_id BIGINT;
ALTER TABLE pmd_schemas_registry ADD COLUMN IF NOT EXISTS version_notes TEXT;

-- Self-referencing foreign key for version chain (parent schema link)
-- Note: Using DO block to avoid error if constraint already exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pmd_schemas_parent_fk'
    ) THEN
        ALTER TABLE pmd_schemas_registry ADD CONSTRAINT pmd_schemas_parent_fk
            FOREIGN KEY (parent_schema_id) REFERENCES pmd_schemas_registry(pmd_schemas_registry_id);
    END IF;
END $$;

-- ============================================================================
-- FIELD MAPPINGS
-- ============================================================================

CREATE SEQUENCE pmd_field_mappings_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_field_mappings (
    pmd_field_mappings_id BIGINT DEFAULT nextval('pmd_field_mappings_seq'::regclass) NOT NULL,
    map_name VARCHAR(255) NOT NULL,
    map_description TEXT,
    source_schema_id BIGINT,
    target_schema_id BIGINT,
    field_mappings JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_field_mappings_pk PRIMARY KEY (pmd_field_mappings_id),
    CONSTRAINT pmd_mappings_source_fk FOREIGN KEY (source_schema_id)
        REFERENCES pmd_schemas_registry(pmd_schemas_registry_id),
    CONSTRAINT pmd_mappings_target_fk FOREIGN KEY (target_schema_id)
        REFERENCES pmd_schemas_registry(pmd_schemas_registry_id)
);


-- ============================================================================
-- CONNECTIONS REGISTRY
-- ============================================================================

CREATE SEQUENCE pmd_connections_registry_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_connections_registry (
    pmd_connections_registry_id BIGINT DEFAULT nextval('pmd_connections_registry_seq'::regclass) NOT NULL,
    connection_name VARCHAR(255) NOT NULL,
    connection_desc TEXT,
    pmd_reference_value_id BIGINT NOT NULL,
    connection_subtype VARCHAR(100) NOT NULL,
    connection_config JSONB NOT NULL,
    last_validated_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_connections_registry_pk PRIMARY KEY (pmd_connections_registry_id),
    CONSTRAINT pmd_connections_type_fk FOREIGN KEY (pmd_reference_value_id)
        REFERENCES pmd_reference_value(pmd_reference_value_id)
);

-- ============================================================================
-- DATA FLOWS TABLE
-- ============================================================================

CREATE SEQUENCE pmd_data_flows_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_data_flows (
    pmd_data_flow_id BIGINT DEFAULT nextval('pmd_data_flows_seq'::regclass) NOT NULL,
    flow_name VARCHAR(255) NOT NULL,
    flow_desc TEXT,
    flow_definition JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true NOT NULL,
    last_run_at TIMESTAMP WITH TIME ZONE,
    last_run_status VARCHAR(50),
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_data_flows_pk PRIMARY KEY (pmd_data_flow_id)
);


-- ============================================================================
-- DATA FLOW RUNS TABLE
-- ============================================================================

CREATE SEQUENCE pmd_data_flow_runs_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_data_flow_runs (
    pmd_data_flow_run_id BIGINT DEFAULT nextval('pmd_data_flow_runs_seq'::regclass) NOT NULL,
    pmd_data_flow_id BIGINT NOT NULL,
    run_status VARCHAR(50) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    execution_logs TEXT,
    error_message TEXT,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_data_flow_runs_pk PRIMARY KEY (pmd_data_flow_run_id),
    CONSTRAINT pmd_data_flow_runs_flow_fk FOREIGN KEY (pmd_data_flow_id)
        REFERENCES pmd_data_flows(pmd_data_flow_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pmd_data_flow_runs_flow ON pmd_data_flow_runs(pmd_data_flow_id);
CREATE INDEX IF NOT EXISTS idx_pmd_data_flow_runs_status ON pmd_data_flow_runs(run_status);
CREATE INDEX IF NOT EXISTS idx_pmd_data_flow_runs_started ON pmd_data_flow_runs(started_at);


-- ============================================================================
-- MIGRATION IMPORTS (Import History & Rollback Tracking)
-- ============================================================================

CREATE SEQUENCE IF NOT EXISTS pmd_migration_imports_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_migration_imports (
    pmd_migration_import_id BIGINT DEFAULT nextval('pmd_migration_imports_seq'::regclass) NOT NULL,
    import_notes TEXT,
    source_system VARCHAR(255),
    source_filename VARCHAR(255),
    export_version VARCHAR(20),
    exported_at TIMESTAMP WITH TIME ZONE,
    exported_by VARCHAR(100),
    artifacts_summary JSONB,
    artifacts_detail JSONB,
    conflict_resolutions JSONB,
    import_status VARCHAR(20) DEFAULT 'success',
    error_details JSONB,
    is_rolled_back BOOLEAN DEFAULT false,
    rolled_back_at TIMESTAMP WITH TIME ZONE,
    rolled_back_by BIGINT,
    rolled_back_by_name VARCHAR(100),
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR(100) DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_migration_imports_pk PRIMARY KEY (pmd_migration_import_id)
);

CREATE INDEX IF NOT EXISTS idx_pmd_migration_imports_created ON pmd_migration_imports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pmd_migration_imports_status ON pmd_migration_imports(import_status);
CREATE INDEX IF NOT EXISTS idx_pmd_migration_imports_rolled_back ON pmd_migration_imports(is_rolled_back);
