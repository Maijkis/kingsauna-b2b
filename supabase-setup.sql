-- ============================================
-- Kingsauna Survey Database Setup
-- Run this in your Supabase SQL Editor
-- ============================================

-- Create survey responses table
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
  landing_page TEXT,
  
  -- Indexes for common queries
  CONSTRAINT valid_type CHECK (type IN ('lauko', 'vidaus', 'kubila'))
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_survey_type ON survey_responses(type);
CREATE INDEX IF NOT EXISTS idx_survey_created_at ON survey_responses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_survey_email ON survey_responses(el_pastas);

-- Enable Row Level Security
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anonymous users to INSERT (for survey submissions)
CREATE POLICY "Allow anonymous survey submissions" ON survey_responses
  FOR INSERT 
  TO anon
  WITH CHECK (true);

-- Policy: Only authenticated users can view all responses (for admin dashboard)
CREATE POLICY "Authenticated users can view responses" ON survey_responses
  FOR SELECT
  TO authenticated
  USING (true);

-- Create a view for easy data analysis (optional)
CREATE OR REPLACE VIEW survey_summary AS
SELECT 
  id,
  created_at,
  vardas,
  el_pastas,
  telefonas,
  miestas,
  type,
  CASE 
    WHEN type = 'lauko' THEN lauko_data
    WHEN type = 'kubila' THEN kubilas_data
    WHEN type = 'vidaus' THEN vidaus_data
  END as survey_details
FROM survey_responses
ORDER BY created_at DESC;

-- ============================================
-- VERIFICATION QUERIES
-- Run these to test your setup
-- ============================================

-- Check if table was created
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_name = 'survey_responses';

-- Check RLS policies
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'survey_responses';

-- View column structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'survey_responses'
ORDER BY ordinal_position;

-- ============================================
-- SAMPLE QUERIES (for viewing data later)
-- ============================================

-- View all submissions
-- SELECT * FROM survey_responses ORDER BY created_at DESC LIMIT 10;

-- Count by type
-- SELECT type, COUNT(*) as count FROM survey_responses GROUP BY type;

-- Recent lauko pirtis submissions
-- SELECT vardas, el_pastas, created_at, lauko_data 
-- FROM survey_responses 
-- WHERE type = 'lauko' 
-- ORDER BY created_at DESC LIMIT 5;

