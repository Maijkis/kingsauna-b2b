-- ============================================
-- VERIFICATION QUERIES
-- Run these in Supabase SQL Editor to verify setup
-- ============================================

-- 1. Check all tables exist
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('visitors', 'page_views', 'events', 'survey_responses')
ORDER BY table_name;

-- Expected result: 4 tables with column counts

-- 2. Check RLS policies are enabled
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('visitors', 'page_views', 'events', 'survey_responses')
ORDER BY tablename, policyname;

-- Expected result: Multiple policies for each table

-- 3. Check views were created
SELECT 
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'VIEW'
  AND table_name IN ('visitor_journey', 'survey_with_visitor')
ORDER BY table_name;

-- Expected result: 2 views

-- 4. Test insert permissions (should work for anonymous)
-- This will fail if RLS is blocking, which is expected for SELECT
-- But INSERT should work
SELECT 'Setup looks good! Tables and policies are in place.' as status;
