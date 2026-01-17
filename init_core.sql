-- ============================================================================
-- Prismaid Database - Core Installation (No Healthcare)
-- ============================================================================
-- Description: Master script that installs core modules only (excludes EDI, HL7, FHIR)
-- Usage: psql -U postgres -d prismaid -f prismaid-db/init_core.sql
-- ============================================================================

\echo '=============================================='
\echo 'Installing Prismaid Database Schema (Core Only)'
\echo '=============================================='

\echo 'Installing extensions...'
\i sql/000_extensions.sql

\echo 'Installing reference data...'
\i sql/001_reference_data.sql

\echo 'Installing authentication & authorization...'
\i sql/002_auth.sql

\echo 'Installing core ETL tables...'
\i sql/003_core_etl.sql

\echo 'Installing automation tables...'
\i sql/004_automation.sql

\echo 'Installing apps & tags...'
\i sql/005_apps_tags.sql

\echo 'Installing API builder...'
\i sql/006_api_builder.sql

\echo 'Installing notifications...'
\i sql/007_notifications.sql

\echo 'Installing SSO (Single Sign-On)...'
\i sql/008_sso.sql

\echo '=============================================='
\echo 'Prismaid Database Schema (Core) installed successfully!'
\echo '=============================================='
\echo ''
\echo 'Installed modules:'
\echo '  - Core: Extensions, Reference Data, Auth, ETL, Automation, Apps/Tags, API Builder, Notifications, SSO'
\echo ''
\echo 'Healthcare modules NOT installed. To add later, run:'
\echo '  psql -U postgres -d prismaid -f prismaid-db/sql/010_edi_x12.sql'
\echo '  psql -U postgres -d prismaid -f prismaid-db/sql/011_hl7_v2.sql'
\echo '  psql -U postgres -d prismaid -f prismaid-db/sql/012_fhir_r4.sql'
\echo ''
