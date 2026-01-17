-- ============================================================================
-- Prismaid Database - Notifications
-- ============================================================================
-- Description: System notifications for users (missed runs, alerts, system events)
-- Dependencies: 002_auth.sql (pmd_users), 003_core_etl.sql (pmd_data_flows),
--               004_automation.sql (pmd_automation_schedules)
-- Tables: pmd_notifications
-- ============================================================================

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================

CREATE SEQUENCE pmd_notifications_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

CREATE TABLE IF NOT EXISTS pmd_notifications (
    pmd_notification_id BIGINT DEFAULT nextval('pmd_notifications_seq'::regclass) NOT NULL,

    -- Notification type and severity
    notification_type VARCHAR(50) NOT NULL,       -- 'missed_run', 'flow_completed', 'flow_failed',
                                                  -- 'connection_error', 'system'
    severity VARCHAR(20) NOT NULL DEFAULT 'info', -- 'info', 'success', 'warning', 'error'

    -- Message content
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,

    -- Related entity (polymorphic reference)
    related_entity_type VARCHAR(50),              -- 'data_flow', 'schedule', 'connection'
    related_entity_id BIGINT,
    related_entity_name VARCHAR(255),             -- Denormalized for display without joins

    -- Action link (optional navigation target)
    action_url VARCHAR(500),                      -- e.g., '/dataflows?flowId=1'
    action_label VARCHAR(100),                    -- e.g., 'View Flow', 'Run Now'

    -- Read status
    is_read BOOLEAN DEFAULT false NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,

    -- User targeting (NULL = system-wide/all users)
    pmd_user_id BIGINT,

    -- Flexible metadata for additional context
    metadata JSONB DEFAULT '{}'::jsonb,           -- e.g., {"missed_count": 3, "scheduled_at": "..."}

    -- Expiration (optional auto-cleanup)
    expires_at TIMESTAMP WITH TIME ZONE,

    -- Audit
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

    CONSTRAINT pmd_notifications_pk PRIMARY KEY (pmd_notification_id),
    CONSTRAINT pmd_notifications_severity_check CHECK (severity IN ('info', 'success', 'warning', 'error')),
    CONSTRAINT pmd_notifications_type_check CHECK (notification_type IN (
        'missed_run', 'flow_completed', 'flow_failed', 'connection_error', 'system'
    )),
    CONSTRAINT pmd_notifications_user_fk FOREIGN KEY (pmd_user_id)
        REFERENCES pmd_users(pmd_user_id) ON DELETE CASCADE
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Primary query: Get unread notifications for a user (or system-wide)
CREATE INDEX idx_notifications_user_unread ON pmd_notifications(pmd_user_id, is_read)
    WHERE is_active = true AND is_read = false;

-- List notifications by creation time (most recent first)
CREATE INDEX idx_notifications_created ON pmd_notifications(created_at DESC)
    WHERE is_active = true;

-- Filter by notification type
CREATE INDEX idx_notifications_type ON pmd_notifications(notification_type)
    WHERE is_active = true;

-- Find notifications for a specific entity (e.g., all notifications for a data flow)
CREATE INDEX idx_notifications_entity ON pmd_notifications(related_entity_type, related_entity_id)
    WHERE is_active = true;

-- Cleanup expired notifications
CREATE INDEX idx_notifications_expires ON pmd_notifications(expires_at)
    WHERE expires_at IS NOT NULL AND is_active = true;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE pmd_notifications IS 'System notifications for users (missed runs, alerts, system events)';
COMMENT ON COLUMN pmd_notifications.notification_type IS 'Type: missed_run, flow_completed, flow_failed, connection_error, system';
COMMENT ON COLUMN pmd_notifications.severity IS 'Severity level: info, success, warning, error';
COMMENT ON COLUMN pmd_notifications.pmd_user_id IS 'NULL for system-wide notifications visible to all users';
COMMENT ON COLUMN pmd_notifications.related_entity_type IS 'Type of related entity: data_flow, schedule, connection';
COMMENT ON COLUMN pmd_notifications.related_entity_name IS 'Denormalized name for display without joins';
COMMENT ON COLUMN pmd_notifications.action_url IS 'Optional URL for user to navigate to (e.g., /dataflows?flowId=1)';
COMMENT ON COLUMN pmd_notifications.metadata IS 'Flexible JSONB for additional context (missed_count, scheduled_at, etc.)';
COMMENT ON COLUMN pmd_notifications.expires_at IS 'Optional expiration timestamp for auto-cleanup';
