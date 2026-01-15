-- ============================================
-- COMPLETE DATABASE SETUP FOR KINGSAUNA
-- This script creates a clean, organized database structure
-- Run this ENTIRE script in Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: Clean up any existing messy tables
-- ============================================
DROP TABLE IF EXISTS funnel_steps CASCADE;
DROP TABLE IF EXISTS user_events CASCADE;
DROP TABLE IF EXISTS page_visitors CASCADE;
DROP TABLE IF EXISTS survey_responses CASCADE;

-- ============================================
-- STEP 2: Create VISITORS table (tracks all visitors)
-- ============================================
CREATE TABLE visitors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Visitor identification
  visitor_id TEXT UNIQUE NOT NULL, -- Unique ID stored in localStorage/cookie
  session_id TEXT NOT NULL, -- Session ID (changes per session)
  
  -- First visit tracking
  first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Traffic source
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  landing_page TEXT, -- First page they visited
  
  -- Device info (optional, for analytics)
  device_type TEXT, -- 'mobile', 'tablet', 'desktop'
  browser TEXT,
  
  -- Engagement metrics
  total_page_views INTEGER DEFAULT 1,
  total_sessions INTEGER DEFAULT 1,
  
  -- Conversion tracking
  converted BOOLEAN DEFAULT FALSE, -- Did they complete a survey?
  converted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_visitors_visitor_id ON visitors(visitor_id);
CREATE INDEX idx_visitors_session_id ON visitors(session_id);
CREATE INDEX idx_visitors_created_at ON visitors(created_at DESC);
CREATE INDEX idx_visitors_converted ON visitors(converted);

-- ============================================
-- STEP 3: Create PAGE_VIEWS table (tracks each page visit)
-- ============================================
CREATE TABLE page_views (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Link to visitor
  visitor_id TEXT NOT NULL REFERENCES visitors(visitor_id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  
  -- Page info
  page_url TEXT NOT NULL,
  page_path TEXT, -- e.g., '/', '/survey.html'
  page_title TEXT,
  
  -- Referrer for this specific page
  referrer TEXT,
  
  -- Time tracking
  time_on_page_seconds INTEGER DEFAULT 0,
  scroll_depth INTEGER DEFAULT 0 -- percentage 0-100
);

CREATE INDEX idx_page_views_visitor_id ON page_views(visitor_id);
CREATE INDEX idx_page_views_session_id ON page_views(session_id);
CREATE INDEX idx_page_views_created_at ON page_views(created_at DESC);
CREATE INDEX idx_page_views_page_path ON page_views(page_path);

-- ============================================
-- STEP 4: Create EVENTS table (tracks user interactions)
-- ============================================
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Link to visitor
  visitor_id TEXT REFERENCES visitors(visitor_id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  
  -- Event details
  event_type TEXT NOT NULL, -- 'button_click', 'cta_click', 'form_start', 'survey_start', etc.
  event_category TEXT, -- 'navigation', 'engagement', 'conversion'
  event_label TEXT, -- Specific identifier (e.g., 'hero_cta', 'product_modal_open')
  
  -- Context
  page_url TEXT NOT NULL,
  page_path TEXT,
  element_id TEXT, -- DOM element ID if available
  element_text TEXT, -- Button/link text
  
  -- Additional data (flexible JSON storage)
  metadata JSONB
);

CREATE INDEX idx_events_visitor_id ON events(visitor_id);
CREATE INDEX idx_events_session_id ON events(session_id);
CREATE INDEX idx_events_event_type ON events(event_type);
CREATE INDEX idx_events_created_at ON events(created_at DESC);
CREATE INDEX idx_events_category ON events(event_category);

-- ============================================
-- STEP 5: Create SURVEY_RESPONSES table (main survey data)
-- ============================================
CREATE TABLE survey_responses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Link to visitor (CRITICAL for tracking visitor to survey)
  visitor_id TEXT REFERENCES visitors(visitor_id) ON DELETE SET NULL,
  session_id TEXT NOT NULL,
  
  -- Contact Information (REQUIRED)
  vardas TEXT NOT NULL,
  el_pastas TEXT NOT NULL,
  telefonas TEXT NOT NULL,
  miestas TEXT,
  komentaras TEXT,
  
  -- Survey Type (REQUIRED)
  type TEXT NOT NULL CHECK (type IN ('lauko', 'vidaus', 'kubila')),
  
  -- Survey Data (stored as JSON - only what's needed)
  lauko_data JSONB, -- Only if type = 'lauko'
  kubilas_data JSONB, -- Only if type = 'kubila'
  vidaus_data JSONB, -- Only if type = 'vidaus'
  
  -- Source tracking (where did they come from?)
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  landing_page TEXT, -- Which page they started on
  
  -- Engagement metrics
  time_to_complete_seconds INTEGER, -- How long survey took
  
  -- Status tracking
  status TEXT DEFAULT 'submitted' CHECK (status IN ('submitted', 'contacted', 'converted', 'cancelled')),
  contacted_at TIMESTAMP WITH TIME ZONE,
  converted_at TIMESTAMP WITH TIME ZONE,
  notes TEXT -- Internal notes
);

CREATE INDEX idx_survey_visitor_id ON survey_responses(visitor_id);
CREATE INDEX idx_survey_session_id ON survey_responses(session_id);
CREATE INDEX idx_survey_type ON survey_responses(type);
CREATE INDEX idx_survey_created_at ON survey_responses(created_at DESC);
CREATE INDEX idx_survey_email ON survey_responses(el_pastas);
CREATE INDEX idx_survey_status ON survey_responses(status);

-- ============================================
-- STEP 6: Enable Row Level Security (RLS)
-- ============================================

-- Visitors table
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous visitor tracking" ON visitors
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anonymous visitor updates" ON visitors
  FOR UPDATE TO anon USING (true);
CREATE POLICY "Admins can view all visitors" ON visitors
  FOR SELECT TO authenticated USING (true);

-- Page views table
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous page view tracking" ON page_views
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins can view all page views" ON page_views
  FOR SELECT TO authenticated USING (true);

-- Events table
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous event tracking" ON events
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins can view all events" ON events
  FOR SELECT TO authenticated USING (true);

-- Survey responses table
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous survey submissions" ON survey_responses
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins can view all survey responses" ON survey_responses
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can update survey responses" ON survey_responses
  FOR UPDATE TO authenticated USING (true);

-- ============================================
-- STEP 7: Create helpful views for analytics
-- ============================================

-- View: Visitor journey (visitor -> page views -> events -> survey)
CREATE OR REPLACE VIEW visitor_journey AS
SELECT 
  v.id as visitor_table_id,
  v.visitor_id,
  v.session_id,
  v.first_seen_at,
  v.last_seen_at,
  v.landing_page,
  v.utm_source,
  v.utm_medium,
  v.utm_campaign,
  v.total_page_views,
  v.total_sessions,
  v.converted,
  v.converted_at,
  COUNT(DISTINCT pv.id) as page_views_count,
  COUNT(DISTINCT e.id) as events_count,
  COUNT(DISTINCT sr.id) as survey_submissions_count,
  MAX(sr.created_at) as last_survey_submission
FROM visitors v
LEFT JOIN page_views pv ON v.visitor_id = pv.visitor_id
LEFT JOIN events e ON v.visitor_id = e.visitor_id
LEFT JOIN survey_responses sr ON v.visitor_id = sr.visitor_id
GROUP BY v.id, v.visitor_id, v.session_id, v.first_seen_at, v.last_seen_at, 
         v.landing_page, v.utm_source, v.utm_medium, v.utm_campaign, 
         v.total_page_views, v.total_sessions, v.converted, v.converted_at;

-- View: Survey responses with visitor info
CREATE OR REPLACE VIEW survey_with_visitor AS
SELECT 
  sr.*,
  v.first_seen_at as visitor_first_seen,
  v.landing_page as visitor_landing_page,
  v.utm_source as visitor_utm_source,
  v.utm_medium as visitor_utm_medium,
  v.utm_campaign as visitor_utm_campaign,
  COUNT(DISTINCT pv.id) as visitor_page_views_before_survey,
  COUNT(DISTINCT e.id) as visitor_events_before_survey
FROM survey_responses sr
LEFT JOIN visitors v ON sr.visitor_id = v.visitor_id
LEFT JOIN page_views pv ON v.visitor_id = pv.visitor_id AND pv.created_at < sr.created_at
LEFT JOIN events e ON v.visitor_id = e.visitor_id AND e.created_at < sr.created_at
GROUP BY sr.id, sr.created_at, sr.visitor_id, sr.session_id, sr.vardas, 
         sr.el_pastas, sr.telefonas, sr.miestas, sr.komentaras, sr.type,
         sr.lauko_data, sr.kubilas_data, sr.vidaus_data, sr.referrer,
         sr.utm_source, sr.utm_medium, sr.utm_campaign, sr.landing_page,
         sr.time_to_complete_seconds, sr.status, sr.contacted_at,
         sr.converted_at, sr.notes,
         v.first_seen_at, v.landing_page, v.utm_source, v.utm_medium, v.utm_campaign;

-- View: Conversion funnel
CREATE OR REPLACE VIEW conversion_funnel AS
SELECT 
  COUNT(DISTINCT v.visitor_id) as total_visitors,
  COUNT(DISTINCT CASE WHEN pv.page_path = '/survey.html' THEN v.visitor_id END) as survey_page_views,
  COUNT(DISTINCT CASE WHEN e.event_type = 'survey_start' THEN v.visitor_id END) as survey_starts,
  COUNT(DISTINCT sr.id) as survey_completions,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN pv.page_path = '/survey.html' THEN v.visitor_id END) / NULLIF(COUNT(DISTINCT v.visitor_id), 0), 2) as survey_page_view_rate,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_type = 'survey_start' THEN v.visitor_id END) / NULLIF(COUNT(DISTINCT CASE WHEN pv.page_path = '/survey.html' THEN v.visitor_id END), 0), 2) as survey_start_rate,
  ROUND(100.0 * COUNT(DISTINCT sr.id) / NULLIF(COUNT(DISTINCT CASE WHEN e.event_type = 'survey_start' THEN v.visitor_id END), 0), 2) as survey_completion_rate
FROM visitors v
LEFT JOIN page_views pv ON v.visitor_id = pv.visitor_id
LEFT JOIN events e ON v.visitor_id = e.visitor_id
LEFT JOIN survey_responses sr ON v.visitor_id = sr.visitor_id;

-- ============================================
-- STEP 8: Verification queries
-- ============================================

-- Check all tables were created
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('visitors', 'page_views', 'events', 'survey_responses')
ORDER BY table_name;

-- Check RLS policies
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

-- ============================================
-- SUCCESS! Your database is now set up.
-- ============================================
-- Tables created:
-- ✅ visitors - Tracks all unique visitors
-- ✅ page_views - Tracks every page visit
-- ✅ events - Tracks user interactions
-- ✅ survey_responses - Stores survey submissions (linked to visitors)
--
-- Views created:
-- ✅ visitor_journey - Complete visitor journey
-- ✅ survey_with_visitor - Survey responses with visitor context
-- ✅ conversion_funnel - Funnel analytics
--
-- All tables are linked via visitor_id for complete tracking!
