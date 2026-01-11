-- ============================================================================
-- FIX ADMIN ACCOUNT - Update Password and Unlock
-- ============================================================================
-- This script fixes the admin account by:
-- 1. Updating to the correct password hash for "admin123"
-- 2. Unlocking the account (reset failed login attempts and locked_until)
-- ============================================================================

-- Update admin user with correct password hash and unlock account
UPDATE pmd_users
SET
    password_hash = '$2b$10$904Lge/3MZScpaTqZfQUP.QMzuw6sXDOZuWE1tdTB5B5ZTYZ1fyo6',
    failed_login_attempts = 0,
    locked_until = NULL
WHERE username = 'admin';

-- Verify the update
SELECT
    username,
    email,
    failed_login_attempts,
    locked_until,
    is_active,
    'Password updated and account unlocked' as status
FROM pmd_users
WHERE username = 'admin';
