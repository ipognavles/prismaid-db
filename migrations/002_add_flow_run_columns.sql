-- Migration script to add triggered_by column to pmd_data_flow_runs
-- This tracks whether a run was manual or automated (via scheduler)

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pmd_data_flow_runs' 
        AND column_name = 'triggered_by'
    ) THEN
        ALTER TABLE pmd_data_flow_runs 
        ADD COLUMN triggered_by VARCHAR(255) DEFAULT 'manual';
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pmd_data_flow_runs' 
        AND column_name = 'records_processed'
    ) THEN
        ALTER TABLE pmd_data_flow_runs 
        ADD COLUMN records_processed INTEGER DEFAULT 0;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pmd_data_flow_runs' 
        AND column_name = 'execution_log'
    ) THEN
        ALTER TABLE pmd_data_flow_runs 
        ADD COLUMN execution_log JSONB;
    END IF;
END $$;

COMMIT;
