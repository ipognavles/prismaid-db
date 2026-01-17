-- ============================================================================
-- Prismaid Database - Extensions
-- ============================================================================
-- Description: PostgreSQL extensions required by Prismaid
-- Dependencies: None (run first)
-- ============================================================================

-- Enable UUID extension for cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
