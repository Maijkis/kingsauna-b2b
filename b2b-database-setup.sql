-- ============================================
-- KingSauna B2B Distributor Leads Table
-- ============================================
-- Run this SQL in your Supabase Dashboard > SQL Editor
-- This creates the table for storing distributor partnership applications
-- from the /b2b/apply/ survey form.
-- ============================================

CREATE TABLE IF NOT EXISTS distributor_leads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,

    -- Contact Information
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    company_name TEXT NOT NULL,
    job_title TEXT,
    website TEXT,

    -- Business Qualification
    business_type TEXT,
    business_type_other TEXT,
    currently_sells_saunas BOOLEAN,
    current_brands TEXT,
    target_country TEXT NOT NULL,
    target_region TEXT,
    estimated_annual_volume TEXT,
    has_warehouse BOOLEAN,
    has_showroom BOOLEAN,
    warehouse_size TEXT,
    how_heard_about_us TEXT,
    additional_message TEXT,

    -- Analytics & Tracking
    visitor_id TEXT,
    session_id TEXT,
    time_to_complete_seconds INTEGER,
    referrer TEXT,
    utm_source TEXT,
    utm_medium TEXT,
    utm_campaign TEXT,
    utm_content TEXT,
    landing_page TEXT,
    device_type TEXT
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_dist_leads_created ON distributor_leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dist_leads_country ON distributor_leads(target_country);
CREATE INDEX IF NOT EXISTS idx_dist_leads_email ON distributor_leads(email);

-- Row Level Security
ALTER TABLE distributor_leads ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users (website visitors) to insert new leads
CREATE POLICY "Allow anonymous distributor submissions"
    ON distributor_leads
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow authenticated users (admin) to view all leads
CREATE POLICY "Authenticated users can view distributor leads"
    ON distributor_leads
    FOR SELECT
    TO authenticated
    USING (true);
