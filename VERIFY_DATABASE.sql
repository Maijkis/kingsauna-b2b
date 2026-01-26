-- ============================================
-- VERIFICATION: Check if all required columns exist
-- Run this to verify your database is ready
-- ============================================

-- Check if table exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'survey_responses'
        ) THEN '✅ Table exists'
        ELSE '❌ Table does NOT exist - Run CREATE_TABLE.sql'
    END as table_status;

-- List all columns in survey_responses table
SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IN (
            'id', 'created_at', 'vardas', 'el_pastas', 'telefonas', 
            'miestas', 'komentaras', 'type', 'lauko_data', 'kubilas_data', 
            'vidaus_data', 'visitor_id', 'session_id', 'time_to_complete_seconds',
            'referrer', 'utm_source', 'utm_medium', 'utm_campaign', 'landing_page'
        ) THEN '✅ Required'
        ELSE '⚠️ Extra'
    END as status
FROM information_schema.columns
WHERE table_name = 'survey_responses'
ORDER BY ordinal_position;

-- Check for missing required columns
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'visitor_id'
        ) THEN '❌ MISSING: visitor_id'
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'session_id'
        ) THEN '❌ MISSING: session_id'
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'time_to_complete_seconds'
        ) THEN '❌ MISSING: time_to_complete_seconds'
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'referrer'
        ) THEN '❌ MISSING: referrer'
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'utm_source'
        ) THEN '❌ MISSING: utm_source'
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'utm_medium'
        ) THEN '❌ MISSING: utm_medium'
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'utm_campaign'
        ) THEN '❌ MISSING: utm_campaign'
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'survey_responses' AND column_name = 'landing_page'
        ) THEN '❌ MISSING: landing_page'
        ELSE '✅ All required columns exist!'
    END as migration_status;

-- Check RLS policies
SELECT 
    policyname,
    cmd as command,
    CASE 
        WHEN cmd = 'INSERT' AND roles = '{anon}' THEN '✅ Anonymous insert allowed'
        WHEN cmd = 'SELECT' AND roles = '{authenticated}' THEN '✅ Authenticated select allowed'
        ELSE '⚠️ Check policy'
    END as policy_status
FROM pg_policies 
WHERE tablename = 'survey_responses';

-- Count existing records (if any)
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT type) as survey_types,
    MAX(created_at) as latest_submission
FROM survey_responses;
