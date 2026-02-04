# ✅ Integration Verification Checklist

## GitHub Status
- ✅ All changes committed and pushed to `main` branch
- ✅ Commit hash: `a7e5c5e`
- ✅ Files synced: survey.html, index.html, SQL scripts

## Supabase Configuration Check

### 1. Connection Details
- **URL**: `https://jwfyumswseoczupzixkm.supabase.co` ✅
- **Anon Key**: Configured in survey.html ✅
- **Client Initialization**: ES Module + UMD fallback ✅

### 2. Database Schema Verification

**Required Columns in `survey_responses` table:**
- ✅ `id` (UUID, PRIMARY KEY)
- ✅ `created_at` (TIMESTAMP)
- ✅ `vardas` (TEXT, NOT NULL)
- ✅ `el_pastas` (TEXT, NOT NULL)
- ✅ `telefonas` (TEXT, NOT NULL)
- ✅ `miestas` (TEXT, nullable)
- ✅ `komentaras` (TEXT, nullable)
- ✅ `type` (TEXT, CHECK constraint: 'lauko', 'vidaus', 'kubila')
- ✅ `lauko_data` (JSONB, nullable)
- ✅ `kubilas_data` (JSONB, nullable)
- ✅ `vidaus_data` (JSONB, nullable)
- ✅ `visitor_id` (TEXT, nullable) - **Analytics**
- ✅ `session_id` (TEXT, nullable) - **Analytics**
- ✅ `time_to_complete_seconds` (INTEGER, nullable) - **Analytics**
- ✅ `referrer` (TEXT, nullable) - **Analytics**
- ✅ `utm_source` (TEXT, nullable) - **Analytics**
- ✅ `utm_medium` (TEXT, nullable) - **Analytics**
- ✅ `utm_campaign` (TEXT, nullable) - **Analytics**
- ✅ `landing_page` (TEXT, nullable) - **Analytics**

### 3. RLS Policies Required
- ✅ Policy: "Allow anonymous survey submissions" (INSERT for anon)
- ✅ Policy: "Authenticated users can view responses" (SELECT for authenticated)

### 4. Indexes
- ✅ `idx_survey_type` on `type`
- ✅ `idx_survey_created_at` on `created_at DESC`
- ✅ `idx_survey_email` on `el_pastas`

## Code Verification

### Survey Form Submission Flow
1. ✅ Form waits for Supabase client (`waitForSupabase()`)
2. ✅ Validates phone number format (+370XXXXXXXX)
3. ✅ Validates city from datalist
4. ✅ Builds payload with all required fields
5. ✅ Attempts insert with full payload
6. ✅ Falls back to minimal payload if column errors
7. ✅ Handles errors gracefully with user-friendly messages
8. ✅ Marks visitor as converted (non-blocking)
9. ✅ Tracks analytics events (non-blocking)

### Error Handling
- ✅ Connection timeout (5 seconds)
- ✅ Missing table error
- ✅ Missing column error (with fallback)
- ✅ RLS permission error
- ✅ Network error
- ✅ Generic database errors

### Payload Structure Match
**Full Payload:**
```javascript
{
  visitor_id: string | null,
  session_id: string,
  vardas: string,
  el_pastas: string,
  telefonas: string,
  miestas: string | null,
  type: 'lauko' | 'vidaus' | 'kubila',
  time_to_complete_seconds: number,
  referrer: string | null,
  utm_source: string | null,
  utm_medium: string | null,
  utm_campaign: string | null,
  landing_page: string,
  lauko_data: object | null,  // if type === 'lauko'
  kubilas_data: object | null, // if type === 'kubila'
  vidaus_data: object | null  // if type === 'vidaus'
}
```

**Minimal Payload (Fallback):**
```javascript
{
  vardas: string,
  el_pastas: string,
  telefonas: string,
  type: 'lauko' | 'vidaus' | 'kubila',
  miestas: string | null,  // if provided
  lauko_data: object | null,  // if type === 'lauko'
  kubilas_data: object | null, // if type === 'kubila'
  vidaus_data: object | null  // if type === 'vidaus'
}
```

## Testing Steps

### Step 1: Run Database Migration
1. Go to: https://app.supabase.com/project/jwfyumswseoczupzixkm
2. Open **SQL Editor** → **New query**
3. Copy and paste `ONE_STEP_FIX.sql`
4. Click **Run**
5. Verify output shows "✅ SETUP COMPLETE!" and lists all columns

### Step 2: Test Survey Submission
1. Open `survey.html` in browser
2. Open browser console (F12)
3. Fill out a complete survey (any type)
4. Submit the form
5. Check console for:
   - ✅ "✅ Supabase client initialized"
   - ✅ "📤 Submitting survey to Supabase..."
   - ✅ "✅ Survey saved successfully to Supabase"
6. Check Supabase **Table Editor** → `survey_responses`
7. Verify new row appears with all data

### Step 3: Verify Data Structure
In Supabase Table Editor, check that:
- ✅ All required fields are populated
- ✅ `type` is one of: 'lauko', 'vidaus', 'kubila'
- ✅ Type-specific data (lauko_data/kubilas_data/vidaus_data) is valid JSON
- ✅ Analytics fields are populated (if available)
- ✅ `created_at` timestamp is set

### Step 4: Test Error Scenarios
1. **Network Error**: Disconnect internet, try submitting → Should show friendly error
2. **Invalid Phone**: Enter wrong format → Should show validation error
3. **Invalid City**: Enter city not in list → Should show validation error

## Common Issues & Solutions

### Issue: "Table not found"
**Solution**: Run `ONE_STEP_FIX.sql` in Supabase SQL Editor

### Issue: "Column does not exist"
**Solution**: Run `ADD_MISSING_COLUMNS.sql` in Supabase SQL Editor

### Issue: "Permission denied"
**Solution**: Verify RLS policies are created (see `ONE_STEP_FIX.sql` Step 5)

### Issue: "Supabase client not initialized"
**Solution**: 
- Check browser console for errors
- Verify Supabase URL and key are correct
- Check network tab for failed requests

### Issue: Survey submits but no data in database
**Solution**:
- Check browser console for errors
- Verify RLS policies allow INSERT for anon role
- Check Supabase logs in dashboard

## Verification Queries

Run these in Supabase SQL Editor to verify setup:

```sql
-- Check table exists
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'survey_responses';

-- Check all columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'survey_responses'
ORDER BY ordinal_position;

-- Check RLS policies
SELECT policyname, cmd, roles
FROM pg_policies 
WHERE tablename = 'survey_responses';

-- Check recent submissions
SELECT id, vardas, el_pastas, type, created_at
FROM survey_responses
ORDER BY created_at DESC
LIMIT 10;
```

## Status: ✅ READY FOR TESTING

All code is verified and ready. Run `ONE_STEP_FIX.sql` in Supabase, then test the survey submission.
