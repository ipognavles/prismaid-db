-- EDI Tables for Prismaid
-- Created: January 9, 2026
-- Purpose: Store EDI X12 transaction sets (837P, 837I, 835, 834, 270/271, etc.)

-- =====================================================
-- Table: pmd_edi_files
-- Purpose: Store metadata for uploaded EDI files
-- =====================================================
CREATE SEQUENCE IF NOT EXISTS pmd_edi_files_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS pmd_edi_files (
    pmd_edi_file_id INT PRIMARY KEY DEFAULT nextval('pmd_edi_files_seq'),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    file_hash VARCHAR(64),

    -- EDI Specific Fields
    transaction_set VARCHAR(10), -- '837P', '837I', '835', '834', etc.
    transaction_version VARCHAR(10), -- '005010', '004010', etc.
    sender_id VARCHAR(50), -- ISA06 - Interchange Sender ID
    receiver_id VARCHAR(50), -- ISA08 - Interchange Receiver ID
    control_number VARCHAR(50), -- ISA13 - Interchange Control Number
    interchange_date DATE, -- ISA09 - Interchange Date
    interchange_time TIME, -- ISA10 - Interchange Time

    -- Functional Group Info
    functional_group_control_number VARCHAR(50), -- GS06
    functional_group_date DATE, -- GS04

    -- Parsing Status
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    parsed_at TIMESTAMP,
    parse_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'success', 'partial', 'error'
    parse_errors JSONB, -- Array of error messages
    parse_warnings JSONB, -- Array of warning messages

    -- Statistics
    total_transactions INT DEFAULT 0, -- Number of ST/SE loops (e.g., number of claims)
    total_segments INT DEFAULT 0, -- Total EDI segments

    -- Metadata
    vendor_id INT, -- Link to pmd_vendor_registry if applicable
    uploaded_by INT, -- User who uploaded (future: link to pmd_users)
    is_active BOOLEAN DEFAULT TRUE,

    -- Constraints
    UNIQUE(file_hash)
);

CREATE INDEX idx_edi_files_transaction_set ON pmd_edi_files(transaction_set);
CREATE INDEX idx_edi_files_sender_id ON pmd_edi_files(sender_id);
CREATE INDEX idx_edi_files_control_number ON pmd_edi_files(control_number);
CREATE INDEX idx_edi_files_interchange_date ON pmd_edi_files(interchange_date);
CREATE INDEX idx_edi_files_parse_status ON pmd_edi_files(parse_status);
CREATE INDEX idx_edi_files_created_at ON pmd_edi_files(created_at);

COMMENT ON TABLE pmd_edi_files IS 'Stores metadata for uploaded EDI X12 files';

-- =====================================================
-- Table: pmd_edi_claims (837P/837I)
-- Purpose: Store parsed professional and institutional claims
-- =====================================================
CREATE SEQUENCE IF NOT EXISTS pmd_edi_claims_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS pmd_edi_claims (
    pmd_claim_id INT PRIMARY KEY DEFAULT nextval('pmd_edi_claims_seq'),
    edi_file_id INT NOT NULL REFERENCES pmd_edi_files(pmd_edi_file_id) ON DELETE CASCADE,

    -- Claim Identifiers
    claim_id VARCHAR(50), -- CLM01 - Patient Control Number
    patient_account_number VARCHAR(50), -- CLM01 or REF*D9
    transaction_set VARCHAR(10), -- '837P' or '837I'
    claim_frequency_code VARCHAR(1), -- CLM05-3 - Original (1), Replacement (7), etc.

    -- Patient Information
    patient_first_name VARCHAR(100),
    patient_last_name VARCHAR(100),
    patient_middle_name VARCHAR(50),
    patient_suffix VARCHAR(10),
    patient_date_of_birth DATE,
    patient_gender VARCHAR(1), -- 'M', 'F', 'U'
    patient_member_id VARCHAR(50), -- Subscriber ID

    -- Claim Amounts
    claim_amount DECIMAL(12,2), -- CLM02 - Total Claim Charge Amount
    paid_amount DECIMAL(12,2), -- From 835 remittance (if linked)
    patient_responsibility DECIMAL(12,2), -- Patient's portion

    -- Service Dates
    service_date_from DATE, -- CLM05-1 (DTP*472)
    service_date_to DATE, -- CLM05-2 (DTP*472)
    statement_date_from DATE, -- DTP*434 (for institutional)
    statement_date_to DATE, -- DTP*435 (for institutional)

    -- Provider Information
    billing_provider_npi VARCHAR(10), -- NM1*85 - Billing Provider NPI
    billing_provider_name VARCHAR(255),
    billing_provider_tax_id VARCHAR(15), -- REF*EI
    rendering_provider_npi VARCHAR(10), -- NM1*82 - Rendering Provider NPI
    rendering_provider_name VARCHAR(255),
    referring_provider_npi VARCHAR(10), -- NM1*DN
    facility_npi VARCHAR(10), -- NM1*FA (for institutional)

    -- Payer Information
    payer_id VARCHAR(50), -- NM1*PR - Payer ID
    payer_name VARCHAR(255),

    -- Diagnosis Codes (up to 12 for 5010)
    diagnosis_code_1 VARCHAR(10),
    diagnosis_code_2 VARCHAR(10),
    diagnosis_code_3 VARCHAR(10),
    diagnosis_code_4 VARCHAR(10),
    diagnosis_code_5 VARCHAR(10),
    diagnosis_code_6 VARCHAR(10),
    diagnosis_code_7 VARCHAR(10),
    diagnosis_code_8 VARCHAR(10),
    diagnosis_code_9 VARCHAR(10),
    diagnosis_code_10 VARCHAR(10),
    diagnosis_code_11 VARCHAR(10),
    diagnosis_code_12 VARCHAR(10),
    diagnosis_code_qualifier VARCHAR(5), -- 'ABK' (ICD-10), 'ABF' (ICD-9)

    -- Institutional-Specific Fields
    admission_date DATE, -- DTP*435 (for institutional)
    discharge_date DATE, -- DTP*096 (for institutional)
    admission_type VARCHAR(2), -- CL1-01
    admission_source VARCHAR(2), -- CL1-02
    patient_status VARCHAR(2), -- CL1-03

    -- Status and Tracking
    claim_status VARCHAR(20) DEFAULT 'submitted', -- 'submitted', 'accepted', 'rejected', 'paid', 'denied'
    claim_status_date DATE,
    claim_notes TEXT,

    -- Full Claim JSON (JSONB for querying)
    claim_json JSONB, -- Full parsed claim in JSON format

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_edi_claims_file_id ON pmd_edi_claims(edi_file_id);
CREATE INDEX idx_edi_claims_claim_id ON pmd_edi_claims(claim_id);
CREATE INDEX idx_edi_claims_patient_account ON pmd_edi_claims(patient_account_number);
CREATE INDEX idx_edi_claims_patient_name ON pmd_edi_claims(patient_last_name, patient_first_name);
CREATE INDEX idx_edi_claims_service_date FROM ON pmd_edi_claims(service_date_from);
CREATE INDEX idx_edi_claims_billing_npi ON pmd_edi_claims(billing_provider_npi);
CREATE INDEX idx_edi_claims_payer_id ON pmd_edi_claims(payer_id);
CREATE INDEX idx_edi_claims_created_at ON pmd_edi_claims(created_at);
CREATE INDEX idx_edi_claims_json ON pmd_edi_claims USING gin(claim_json); -- For JSONB queries

COMMENT ON TABLE pmd_edi_claims IS 'Stores parsed 837P/837I professional and institutional claims';

-- =====================================================
-- Table: pmd_edi_service_lines (837P/837I)
-- Purpose: Store individual service lines from claims
-- =====================================================
CREATE SEQUENCE IF NOT EXISTS pmd_edi_service_lines_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS pmd_edi_service_lines (
    pmd_service_line_id INT PRIMARY KEY DEFAULT nextval('pmd_edi_service_lines_seq'),
    claim_id INT NOT NULL REFERENCES pmd_edi_claims(pmd_claim_id) ON DELETE CASCADE,

    -- Service Line Identifiers
    line_number INT, -- Sequential line number within claim
    service_id VARCHAR(50), -- REF*6R

    -- Procedure Codes
    procedure_code VARCHAR(10), -- SV1-01-2 or SV2-01-2 - CPT/HCPCS code
    procedure_code_qualifier VARCHAR(5), -- 'HC' (HCPCS), 'ER' (Revenue Code), etc.
    modifier_1 VARCHAR(2), -- SV1-01-3
    modifier_2 VARCHAR(2), -- SV1-01-4
    modifier_3 VARCHAR(2), -- SV1-01-5
    modifier_4 VARCHAR(2), -- SV1-01-6
    procedure_description VARCHAR(255),

    -- Revenue Code (for institutional)
    revenue_code VARCHAR(4), -- SV2-01

    -- Service Details
    service_date DATE, -- DTP*472
    line_charge_amount DECIMAL(10,2), -- SV1-02 or SV2-03
    units DECIMAL(10,3), -- SV1-04 or SV2-05
    unit_type VARCHAR(2), -- 'UN' (Unit), 'MJ' (Minutes), etc.

    -- Place of Service
    place_of_service VARCHAR(2), -- SV1-05 - '11' (Office), '21' (Inpatient Hospital), etc.

    -- Diagnosis Pointers
    diagnosis_pointer_1 INT, -- Points to diagnosis_code_N in claim (1-12)
    diagnosis_pointer_2 INT,
    diagnosis_pointer_3 INT,
    diagnosis_pointer_4 INT,

    -- Emergency Indicator
    emergency_indicator VARCHAR(1), -- SV1-09 - 'Y' or 'N'

    -- Service Line JSON (full details)
    service_line_json JSONB,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_edi_service_lines_claim_id ON pmd_edi_service_lines(claim_id);
CREATE INDEX idx_edi_service_lines_procedure_code ON pmd_edi_service_lines(procedure_code);
CREATE INDEX idx_edi_service_lines_revenue_code ON pmd_edi_service_lines(revenue_code);
CREATE INDEX idx_edi_service_lines_service_date ON pmd_edi_service_lines(service_date);

COMMENT ON TABLE pmd_edi_service_lines IS 'Stores individual service lines from 837P/837I claims';

-- =====================================================
-- Table: pmd_edi_remittances (835)
-- Purpose: Store parsed remittance advice (payment information)
-- =====================================================
CREATE SEQUENCE IF NOT EXISTS pmd_edi_remittances_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS pmd_edi_remittances (
    pmd_remittance_id INT PRIMARY KEY DEFAULT nextval('pmd_edi_remittances_seq'),
    edi_file_id INT NOT NULL REFERENCES pmd_edi_files(pmd_edi_file_id) ON DELETE CASCADE,

    -- Check/Payment Information
    check_number VARCHAR(50), -- TRN02 - Check/EFT Number
    payment_method VARCHAR(2), -- BPR01 - 'C' (Check), 'ACH', etc.
    payment_amount DECIMAL(12,2), -- BPR02 - Total Payment Amount
    payment_date DATE, -- BPR16 - Payment Date (CCYYMMDD)

    -- Payer Information
    payer_id VARCHAR(50), -- NM1*PR - Payer ID
    payer_name VARCHAR(255),
    payer_address VARCHAR(255),
    payer_city VARCHAR(100),
    payer_state VARCHAR(2),
    payer_zip VARCHAR(15),

    -- Payee Information
    payee_npi VARCHAR(10), -- NM1*PE - Payee NPI
    payee_name VARCHAR(255),
    payee_tax_id VARCHAR(15),

    -- Totals
    total_claim_count INT DEFAULT 0, -- Number of claims in this 835
    total_billed_amount DECIMAL(12,2), -- Sum of all claim charges
    total_paid_amount DECIMAL(12,2), -- Sum of all payments
    total_patient_responsibility DECIMAL(12,2), -- Sum of all patient portions
    total_adjustments DECIMAL(12,2), -- Sum of all adjustments

    -- Full Remittance JSON
    remittance_json JSONB, -- Full parsed 835 in JSON format

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_edi_remit_file_id ON pmd_edi_remittances(edi_file_id);
CREATE INDEX idx_edi_remit_check_number ON pmd_edi_remittances(check_number);
CREATE INDEX idx_edi_remit_payer_id ON pmd_edi_remittances(payer_id);
CREATE INDEX idx_edi_remit_payment_date ON pmd_edi_remittances(payment_date);
CREATE INDEX idx_edi_remit_payee_npi ON pmd_edi_remittances(payee_npi);
CREATE INDEX idx_edi_remit_created_at ON pmd_edi_remittances(created_at);

COMMENT ON TABLE pmd_edi_remittances IS 'Stores parsed 835 remittance advice (payment information)';

-- =====================================================
-- Table: pmd_edi_claim_payments (835 details)
-- Purpose: Store individual claim-level payment details from 835
-- =====================================================
CREATE SEQUENCE IF NOT EXISTS pmd_edi_claim_payments_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS pmd_edi_claim_payments (
    pmd_claim_payment_id INT PRIMARY KEY DEFAULT nextval('pmd_edi_claim_payments_seq'),
    remittance_id INT NOT NULL REFERENCES pmd_edi_remittances(pmd_remittance_id) ON DELETE CASCADE,
    claim_id INT, -- Link to pmd_edi_claims if found (can be NULL)

    -- Claim Identifiers
    patient_account_number VARCHAR(50), -- CLP01
    claim_status_code VARCHAR(2), -- CLP02 - '1' (Processed), '2' (Denied), etc.
    claim_charge_amount DECIMAL(10,2), -- CLP03
    claim_payment_amount DECIMAL(10,2), -- CLP04
    patient_responsibility DECIMAL(10,2), -- CLP05

    -- Service Provider
    provider_npi VARCHAR(10),
    provider_name VARCHAR(255),

    -- Service Dates
    service_date_from DATE,
    service_date_to DATE,

    -- Adjustment Codes and Amounts
    adjustment_group_code_1 VARCHAR(2), -- CAS01 - 'CO' (Contractual), 'PR' (Patient), etc.
    adjustment_reason_code_1 VARCHAR(5), -- CAS02
    adjustment_amount_1 DECIMAL(10,2), -- CAS03

    adjustment_group_code_2 VARCHAR(2),
    adjustment_reason_code_2 VARCHAR(5),
    adjustment_amount_2 DECIMAL(10,2),

    adjustment_group_code_3 VARCHAR(2),
    adjustment_reason_code_3 VARCHAR(5),
    adjustment_amount_3 DECIMAL(10,2),

    -- Claim Payment JSON (full details including all adjustments)
    claim_payment_json JSONB,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_edi_claim_payments_remit_id ON pmd_edi_claim_payments(remittance_id);
CREATE INDEX idx_edi_claim_payments_claim_id ON pmd_edi_claim_payments(claim_id);
CREATE INDEX idx_edi_claim_payments_patient_account ON pmd_edi_claim_payments(patient_account_number);
CREATE INDEX idx_edi_claim_payments_provider_npi ON pmd_edi_claim_payments(provider_npi);

COMMENT ON TABLE pmd_edi_claim_payments IS 'Stores individual claim-level payment details from 835 remittance';

-- =====================================================
-- Grant permissions (adjust as needed for your setup)
-- =====================================================
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO prismaid_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO prismaid_user;
