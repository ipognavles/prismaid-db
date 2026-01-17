-- ============================================================================
-- Prismaid Database - FHIR R4
-- ============================================================================
-- Description: Tables for storing parsed FHIR R4 resources (US Core profiles)
--              Supports Patient, Encounter, Claim, Observation, Condition, Coverage
-- Dependencies: 001_reference_data.sql (for reference values)
-- Tables: pmd_fhir_imports, pmd_fhir_patients, pmd_fhir_encounters,
--         pmd_fhir_claims, pmd_fhir_observations, pmd_fhir_conditions, pmd_fhir_coverages
-- ============================================================================

-- ============================================================================
-- FHIR IMPORTS REGISTRY
-- ============================================================================

CREATE SEQUENCE pmd_fhir_imports_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_fhir_imports (
    pmd_fhir_import_id BIGINT DEFAULT nextval('pmd_fhir_imports_seq'::regclass) NOT NULL,

    -- Source info
    source_type VARCHAR(20) NOT NULL,         -- 'file', 'api'
    file_name VARCHAR(255),
    file_path TEXT,
    file_size BIGINT,
    file_hash VARCHAR(64),
    fhir_server_url TEXT,                     -- For API imports
    connection_id BIGINT,                     -- FK to pmd_connections_registry for API

    -- Content info
    format VARCHAR(10),                       -- 'json', 'xml'
    bundle_type VARCHAR(50),                  -- 'searchset', 'collection', 'transaction', 'batch', etc.
    fhir_version VARCHAR(20),                 -- 'R4', '4.0.1', etc.

    -- Parsing results
    parsed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    parse_status VARCHAR(20) DEFAULT 'success',
    parse_errors JSONB,
    parse_warnings JSONB,
    total_resources INTEGER DEFAULT 0,

    -- Resource type breakdown
    resource_counts JSONB,                    -- {"Patient": 10, "Observation": 50, ...}

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_fhir_imports_pk PRIMARY KEY (pmd_fhir_import_id)
);

CREATE INDEX idx_fhir_imports_source_type ON pmd_fhir_imports(source_type);
CREATE INDEX idx_fhir_imports_parsed_at ON pmd_fhir_imports(parsed_at DESC);

COMMENT ON TABLE pmd_fhir_imports IS 'FHIR R4 import registry - tracks file and API imports';


-- ============================================================================
-- FHIR PATIENTS (US Core Patient)
-- ============================================================================

CREATE SEQUENCE pmd_fhir_patients_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_fhir_patients (
    pmd_fhir_patient_id BIGINT DEFAULT nextval('pmd_fhir_patients_seq'::regclass) NOT NULL,
    fhir_import_id BIGINT NOT NULL,

    -- FHIR identifiers
    fhir_id VARCHAR(64) NOT NULL,             -- Resource.id

    -- US Core required fields
    identifier_mrn VARCHAR(255),              -- MRN identifier
    identifier_ssn VARCHAR(11),               -- SSN (should be masked in prod)

    -- Name
    family_name VARCHAR(255),
    given_name VARCHAR(255),
    middle_name VARCHAR(255),
    name_prefix VARCHAR(50),
    name_suffix VARCHAR(50),

    -- Demographics
    birth_date DATE,
    gender VARCHAR(10),                       -- male, female, other, unknown
    deceased_boolean BOOLEAN,
    deceased_datetime TIMESTAMP WITH TIME ZONE,

    -- US Core extensions
    race JSONB,                               -- US Core Race extension
    ethnicity JSONB,                          -- US Core Ethnicity extension
    birth_sex VARCHAR(10),                    -- US Core Birth Sex

    -- Contact
    phone VARCHAR(50),
    email VARCHAR(255),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    address_city VARCHAR(100),
    address_state VARCHAR(50),
    address_postal_code VARCHAR(20),
    address_country VARCHAR(50),
    address_json JSONB,                       -- Full address array

    -- Communication
    preferred_language VARCHAR(50),

    -- Managing organization
    managing_organization_reference VARCHAR(255),
    managing_organization_display VARCHAR(255),

    -- General practitioner
    general_practitioner_reference VARCHAR(255),
    general_practitioner_display VARCHAR(255),

    -- Full resource
    resource_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_fhir_patients_pk PRIMARY KEY (pmd_fhir_patient_id),
    CONSTRAINT pmd_fhir_patients_import_fk FOREIGN KEY (fhir_import_id)
        REFERENCES pmd_fhir_imports(pmd_fhir_import_id) ON DELETE CASCADE
);

CREATE INDEX idx_fhir_patients_import_id ON pmd_fhir_patients(fhir_import_id);
CREATE INDEX idx_fhir_patients_fhir_id ON pmd_fhir_patients(fhir_id);
CREATE INDEX idx_fhir_patients_mrn ON pmd_fhir_patients(identifier_mrn);
CREATE INDEX idx_fhir_patients_name ON pmd_fhir_patients(family_name, given_name);
CREATE INDEX idx_fhir_patients_birth_date ON pmd_fhir_patients(birth_date);

COMMENT ON TABLE pmd_fhir_patients IS 'FHIR R4 Patient resources (US Core profile)';


-- ============================================================================
-- FHIR ENCOUNTERS (US Core Encounter)
-- ============================================================================

CREATE SEQUENCE pmd_fhir_encounters_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_fhir_encounters (
    pmd_fhir_encounter_id BIGINT DEFAULT nextval('pmd_fhir_encounters_seq'::regclass) NOT NULL,
    fhir_import_id BIGINT NOT NULL,

    fhir_id VARCHAR(64) NOT NULL,

    -- Status
    status VARCHAR(20),                       -- planned, arrived, triaged, in-progress, onleave, finished, cancelled
    class_code VARCHAR(50),                   -- AMB, EMER, FLD, HH, IMP, ACUTE, NONAC, OBSENC, PRENC, SS, VR
    class_display VARCHAR(100),

    -- Type
    type_code VARCHAR(50),
    type_display VARCHAR(255),
    type_json JSONB,

    -- Service type
    service_type_code VARCHAR(50),
    service_type_display VARCHAR(255),

    -- Priority
    priority_code VARCHAR(50),
    priority_display VARCHAR(100),

    -- Patient
    patient_reference VARCHAR(255),
    patient_fhir_id VARCHAR(64),
    patient_display VARCHAR(255),

    -- Period
    period_start TIMESTAMP WITH TIME ZONE,
    period_end TIMESTAMP WITH TIME ZONE,

    -- Length (duration in minutes)
    length_value NUMERIC(10,2),
    length_unit VARCHAR(20),

    -- Reason
    reason_code VARCHAR(50),
    reason_display VARCHAR(255),
    reason_json JSONB,

    -- Hospitalization
    admit_source_code VARCHAR(50),
    admit_source_display VARCHAR(100),
    discharge_disposition_code VARCHAR(50),
    discharge_disposition_display VARCHAR(100),

    -- Location
    location_json JSONB,

    -- Participant (providers)
    participant_json JSONB,

    -- Diagnosis
    diagnosis_json JSONB,

    -- Service provider organization
    service_provider_reference VARCHAR(255),
    service_provider_display VARCHAR(255),

    -- Full resource
    resource_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_fhir_encounters_pk PRIMARY KEY (pmd_fhir_encounter_id),
    CONSTRAINT pmd_fhir_encounters_import_fk FOREIGN KEY (fhir_import_id)
        REFERENCES pmd_fhir_imports(pmd_fhir_import_id) ON DELETE CASCADE
);

CREATE INDEX idx_fhir_encounters_import_id ON pmd_fhir_encounters(fhir_import_id);
CREATE INDEX idx_fhir_encounters_fhir_id ON pmd_fhir_encounters(fhir_id);
CREATE INDEX idx_fhir_encounters_patient_id ON pmd_fhir_encounters(patient_fhir_id);
CREATE INDEX idx_fhir_encounters_status ON pmd_fhir_encounters(status);
CREATE INDEX idx_fhir_encounters_class ON pmd_fhir_encounters(class_code);
CREATE INDEX idx_fhir_encounters_period ON pmd_fhir_encounters(period_start DESC);

COMMENT ON TABLE pmd_fhir_encounters IS 'FHIR R4 Encounter resources (US Core profile)';


-- ============================================================================
-- FHIR CLAIMS
-- ============================================================================

CREATE SEQUENCE pmd_fhir_claims_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_fhir_claims (
    pmd_fhir_claim_id BIGINT DEFAULT nextval('pmd_fhir_claims_seq'::regclass) NOT NULL,
    fhir_import_id BIGINT NOT NULL,

    fhir_id VARCHAR(64) NOT NULL,

    -- Claim header
    status VARCHAR(20),                       -- active, cancelled, draft, entered-in-error
    type_code VARCHAR(50),                    -- institutional, oral, pharmacy, professional, vision
    type_display VARCHAR(100),
    use VARCHAR(20),                          -- claim, preauthorization, predetermination

    -- Patient reference
    patient_reference VARCHAR(255),
    patient_fhir_id VARCHAR(64),
    patient_display VARCHAR(255),

    -- Provider
    provider_reference VARCHAR(255),
    provider_npi VARCHAR(10),
    provider_display VARCHAR(255),

    -- Insurer
    insurer_reference VARCHAR(255),
    insurer_display VARCHAR(255),

    -- Priority
    priority_code VARCHAR(50),

    -- Prescription
    prescription_reference VARCHAR(255),

    -- Facility
    facility_reference VARCHAR(255),
    facility_display VARCHAR(255),

    -- Amounts
    total_value NUMERIC(12,2),
    total_currency VARCHAR(3),

    -- Dates
    created_date TIMESTAMP WITH TIME ZONE,
    billable_period_start DATE,
    billable_period_end DATE,

    -- Diagnosis (array)
    diagnosis_json JSONB,
    diagnosis_count INTEGER DEFAULT 0,

    -- Procedure (array)
    procedure_json JSONB,
    procedure_count INTEGER DEFAULT 0,

    -- Insurance (array)
    insurance_json JSONB,

    -- Items (service lines)
    item_count INTEGER DEFAULT 0,
    items_json JSONB,

    -- Supporting info
    supporting_info_json JSONB,

    -- Full resource
    resource_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_fhir_claims_pk PRIMARY KEY (pmd_fhir_claim_id),
    CONSTRAINT pmd_fhir_claims_import_fk FOREIGN KEY (fhir_import_id)
        REFERENCES pmd_fhir_imports(pmd_fhir_import_id) ON DELETE CASCADE
);

CREATE INDEX idx_fhir_claims_import_id ON pmd_fhir_claims(fhir_import_id);
CREATE INDEX idx_fhir_claims_fhir_id ON pmd_fhir_claims(fhir_id);
CREATE INDEX idx_fhir_claims_patient_id ON pmd_fhir_claims(patient_fhir_id);
CREATE INDEX idx_fhir_claims_status ON pmd_fhir_claims(status);
CREATE INDEX idx_fhir_claims_type ON pmd_fhir_claims(type_code);
CREATE INDEX idx_fhir_claims_created ON pmd_fhir_claims(created_date DESC);

COMMENT ON TABLE pmd_fhir_claims IS 'FHIR R4 Claim resources';


-- ============================================================================
-- FHIR OBSERVATIONS (US Core Vital Signs, Lab Results)
-- ============================================================================

CREATE SEQUENCE pmd_fhir_observations_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_fhir_observations (
    pmd_fhir_observation_id BIGINT DEFAULT nextval('pmd_fhir_observations_seq'::regclass) NOT NULL,
    fhir_import_id BIGINT NOT NULL,

    fhir_id VARCHAR(64) NOT NULL,

    -- Status
    status VARCHAR(20),                       -- registered, preliminary, final, amended, corrected, cancelled, entered-in-error

    -- Category (vital-signs, laboratory, etc.)
    category_code VARCHAR(100),
    category_display VARCHAR(255),
    category_json JSONB,

    -- Code (LOINC, etc.)
    code_system VARCHAR(255),
    code_code VARCHAR(50),
    code_display VARCHAR(255),

    -- Value (polymorphic)
    value_quantity_value NUMERIC(18,6),
    value_quantity_unit VARCHAR(50),
    value_quantity_system VARCHAR(255),
    value_quantity_code VARCHAR(50),
    value_string TEXT,
    value_boolean BOOLEAN,
    value_integer INTEGER,
    value_codeable_concept_code VARCHAR(50),
    value_codeable_concept_display VARCHAR(255),
    value_codeable_concept_json JSONB,

    -- Data absent reason
    data_absent_reason_code VARCHAR(50),
    data_absent_reason_display VARCHAR(100),

    -- Reference ranges
    reference_range_low NUMERIC(18,6),
    reference_range_high NUMERIC(18,6),
    reference_range_text VARCHAR(255),
    reference_range_json JSONB,

    -- Interpretation
    interpretation_code VARCHAR(50),          -- normal, abnormal, high, low, etc.
    interpretation_display VARCHAR(100),
    interpretation_json JSONB,

    -- Patient/Encounter references
    patient_reference VARCHAR(255),
    patient_fhir_id VARCHAR(64),
    encounter_reference VARCHAR(255),
    encounter_fhir_id VARCHAR(64),

    -- Performer
    performer_reference VARCHAR(255),
    performer_display VARCHAR(255),

    -- Timing
    effective_datetime TIMESTAMP WITH TIME ZONE,
    effective_period_start TIMESTAMP WITH TIME ZONE,
    effective_period_end TIMESTAMP WITH TIME ZONE,
    issued_datetime TIMESTAMP WITH TIME ZONE,

    -- Body site
    body_site_code VARCHAR(50),
    body_site_display VARCHAR(100),

    -- Method
    method_code VARCHAR(50),
    method_display VARCHAR(100),

    -- Specimen
    specimen_reference VARCHAR(255),

    -- Device
    device_reference VARCHAR(255),

    -- Has member/derived from (for panels)
    has_member_json JSONB,
    derived_from_json JSONB,

    -- Component observations (for multi-component like BP)
    component_json JSONB,
    component_count INTEGER DEFAULT 0,

    -- Full resource
    resource_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_fhir_observations_pk PRIMARY KEY (pmd_fhir_observation_id),
    CONSTRAINT pmd_fhir_observations_import_fk FOREIGN KEY (fhir_import_id)
        REFERENCES pmd_fhir_imports(pmd_fhir_import_id) ON DELETE CASCADE
);

CREATE INDEX idx_fhir_observations_import_id ON pmd_fhir_observations(fhir_import_id);
CREATE INDEX idx_fhir_observations_fhir_id ON pmd_fhir_observations(fhir_id);
CREATE INDEX idx_fhir_observations_patient_id ON pmd_fhir_observations(patient_fhir_id);
CREATE INDEX idx_fhir_observations_encounter_id ON pmd_fhir_observations(encounter_fhir_id);
CREATE INDEX idx_fhir_observations_code ON pmd_fhir_observations(code_code);
CREATE INDEX idx_fhir_observations_category ON pmd_fhir_observations(category_code);
CREATE INDEX idx_fhir_observations_effective ON pmd_fhir_observations(effective_datetime DESC);
CREATE INDEX idx_fhir_observations_status ON pmd_fhir_observations(status);

COMMENT ON TABLE pmd_fhir_observations IS 'FHIR R4 Observation resources (vital signs, lab results)';


-- ============================================================================
-- FHIR CONDITIONS (US Core Condition)
-- ============================================================================

CREATE SEQUENCE pmd_fhir_conditions_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_fhir_conditions (
    pmd_fhir_condition_id BIGINT DEFAULT nextval('pmd_fhir_conditions_seq'::regclass) NOT NULL,
    fhir_import_id BIGINT NOT NULL,

    fhir_id VARCHAR(64) NOT NULL,

    -- Clinical status
    clinical_status_code VARCHAR(20),         -- active, recurrence, relapse, inactive, remission, resolved
    clinical_status_display VARCHAR(100),

    -- Verification status
    verification_status_code VARCHAR(20),     -- unconfirmed, provisional, differential, confirmed, refuted, entered-in-error
    verification_status_display VARCHAR(100),

    -- Category
    category_code VARCHAR(100),               -- problem-list-item, encounter-diagnosis, health-concern
    category_display VARCHAR(255),
    category_json JSONB,

    -- Severity
    severity_code VARCHAR(50),
    severity_display VARCHAR(100),

    -- Code (ICD-10, SNOMED)
    code_system VARCHAR(255),
    code_code VARCHAR(50),
    code_display VARCHAR(255),

    -- Body site
    body_site_code VARCHAR(50),
    body_site_display VARCHAR(100),
    body_site_json JSONB,

    -- Patient/Encounter
    patient_reference VARCHAR(255),
    patient_fhir_id VARCHAR(64),
    encounter_reference VARCHAR(255),
    encounter_fhir_id VARCHAR(64),

    -- Dates
    onset_datetime TIMESTAMP WITH TIME ZONE,
    onset_age_value NUMERIC(5,2),
    onset_age_unit VARCHAR(20),
    onset_string VARCHAR(255),
    abatement_datetime TIMESTAMP WITH TIME ZONE,
    abatement_age_value NUMERIC(5,2),
    abatement_age_unit VARCHAR(20),
    abatement_string VARCHAR(255),
    recorded_date DATE,

    -- Recorder/Asserter
    recorder_reference VARCHAR(255),
    recorder_display VARCHAR(255),
    asserter_reference VARCHAR(255),
    asserter_display VARCHAR(255),

    -- Stage
    stage_summary_code VARCHAR(50),
    stage_summary_display VARCHAR(100),
    stage_json JSONB,

    -- Evidence
    evidence_json JSONB,

    -- Notes
    note_json JSONB,

    -- Full resource
    resource_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_fhir_conditions_pk PRIMARY KEY (pmd_fhir_condition_id),
    CONSTRAINT pmd_fhir_conditions_import_fk FOREIGN KEY (fhir_import_id)
        REFERENCES pmd_fhir_imports(pmd_fhir_import_id) ON DELETE CASCADE
);

CREATE INDEX idx_fhir_conditions_import_id ON pmd_fhir_conditions(fhir_import_id);
CREATE INDEX idx_fhir_conditions_fhir_id ON pmd_fhir_conditions(fhir_id);
CREATE INDEX idx_fhir_conditions_patient_id ON pmd_fhir_conditions(patient_fhir_id);
CREATE INDEX idx_fhir_conditions_encounter_id ON pmd_fhir_conditions(encounter_fhir_id);
CREATE INDEX idx_fhir_conditions_code ON pmd_fhir_conditions(code_code);
CREATE INDEX idx_fhir_conditions_category ON pmd_fhir_conditions(category_code);
CREATE INDEX idx_fhir_conditions_clinical_status ON pmd_fhir_conditions(clinical_status_code);

COMMENT ON TABLE pmd_fhir_conditions IS 'FHIR R4 Condition resources (diagnoses, problems)';


-- ============================================================================
-- FHIR COVERAGE (Insurance)
-- ============================================================================

CREATE SEQUENCE pmd_fhir_coverages_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_fhir_coverages (
    pmd_fhir_coverage_id BIGINT DEFAULT nextval('pmd_fhir_coverages_seq'::regclass) NOT NULL,
    fhir_import_id BIGINT NOT NULL,

    fhir_id VARCHAR(64) NOT NULL,

    -- Status
    status VARCHAR(20),                       -- active, cancelled, draft, entered-in-error

    -- Type
    type_code VARCHAR(50),
    type_display VARCHAR(100),

    -- Policy holder
    policy_holder_reference VARCHAR(255),
    policy_holder_display VARCHAR(255),

    -- Subscriber
    subscriber_reference VARCHAR(255),
    subscriber_display VARCHAR(255),
    subscriber_id VARCHAR(255),

    -- Beneficiary (patient)
    beneficiary_reference VARCHAR(255),
    beneficiary_fhir_id VARCHAR(64),
    beneficiary_display VARCHAR(255),

    -- Dependent
    dependent VARCHAR(50),

    -- Relationship
    relationship_code VARCHAR(50),
    relationship_display VARCHAR(100),

    -- Period
    period_start DATE,
    period_end DATE,

    -- Payor (insurance company)
    payor_reference VARCHAR(255),
    payor_display VARCHAR(255),
    payor_json JSONB,

    -- Class (plan details)
    class_type_code VARCHAR(50),
    class_type_display VARCHAR(100),
    class_value VARCHAR(255),
    class_name VARCHAR(255),
    class_json JSONB,

    -- Order
    coverage_order INTEGER,

    -- Network
    network VARCHAR(255),

    -- Cost to beneficiary
    cost_to_beneficiary_json JSONB,

    -- Subrogation
    subrogation BOOLEAN,

    -- Contract
    contract_json JSONB,

    -- Full resource
    resource_json JSONB NOT NULL,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_fhir_coverages_pk PRIMARY KEY (pmd_fhir_coverage_id),
    CONSTRAINT pmd_fhir_coverages_import_fk FOREIGN KEY (fhir_import_id)
        REFERENCES pmd_fhir_imports(pmd_fhir_import_id) ON DELETE CASCADE
);

CREATE INDEX idx_fhir_coverages_import_id ON pmd_fhir_coverages(fhir_import_id);
CREATE INDEX idx_fhir_coverages_fhir_id ON pmd_fhir_coverages(fhir_id);
CREATE INDEX idx_fhir_coverages_beneficiary_id ON pmd_fhir_coverages(beneficiary_fhir_id);
CREATE INDEX idx_fhir_coverages_subscriber_id ON pmd_fhir_coverages(subscriber_id);
CREATE INDEX idx_fhir_coverages_status ON pmd_fhir_coverages(status);
CREATE INDEX idx_fhir_coverages_period ON pmd_fhir_coverages(period_start, period_end);

COMMENT ON TABLE pmd_fhir_coverages IS 'FHIR R4 Coverage resources (insurance coverage)';


-- ============================================================================
-- ADDITIONAL REFERENCE DATA FOR HEALTHCARE
-- ============================================================================

-- Add FHIR_SERVER as a connection type
INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc)
SELECT 4, 'FHIR_SERVER', 'FHIR Server', 'FHIR R4 Server Connection (REST API)'
WHERE EXISTS (SELECT 1 FROM pmd_reference_category WHERE pmd_reference_category_id = 4)
ON CONFLICT DO NOTHING;

-- Add HL7 and FHIR to schema format reference values
INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc)
SELECT 3, 'hl7', 'hl7', 'HL7 v2.x message format'
WHERE EXISTS (SELECT 1 FROM pmd_reference_category WHERE pmd_reference_category_id = 3)
ON CONFLICT DO NOTHING;

INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc)
SELECT 3, 'fhir', 'fhir', 'FHIR R4 resource format'
WHERE EXISTS (SELECT 1 FROM pmd_reference_category WHERE pmd_reference_category_id = 3)
ON CONFLICT DO NOTHING;
