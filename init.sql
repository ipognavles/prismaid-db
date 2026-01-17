-- ============================================================================
-- Prismaid Database - Full Installation
-- ============================================================================
-- Description: Master script that installs all modules including healthcare
-- Usage: psql -U postgres -d prismaid -f prismaid-db/init.sql
-- ============================================================================

\echo '=============================================='
\echo 'Installing Prismaid Database Schema (Full)'
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

\echo 'Installing EDI X12 healthcare tables...'
\i sql/010_edi_x12.sql

\echo 'Installing HL7 v2.x healthcare tables...'
\i sql/011_hl7_v2.sql

\echo 'Installing FHIR R4 healthcare tables...'
\i sql/012_fhir_r4.sql

\echo '=============================================='
\echo 'Prismaid Database Schema installed successfully!'
\echo '=============================================='
\echo ''
\echo 'Installed modules:'
\echo '  - Core: Extensions, Reference Data, Auth, ETL, Automation, Apps/Tags, API Builder, Notifications, SSO'
\echo '  - Healthcare: EDI X12, HL7 v2.x, FHIR R4'
\echo ''
