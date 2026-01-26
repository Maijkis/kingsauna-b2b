-- ============================================
-- ONE-STEP FIX: Run this to fix everything
-- Copy this entire file and paste into Supabase SQL Editor
-- ============================================

-- Step 1: Create table if it doesn't exist (with all columns)
CREATE TABLE IF NOT EXISTS survey_responses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Contact Information
  vardas TEXT NOT NULL,
  el_pastas TEXT NOT NULL,
  telefonas TEXT NOT NULL,
  miestas TEXT,
  komentaras TEXT,
  
  -- Survey Type
  type TEXT NOT NULL CHECK (type IN ('lauko', 'vidaus', 'kubila')),
  
  -- Type-specific data stored as JSON
  lauko_data JSONB,
  kubilas_data JSONB,
  vidaus_data JSONB,
  
  -- Analytics & Tracking Fields
  visitor_id TEXT,
  session_id TEXT,
  time_to_complete_seconds INTEGER,
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  landing_page TEXT
);

-- Step 2: Add missing columns if table already exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'visitor_id') THEN
        ALTER TABLE survey_responses ADD COLUMN visitor_id TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'session_id') THEN
        ALTER TABLE survey_responses ADD COLUMN session_id TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'time_to_complete_seconds') THEN
        ALTER TABLE survey_responses ADD COLUMN time_to_complete_seconds INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'referrer') THEN
        ALTER TABLE survey_responses ADD COLUMN referrer TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'utm_source') THEN
        ALTER TABLE survey_responses ADD COLUMN utm_source TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'utm_medium') THEN
        ALTER TABLE survey_responses ADD COLUMN utm_medium TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'utm_campaign') THEN
        ALTER TABLE survey_responses ADD COLUMN utm_campaign TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'survey_responses' AND column_name = 'landing_page') THEN
        ALTER TABLE survey_responses ADD COLUMN landing_page TEXT;
    END IF;
END $$;

-- Step 3: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_survey_type ON survey_responses(type);
CREATE INDEX IF NOT EXISTS idx_survey_created_at ON survey_responses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_survey_email ON survey_responses(el_pastas);

-- Step 4: Enable Row Level Security
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;

-- Step 5: Create/Update RLS Policies
-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow anonymous survey submissions" ON survey_responses;
DROP POLICY IF EXISTS "Authenticated users can view responses" ON survey_responses;

-- Create policies
CREATE POLICY "Allow anonymous survey submissions" ON survey_responses
  FOR INSERT 
  TO anon
  WITH CHECK (true);

CREATE POLICY "Authenticated users can view responses" ON survey_responses
  FOR SELECT
  TO authenticated
  USING (true);

-- Step 6: Verify everything is set up correctly
SELECT 
    '✅ SETUP COMPLETE!' as status,
    COUNT(*) as total_columns,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'survey_responses') as rls_policies_count
FROM information_schema.columns
WHERE table_name = 'survey_responses';

-- Show all columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'survey_responses'
ORDER BY ordinal_position;
