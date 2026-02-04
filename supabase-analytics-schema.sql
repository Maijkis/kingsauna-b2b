-- ============================================
-- Kingsauna Complete Analytics & Tracking
-- Run this in Supabase SQL Editor
-- ============================================

-- =============================================
-- 1. VISITOR TRACKING TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS page_visitors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Session Info
  session_id TEXT NOT NULL,
  visitor_id TEXT, -- Anonymous visitor ID (from cookie/localStorage)
  
  -- Page Info
  page_url TEXT NOT NULL,
  page_title TEXT,
  page_path TEXT,
  
  -- Referrer & Traffic Source
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  utm_term TEXT,
  
  -- Device & Browser Info
  user_agent TEXT,
  device_type TEXT, -- 'mobile', 'tablet', 'desktop'
  browser TEXT,
  os TEXT,
  screen_width INTEGER,
  screen_height INTEGER,
  
  -- Location (if available)
  ip_address TEXT,
  country TEXT,
  city TEXT,
  
  -- Time on page (updated on exit)
  time_on_page_seconds INTEGER DEFAULT 0,
  
  -- Engagement
  scroll_depth INTEGER DEFAULT 0, -- percentage
  interactions_count INTEGER DEFAULT 0
);

CREATE INDEX idx_visitors_session ON page_visitors(session_id);
CREATE INDEX idx_visitors_created ON page_visitors(created_at DESC);
CREATE INDEX idx_visitors_page_path ON page_visitors(page_path);
CREATE INDEX idx_visitors_utm_source ON page_visitors(utm_source);

-- =============================================
-- 2. USER EVENTS / ANALYTICS EVENTS
-- =============================================
CREATE TABLE IF NOT EXISTS user_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Session tracking
  session_id TEXT NOT NULL,
  visitor_id TEXT,
  
  -- Event details
  event_type TEXT NOT NULL, -- 'button_click', 'form_start', 'cta_click', 'modal_open', etc.
  event_category TEXT, -- 'navigation', 'engagement', 'conversion'
  event_label TEXT, -- Specific identifier
  event_value NUMERIC, -- Optional numeric value
  
  -- Context
  page_url TEXT NOT NULL,
  page_path TEXT,
  element_id TEXT, -- DOM element ID
  element_text TEXT, -- Button text, link text, etc.
  element_position TEXT, -- 'hero', 'footer', 'section-2', etc.
  
  -- Additional data
  metadata JSONB -- Flexible storage for event-specific data
);

CREATE INDEX idx_events_session ON user_events(session_id);
CREATE INDEX idx_events_type ON user_events(event_type);
CREATE INDEX idx_events_created ON user_events(created_at DESC);
CREATE INDEX idx_events_category ON user_events(event_category);

-- =============================================
-- 3. ENHANCED SURVEY RESPONSES TABLE
-- (Replaces/extends previous version)
-- =============================================
DROP TABLE IF EXISTS survey_responses CASCADE;

CREATE TABLE survey_responses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Tracking Info
  session_id TEXT,
  visitor_id TEXT,
  
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
  
  -- Source tracking
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  landing_page TEXT, -- Which page they started on
  
  -- Engagement metrics
  time_to_complete_seconds INTEGER, -- How long survey took
  
  -- Status
  status TEXT DEFAULT 'submitted' CHECK (status IN ('submitted', 'contacted', 'converted', 'cancelled')),
  
  -- Follow-up
  contacted_at TIMESTAMP WITH TIME ZONE,
  converted_at TIMESTAMP WITH TIME ZONE,
  notes TEXT
);

CREATE INDEX idx_survey_type ON survey_responses(type);
CREATE INDEX idx_survey_created ON survey_responses(created_at DESC);
CREATE INDEX idx_survey_email ON survey_responses(el_pastas);
CREATE INDEX idx_survey_status ON survey_responses(status);
CREATE INDEX idx_survey_session ON survey_responses(session_id);

-- =============================================
-- 4. CONVERSION FUNNEL TRACKING
-- =============================================
CREATE TABLE IF NOT EXISTS funnel_steps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  session_id TEXT NOT NULL,
  visitor_id TEXT,
  
  -- Funnel stage
  step_name TEXT NOT NULL, -- 'landing_view', 'cta_click', 'survey_start', 'survey_complete', etc.
  step_number INTEGER,
  
  -- Which funnel
  funnel_type TEXT, -- 'lauko', 'vidaus', 'kubila'
  
  -- Additional context
  page_url TEXT,
  metadata JSONB
);

CREATE INDEX idx_funnel_session ON funnel_steps(session_id);
CREATE INDEX idx_funnel_step ON funnel_steps(step_name);
CREATE INDEX idx_funnel_created ON funnel_steps(created_at DESC);

-- =============================================
-- 5. ROW LEVEL SECURITY POLICIES
-- =============================================

-- Page Visitors
ALTER TABLE page_visitors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous page tracking" ON page_visitors
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon updates" ON page_visitors
  FOR UPDATE TO anon USING (true);
CREATE POLICY "Admins view all visitors" ON page_visitors
  FOR SELECT TO authenticated USING (true);

-- User Events
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous event tracking" ON user_events
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins view all events" ON user_events
  FOR SELECT TO authenticated USING (true);

-- Survey Responses
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous survey submissions" ON survey_responses
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon updates to surveys" ON survey_responses
  FOR UPDATE TO anon USING (true);
CREATE POLICY "Admins view all surveys" ON survey_responses
  FOR SELECT TO authenticated USING (true);

-- Funnel Steps
ALTER TABLE funnel_steps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous funnel tracking" ON funnel_steps
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Admins view all funnel data" ON funnel_steps
  FOR SELECT TO authenticated USING (true);

-- =============================================
-- 6. ANALYTICS VIEWS FOR EASY REPORTING
-- =============================================

-- Daily visitor summary
CREATE OR REPLACE VIEW daily_visitor_stats AS
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT session_id) as unique_sessions,
  COUNT(DISTINCT visitor_id) as unique_visitors,
  COUNT(*) as total_page_views,
  AVG(time_on_page_seconds) as avg_time_on_page,
  AVG(scroll_depth) as avg_scroll_depth
FROM page_visitors
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Traffic sources
CREATE OR REPLACE VIEW traffic_sources AS
SELECT 
  COALESCE(utm_source, 'direct') as source,
  COALESCE(utm_medium, 'none') as medium,
  COUNT(DISTINCT session_id) as sessions,
  COUNT(*) as pageviews
FROM page_visitors
GROUP BY utm_source, utm_medium
ORDER BY sessions DESC;

-- Survey conversion funnel
CREATE OR REPLACE VIEW survey_funnel AS
SELECT 
  type,
  COUNT(*) as total_submissions,
  COUNT(CASE WHEN status = 'contacted' THEN 1 END) as contacted,
  COUNT(CASE WHEN status = 'converted' THEN 1 END) as converted,
  ROUND(100.0 * COUNT(CASE WHEN status = 'converted' THEN 1 END) / COUNT(*), 2) as conversion_rate
FROM survey_responses
GROUP BY type;

-- Popular events
CREATE OR REPLACE VIEW popular_events AS
SELECT 
  event_type,
  event_category,
  COUNT(*) as event_count,
  COUNT(DISTINCT session_id) as unique_sessions
FROM user_events
GROUP BY event_type, event_category
ORDER BY event_count DESC;

-- Survey completion times
CREATE OR REPLACE VIEW survey_timing_stats AS
SELECT 
  type,
  AVG(time_to_complete_seconds) as avg_completion_time,
  MIN(time_to_complete_seconds) as min_completion_time,
  MAX(time_to_complete_seconds) as max_completion_time,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time_to_complete_seconds) as median_completion_time
FROM survey_responses
WHERE time_to_complete_seconds IS NOT NULL
GROUP BY type;

-- =============================================
-- 7. USEFUL QUERIES FOR ANALYSIS
-- =============================================

-- Most recent visitors
-- SELECT * FROM page_visitors ORDER BY created_at DESC LIMIT 20;

-- Today's traffic
-- SELECT * FROM daily_visitor_stats WHERE date = CURRENT_DATE;

-- Conversion rate by source
-- SELECT 
--   pv.utm_source,
--   COUNT(DISTINCT pv.session_id) as sessions,
--   COUNT(DISTINCT sr.id) as conversions,
--   ROUND(100.0 * COUNT(DISTINCT sr.id) / COUNT(DISTINCT pv.session_id), 2) as conversion_rate
-- FROM page_visitors pv
-- LEFT JOIN survey_responses sr ON pv.session_id = sr.session_id
-- GROUP BY pv.utm_source
-- ORDER BY sessions DESC;

-- Popular CTAs
-- SELECT 
--   event_label,
--   element_text,
--   COUNT(*) as clicks
-- FROM user_events
-- WHERE event_type = 'cta_click'
-- GROUP BY event_label, element_text
-- ORDER BY clicks DESC;

-- =============================================
-- SUCCESS!
-- =============================================
-- Tables created:
-- ✅ page_visitors - Track every page view
-- ✅ user_events - Track button clicks, interactions
-- ✅ survey_responses - Enhanced with tracking
-- ✅ funnel_steps - Conversion funnel analysis
-- ✅ 5 analytics views for easy reporting

