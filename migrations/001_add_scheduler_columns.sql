-- Migration script to add scheduler tracking columns to pmd_automation_schedules
-- Run this if your table already exists without these columns

-- Add last_run_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pmd_automation_schedules' 
        AND column_name = 'last_run_at'
    ) THEN
        ALTER TABLE pmd_automation_schedules 
        ADD COLUMN last_run_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Add run_count column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pmd_automation_schedules' 
        AND column_name = 'run_count'
    ) THEN
        ALTER TABLE pmd_automation_schedules 
        ADD COLUMN run_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- Add last_error column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pmd_automation_schedules' 
        AND column_name = 'last_error'
    ) THEN
        ALTER TABLE pmd_automation_schedules 
        ADD COLUMN last_error TEXT;
    END IF;
END $$;

-- Add last_error_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pmd_automation_schedules' 
        AND column_name = 'last_error_at'
    ) THEN
        ALTER TABLE pmd_automation_schedules 
        ADD COLUMN last_error_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Update existing records to have run_count = 0 if NULL
UPDATE pmd_automation_schedules 
SET run_count = 0 
WHERE run_count IS NULL;

COMMIT;
