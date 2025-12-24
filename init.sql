-- Prismaid Database Setup Script

-- Create database (run as postgres superuser)
-- CREATE DATABASE prismaid;
-- \c prismaid

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schemas table
CREATE TABLE IF NOT EXISTS schemas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  vendor VARCHAR(255),
  schema_type VARCHAR(20) DEFAULT 'target' CHECK (schema_type IN ('source', 'target')),
  source_type VARCHAR(20) DEFAULT 'file' CHECK (source_type IN ('file', 'api')),
  format_type VARCHAR(50) DEFAULT 'json' CHECK (format_type IN ('json', 'xml', 'csv', 'tsv', 'pipe', 'edi', 'api', 'custom')),
  schema_definition JSONB NOT NULL,
  raw_content TEXT,
  delimiter VARCHAR(10),
  edi_transaction VARCHAR(50),
  swagger_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create uploaded_files table
CREATE TABLE IF NOT EXISTS uploaded_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filename VARCHAR(255) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50),
  file_path VARCHAR(500),
  detected_fields JSONB,
  sample_data JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create mappings table
CREATE TABLE IF NOT EXISTS mappings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  source_schema_id UUID REFERENCES schemas(id) ON DELETE CASCADE,
  target_schema_id UUID REFERENCES schemas(id) ON DELETE CASCADE,
  field_mappings JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_mappings_source_schema_id ON mappings(source_schema_id);
CREATE INDEX IF NOT EXISTS idx_mappings_target_schema_id ON mappings(target_schema_id);
CREATE INDEX IF NOT EXISTS idx_schemas_name ON schemas(name);
CREATE INDEX IF NOT EXISTS idx_mappings_name ON mappings(name);

-- Insert sample schema for testing
INSERT INTO schemas (name, description, schema_type, schema_definition) VALUES
('Customer Schema', 'Standard customer data schema', 'target', '{
  "fields": [
    {"name": "firstName", "type": "string", "required": true},
    {"name": "lastName", "type": "string", "required": true},
    {"name": "email", "type": "email", "required": true},
    {"name": "phone", "type": "phone", "required": false},
    {"name": "address", "type": "string", "required": false},
    {"name": "city", "type": "string", "required": false},
    {"name": "state", "type": "string", "required": false},
    {"name": "zipCode", "type": "string", "required": false},
    {"name": "country", "type": "string", "required": false},
    {"name": "dateOfBirth", "type": "date", "required": false}
  ]
}'::jsonb)
ON CONFLICT DO NOTHING;

-- Display confirmation
SELECT 'Database initialized successfully!' as status;
