-- ============================================================================
-- Prismaid Database - HL7 v2.x Messaging
-- ============================================================================
-- Description: Tables for storing parsed HL7 v2.x messages
--              Supports ADT (patient events), ORM (orders), ORU (results), DFT (financials)
-- Dependencies: None (standalone healthcare module)
-- Tables: pmd_hl7_messages, pmd_hl7_patient_events, pmd_hl7_orders,
--         pmd_hl7_observations, pmd_hl7_financial_transactions
-- ============================================================================

-- ============================================================================
-- HL7 MESSAGES REGISTRY
-- ============================================================================

CREATE SEQUENCE pmd_hl7_messages_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_hl7_messages (
    pmd_hl7_message_id BIGINT DEFAULT nextval('pmd_hl7_messages_seq'::regclass) NOT NULL,

    -- File info
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    file_hash VARCHAR(64),

    -- MSH Header Data
    message_type VARCHAR(10) NOT NULL,        -- ADT, ORM, ORU, DFT
    trigger_event VARCHAR(10),                -- A01, A02, O01, R01, P03, etc.
    message_control_id VARCHAR(199),          -- MSH-10
    hl7_version VARCHAR(20),                  -- 2.3, 2.5.1, 2.7, etc.
    sending_application VARCHAR(227),         -- MSH-3
    sending_facility VARCHAR(227),            -- MSH-4
    receiving_application VARCHAR(227),       -- MSH-5
    receiving_facility VARCHAR(227),          -- MSH-6
    message_datetime TIMESTAMP WITH TIME ZONE, -- MSH-7
    processing_id VARCHAR(10),                -- MSH-11 (P=Production, T=Training, D=Debug)

    -- Parsing status
    parsed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    parse_status VARCHAR(20) DEFAULT 'success',
    parse_errors JSONB,
    parse_warnings JSONB,
    total_segments INTEGER DEFAULT 0,

    -- Full message for reference
    raw_message TEXT,
    message_json JSONB NOT NULL,

    -- Audit columns
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_hl7_messages_pk PRIMARY KEY (pmd_hl7_message_id)
);

CREATE INDEX idx_hl7_messages_type ON pmd_hl7_messages(message_type, trigger_event);
CREATE INDEX idx_hl7_messages_control_id ON pmd_hl7_messages(message_control_id);
CREATE INDEX idx_hl7_messages_datetime ON pmd_hl7_messages(message_datetime DESC);
CREATE INDEX idx_hl7_messages_sending_facility ON pmd_hl7_messages(sending_facility);

COMMENT ON TABLE pmd_hl7_messages IS 'HL7 v2.x message registry - stores parsed message metadata';


-- ============================================================================
-- HL7 PATIENT EVENTS (ADT Messages)
-- ============================================================================

CREATE SEQUENCE pmd_hl7_patient_events_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_hl7_patient_events (
    pmd_hl7_patient_event_id BIGINT DEFAULT nextval('pmd_hl7_patient_events_seq'::regclass) NOT NULL,
    hl7_message_id BIGINT NOT NULL,

    -- Event Info
    event_type VARCHAR(10) NOT NULL,          -- A01, A02, A03, A04, A08, etc.
    event_description VARCHAR(100),
    event_datetime TIMESTAMP WITH TIME ZONE,
    event_reason_code VARCHAR(50),

    -- Patient (PID)
    patient_id VARCHAR(250),                  -- PID-3
    patient_account_number VARCHAR(250),      -- PID-18
    patient_last_name VARCHAR(194),           -- PID-5.1
    patient_first_name VARCHAR(194),          -- PID-5.2
    patient_middle_name VARCHAR(194),         -- PID-5.3
    patient_dob DATE,                         -- PID-7
    patient_gender VARCHAR(1),                -- PID-8
    patient_ssn VARCHAR(11),                  -- PID-19
    patient_race VARCHAR(50),                 -- PID-10
    patient_marital_status VARCHAR(10),       -- PID-16
    patient_address JSONB,                    -- PID-11 full address
    patient_phone_home VARCHAR(50),           -- PID-13
    patient_phone_business VARCHAR(50),       -- PID-14

    -- Visit (PV1)
    visit_number VARCHAR(250),                -- PV1-19
    patient_class VARCHAR(1),                 -- PV1-2 (I=Inpatient, O=Outpatient, E=Emergency)
    patient_class_description VARCHAR(50),
    admit_datetime TIMESTAMP WITH TIME ZONE,  -- PV1-44
    discharge_datetime TIMESTAMP WITH TIME ZONE, -- PV1-45
    hospital_service VARCHAR(50),             -- PV1-10
    admission_type VARCHAR(50),               -- PV1-4

    -- Location (PV1-3)
    location_facility VARCHAR(100),
    location_point_of_care VARCHAR(50),
    location_room VARCHAR(50),
    location_bed VARCHAR(50),

    -- Providers
    attending_physician_id VARCHAR(250),      -- PV1-7
    attending_physician_name VARCHAR(255),
    attending_physician_npi VARCHAR(10),
    referring_physician_id VARCHAR(250),      -- PV1-8
    referring_physician_name VARCHAR(255),
    referring_physician_npi VARCHAR(10),

    -- Primary Diagnosis
    primary_diagnosis_code VARCHAR(50),
    primary_diagnosis_description VARCHAR(255),
    primary_diagnosis_type VARCHAR(10),

    -- Primary Insurance
    insurance_company_name VARCHAR(255),
    insurance_group_number VARCHAR(50),
    insurance_member_id VARCHAR(80),

    -- Counts
    diagnosis_count INTEGER DEFAULT 0,
    insurance_count INTEGER DEFAULT 0,
    allergy_count INTEGER DEFAULT 0,

    -- Full event as JSONB (preserves all segments)
    event_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_hl7_patient_events_pk PRIMARY KEY (pmd_hl7_patient_event_id),
    CONSTRAINT pmd_hl7_patient_events_message_fk FOREIGN KEY (hl7_message_id)
        REFERENCES pmd_hl7_messages(pmd_hl7_message_id) ON DELETE CASCADE
);

CREATE INDEX idx_hl7_patient_events_message_id ON pmd_hl7_patient_events(hl7_message_id);
CREATE INDEX idx_hl7_patient_events_patient_id ON pmd_hl7_patient_events(patient_id);
CREATE INDEX idx_hl7_patient_events_visit_number ON pmd_hl7_patient_events(visit_number);
CREATE INDEX idx_hl7_patient_events_event_type ON pmd_hl7_patient_events(event_type);
CREATE INDEX idx_hl7_patient_events_event_datetime ON pmd_hl7_patient_events(event_datetime DESC);
CREATE INDEX idx_hl7_patient_events_patient_name ON pmd_hl7_patient_events(patient_last_name, patient_first_name);

COMMENT ON TABLE pmd_hl7_patient_events IS 'HL7 ADT patient events - admits, discharges, transfers';


-- ============================================================================
-- HL7 ORDERS (ORM Messages)
-- ============================================================================

CREATE SEQUENCE pmd_hl7_orders_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_hl7_orders (
    pmd_hl7_order_id BIGINT DEFAULT nextval('pmd_hl7_orders_seq'::regclass) NOT NULL,
    hl7_message_id BIGINT NOT NULL,

    -- Order Common (ORC)
    order_control VARCHAR(2),                 -- ORC-1 (NW=New, CA=Cancel, SC=Status Changed, etc.)
    order_control_description VARCHAR(100),
    placer_order_number VARCHAR(427),         -- ORC-2
    filler_order_number VARCHAR(427),         -- ORC-3
    order_status VARCHAR(10),                 -- ORC-5
    order_status_description VARCHAR(100),
    order_datetime TIMESTAMP WITH TIME ZONE,  -- ORC-9

    -- Ordering Provider
    ordering_provider_id VARCHAR(250),        -- ORC-12
    ordering_provider_name VARCHAR(255),
    ordering_provider_npi VARCHAR(10),

    -- Order Detail (OBR)
    universal_service_id VARCHAR(705),        -- OBR-4
    universal_service_text VARCHAR(255),
    universal_service_coding_system VARCHAR(50),
    priority VARCHAR(10),                     -- OBR-5
    requested_datetime TIMESTAMP WITH TIME ZONE, -- OBR-6
    observation_datetime TIMESTAMP WITH TIME ZONE, -- OBR-7
    specimen_source VARCHAR(300),             -- OBR-15
    clinical_info TEXT,                       -- OBR-13

    -- Patient link
    patient_id VARCHAR(250),
    patient_last_name VARCHAR(194),
    patient_first_name VARCHAR(194),
    patient_dob DATE,
    patient_gender VARCHAR(1),
    visit_number VARCHAR(250),

    -- Primary Diagnosis
    primary_diagnosis_code VARCHAR(50),
    primary_diagnosis_description VARCHAR(255),

    -- Observation/Result counts
    observation_count INTEGER DEFAULT 0,
    diagnosis_count INTEGER DEFAULT 0,

    -- Full order as JSONB
    order_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_hl7_orders_pk PRIMARY KEY (pmd_hl7_order_id),
    CONSTRAINT pmd_hl7_orders_message_fk FOREIGN KEY (hl7_message_id)
        REFERENCES pmd_hl7_messages(pmd_hl7_message_id) ON DELETE CASCADE
);

CREATE INDEX idx_hl7_orders_message_id ON pmd_hl7_orders(hl7_message_id);
CREATE INDEX idx_hl7_orders_patient_id ON pmd_hl7_orders(patient_id);
CREATE INDEX idx_hl7_orders_placer_order ON pmd_hl7_orders(placer_order_number);
CREATE INDEX idx_hl7_orders_filler_order ON pmd_hl7_orders(filler_order_number);
CREATE INDEX idx_hl7_orders_order_control ON pmd_hl7_orders(order_control);
CREATE INDEX idx_hl7_orders_order_datetime ON pmd_hl7_orders(order_datetime DESC);

COMMENT ON TABLE pmd_hl7_orders IS 'HL7 ORM orders - lab orders, radiology orders, etc.';


-- ============================================================================
-- HL7 OBSERVATIONS/RESULTS (ORU Messages)
-- ============================================================================

CREATE SEQUENCE pmd_hl7_observations_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_hl7_observations (
    pmd_hl7_observation_id BIGINT DEFAULT nextval('pmd_hl7_observations_seq'::regclass) NOT NULL,
    hl7_message_id BIGINT NOT NULL,
    hl7_order_id BIGINT,                      -- Optional link to ORM order

    -- Order info (OBR)
    placer_order_number VARCHAR(427),
    filler_order_number VARCHAR(427),
    universal_service_id VARCHAR(705),        -- Test/panel code
    universal_service_text VARCHAR(255),
    result_status VARCHAR(1),                 -- OBR-25 (F=Final, P=Preliminary, etc.)
    result_status_description VARCHAR(100),
    observation_datetime TIMESTAMP WITH TIME ZONE,

    -- Specimen
    specimen_id VARCHAR(80),
    specimen_type VARCHAR(100),
    specimen_source_site VARCHAR(100),
    specimen_collection_datetime TIMESTAMP WITH TIME ZONE,

    -- Observation result (OBX)
    obx_set_id INTEGER,                       -- OBX-1
    value_type VARCHAR(3),                    -- OBX-2 (NM, ST, CE, etc.)
    observation_identifier VARCHAR(705),      -- OBX-3
    observation_text VARCHAR(255),
    observation_coding_system VARCHAR(50),
    observation_value TEXT,                   -- OBX-5
    observation_value_raw TEXT,
    units VARCHAR(100),                       -- OBX-6
    reference_range VARCHAR(60),              -- OBX-7
    abnormal_flags VARCHAR(20),               -- OBX-8
    abnormal_flags_description VARCHAR(100),
    observation_result_status VARCHAR(1),     -- OBX-11
    observation_result_status_description VARCHAR(100),
    obx_observation_datetime TIMESTAMP WITH TIME ZONE, -- OBX-14

    -- Patient link
    patient_id VARCHAR(250),
    patient_last_name VARCHAR(194),
    patient_first_name VARCHAR(194),
    patient_dob DATE,
    patient_gender VARCHAR(1),
    visit_number VARCHAR(250),

    -- Ordering Provider
    ordering_provider_id VARCHAR(250),
    ordering_provider_npi VARCHAR(10),

    -- Full observation as JSONB
    observation_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_hl7_observations_pk PRIMARY KEY (pmd_hl7_observation_id),
    CONSTRAINT pmd_hl7_observations_message_fk FOREIGN KEY (hl7_message_id)
        REFERENCES pmd_hl7_messages(pmd_hl7_message_id) ON DELETE CASCADE,
    CONSTRAINT pmd_hl7_observations_order_fk FOREIGN KEY (hl7_order_id)
        REFERENCES pmd_hl7_orders(pmd_hl7_order_id) ON DELETE SET NULL
);

CREATE INDEX idx_hl7_observations_message_id ON pmd_hl7_observations(hl7_message_id);
CREATE INDEX idx_hl7_observations_order_id ON pmd_hl7_observations(hl7_order_id);
CREATE INDEX idx_hl7_observations_patient_id ON pmd_hl7_observations(patient_id);
CREATE INDEX idx_hl7_observations_filler_order ON pmd_hl7_observations(filler_order_number);
CREATE INDEX idx_hl7_observations_observation_id ON pmd_hl7_observations(observation_identifier);
CREATE INDEX idx_hl7_observations_datetime ON pmd_hl7_observations(observation_datetime DESC);
CREATE INDEX idx_hl7_observations_abnormal ON pmd_hl7_observations(abnormal_flags) WHERE abnormal_flags IS NOT NULL AND abnormal_flags != 'N';

COMMENT ON TABLE pmd_hl7_observations IS 'HL7 ORU observation results - lab results, vitals, etc.';


-- ============================================================================
-- HL7 FINANCIAL TRANSACTIONS (DFT Messages)
-- ============================================================================

CREATE SEQUENCE pmd_hl7_financial_transactions_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_hl7_financial_transactions (
    pmd_hl7_financial_id BIGINT DEFAULT nextval('pmd_hl7_financial_transactions_seq'::regclass) NOT NULL,
    hl7_message_id BIGINT NOT NULL,

    -- FT1 Data
    transaction_id VARCHAR(12),               -- FT1-2
    transaction_batch_id VARCHAR(10),         -- FT1-3
    transaction_date TIMESTAMP WITH TIME ZONE, -- FT1-4
    transaction_posting_date TIMESTAMP WITH TIME ZONE, -- FT1-5
    transaction_type VARCHAR(8),              -- FT1-6 (CG=Charge, CD=Credit, PY=Payment, AJ=Adjustment)
    transaction_type_description VARCHAR(50),

    -- Transaction code/procedure
    transaction_code VARCHAR(705),            -- FT1-7
    transaction_code_text VARCHAR(255),
    transaction_code_system VARCHAR(50),
    transaction_description VARCHAR(255),     -- FT1-8

    -- Amounts
    transaction_quantity NUMERIC(10,2),       -- FT1-10
    transaction_amount NUMERIC(12,2),         -- FT1-11 (extended amount)
    transaction_amount_unit NUMERIC(12,2),    -- FT1-12
    unit_cost NUMERIC(12,2),                  -- FT1-22
    insurance_amount NUMERIC(12,2),           -- FT1-15

    -- Department
    department_code VARCHAR(705),             -- FT1-13
    department_name VARCHAR(255),

    -- Procedure from FT1
    ft1_procedure_code VARCHAR(705),          -- FT1-25
    ft1_procedure_code_text VARCHAR(255),
    ft1_procedure_modifiers VARCHAR(100),     -- FT1-26 (comma-separated)

    -- Diagnosis from FT1
    ft1_diagnosis_code VARCHAR(705),          -- FT1-19
    ft1_diagnosis_description VARCHAR(255),

    -- Providers
    performed_by_id VARCHAR(250),             -- FT1-20
    performed_by_name VARCHAR(255),
    performed_by_npi VARCHAR(10),
    ordered_by_id VARCHAR(250),               -- FT1-21
    ordered_by_name VARCHAR(255),
    ordered_by_npi VARCHAR(10),

    -- Associated procedure (PR1)
    pr1_procedure_code VARCHAR(705),
    pr1_procedure_code_text VARCHAR(255),
    pr1_procedure_datetime TIMESTAMP WITH TIME ZONE,
    pr1_surgeon_name VARCHAR(255),
    pr1_surgeon_npi VARCHAR(10),

    -- Patient link
    patient_id VARCHAR(250),
    patient_last_name VARCHAR(194),
    patient_first_name VARCHAR(194),
    patient_dob DATE,
    patient_gender VARCHAR(1),
    patient_account_number VARCHAR(250),
    visit_number VARCHAR(250),
    patient_class VARCHAR(1),

    -- Primary diagnosis (DG1)
    primary_diagnosis_code VARCHAR(50),
    primary_diagnosis_description VARCHAR(255),
    primary_diagnosis_type VARCHAR(10),

    -- Primary insurance (IN1)
    insurance_company_id VARCHAR(255),
    insurance_company_name VARCHAR(255),
    insurance_group_number VARCHAR(50),
    insurance_policy_number VARCHAR(80),

    -- Counts
    procedure_count INTEGER DEFAULT 0,
    diagnosis_count INTEGER DEFAULT 0,
    insurance_count INTEGER DEFAULT 0,

    -- Full transaction as JSONB
    transaction_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_hl7_financial_transactions_pk PRIMARY KEY (pmd_hl7_financial_id),
    CONSTRAINT pmd_hl7_financial_transactions_message_fk FOREIGN KEY (hl7_message_id)
        REFERENCES pmd_hl7_messages(pmd_hl7_message_id) ON DELETE CASCADE
);

CREATE INDEX idx_hl7_financial_message_id ON pmd_hl7_financial_transactions(hl7_message_id);
CREATE INDEX idx_hl7_financial_patient_id ON pmd_hl7_financial_transactions(patient_id);
CREATE INDEX idx_hl7_financial_transaction_id ON pmd_hl7_financial_transactions(transaction_id);
CREATE INDEX idx_hl7_financial_transaction_date ON pmd_hl7_financial_transactions(transaction_date DESC);
CREATE INDEX idx_hl7_financial_transaction_type ON pmd_hl7_financial_transactions(transaction_type);
CREATE INDEX idx_hl7_financial_department ON pmd_hl7_financial_transactions(department_code);
CREATE INDEX idx_hl7_financial_procedure ON pmd_hl7_financial_transactions(ft1_procedure_code);

COMMENT ON TABLE pmd_hl7_financial_transactions IS 'HL7 DFT financial transactions - charges, payments, adjustments';
