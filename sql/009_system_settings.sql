-- ============================================================================
-- Prismaid Database - System Settings
-- ============================================================================
-- Description: Runtime-editable system configuration settings
-- Dependencies: 002_auth.sql
-- Tables: pmd_system_settings
-- ============================================================================

-- ============================================================================
-- SYSTEM SETTINGS TABLE
-- ============================================================================

CREATE SEQUENCE pmd_system_settings_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_system_settings (
    pmd_system_setting_id BIGINT DEFAULT nextval('pmd_system_settings_seq'::regclass) NOT NULL,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value VARCHAR(1000),
    default_value VARCHAR(1000) NOT NULL,
    setting_category VARCHAR(50) NOT NULL,
    data_type VARCHAR(20) NOT NULL CHECK (data_type IN ('string', 'number', 'boolean', 'json')),
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    is_editable BOOLEAN DEFAULT true NOT NULL,
    is_sensitive BOOLEAN DEFAULT false NOT NULL,
    validation_regex VARCHAR(500),
    min_value NUMERIC,
    max_value NUMERIC,
    requires_restart BOOLEAN DEFAULT false NOT NULL,
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_system_settings_pk PRIMARY KEY (pmd_system_setting_id)
);

CREATE INDEX idx_system_settings_key ON pmd_system_settings(setting_key);
CREATE INDEX idx_system_settings_category ON pmd_system_settings(setting_category);

COMMENT ON TABLE pmd_system_settings IS 'Runtime-editable system configuration. DB values override environment variables.';
COMMENT ON COLUMN pmd_system_settings.setting_value IS 'Current value (NULL = use default_value)';
COMMENT ON COLUMN pmd_system_settings.is_sensitive IS 'If true, value is never returned to frontend';
COMMENT ON COLUMN pmd_system_settings.requires_restart IS 'If true, changes require service restart to take effect';
COMMENT ON COLUMN pmd_system_settings.display_order IS 'Order to display settings within a category';

-- ============================================================================
-- SEED DATA - Security Settings
-- ============================================================================

INSERT INTO pmd_system_settings (setting_key, default_value, setting_category, data_type, display_name, description, is_editable, min_value, max_value, display_order) VALUES
('MAX_LOGIN_ATTEMPTS', '5', 'security', 'number', 'Max Login Attempts', 'Number of failed login attempts before account lockout', true, 3, 10, 1),
('LOCK_DURATION_MINUTES', '15', 'security', 'number', 'Lock Duration (minutes)', 'How long an account stays locked after max failed attempts', true, 5, 60, 2),
('JWT_ACCESS_EXPIRY', '15m', 'security', 'string', 'Access Token Expiry', 'JWT access token lifetime (e.g., 15m, 1h, 2h)', true, NULL, NULL, 3),
('JWT_REFRESH_EXPIRY', '7d', 'security', 'string', 'Refresh Token Expiry', 'JWT refresh token lifetime (e.g., 7d, 14d, 30d)', true, NULL, NULL, 4),
('BCRYPT_ROUNDS', '10', 'security', 'number', 'Password Hash Rounds', 'Bcrypt cost factor for password hashing (higher = more secure but slower)', false, 10, 14, 5),
('SESSION_TIMEOUT_MINUTES', '30', 'security', 'number', 'Session Timeout (minutes)', 'Inactivity timeout before session expires', true, 15, 120, 6);

-- ============================================================================
-- SEED DATA - Rate Limiting Settings
-- ============================================================================

INSERT INTO pmd_system_settings (setting_key, default_value, setting_category, data_type, display_name, description, is_editable, min_value, max_value, display_order) VALUES
('RATE_LIMIT_GENERAL', '100', 'rate_limiting', 'number', 'General Rate Limit', 'Requests per minute for general API endpoints', true, 50, 500, 1),
('RATE_LIMIT_AUTH', '50', 'rate_limiting', 'number', 'Auth Rate Limit', 'Requests per 15 minutes for authentication endpoints', true, 10, 100, 2),
('RATE_LIMIT_OAUTH', '20', 'rate_limiting', 'number', 'OAuth Rate Limit', 'Requests per minute for OAuth token endpoint', true, 10, 50, 3),
('RATE_LIMIT_QUERY', '30', 'rate_limiting', 'number', 'Query Rate Limit', 'Requests per minute for database query endpoints', true, 10, 100, 4),
('RATE_LIMIT_FLOW_EXEC', '10', 'rate_limiting', 'number', 'Flow Execution Rate Limit', 'Flow executions per minute per user', true, 5, 30, 5);

-- ============================================================================
-- SEED DATA - Database Pool Settings
-- ============================================================================

INSERT INTO pmd_system_settings (setting_key, default_value, setting_category, data_type, display_name, description, is_editable, min_value, max_value, requires_restart, display_order) VALUES
('DB_POOL_MAX', '20', 'database', 'number', 'Max Pool Connections', 'Maximum number of connections in the database pool', true, 5, 100, true, 1),
('DB_IDLE_TIMEOUT', '30000', 'database', 'number', 'Idle Timeout (ms)', 'Milliseconds before an idle connection is released', true, 10000, 60000, true, 2),
('DB_CONNECT_TIMEOUT', '5000', 'database', 'number', 'Connection Timeout (ms)', 'Milliseconds to wait for a new connection', true, 1000, 30000, true, 3);

-- ============================================================================
-- SEED DATA - Engine Settings
-- ============================================================================

INSERT INTO pmd_system_settings (setting_key, default_value, setting_category, data_type, display_name, description, is_editable, min_value, max_value, display_order) VALUES
('PYTHON_ENGINE_TIMEOUT', '300000', 'engine', 'number', 'Engine Timeout (ms)', 'Maximum time to wait for Python engine execution (5 min default)', true, 60000, 600000, 1),
('MAX_FILE_UPLOAD_SIZE', '52428800', 'engine', 'number', 'Max File Upload Size (bytes)', 'Maximum file size for uploads (50MB default)', true, 1048576, 104857600, 2),
('MAX_ROWS_PREVIEW', '1000', 'engine', 'number', 'Max Preview Rows', 'Maximum rows to display in data previews', true, 100, 10000, 3);

-- ============================================================================
-- SEED DATA - System Information (Read-only)
-- ============================================================================

INSERT INTO pmd_system_settings (setting_key, default_value, setting_category, data_type, display_name, description, is_editable, is_sensitive, display_order) VALUES
('DB_HOST', 'localhost', 'system_info', 'string', 'Database Host', 'PostgreSQL server hostname', false, false, 1),
('DB_PORT', '5432', 'system_info', 'string', 'Database Port', 'PostgreSQL server port', false, false, 2),
('DB_NAME', 'prismaid', 'system_info', 'string', 'Database Name', 'PostgreSQL database name', false, false, 3),
('API_URL', 'http://localhost:3001', 'system_info', 'string', 'API URL', 'Node.js API service URL', false, false, 4),
('ENGINE_URL', 'http://localhost:8000', 'system_info', 'string', 'Engine URL', 'Python engine service URL', false, false, 5);

-- ============================================================================
-- SEED DATA - Notification Settings
-- ============================================================================

INSERT INTO pmd_system_settings (setting_key, default_value, setting_category, data_type, display_name, description, is_editable, min_value, max_value, display_order) VALUES
('NOTIFICATION_RETENTION_DAYS', '30', 'notifications', 'number', 'Notification Retention (days)', 'Days to keep notifications before auto-cleanup', true, 7, 365, 1),
('EMAIL_NOTIFICATIONS_ENABLED', 'false', 'notifications', 'boolean', 'Email Notifications', 'Enable email notifications for flow failures and alerts', true, NULL, NULL, 2),
('NOTIFICATION_POLLING_INTERVAL', '300000', 'notifications', 'number', 'Polling Interval (ms)', 'How often clients check for new notifications (0 = disabled, default 5 minutes)', true, 0, 1800000, 3);

-- ============================================================================
-- CATEGORY METADATA VIEW (Optional helper view)
-- ============================================================================

CREATE OR REPLACE VIEW v_system_settings_categories AS
SELECT DISTINCT
    setting_category,
    CASE setting_category
        WHEN 'security' THEN 'Security'
        WHEN 'rate_limiting' THEN 'Rate Limiting'
        WHEN 'database' THEN 'Database'
        WHEN 'engine' THEN 'Engine'
        WHEN 'system_info' THEN 'System Information'
        WHEN 'notifications' THEN 'Notifications'
        ELSE INITCAP(REPLACE(setting_category, '_', ' '))
    END AS category_display_name,
    CASE setting_category
        WHEN 'security' THEN 1
        WHEN 'rate_limiting' THEN 2
        WHEN 'database' THEN 3
        WHEN 'engine' THEN 4
        WHEN 'notifications' THEN 5
        WHEN 'system_info' THEN 99
        ELSE 50
    END AS category_order,
    CASE setting_category
        WHEN 'security' THEN 'shield'
        WHEN 'rate_limiting' THEN 'gauge'
        WHEN 'database' THEN 'database'
        WHEN 'engine' THEN 'cpu'
        WHEN 'system_info' THEN 'info'
        WHEN 'notifications' THEN 'bell'
        ELSE 'settings'
    END AS category_icon
FROM pmd_system_settings
WHERE is_active = true
ORDER BY category_order;
