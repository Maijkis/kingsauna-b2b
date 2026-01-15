# 🚀 Supabase Quick Setup Guide

## The Problem
The error "Could not find the table 'public.survey_responses'" means the database table hasn't been created yet.

## ✅ Solution: Create the Table

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Log in to your account
3. Select your project (the one with URL: `jwfyumswseoczupzixkm.supabase.co`)

### Step 2: Open SQL Editor
1. Click on **"SQL Editor"** in the left sidebar
2. Click **"New query"**

### Step 3: Run This SQL Code
Copy and paste the following SQL code into the editor and click **"Run"**:

```sql
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
  vidaus_data JSONB
);

-- Create indexes
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
```

### Step 4: Verify It Worked
After running the SQL, you should see:
- ✅ "Success. No rows returned"
- The table should now appear in the **Table Editor**

### Step 5: Test the Survey
Go back to your survey page and try submitting again. It should work now! 🎉

## 🔍 Troubleshooting

### If you get a "permission denied" error:
1. Go to **Authentication** → **Policies** in Supabase
2. Make sure the policy "Allow anonymous survey submissions" exists
3. If not, run the CREATE POLICY command again

### If the table still doesn't appear:
1. Refresh the Supabase dashboard
2. Go to **Table Editor** and check if `survey_responses` is listed
3. If not, check the SQL Editor for any error messages

## 📝 Optional: Add Tracking Columns (Advanced)
If you want to track more data (session IDs, UTM parameters, etc.), you can run the full schema from `supabase-analytics-schema.sql` file, but the basic setup above is enough to get the survey working.
