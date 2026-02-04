# 🧪 Test Survey Integration - Step by Step

## Pre-Test: Database Setup

### ✅ Step 1: Run Database Migration
1. Go to: https://app.supabase.com/project/jwfyumswseoczupzixkm
2. Click **SQL Editor** (left sidebar)
3. Click **"New query"**
4. Open `ONE_STEP_FIX.sql` from your project
5. **Copy ALL the SQL code**
6. **Paste** into Supabase SQL Editor
7. Click **"Run"** (or Cmd/Ctrl + Enter)

**Expected Result:**
- ✅ Success message: "✅ SETUP COMPLETE!"
- ✅ List of all 19 columns
- ✅ RLS policies count: 2

---

## Test 1: Survey Submission (Lauko Pirtis)

### Steps:
1. Open `survey.html` in your browser
2. Open **Browser Console** (F12 → Console tab)
3. Select **"Lauko pirtį"** option
4. Fill out the survey:
   - Choose a forma (e.g., "Bačka")
   - Enter measurements or select "Norėčiau Pasikonsultuoti"
   - Continue through all steps
5. On contact form, enter:
   - **Vardas**: Test User
   - **El. paštas**: test@example.com
   - **Telefonas**: +37060012345
   - **Miestas**: Vilnius
6. Click **"Pateikti"** button

### Expected Console Output:
```
✅ Supabase client initialized (ES Module)
✅ Supabase connection verified - table exists!
📤 Submitting survey to Supabase... {payload object}
✅ Survey saved successfully to Supabase
✅ Visitor marked as converted
```

### Verify in Supabase:
1. Go to Supabase Dashboard → **Table Editor**
2. Click `survey_responses` table
3. Find your test submission
4. Verify:
   - ✅ `vardas` = "Test User"
   - ✅ `el_pastas` = "test@example.com"
   - ✅ `telefonas` = "+37060012345"
   - ✅ `miestas` = "Vilnius"
   - ✅ `type` = "lauko"
   - ✅ `lauko_data` contains JSON with survey answers
   - ✅ `visitor_id` and `session_id` are populated
   - ✅ `time_to_complete_seconds` is a number
   - ✅ `created_at` timestamp is set

---

## Test 2: Survey Submission (Vidaus Pirtis)

### Steps:
1. Refresh `survey.html`
2. Select **"Vidaus pirtį"** option
3. Fill out the survey:
   - Choose pirties tipas
   - Choose vieta
   - Enter measurements or select "Norėčiau Pasikonsultuoti"
   - Choose krosnelė
4. On contact form, enter different test data
5. Submit

### Verify:
- ✅ New row appears in `survey_responses`
- ✅ `type` = "vidaus"
- ✅ `vidaus_data` contains JSON

---

## Test 3: Survey Submission (Kubilas)

### Steps:
1. Refresh `survey.html`
2. Select **"Kubilą"** option
3. Fill out the survey
4. Submit with test data

### Verify:
- ✅ New row appears
- ✅ `type` = "kubila"
- ✅ `kubilas_data` contains JSON

---

## Test 4: Error Handling

### Test 4a: Invalid Phone Number
1. Fill out survey
2. Enter phone: `123456` (invalid format)
3. Try to submit

**Expected:** 
- ❌ Error message appears below phone field
- ❌ Form does NOT submit
- ✅ Button re-enables

### Test 4b: Invalid City
1. Fill out survey
2. Enter city: `InvalidCity` (not in list)
3. Try to submit

**Expected:**
- ❌ Error message appears below city field
- ❌ Form does NOT submit

### Test 4c: Network Error (Optional)
1. Disconnect internet
2. Fill out and submit survey

**Expected:**
- ❌ User-friendly error dialog appears
- ✅ Error message: "Tinklo klaida. Patikrinkite interneto ryšį..."

---

## Test 5: Analytics Tracking

### Verify Analytics Fields:
Check that submitted surveys include:
- ✅ `visitor_id` (if analytics initialized)
- ✅ `session_id`
- ✅ `time_to_complete_seconds` (positive number)
- ✅ `referrer` (if available)
- ✅ `landing_page` (URL)

---

## Troubleshooting

### ❌ Error: "Table not found"
**Fix:** Run `ONE_STEP_FIX.sql` in Supabase SQL Editor

### ❌ Error: "Column does not exist"
**Fix:** Run `ADD_MISSING_COLUMNS.sql` in Supabase SQL Editor

### ❌ Error: "Permission denied" or "RLS policy violation"
**Fix:** Verify RLS policies exist (run Step 5 of `ONE_STEP_FIX.sql`)

### ❌ Error: "Supabase client not initialized"
**Check:**
- Browser console for JavaScript errors
- Network tab for failed requests to Supabase
- Supabase URL and key are correct

### ❌ Survey submits but no data appears
**Check:**
- Browser console for errors
- Supabase Table Editor (refresh page)
- Supabase Logs (Dashboard → Logs)
- RLS policies allow INSERT for anon role

---

## Success Criteria ✅

All tests pass if:
- ✅ All 3 survey types submit successfully
- ✅ Data appears in Supabase `survey_responses` table
- ✅ All required fields are populated
- ✅ Type-specific JSON data is saved correctly
- ✅ Analytics fields are populated
- ✅ Error handling works for invalid inputs
- ✅ No JavaScript errors in console
- ✅ User-friendly error messages appear

---

## Quick Verification Query

Run this in Supabase SQL Editor to see all submissions:

```sql
SELECT 
    id,
    vardas,
    el_pastas,
    type,
    created_at,
    time_to_complete_seconds,
    CASE 
        WHEN type = 'lauko' THEN lauko_data
        WHEN type = 'vidaus' THEN vidaus_data
        WHEN type = 'kubila' THEN kubilas_data
    END as survey_data
FROM survey_responses
ORDER BY created_at DESC
LIMIT 10;
```

---

**Status:** Ready to test! 🚀
