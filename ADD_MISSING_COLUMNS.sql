-- ============================================
-- MIGRATION: Add Missing Analytics Columns
-- Run this if you already have survey_responses table
-- ============================================

-- Add analytics & tracking columns if they don't exist
DO $$ 
BEGIN
    -- Add visitor_id column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'visitor_id') THEN
        ALTER TABLE survey_responses ADD COLUMN visitor_id TEXT;
    END IF;
    
    -- Add session_id column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'session_id') THEN
        ALTER TABLE survey_responses ADD COLUMN session_id TEXT;
    END IF;
    
    -- Add time_to_complete_seconds column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'time_to_complete_seconds') THEN
        ALTER TABLE survey_responses ADD COLUMN time_to_complete_seconds INTEGER;
    END IF;
    
    -- Add referrer column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'referrer') THEN
        ALTER TABLE survey_responses ADD COLUMN referrer TEXT;
    END IF;
    
    -- Add utm_source column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'utm_source') THEN
        ALTER TABLE survey_responses ADD COLUMN utm_source TEXT;
    END IF;
    
    -- Add utm_medium column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'utm_medium') THEN
        ALTER TABLE survey_responses ADD COLUMN utm_medium TEXT;
    END IF;
    
    -- Add utm_campaign column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'utm_campaign') THEN
        ALTER TABLE survey_responses ADD COLUMN utm_campaign TEXT;
    END IF;
    
    -- Add landing_page column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'landing_page') THEN
        ALTER TABLE survey_responses ADD COLUMN landing_page TEXT;
    END IF;
END $$;

-- Verify columns were added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'survey_responses'
ORDER BY ordinal_position;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
-- If you see all columns listed above, the migration was successful!
