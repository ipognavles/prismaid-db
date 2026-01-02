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
    (4, 'EVENT_STREAM', 'Event Stream', 'Event Stream');

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
-- FILE UPLOADS
-- ============================================================================

-- DROP SEQUENCE pmd_file_uploads_seq;
CREATE SEQUENCE pmd_file_uploads_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_file_uploads (
    pmd_file_uploads_id BIGINT DEFAULT nextval('pmd_file_uploads_seq'::regclass) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50),
    file_path VARCHAR(500),
    detected_fields JSONB,
    sample_data JSONB,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_file_uploads_pk PRIMARY KEY (pmd_file_uploads_id)
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