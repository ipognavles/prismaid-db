-- ============================================================================
-- SSO (Single Sign-On) Configuration Tables
-- Supports Microsoft Entra (Azure AD), Google, and other SAML/OAuth providers
-- ============================================================================

-- SSO Provider Configuration
CREATE TABLE IF NOT EXISTS pmd_sso_providers (
  pmd_sso_provider_id SERIAL PRIMARY KEY,
  provider_name VARCHAR(100) NOT NULL UNIQUE, -- 'microsoft_entra', 'google', 'okta', etc.
  provider_type VARCHAR(50) NOT NULL, -- 'oauth2', 'saml', 'oidc'
  is_enabled BOOLEAN DEFAULT false,

  -- OAuth 2.0 / OpenID Connect Configuration
  client_id VARCHAR(500), -- Application (client) ID
  client_secret VARCHAR(500), -- Client secret (encrypted in production)
  tenant_id VARCHAR(200), -- For Microsoft Entra (Azure AD)
  authority_url VARCHAR(500), -- Authorization endpoint
  token_url VARCHAR(500), -- Token endpoint
  user_info_url VARCHAR(500), -- User info endpoint

  -- SAML Configuration
  entity_id VARCHAR(500), -- SAML Entity ID
  sso_url VARCHAR(500), -- SAML SSO URL
  certificate TEXT, -- SAML X.509 certificate

  -- Common Configuration
  redirect_uri VARCHAR(500), -- Callback URL after authentication
  scopes TEXT, -- Comma-separated scopes (e.g., 'openid,profile,email')

  -- User Attribute Mapping
  username_claim VARCHAR(100) DEFAULT 'preferred_username', -- Claim for username
  email_claim VARCHAR(100) DEFAULT 'email', -- Claim for email
  full_name_claim VARCHAR(100) DEFAULT 'name', -- Claim for full name
  groups_claim VARCHAR(100) DEFAULT 'groups', -- Claim for groups/roles

  -- Settings
  auto_provision_users BOOLEAN DEFAULT true, -- Auto-create users on first login
  default_role_id INTEGER, -- Default role for auto-provisioned users
  allow_local_login BOOLEAN DEFAULT true, -- Allow username/password alongside SSO

  -- Audit fields
  created_at TIMESTAMP DEFAULT NOW(),
  created_by INTEGER,
  created_by_name VARCHAR(100),
  updated_at TIMESTAMP DEFAULT NOW(),
  updated_by INTEGER,
  updated_by_name VARCHAR(100),
  is_active BOOLEAN DEFAULT true,

  FOREIGN KEY (default_role_id) REFERENCES pmd_roles(pmd_role_id),
  FOREIGN KEY (created_by) REFERENCES pmd_users(pmd_user_id),
  FOREIGN KEY (updated_by) REFERENCES pmd_users(pmd_user_id)
);

-- SSO Group/Role Mapping
-- Maps external identity provider groups to Prismaid roles
CREATE TABLE IF NOT EXISTS pmd_sso_role_mappings (
  pmd_sso_role_mapping_id SERIAL PRIMARY KEY,
  pmd_sso_provider_id INTEGER NOT NULL,
  external_group_id VARCHAR(200) NOT NULL, -- Azure AD Group Object ID or name
  external_group_name VARCHAR(200), -- Friendly name for display
  pmd_role_id INTEGER NOT NULL,

  -- Audit fields
  created_at TIMESTAMP DEFAULT NOW(),
  created_by INTEGER,
  created_by_name VARCHAR(100),
  updated_at TIMESTAMP DEFAULT NOW(),
  updated_by INTEGER,
  updated_by_name VARCHAR(100),
  is_active BOOLEAN DEFAULT true,

  FOREIGN KEY (pmd_sso_provider_id) REFERENCES pmd_sso_providers(pmd_sso_provider_id),
  FOREIGN KEY (pmd_role_id) REFERENCES pmd_roles(pmd_role_id),
  FOREIGN KEY (created_by) REFERENCES pmd_users(pmd_user_id),
  FOREIGN KEY (updated_by) REFERENCES pmd_users(pmd_user_id),
  UNIQUE (pmd_sso_provider_id, external_group_id, pmd_role_id)
);

-- SSO User External Identity Mapping
-- Links Prismaid users to their external identity provider accounts
CREATE TABLE IF NOT EXISTS pmd_sso_user_identities (
  pmd_sso_user_identity_id SERIAL PRIMARY KEY,
  pmd_user_id INTEGER NOT NULL,
  pmd_sso_provider_id INTEGER NOT NULL,
  external_user_id VARCHAR(200) NOT NULL, -- Azure AD Object ID, Google sub, etc.
  external_username VARCHAR(200), -- UPN, email, etc.
  external_email VARCHAR(200),

  -- Audit fields
  created_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP,
  is_active BOOLEAN DEFAULT true,

  FOREIGN KEY (pmd_user_id) REFERENCES pmd_users(pmd_user_id),
  FOREIGN KEY (pmd_sso_provider_id) REFERENCES pmd_sso_providers(pmd_sso_provider_id),
  UNIQUE (pmd_sso_provider_id, external_user_id)
);

-- Create sequences
CREATE SEQUENCE IF NOT EXISTS pmd_sso_providers_seq START WITH 1;
CREATE SEQUENCE IF NOT EXISTS pmd_sso_role_mappings_seq START WITH 1;
CREATE SEQUENCE IF NOT EXISTS pmd_sso_user_identities_seq START WITH 1;

-- ============================================================================
-- Default Microsoft Entra (Azure AD) Provider Configuration (Disabled)
-- ============================================================================

INSERT INTO pmd_sso_providers (
  provider_name,
  provider_type,
  is_enabled,
  client_id,
  client_secret,
  tenant_id,
  authority_url,
  token_url,
  user_info_url,
  redirect_uri,
  scopes,
  username_claim,
  email_claim,
  full_name_claim,
  groups_claim,
  auto_provision_users,
  default_role_id,
  allow_local_login,
  created_by,
  created_by_name
) VALUES (
  'microsoft_entra',
  'oidc',
  false, -- Disabled by default, admin must configure
  'YOUR_CLIENT_ID_HERE', -- Application (client) ID from Azure Portal
  'YOUR_CLIENT_SECRET_HERE', -- Client secret from Azure Portal
  'YOUR_TENANT_ID_HERE', -- Directory (tenant) ID from Azure Portal
  'https://login.microsoftonline.com/YOUR_TENANT_ID_HERE/oauth2/v2.0/authorize',
  'https://login.microsoftonline.com/YOUR_TENANT_ID_HERE/oauth2/v2.0/token',
  'https://graph.microsoft.com/v1.0/me',
  'http://localhost:3001/api/auth/sso/callback', -- Update for production
  'openid,profile,email,User.Read,GroupMember.Read.All',
  'preferred_username', -- Or 'unique_name', 'upn'
  'email',
  'name',
  'groups', -- Requires Azure AD Premium or group claims configuration
  true, -- Auto-create users on first SSO login
  2, -- Default to flow_designer role (update as needed)
  true, -- Allow username/password alongside SSO
  1,
  'system'
) ON CONFLICT (provider_name) DO NOTHING;

-- ============================================================================
-- Sample Role Mappings (Examples - Configure based on your Azure AD groups)
-- ============================================================================

-- Example: Map Azure AD "Prismaid Admins" group to Admin role
-- INSERT INTO pmd_sso_role_mappings (
--   pmd_sso_provider_id,
--   external_group_id,
--   external_group_name,
--   pmd_role_id,
--   created_by,
--   created_by_name
-- ) VALUES (
--   (SELECT pmd_sso_provider_id FROM pmd_sso_providers WHERE provider_name = 'microsoft_entra'),
--   'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', -- Azure AD Group Object ID
--   'Prismaid Admins',
--   (SELECT pmd_role_id FROM pmd_roles WHERE role_name = 'admin'),
--   1,
--   'system'
-- );

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_sso_providers_name ON pmd_sso_providers(provider_name);
CREATE INDEX IF NOT EXISTS idx_sso_providers_enabled ON pmd_sso_providers(is_enabled);
CREATE INDEX IF NOT EXISTS idx_sso_role_mappings_provider ON pmd_sso_role_mappings(pmd_sso_provider_id);
CREATE INDEX IF NOT EXISTS idx_sso_role_mappings_group ON pmd_sso_role_mappings(external_group_id);
CREATE INDEX IF NOT EXISTS idx_sso_user_identities_user ON pmd_sso_user_identities(pmd_user_id);
CREATE INDEX IF NOT EXISTS idx_sso_user_identities_provider ON pmd_sso_user_identities(pmd_sso_provider_id);
CREATE INDEX IF NOT EXISTS idx_sso_user_identities_external ON pmd_sso_user_identities(external_user_id);

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE pmd_sso_providers IS 'SSO provider configurations (Microsoft Entra, Google, Okta, etc.)';
COMMENT ON TABLE pmd_sso_role_mappings IS 'Maps external identity provider groups to Prismaid roles';
COMMENT ON TABLE pmd_sso_user_identities IS 'Links Prismaid users to external identity accounts';

COMMENT ON COLUMN pmd_sso_providers.tenant_id IS 'Azure AD: Directory (tenant) ID';
COMMENT ON COLUMN pmd_sso_providers.client_id IS 'OAuth: Application (client) ID';
COMMENT ON COLUMN pmd_sso_providers.client_secret IS 'OAuth: Client secret (encrypt in production)';
COMMENT ON COLUMN pmd_sso_providers.groups_claim IS 'JWT claim containing user groups (requires Azure AD Premium or app manifest configuration)';
COMMENT ON COLUMN pmd_sso_role_mappings.external_group_id IS 'Azure AD: Group Object ID; Google: Group email; Okta: Group ID';
