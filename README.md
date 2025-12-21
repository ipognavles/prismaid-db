# Prismaid Database

This folder contains the database schema and initialization scripts for the Prismaid data mapping application.

## Database Setup

### Prerequisites
- PostgreSQL 12 or higher installed
- PostgreSQL command-line tools (psql)

### Initial Setup

1. **Create the database:**
   ```bash
   psql -U postgres -c "CREATE DATABASE prismaid;"
   ```

2. **Run the initialization script:**
   ```bash
   psql -U postgres -d prismaid -f init.sql
   ```

   Or connect to PostgreSQL and run:
   ```sql
   \c prismaid
   \i init.sql
   ```

### Database Schema

The application uses three main tables:

#### 1. schemas
Stores destination schema definitions that data will be mapped to.
- `id` - Unique identifier (UUID)
- `name` - Schema name
- `description` - Optional description
- `schema_definition` - JSONB containing field definitions
- `created_at` - Timestamp
- `updated_at` - Timestamp

#### 2. uploaded_files
Stores metadata about uploaded source files.
- `id` - Unique identifier (UUID)
- `filename` - System filename
- `original_name` - Original uploaded filename
- `file_type` - Detected file type (csv, json, excel)
- `file_path` - Path to stored file
- `detected_fields` - JSONB array of detected field information
- `sample_data` - JSONB array of sample records
- `created_at` - Timestamp

#### 3. mappings
Stores field mapping configurations.
- `id` - Unique identifier (UUID)
- `name` - Mapping name
- `description` - Optional description
- `schema_id` - Foreign key to schemas table
- `file_id` - Foreign key to uploaded_files table
- `field_mappings` - JSONB array of field mapping configurations
- `created_at` - Timestamp
- `updated_at` - Timestamp

### Connection Configuration

Update the `.env` file in the API project with your database credentials:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=prismaid
DB_USER=postgres
DB_PASSWORD=your_password
```

### Sample Data

The initialization script includes a sample "Customer Schema" for testing purposes.

### Backup and Restore

**Backup:**
```bash
pg_dump -U postgres prismaid > prismaid_backup.sql
```

**Restore:**
```bash
psql -U postgres prismaid < prismaid_backup.sql
```

### Reset Database

To reset the database and start fresh:
```bash
psql -U postgres -c "DROP DATABASE IF EXISTS prismaid;"
psql -U postgres -c "CREATE DATABASE prismaid;"
psql -U postgres -d prismaid -f init.sql
```
