-- ============================================================================
-- Prismaid Database - Authentication & Authorization
-- ============================================================================
-- Description: User accounts, roles, tokens, and audit logging for RBAC
-- Dependencies: 001_reference_data.sql
-- Tables: pmd_users, pmd_roles, pmd_user_roles, pmd_refresh_tokens, pmd_audit_log
-- ============================================================================

-- ============================================================================
-- USERS TABLE
-- ============================================================================

CREATE SEQUENCE pmd_users_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_users (
    pmd_user_id BIGINT DEFAULT nextval('pmd_users_seq'::regclass) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_users_pk PRIMARY KEY (pmd_user_id)
);

CREATE INDEX idx_users_username ON pmd_users(username);
CREATE INDEX idx_users_email ON pmd_users(email);
CREATE INDEX idx_users_active ON pmd_users(is_active);

COMMENT ON TABLE pmd_users IS 'User accounts for authentication and authorization';
COMMENT ON COLUMN pmd_users.password_hash IS 'Bcrypt hashed password (10 rounds)';
COMMENT ON COLUMN pmd_users.failed_login_attempts IS 'Counter for account lockout mechanism';
COMMENT ON COLUMN pmd_users.locked_until IS 'Timestamp when account lockout expires';

-- ============================================================================
-- ROLES TABLE
-- ============================================================================

CREATE SEQUENCE pmd_roles_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_roles (
    pmd_role_id BIGINT DEFAULT nextval('pmd_roles_seq'::regclass) NOT NULL,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    role_description TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_by BIGINT DEFAULT 1 NOT NULL,
    created_by_name VARCHAR DEFAULT 'system' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by BIGINT DEFAULT 1 NOT NULL,
    updated_by_name VARCHAR DEFAULT 'system' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_roles_pk PRIMARY KEY (pmd_role_id)
);

CREATE INDEX idx_roles_name ON pmd_roles(role_name);

COMMENT ON TABLE pmd_roles IS 'Role definitions for RBAC';
COMMENT ON COLUMN pmd_roles.role_name IS 'Unique role identifier: admin, flow_designer, operator, viewer';

-- ============================================================================
-- USER-ROLE JUNCTION TABLE
-- ============================================================================

CREATE SEQUENCE pmd_user_roles_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_user_roles (
    pmd_user_role_id BIGINT DEFAULT nextval('pmd_user_roles_seq'::regclass) NOT NULL,
    pmd_user_id BIGINT NOT NULL,
    pmd_role_id BIGINT NOT NULL,
    granted_by BIGINT DEFAULT 1 NOT NULL,
    granted_by_name VARCHAR DEFAULT 'system' NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_user_roles_pk PRIMARY KEY (pmd_user_role_id),
    CONSTRAINT pmd_user_roles_user_fk FOREIGN KEY (pmd_user_id)
        REFERENCES pmd_users(pmd_user_id) ON DELETE CASCADE,
    CONSTRAINT pmd_user_roles_role_fk FOREIGN KEY (pmd_role_id)
        REFERENCES pmd_roles(pmd_role_id) ON DELETE CASCADE,
    CONSTRAINT pmd_user_roles_unique UNIQUE (pmd_user_id, pmd_role_id)
);

CREATE INDEX idx_user_roles_user ON pmd_user_roles(pmd_user_id);
CREATE INDEX idx_user_roles_role ON pmd_user_roles(pmd_role_id);

COMMENT ON TABLE pmd_user_roles IS 'Many-to-many relationship between users and roles';

-- ============================================================================
-- REFRESH TOKENS TABLE
-- ============================================================================

CREATE SEQUENCE pmd_refresh_tokens_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_refresh_tokens (
    pmd_refresh_token_id BIGINT DEFAULT nextval('pmd_refresh_tokens_seq'::regclass) NOT NULL,
    pmd_user_id BIGINT NOT NULL,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_refresh_tokens_pk PRIMARY KEY (pmd_refresh_token_id),
    CONSTRAINT pmd_refresh_tokens_user_fk FOREIGN KEY (pmd_user_id)
        REFERENCES pmd_users(pmd_user_id) ON DELETE CASCADE
);

CREATE INDEX idx_refresh_tokens_user ON pmd_refresh_tokens(pmd_user_id);
CREATE INDEX idx_refresh_tokens_hash ON pmd_refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires ON pmd_refresh_tokens(expires_at);

COMMENT ON TABLE pmd_refresh_tokens IS 'JWT refresh tokens storage (SHA-256 hashed)';
COMMENT ON COLUMN pmd_refresh_tokens.token_hash IS 'SHA-256 hash of refresh token for security';
COMMENT ON COLUMN pmd_refresh_tokens.is_revoked IS 'True when token is invalidated (logout, password change)';

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================

CREATE SEQUENCE pmd_audit_log_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE pmd_audit_log (
    pmd_audit_log_id BIGINT DEFAULT nextval('pmd_audit_log_seq'::regclass) NOT NULL,
    pmd_user_id BIGINT NOT NULL,
    username VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(100),
    resource_id BIGINT,
    resource_name VARCHAR(255),
    details JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pmd_audit_log_pk PRIMARY KEY (pmd_audit_log_id),
    CONSTRAINT pmd_audit_log_user_fk FOREIGN KEY (pmd_user_id)
        REFERENCES pmd_users(pmd_user_id) ON DELETE CASCADE
);

CREATE INDEX idx_audit_log_user ON pmd_audit_log(pmd_user_id);
CREATE INDEX idx_audit_log_action ON pmd_audit_log(action);
CREATE INDEX idx_audit_log_resource ON pmd_audit_log(resource_type, resource_id);
CREATE INDEX idx_audit_log_created ON pmd_audit_log(created_at DESC);

COMMENT ON TABLE pmd_audit_log IS 'Comprehensive audit trail for compliance (7-year retention for HIPAA)';
COMMENT ON COLUMN pmd_audit_log.action IS 'Action type: login, logout, create, update, delete, execute';
COMMENT ON COLUMN pmd_audit_log.resource_type IS 'Resource affected: dataflow, schema, mapping, connection, vendor, schedule, user';
COMMENT ON COLUMN pmd_audit_log.details IS 'Additional context stored as JSON';

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Insert 4 roles (admin, flow_designer, operator, viewer)
INSERT INTO pmd_roles (pmd_role_id, role_name, role_description) VALUES
(1, 'admin', 'Full system access - can manage users, configure system, and perform all operations'),
(2, 'flow_designer', 'Can create and edit data flows, schemas, mappings, and connections. Cannot manage users'),
(3, 'operator', 'Can execute flows and view results. Cannot create or edit flows'),
(4, 'viewer', 'Read-only access to all resources. Cannot execute or modify anything');

-- Insert default admin user
-- Username: admin
-- Password: admin123 (MUST BE CHANGED IMMEDIATELY AFTER FIRST LOGIN)
-- Password hash generated with bcrypt rounds=10
INSERT INTO pmd_users (pmd_user_id, username, email, password_hash, full_name) VALUES
(1, 'admin', 'admin@prismaid.local', '$2b$10$904Lge/3MZScpaTqZfQUP.QMzuw6sXDOZuWE1tdTB5B5ZTYZ1fyo6', 'System Administrator');

-- Assign admin role to default user
INSERT INTO pmd_user_roles (pmd_user_id, pmd_role_id) VALUES
(1, 1);

-- Update created_by self-reference for admin user
UPDATE pmd_users SET created_by = 1, created_by_name = 'admin' WHERE pmd_user_id = 1;

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Function to clean up expired refresh tokens (run periodically via cron or scheduled job)
CREATE OR REPLACE FUNCTION cleanup_expired_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM pmd_refresh_tokens
    WHERE expires_at < NOW() OR is_revoked = true;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_expired_tokens() IS 'Removes expired and revoked refresh tokens. Run daily via scheduler';
