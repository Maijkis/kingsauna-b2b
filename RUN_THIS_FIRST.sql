-- ============================================
-- 🚀 RUN THIS IN SUPABASE SQL EDITOR
-- Copy the ENTIRE file and paste into Supabase
-- ============================================

-- This will create a clean, organized database structure
-- that tracks visitors from landing page to survey completion

-- ============================================
-- STEP 1: Clean up any existing messy tables
-- ============================================
DROP TABLE IF EXISTS funnel_steps CASCADE;
DROP TABLE IF EXISTS user_events CASCADE;
DROP TABLE IF EXISTS page_visitors CASCADE;
DROP TABLE IF EXISTS survey_responses CASCADE;

-- ============================================
-- STEP 2: Create VISITORS table
-- ============================================
CREATE TABLE visitors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  visitor_id TEXT UNIQUE NOT NULL,
  session_id TEXT NOT NULL,
  first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  landing_page TEXT,
  device_type TEXT,
  browser TEXT,
  total_page_views INTEGER DEFAULT 1,
  total_sessions INTEGER DEFAULT 1,
  converted BOOLEAN DEFAULT FALSE,
  converted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_visitors_visitor_id ON visitors(visitor_id);
CREATE INDEX idx_visitors_session_id ON visitors(session_id);
CREATE INDEX idx_visitors_created_at ON visitors(created_at DESC);
CREATE INDEX idx_visitors_converted ON visitors(converted);

-- ============================================
-- STEP 3: Create PAGE_VIEWS table
-- ============================================
CREATE TABLE page_views (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  visitor_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  page_url TEXT NOT NULL,
  page_path TEXT,
  page_title TEXT,
  referrer TEXT,
  time_on_page_seconds INTEGER DEFAULT 0,
  scroll_depth INTEGER DEFAULT 0
);

CREATE INDEX idx_page_views_visitor_id ON page_views(visitor_id);
CREATE INDEX idx_page_views_session_id ON page_views(session_id);
CREATE INDEX idx_page_views_created_at ON page_views(created_at DESC);
CREATE INDEX idx_page_views_page_path ON page_views(page_path);

-- ============================================
-- STEP 4: Create EVENTS table
-- ============================================
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  visitor_id TEXT,
  session_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_category TEXT,
  event_label TEXT,
  page_url TEXT NOT NULL,
  page_path TEXT,
  element_id TEXT,
  element_text TEXT,
  metadata JSONB
);

CREATE INDEX idx_events_visitor_id ON events(visitor_id);
CREATE INDEX idx_events_session_id ON events(session_id);
CREATE INDEX idx_events_event_type ON events(event_type);
CREATE INDEX idx_events_created_at ON events(created_at DESC);
CREATE INDEX idx_events_category ON events(event_category);

-- ============================================
-- STEP 5: Create SURVEY_RESPONSES table
-- ============================================
CREATE TABLE survey_responses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  visitor_id TEXT,
  session_id TEXT NOT NULL,
  vardas TEXT NOT NULL,
  el_pastas TEXT NOT NULL,
  telefonas TEXT NOT NULL,
  miestas TEXT,
  komentaras TEXT,
  type TEXT NOT NULL CHECK (type IN ('lauko', 'vidaus', 'kubila')),
  lauko_data JSONB,
  kubilas_data JSONB,
  vidaus_data JSONB,
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  landing_page TEXT,
  time_to_complete_seconds INTEGER,
  status TEXT DEFAULT 'submitted' CHECK (status IN ('submitted', 'contacted', 'converted', 'cancelled')),
  contacted_at TIMESTAMP WITH TIME ZONE,
  converted_at TIMESTAMP WITH TIME ZONE,
  notes TEXT
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

ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous visitor tracking" ON visitors
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anonymous visitor updates" ON visitors
  FOR UPDATE TO anon USING (true);
CREATE POLICY "Admins can view all visitors" ON visitors
  FOR SELECT TO authenticated USING (true);

ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous page view tracking" ON page_views
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins can view all page views" ON page_views
  FOR SELECT TO authenticated USING (true);

ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous event tracking" ON events
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins can view all events" ON events
  FOR SELECT TO authenticated USING (true);

ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous survey submissions" ON survey_responses
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins can view all survey responses" ON survey_responses
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can update survey responses" ON survey_responses
  FOR UPDATE TO authenticated USING (true);

-- ============================================
-- STEP 7: Create helpful views
-- ============================================

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

-- ============================================
-- ✅ DONE! Your database is now set up.
-- ============================================
