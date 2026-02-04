-- ============================================
-- QUICK SETUP: Copy and paste this into Supabase SQL Editor
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
  landing_page TEXT
);

-- Create indexes for better performance
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

-- Policy: Only authenticated users can view all responses
CREATE POLICY "Authenticated users can view responses" ON survey_responses
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- VERIFICATION: Run this to check if it worked
-- ============================================
-- SELECT table_name FROM information_schema.tables WHERE table_name = 'survey_responses';
