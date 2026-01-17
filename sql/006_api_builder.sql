-- ============================================================================
-- Prismaid Database - API Builder
-- ============================================================================
-- Description: Dynamic REST API creation from database connections and files
-- Dependencies: 001_reference_data.sql, 003_core_etl.sql (connections),
--               005_apps_tags.sql (apps, tags)
-- Tables: pmd_api_definitions, pmd_api_auth, pmd_api_access_tokens,
--         pmd_api_schedules, pmd_api_ip_whitelist, pmd_api_rate_limits,
--         pmd_api_call_logs, pmd_api_statistics, pmd_api_definition_tags
-- ============================================================================

-- ============================================================================
-- API DEFINITIONS - Main table for API configurations
-- ============================================================================

CREATE SEQUENCE pmd_api_definitions_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_definitions (
    pmd_api_definition_id BIGINT DEFAULT nextval('pmd_api_definitions_seq'::regclass) NOT NULL,

    -- API Identity
    api_name VARCHAR(100) NOT NULL,
    api_description TEXT,
    api_path VARCHAR(255) NOT NULL,              -- e.g., '/customers', '/orders'
    api_version VARCHAR(10) DEFAULT 'v1' NOT NULL, -- 'v1', 'v2', etc.
    http_method VARCHAR(10) NOT NULL,             -- 'GET', 'POST'

    -- Source/Destination Configuration
    api_type VARCHAR(20) NOT NULL,                -- 'source' (GET) or 'destination' (POST)
    pmd_connections_registry_id BIGINT NOT NULL,  -- FK to connection
    source_type VARCHAR(20),                      -- 'table', 'view', 'procedure', 'function', 'custom_sql', 'file'
    source_object_name VARCHAR(255),              -- table/view/procedure name
    source_custom_sql TEXT,                       -- for custom SQL queries
    source_file_pattern VARCHAR(255),             -- for SMB file sources (e.g., '*.csv', 'report_*.json')

    -- Destination-specific (POST endpoints)
    destination_type VARCHAR(20),                 -- 'table', 'create_file', 'append_file'
    destination_table_name VARCHAR(255),
    destination_file_path VARCHAR(500),
    destination_file_format VARCHAR(20),          -- 'csv', 'json', 'xml'

    -- Query Parameters (for GET endpoints)
    allowed_filters JSONB DEFAULT '[]'::jsonb,    -- Array of allowed filter field names
    default_sort_field VARCHAR(100),
    default_sort_order VARCHAR(4) DEFAULT 'ASC',  -- 'ASC' or 'DESC'

    -- Response Configuration
    response_format VARCHAR(20) DEFAULT 'json',   -- 'json', 'xml', 'csv'
    pagination_enabled BOOLEAN DEFAULT true,
    default_page_size INTEGER DEFAULT 100,
    max_page_size INTEGER DEFAULT 1000,

    -- OpenAPI/Swagger metadata
    swagger_summary VARCHAR(255),
    swagger_tags JSONB DEFAULT '[]'::jsonb,       -- ["customers", "sales"]
    request_schema JSONB,                         -- JSON Schema for POST body validation
    response_schema JSONB,                        -- JSON Schema for response documentation

    -- State management
    is_enabled BOOLEAN DEFAULT false NOT NULL,    -- Start/stop API (determines if mounted)

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,      -- Soft delete
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_api_definitions_pk PRIMARY KEY (pmd_api_definition_id),
    CONSTRAINT pmd_api_definitions_connection_fk FOREIGN KEY (pmd_connections_registry_id)
        REFERENCES pmd_connections_registry(pmd_connections_registry_id),
    CONSTRAINT pmd_api_definitions_unique_path UNIQUE (api_path, api_version, http_method),
    CONSTRAINT pmd_api_definitions_http_method_check CHECK (http_method IN ('GET', 'POST')),
    CONSTRAINT pmd_api_definitions_api_type_check CHECK (api_type IN ('source', 'destination'))
);

CREATE INDEX idx_api_definitions_path ON pmd_api_definitions(api_path, api_version);
CREATE INDEX idx_api_definitions_connection ON pmd_api_definitions(pmd_connections_registry_id);
CREATE INDEX idx_api_definitions_enabled ON pmd_api_definitions(is_enabled) WHERE is_active = true;

COMMENT ON TABLE pmd_api_definitions IS 'API Builder - Main API definitions with source/destination configuration';
COMMENT ON COLUMN pmd_api_definitions.api_path IS 'URL path for the API (e.g., /customers, /orders)';
COMMENT ON COLUMN pmd_api_definitions.is_enabled IS 'Whether API is currently mounted and accepting requests';


-- ============================================================================
-- API AUTHENTICATION CONFIGURATION
-- ============================================================================

CREATE SEQUENCE pmd_api_auth_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_auth (
    pmd_api_auth_id BIGINT DEFAULT nextval('pmd_api_auth_seq'::regclass) NOT NULL,
    pmd_api_definition_id BIGINT NOT NULL,

    auth_type VARCHAR(20) NOT NULL DEFAULT 'none', -- 'none', 'basic', 'oauth2'

    -- Basic Auth credentials (password stored as bcrypt hash)
    basic_username VARCHAR(100),
    basic_password_hash VARCHAR(255),

    -- OAuth2 Client Credentials (secret stored as bcrypt hash)
    oauth2_client_id VARCHAR(255),
    oauth2_client_secret_hash VARCHAR(255),
    oauth2_token_expiry INTEGER DEFAULT 3600,     -- Token expiry in seconds (default 1 hour)
    oauth2_scope VARCHAR(255),                    -- Optional scope description

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_api_auth_pk PRIMARY KEY (pmd_api_auth_id),
    CONSTRAINT pmd_api_auth_definition_fk FOREIGN KEY (pmd_api_definition_id)
        REFERENCES pmd_api_definitions(pmd_api_definition_id) ON DELETE CASCADE,
    CONSTRAINT pmd_api_auth_type_check CHECK (auth_type IN ('none', 'basic', 'oauth2'))
);

CREATE INDEX idx_api_auth_definition ON pmd_api_auth(pmd_api_definition_id);
CREATE UNIQUE INDEX idx_api_auth_client_id ON pmd_api_auth(oauth2_client_id) WHERE oauth2_client_id IS NOT NULL;

COMMENT ON TABLE pmd_api_auth IS 'API Builder - Authentication configuration per API';
COMMENT ON COLUMN pmd_api_auth.oauth2_token_expiry IS 'Token expiry in seconds (default 3600 = 1 hour)';


-- ============================================================================
-- OAUTH2 ACCESS TOKENS
-- ============================================================================

CREATE SEQUENCE pmd_api_access_tokens_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_access_tokens (
    pmd_api_access_token_id BIGINT DEFAULT nextval('pmd_api_access_tokens_seq'::regclass) NOT NULL,
    pmd_api_auth_id BIGINT NOT NULL,

    token_hash VARCHAR(64) NOT NULL,              -- SHA-256 hash of token (never store plaintext)
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked BOOLEAN DEFAULT false,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT pmd_api_access_tokens_pk PRIMARY KEY (pmd_api_access_token_id),
    CONSTRAINT pmd_api_access_tokens_auth_fk FOREIGN KEY (pmd_api_auth_id)
        REFERENCES pmd_api_auth(pmd_api_auth_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_api_access_tokens_hash ON pmd_api_access_tokens(token_hash);
CREATE INDEX idx_api_access_tokens_auth ON pmd_api_access_tokens(pmd_api_auth_id);
CREATE INDEX idx_api_access_tokens_expires ON pmd_api_access_tokens(expires_at);

COMMENT ON TABLE pmd_api_access_tokens IS 'API Builder - OAuth2 access tokens (hashed)';
COMMENT ON COLUMN pmd_api_access_tokens.token_hash IS 'SHA-256 hash of the access token';


-- ============================================================================
-- API SCHEDULES (Time-based Availability)
-- ============================================================================

CREATE SEQUENCE pmd_api_schedules_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_schedules (
    pmd_api_schedule_id BIGINT DEFAULT nextval('pmd_api_schedules_seq'::regclass) NOT NULL,
    pmd_api_definition_id BIGINT NOT NULL,

    schedule_type VARCHAR(20) NOT NULL DEFAULT 'always', -- 'always', 'time_window', 'cron'

    -- Time Window (e.g., 9 AM - 5 PM weekdays)
    time_window_start TIME,                       -- e.g., '09:00:00'
    time_window_end TIME,                         -- e.g., '17:00:00'
    days_of_week INTEGER[],                       -- [1,2,3,4,5] = Mon-Fri (1=Mon, 7=Sun)
    timezone VARCHAR(50) DEFAULT 'UTC',

    -- Cron-based schedule (for more complex availability patterns)
    cron_expression VARCHAR(100),                 -- cron syntax for when API is available

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_api_schedules_pk PRIMARY KEY (pmd_api_schedule_id),
    CONSTRAINT pmd_api_schedules_definition_fk FOREIGN KEY (pmd_api_definition_id)
        REFERENCES pmd_api_definitions(pmd_api_definition_id) ON DELETE CASCADE,
    CONSTRAINT pmd_api_schedules_type_check CHECK (schedule_type IN ('always', 'time_window', 'cron'))
);

CREATE INDEX idx_api_schedules_definition ON pmd_api_schedules(pmd_api_definition_id);

COMMENT ON TABLE pmd_api_schedules IS 'API Builder - Time-based availability schedules';
COMMENT ON COLUMN pmd_api_schedules.days_of_week IS 'Array of weekday numbers (1=Monday, 7=Sunday)';


-- ============================================================================
-- API IP WHITELISTS
-- ============================================================================

CREATE SEQUENCE pmd_api_ip_whitelist_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_ip_whitelist (
    pmd_api_ip_whitelist_id BIGINT DEFAULT nextval('pmd_api_ip_whitelist_seq'::regclass) NOT NULL,
    pmd_api_definition_id BIGINT NOT NULL,

    ip_address VARCHAR(50) NOT NULL,              -- IP or CIDR notation (e.g., '192.168.1.0/24')
    description VARCHAR(255),                     -- Optional description (e.g., 'Office network')

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_api_ip_whitelist_pk PRIMARY KEY (pmd_api_ip_whitelist_id),
    CONSTRAINT pmd_api_ip_whitelist_definition_fk FOREIGN KEY (pmd_api_definition_id)
        REFERENCES pmd_api_definitions(pmd_api_definition_id) ON DELETE CASCADE
);

CREATE INDEX idx_api_ip_whitelist_definition ON pmd_api_ip_whitelist(pmd_api_definition_id);

COMMENT ON TABLE pmd_api_ip_whitelist IS 'API Builder - IP address whitelist per API';
COMMENT ON COLUMN pmd_api_ip_whitelist.ip_address IS 'IP address or CIDR notation (e.g., 192.168.1.0/24)';


-- ============================================================================
-- API RATE LIMITS
-- ============================================================================

CREATE SEQUENCE pmd_api_rate_limits_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_rate_limits (
    pmd_api_rate_limit_id BIGINT DEFAULT nextval('pmd_api_rate_limits_seq'::regclass) NOT NULL,
    pmd_api_definition_id BIGINT NOT NULL,

    limit_type VARCHAR(20) NOT NULL,              -- 'per_minute', 'per_hour', 'per_day'
    max_requests INTEGER NOT NULL,                -- Maximum requests allowed in window
    window_seconds INTEGER NOT NULL,              -- Sliding window size in seconds

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_api_rate_limits_pk PRIMARY KEY (pmd_api_rate_limit_id),
    CONSTRAINT pmd_api_rate_limits_definition_fk FOREIGN KEY (pmd_api_definition_id)
        REFERENCES pmd_api_definitions(pmd_api_definition_id) ON DELETE CASCADE,
    CONSTRAINT pmd_api_rate_limits_type_check CHECK (limit_type IN ('per_minute', 'per_hour', 'per_day'))
);

CREATE INDEX idx_api_rate_limits_definition ON pmd_api_rate_limits(pmd_api_definition_id);

COMMENT ON TABLE pmd_api_rate_limits IS 'API Builder - Rate limiting configuration per API';
COMMENT ON COLUMN pmd_api_rate_limits.window_seconds IS 'Sliding window size in seconds';


-- ============================================================================
-- API CALL LOGS
-- ============================================================================

CREATE SEQUENCE pmd_api_call_logs_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_call_logs (
    pmd_api_call_log_id BIGINT DEFAULT nextval('pmd_api_call_logs_seq'::regclass) NOT NULL,
    pmd_api_definition_id BIGINT NOT NULL,

    -- Request details
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    request_ip VARCHAR(50),
    request_method VARCHAR(10),
    request_path VARCHAR(500),
    request_query_params JSONB,
    request_body_size INTEGER,                    -- Size in bytes
    request_headers JSONB,                        -- Selected headers only (for debugging)

    -- Response details
    response_status INTEGER NOT NULL,             -- HTTP status code
    response_time_ms INTEGER,                     -- Duration in milliseconds
    response_body_size INTEGER,                   -- Size in bytes
    rows_returned INTEGER,                        -- For GET requests
    rows_inserted INTEGER,                        -- For POST requests

    -- Error details (if any)
    error_message TEXT,
    error_details JSONB,

    -- Auth details (for tracking usage by client)
    auth_type VARCHAR(20),                        -- 'none', 'basic', 'oauth2'
    auth_client_id VARCHAR(255),                  -- OAuth2 client_id or Basic username

    CONSTRAINT pmd_api_call_logs_pk PRIMARY KEY (pmd_api_call_log_id),
    CONSTRAINT pmd_api_call_logs_definition_fk FOREIGN KEY (pmd_api_definition_id)
        REFERENCES pmd_api_definitions(pmd_api_definition_id) ON DELETE CASCADE
);

CREATE INDEX idx_api_call_logs_definition ON pmd_api_call_logs(pmd_api_definition_id);
CREATE INDEX idx_api_call_logs_timestamp ON pmd_api_call_logs(request_timestamp DESC);
CREATE INDEX idx_api_call_logs_status ON pmd_api_call_logs(response_status);
CREATE INDEX idx_api_call_logs_client ON pmd_api_call_logs(auth_client_id) WHERE auth_client_id IS NOT NULL;
-- Use date_trunc with 'day' at UTC timezone for immutable date grouping
CREATE INDEX idx_api_call_logs_date ON pmd_api_call_logs((date_trunc('day', request_timestamp AT TIME ZONE 'UTC')));

COMMENT ON TABLE pmd_api_call_logs IS 'API Builder - Request/response logging for statistics and debugging';
COMMENT ON COLUMN pmd_api_call_logs.response_time_ms IS 'Request duration in milliseconds';

-- Note: Consider partitioning by month for high-volume deployments:
-- CREATE TABLE pmd_api_call_logs_2026_01 PARTITION OF pmd_api_call_logs
--     FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');


-- ============================================================================
-- API STATISTICS (Pre-aggregated)
-- ============================================================================

CREATE SEQUENCE pmd_api_statistics_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_api_statistics (
    pmd_api_statistic_id BIGINT DEFAULT nextval('pmd_api_statistics_seq'::regclass) NOT NULL,
    pmd_api_definition_id BIGINT NOT NULL,

    stat_date DATE NOT NULL,
    stat_hour INTEGER,                            -- 0-23, NULL for daily aggregates

    -- Request counts
    total_requests INTEGER DEFAULT 0,
    successful_requests INTEGER DEFAULT 0,        -- 2xx responses
    client_errors INTEGER DEFAULT 0,              -- 4xx responses
    server_errors INTEGER DEFAULT 0,              -- 5xx responses

    -- Performance metrics
    avg_response_time_ms INTEGER,
    min_response_time_ms INTEGER,
    max_response_time_ms INTEGER,
    p95_response_time_ms INTEGER,                 -- 95th percentile

    -- Data volume
    total_rows_returned BIGINT DEFAULT 0,
    total_rows_inserted BIGINT DEFAULT 0,
    total_bytes_sent BIGINT DEFAULT 0,
    total_bytes_received BIGINT DEFAULT 0,

    CONSTRAINT pmd_api_statistics_pk PRIMARY KEY (pmd_api_statistic_id),
    CONSTRAINT pmd_api_statistics_definition_fk FOREIGN KEY (pmd_api_definition_id)
        REFERENCES pmd_api_definitions(pmd_api_definition_id) ON DELETE CASCADE,
    CONSTRAINT pmd_api_statistics_unique UNIQUE (pmd_api_definition_id, stat_date, stat_hour)
);

CREATE INDEX idx_api_statistics_definition_date ON pmd_api_statistics(pmd_api_definition_id, stat_date DESC);

COMMENT ON TABLE pmd_api_statistics IS 'API Builder - Pre-aggregated statistics (optional, can calculate on-demand from logs)';


-- ============================================================================
-- REFERENCE DATA FOR API SOURCE TYPES
-- ============================================================================

INSERT INTO pmd_reference_category (reference_category, reference_description)
VALUES ('api_source_type', 'API Builder Source Types')
ON CONFLICT DO NOTHING;

-- Insert API source type reference values
DO $$
DECLARE
    cat_id BIGINT;
BEGIN
    SELECT pmd_reference_category_id INTO cat_id
    FROM pmd_reference_category
    WHERE reference_category = 'api_source_type';

    IF cat_id IS NOT NULL THEN
        INSERT INTO pmd_reference_value (pmd_reference_category_id, reference_value_code, reference_value_name, reference_value_desc)
        VALUES
            (cat_id, 'table', 'Database Table', 'Read from or write to database table'),
            (cat_id, 'view', 'Database View', 'Read from database view'),
            (cat_id, 'procedure', 'Stored Procedure', 'Execute stored procedure'),
            (cat_id, 'function', 'Database Function', 'Execute database function'),
            (cat_id, 'custom_sql', 'Custom SQL', 'Execute custom SQL query'),
            (cat_id, 'file', 'File (SMB)', 'Read files from SMB/network share')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;


-- ============================================================================
-- API DEFINITION TAGS (Junction Table)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pmd_api_definition_tags (
    pmd_api_definition_id BIGINT REFERENCES pmd_api_definitions(pmd_api_definition_id) ON DELETE CASCADE,
    pmd_tag_id INT REFERENCES pmd_tags(pmd_tag_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pmd_api_definition_id, pmd_tag_id)
);

CREATE INDEX IF NOT EXISTS idx_api_definition_tags_api ON pmd_api_definition_tags(pmd_api_definition_id);
CREATE INDEX IF NOT EXISTS idx_api_definition_tags_tag ON pmd_api_definition_tags(pmd_tag_id);

-- Add app_id to API definitions for grouping
ALTER TABLE pmd_api_definitions
ADD COLUMN IF NOT EXISTS pmd_app_id INT REFERENCES pmd_apps(pmd_app_id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_api_definitions_app_id ON pmd_api_definitions(pmd_app_id);

COMMENT ON TABLE pmd_api_definition_tags IS 'API Builder - Tags junction table for categorization';
