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


-- ============================================================================
-- EDI TABLES (Phase 2: Healthcare Formats)
-- ============================================================================

-- EDI Files Registry
CREATE SEQUENCE pmd_edi_files_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_edi_files (
    pmd_edi_file_id BIGINT DEFAULT nextval('pmd_edi_files_seq'::regclass) NOT NULL,

    -- File metadata
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    file_hash VARCHAR(64),  -- SHA-256

    -- EDI envelope data (ISA/GS)
    transaction_set VARCHAR(10) NOT NULL,  -- '837P', '837I', '835', '834'
    transaction_version VARCHAR(20),  -- '005010X222A2'
    sender_id VARCHAR(15),  -- ISA06
    receiver_id VARCHAR(15),  -- ISA08
    control_number VARCHAR(9),  -- ISA13
    interchange_date DATE,  -- ISA09
    interchange_time TIME,  -- ISA10
    functional_group_control_number VARCHAR(9),  -- GS06
    functional_group_date DATE,  -- GS04

    -- Parsing results
    parsed_at TIMESTAMP WITH TIME ZONE,
    parse_status VARCHAR(20) DEFAULT 'pending',  -- pending, success, error, warning
    parse_errors JSONB,  -- Array of error objects
    parse_warnings JSONB,  -- Array of warning objects
    total_transactions INTEGER DEFAULT 0,
    total_segments INTEGER DEFAULT 0,

    -- Business metadata
    vendor_id BIGINT,  -- FK to pmd_vendor_registry
    uploaded_by BIGINT,  -- FK to future user table

    -- Full raw EDI for debugging/re-processing
    raw_edi_content TEXT,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_edi_files_pk PRIMARY KEY (pmd_edi_file_id),
    CONSTRAINT pmd_edi_files_vendor_fk FOREIGN KEY (vendor_id)
        REFERENCES pmd_vendor_registry(pmd_vendor_registry_id)
);

CREATE INDEX idx_edi_files_transaction_set ON pmd_edi_files(transaction_set);
CREATE INDEX idx_edi_files_sender_id ON pmd_edi_files(sender_id);
CREATE INDEX idx_edi_files_parse_status ON pmd_edi_files(parse_status);
CREATE INDEX idx_edi_files_created_at ON pmd_edi_files(created_at DESC);


-- EDI Claims (837P, 837I)
CREATE SEQUENCE pmd_edi_claims_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_edi_claims (
    pmd_claim_id BIGINT DEFAULT nextval('pmd_edi_claims_seq'::regclass) NOT NULL,
    edi_file_id BIGINT NOT NULL,

    -- Claim header data
    claim_id VARCHAR(50),  -- CLM01 (patient account number)
    patient_account_number VARCHAR(50),
    transaction_set VARCHAR(10) NOT NULL,  -- '837P' or '837I'

    -- Claim amounts
    claim_amount NUMERIC(12,2),  -- CLM02
    paid_amount NUMERIC(12,2),  -- For 835 linkage
    patient_responsibility NUMERIC(12,2),

    -- Claim type/frequency
    claim_frequency_code VARCHAR(2),  -- CLM05-3
    place_of_service VARCHAR(2),
    claim_type_code VARCHAR(2),  -- CLM05-1

    -- Patient demographics
    patient_first_name VARCHAR(35),
    patient_last_name VARCHAR(60),
    patient_middle_name VARCHAR(25),
    patient_suffix VARCHAR(10),
    patient_date_of_birth DATE,  -- DMG02
    patient_gender VARCHAR(1),  -- DMG03
    patient_member_id VARCHAR(80),  -- NM109 (subscriber loop)

    -- Service dates
    service_date_from DATE,  -- DTP-472
    service_date_to DATE,

    -- Provider information
    billing_provider_npi VARCHAR(10),  -- NM109 (Loop 2010AA)
    billing_provider_name VARCHAR(60),
    billing_provider_tax_id VARCHAR(9),  -- REF-EI
    rendering_provider_npi VARCHAR(10),  -- NM109 (Loop 2310B)
    rendering_provider_name VARCHAR(60),

    -- Payer information
    payer_id VARCHAR(80),  -- NM109 (Loop 2010BB)
    payer_name VARCHAR(60),

    -- Diagnosis codes (up to 12 allowed in 5010, storing top 4 separately)
    diagnosis_code_1 VARCHAR(10),
    diagnosis_code_2 VARCHAR(10),
    diagnosis_code_3 VARCHAR(10),
    diagnosis_code_4 VARCHAR(10),
    diagnosis_code_qualifier VARCHAR(3),  -- ABK (ICD-10), ABF (ICD-9)
    diagnosis_codes_json JSONB,  -- Full array of all diagnosis codes

    -- Claim status (for claim status tracking)
    claim_status VARCHAR(20),  -- pending, accepted, denied, paid, etc.
    claim_status_date TIMESTAMP WITH TIME ZONE,

    -- Full claim as JSONB (preserves all segments)
    claim_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_edi_claims_pk PRIMARY KEY (pmd_claim_id),
    CONSTRAINT pmd_edi_claims_file_fk FOREIGN KEY (edi_file_id)
        REFERENCES pmd_edi_files(pmd_edi_file_id) ON DELETE CASCADE
);

CREATE INDEX idx_edi_claims_file_id ON pmd_edi_claims(edi_file_id);
CREATE INDEX idx_edi_claims_claim_id ON pmd_edi_claims(claim_id);
CREATE INDEX idx_edi_claims_patient_name ON pmd_edi_claims(patient_last_name, patient_first_name);
CREATE INDEX idx_edi_claims_billing_npi ON pmd_edi_claims(billing_provider_npi);
CREATE INDEX idx_edi_claims_payer_id ON pmd_edi_claims(payer_id);
CREATE INDEX idx_edi_claims_service_date ON pmd_edi_claims(service_date_from DESC);
CREATE INDEX idx_edi_claims_status ON pmd_edi_claims(claim_status);


-- EDI Service Lines (837P, 837I - Loop 2400)
CREATE SEQUENCE pmd_edi_service_lines_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_edi_service_lines (
    pmd_service_line_id BIGINT DEFAULT nextval('pmd_edi_service_lines_seq'::regclass) NOT NULL,
    claim_id BIGINT NOT NULL,

    line_number INTEGER NOT NULL,

    -- Procedure code (SV1 or SV2)
    procedure_code VARCHAR(48),  -- SV101-2 or SV201-2
    procedure_code_qualifier VARCHAR(3),  -- SV101-1 (HC = HCPCS)
    procedure_description VARCHAR(80),

    -- Modifiers (up to 4)
    modifier_1 VARCHAR(2),
    modifier_2 VARCHAR(2),
    modifier_3 VARCHAR(2),
    modifier_4 VARCHAR(2),

    -- Service details
    service_date DATE,  -- DTP-472 at line level
    line_charge_amount NUMERIC(12,2),  -- SV102
    units NUMERIC(12,3),  -- SV104
    unit_type VARCHAR(2),  -- SV103 (UN = units)
    place_of_service VARCHAR(2),  -- SV105

    -- Diagnosis pointers (link to claim-level diagnosis codes)
    diagnosis_pointer_1 INTEGER,  -- SV107 (1-12)
    diagnosis_pointer_2 INTEGER,
    diagnosis_pointer_3 INTEGER,
    diagnosis_pointer_4 INTEGER,

    -- Revenue code (for 837I institutional claims)
    revenue_code VARCHAR(4),  -- SV201-1

    -- Line-level adjustments (from 835 remittance)
    paid_amount NUMERIC(12,2),
    adjustment_amount NUMERIC(12,2),
    adjustment_reason_codes JSONB,  -- Array of CAS codes

    -- Full service line as JSONB (preserves all segments)
    service_line_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_edi_service_lines_pk PRIMARY KEY (pmd_service_line_id),
    CONSTRAINT pmd_edi_service_lines_claim_fk FOREIGN KEY (claim_id)
        REFERENCES pmd_edi_claims(pmd_claim_id) ON DELETE CASCADE
);

CREATE INDEX idx_edi_service_lines_claim_id ON pmd_edi_service_lines(claim_id);
CREATE INDEX idx_edi_service_lines_procedure_code ON pmd_edi_service_lines(procedure_code);
CREATE INDEX idx_edi_service_lines_service_date ON pmd_edi_service_lines(service_date DESC);


-- EDI Remittances (835 - Payment/Advice)
CREATE SEQUENCE pmd_edi_remittances_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_edi_remittances (
    pmd_remittance_id BIGINT DEFAULT nextval('pmd_edi_remittances_seq'::regclass) NOT NULL,
    edi_file_id BIGINT NOT NULL,

    -- Payment header (Loop 1000A)
    check_number VARCHAR(50),  -- TRN02
    payment_method VARCHAR(3),  -- BPR01 (ACH, CHK, etc.)
    payment_amount NUMERIC(12,2),  -- BPR02
    payment_date DATE,  -- BPR16

    -- Payer information (Loop 1000A)
    payer_id VARCHAR(80),
    payer_name VARCHAR(60),
    payer_address TEXT,

    -- Payee information (Loop 1000B)
    payee_npi VARCHAR(10),
    payee_name VARCHAR(60),
    payee_tax_id VARCHAR(9),
    payee_address TEXT,

    -- Payment totals
    total_claim_count INTEGER,  -- Count of claims in this remittance
    total_billed_amount NUMERIC(12,2),  -- Sum of all claim billed amounts
    total_paid_amount NUMERIC(12,2),  -- Sum of all claim paid amounts
    total_patient_responsibility NUMERIC(12,2),
    total_adjustments NUMERIC(12,2),

    -- Full remittance as JSONB (preserves all segments)
    remittance_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_edi_remittances_pk PRIMARY KEY (pmd_remittance_id),
    CONSTRAINT pmd_edi_remittances_file_fk FOREIGN KEY (edi_file_id)
        REFERENCES pmd_edi_files(pmd_edi_file_id) ON DELETE CASCADE
);

CREATE INDEX idx_edi_remittances_file_id ON pmd_edi_remittances(edi_file_id);
CREATE INDEX idx_edi_remittances_check_number ON pmd_edi_remittances(check_number);
CREATE INDEX idx_edi_remittances_payer_id ON pmd_edi_remittances(payer_id);
CREATE INDEX idx_edi_remittances_payee_npi ON pmd_edi_remittances(payee_npi);
CREATE INDEX idx_edi_remittances_payment_date ON pmd_edi_remittances(payment_date DESC);


-- EDI Claim Payments (835 - Loop 2100)
CREATE SEQUENCE pmd_edi_claim_payments_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_edi_claim_payments (
    pmd_claim_payment_id BIGINT DEFAULT nextval('pmd_edi_claim_payments_seq'::regclass) NOT NULL,
    remittance_id BIGINT NOT NULL,

    -- Link to original claim (if available)
    original_claim_id BIGINT,  -- FK to pmd_edi_claims

    -- Claim identification
    patient_account_number VARCHAR(50),  -- CLP01
    claim_status_code VARCHAR(2),  -- CLP02 (1=processed, 2=denied, etc.)
    claim_billed_amount NUMERIC(12,2),  -- CLP03
    claim_paid_amount NUMERIC(12,2),  -- CLP04
    patient_responsibility NUMERIC(12,2),  -- CLP05

    -- Claim dates
    service_date_from DATE,
    service_date_to DATE,

    -- Adjustments at claim level
    claim_adjustment_amount NUMERIC(12,2),
    claim_adjustment_reason_codes JSONB,  -- Array of CAS segments

    -- Full claim payment as JSONB (preserves all segments)
    claim_payment_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_edi_claim_payments_pk PRIMARY KEY (pmd_claim_payment_id),
    CONSTRAINT pmd_edi_claim_payments_remittance_fk FOREIGN KEY (remittance_id)
        REFERENCES pmd_edi_remittances(pmd_remittance_id) ON DELETE CASCADE,
    CONSTRAINT pmd_edi_claim_payments_claim_fk FOREIGN KEY (original_claim_id)
        REFERENCES pmd_edi_claims(pmd_claim_id) ON DELETE SET NULL
);

CREATE INDEX idx_edi_claim_payments_remittance_id ON pmd_edi_claim_payments(remittance_id);
CREATE INDEX idx_edi_claim_payments_original_claim_id ON pmd_edi_claim_payments(original_claim_id);
CREATE INDEX idx_edi_claim_payments_patient_acct ON pmd_edi_claim_payments(patient_account_number);
CREATE INDEX idx_edi_claim_payments_status ON pmd_edi_claim_payments(claim_status_code);


-- EDI Enrollments (834 - Member Enrollment/Maintenance)
CREATE SEQUENCE pmd_edi_enrollments_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_edi_enrollments (
    pmd_enrollment_id BIGINT DEFAULT nextval('pmd_edi_enrollments_seq'::regclass) NOT NULL,
    edi_file_id BIGINT NOT NULL,

    -- Member identification
    member_id VARCHAR(80),  -- REF-0F
    subscriber_id VARCHAR(80),
    ssn VARCHAR(9),

    -- Member demographics
    first_name VARCHAR(35),
    last_name VARCHAR(60),
    middle_name VARCHAR(25),
    date_of_birth DATE,
    gender VARCHAR(1),

    -- Enrollment details
    maintenance_type_code VARCHAR(3),  -- INS03 (001=Change, 021=Add, 024=Cancel, 025=Reinstate)
    maintenance_reason_code VARCHAR(2),  -- INS04
    benefit_status_code VARCHAR(1),  -- INS05 (A=active, C=COBRA, T=terminated)

    -- Coverage dates
    coverage_effective_date DATE,  -- DTP-348
    coverage_termination_date DATE,  -- DTP-349

    -- Plan information
    plan_coverage_description VARCHAR(80),
    group_number VARCHAR(50),

    -- Full enrollment as JSONB (preserves all segments)
    enrollment_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_edi_enrollments_pk PRIMARY KEY (pmd_enrollment_id),
    CONSTRAINT pmd_edi_enrollments_file_fk FOREIGN KEY (edi_file_id)
        REFERENCES pmd_edi_files(pmd_edi_file_id) ON DELETE CASCADE
);

CREATE INDEX idx_edi_enrollments_file_id ON pmd_edi_enrollments(edi_file_id);
CREATE INDEX idx_edi_enrollments_member_id ON pmd_edi_enrollments(member_id);
CREATE INDEX idx_edi_enrollments_subscriber_id ON pmd_edi_enrollments(subscriber_id);
CREATE INDEX idx_edi_enrollments_name ON pmd_edi_enrollments(last_name, first_name);
CREATE INDEX idx_edi_enrollments_effective_date ON pmd_edi_enrollments(coverage_effective_date DESC);


-- ============================================================================
-- APPS & TAGS FEATURE (Hybrid Grouping System)
-- ============================================================================
-- Version: 1.0
-- Date: January 10, 2026
-- Description: Apps provide primary 1-to-1 grouping, Tags provide flexible
--              many-to-many categorization across all artifact types
-- ============================================================================

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

COMMENT ON TABLE pmd_apps IS 'Apps for primary grouping of artifacts (1-to-1 relationship)';
COMMENT ON TABLE pmd_tags IS 'Tags for flexible cross-cutting categorization (many-to-many)';
COMMENT ON COLUMN pmd_apps.app_color IS 'Hex color code for UI display (e.g., #0066cc)';
COMMENT ON COLUMN pmd_apps.app_icon IS 'Lucide React icon name (e.g., Package, Workflow)';
COMMENT ON COLUMN pmd_tags.tag_color IS 'Hex color code for tag pill display';