-- ============================================================================
-- Prismaid Database Setup Script
-- ============================================================================
-- Create database (run as postgres superuser)
-- CREATE DATABASE prismaid;
-- \c prismaid

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================================================
-- REFERENCE TABLES
-- ============================================================================

-- DROP SEQUENCE pmd_reference_category_seq;
CREATE SEQUENCE pmd_reference_category_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_reference_category (
    pmd_reference_category_id BIGINT DEFAULT nextval('pmd_reference_category_seq'::regclass) NOT NULL,
    reference_category VARCHAR NOT NULL,
    reference_description VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_reference_category_pk PRIMARY KEY (pmd_reference_category_id)
);

-- DROP SEQUENCE pmd_reference_value_seq;
CREATE SEQUENCE pmd_reference_value_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_reference_value (
    pmd_reference_value_id BIGINT DEFAULT nextval('pmd_reference_value_seq'::regclass) NOT NULL,
    pmd_reference_category_id BIGINT NOT NULL,
    reference_value_code VARCHAR NOT NULL,
    reference_value_name VARCHAR NOT NULL,
    reference_value_desc VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_reference_value_pk PRIMARY KEY (pmd_reference_value_id),
    CONSTRAINT pmd_reference_category_fk FOREIGN KEY (pmd_reference_category_id) 
        REFERENCES pmd_reference_category(pmd_reference_category_id)
);


-- ============================================================================
-- REFERENCE DATA
-- ============================================================================

-- Schema Type Reference Data
INSERT INTO pmd_reference_category (pmd_reference_category_id, reference_category, reference_description) 
VALUES (1, 'schema_type', 'Type of Schema');

INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc) 
VALUES 
    (1, 'source', 'source', 'source'),
    (1, 'target', 'target', 'target'),
    (1, 'generic', 'generic', 'generic');

-- Schema Source Reference Data
INSERT INTO pmd_reference_category (pmd_reference_category_id, reference_category, reference_description) 
VALUES (2, 'schema_source', 'Schema Origin');

INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc) 
VALUES 
    (2, 'file', 'file', 'file'),
    (2, 'api', 'api', 'api'),
    (2, 'manual', 'manual', 'manual');

-- Schema Format Reference Data
INSERT INTO pmd_reference_category (pmd_reference_category_id, reference_category, reference_description) 
VALUES (3, 'schema_format', 'Schema Format');

INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc) 
VALUES 
    (3, 'json', 'json', 'json'),
    (3, 'xml', 'xml', 'xml'),
    (3, 'csv', 'csv', 'csv'),
    (3, 'tsv', 'tsv', 'tsv'),
    (3, 'pipe', 'pipe', 'pipe'),
    (3, 'edi', 'edi', 'edi'),
    (3, 'xlsx', 'xlsx', 'xlsx'),
    (3, 'sql', 'sql', 'sql'),
    (3, 'custom', 'custom', 'custom');

-- Schema Format Reference Data
INSERT INTO pmd_reference_category (pmd_reference_category_id, reference_category, reference_description) 
VALUES (4, 'connection_type', 'Connection Type');

INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc) 
VALUES 
    (4, 'SQL_DB', 'SQL Database', 'SQL Database'),
    (4, 'NOSQL_DB', 'NoSQL Database', 'NoSQL Database'),
    (4, 'API', 'API', 'API'),
    (4, 'SFTP_FTPS', 'SFTP / FTPS', 'SFTP / FTPS'),
    (4, 'FILE_STORAGE', 'File Storage', 'File Storage'),
    (4, 'MSG_QUEUE', 'Message Queue', 'Message Queue'),
    (4, 'EVENT_STREAM', 'Event Stream', 'Event Stream'),
    (4, 'AI_SERVICES', 'AI Services', 'AI Services');

-- ============================================================================
-- VENDOR REGISTRY
-- ============================================================================

-- DROP SEQUENCE pmd_vendor_registry_seq;
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

-- DROP SEQUENCE pmd_schemas_registry_seq;
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

-- ============================================================================
-- FIELD MAPPINGS
-- ============================================================================

-- DROP SEQUENCE pmd_field_mappings_seq;
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

-- DROP SEQUENCE pmd_connections_registry_seq;
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
-- AUTOMATION SCHEDULES TABLE
-- ============================================================================

CREATE SEQUENCE pmd_automation_schedules_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_automation_schedules (
    pmd_automation_schedule_id BIGINT DEFAULT nextval('pmd_automation_schedules_seq'::regclass) NOT NULL,
    schedule_name VARCHAR(255) NOT NULL,
    schedule_desc TEXT,
    pmd_data_flow_id BIGINT NOT NULL,
    cron_expression VARCHAR(100) NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC' NOT NULL,
    next_run_at TIMESTAMP WITH TIME ZONE,
    last_run_at TIMESTAMP WITH TIME ZONE,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    run_count INTEGER DEFAULT 0,
    last_error TEXT,
    last_error_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_automation_schedules_pk PRIMARY KEY (pmd_automation_schedule_id),
    CONSTRAINT pmd_schedules_flow_fk FOREIGN KEY (pmd_data_flow_id) 
        REFERENCES pmd_data_flows(pmd_data_flow_id) ON DELETE CASCADE
);

CREATE INDEX idx_schedules_flow ON pmd_automation_schedules(pmd_data_flow_id);
CREATE INDEX idx_schedules_next_run ON pmd_automation_schedules(next_run_at) WHERE is_active = true;


-- ============================================================================
-- FLOW EXECUTIONS TABLE (Detailed History)
-- ============================================================================

CREATE SEQUENCE pmd_flow_executions_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_flow_executions (
    pmd_flow_execution_id BIGINT DEFAULT nextval('pmd_flow_executions_seq'::regclass) NOT NULL,
    pmd_data_flow_id BIGINT NOT NULL,
    pmd_automation_schedule_id BIGINT,
    execution_trigger VARCHAR(50) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds NUMERIC(10,2),
    status VARCHAR(50) NOT NULL,
    nodes_executed INTEGER DEFAULT 0,
    rows_processed INTEGER DEFAULT 0,
    logs_jsonb JSONB,
    error_message TEXT,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_flow_executions_pk PRIMARY KEY (pmd_flow_execution_id),
    CONSTRAINT pmd_executions_flow_fk FOREIGN KEY (pmd_data_flow_id) 
        REFERENCES pmd_data_flows(pmd_data_flow_id) ON DELETE CASCADE,
    CONSTRAINT pmd_executions_schedule_fk FOREIGN KEY (pmd_automation_schedule_id) 
        REFERENCES pmd_automation_schedules(pmd_automation_schedule_id) ON DELETE SET NULL
);

CREATE INDEX idx_executions_flow ON pmd_flow_executions(pmd_data_flow_id);
CREATE INDEX idx_executions_schedule ON pmd_flow_executions(pmd_automation_schedule_id);
CREATE INDEX idx_executions_started ON pmd_flow_executions(started_at DESC);
CREATE INDEX idx_executions_status ON pmd_flow_executions(status);