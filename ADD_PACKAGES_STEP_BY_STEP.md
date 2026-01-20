# Step-by-Step: Adding Swift Packages

## ⚠️ CRITICAL: Add Packages ONE AT A TIME

**Wait for each package to fully resolve before adding the next!**

---

## Package 1: Supabase

### Steps:
1. In Xcode, select the **FaithCheckin** project (blue icon) in the Project Navigator (left side)
2. In the main editor area, you should see project settings
3. Make sure the **FaithCheckin** target is selected (under "TARGETS")
4. Click on the **"Package Dependencies"** tab (at the top, next to "Info", "Build Settings", etc.)
5. Click the **"+"** button (bottom left of the Package Dependencies section)
6. In the search/URL field, enter: 
   ```
   https://github.com/supabase/supabase-swift
   ```
7. Click **"Add Package"** button
8. **WAIT** - Xcode will resolve the package (this may take 30-60 seconds)
   - You'll see a progress indicator
   - Watch the bottom of Xcode for status messages
   - **DO NOT** click anything while it's resolving
9. Once resolved, you'll see a product selection screen:
   - Select **"Supabase"** ✓ (check the box)
   - **DO NOT** select any other products (like SupabaseAuth, etc.)
10. Make sure **"Add to Target"** shows **"FaithCheckin"** ✓
11. Click **"Add Package"**
12. **WAIT** for it to finish (another 10-30 seconds)
13. You should see "Supabase" appear in the Package Dependencies list

### ✅ Verification:
- Look in Project Navigator - you should see "Package Dependencies" section
- "Supabase" should be listed there
- No error messages

### ⏸️ STOP HERE - Wait 30 seconds before proceeding

---

## Package 2: OpenAIKit

### Steps:
1. Still in the **"Package Dependencies"** tab
2. Click the **"+"** button again
3. In the search/URL field, enter:
   ```
   https://github.com/dylanshine/openai-kit
   ```
4. Click **"Add Package"**
5. **WAIT** for resolution (30-60 seconds)
   - **DO NOT** interrupt or click anything
6. Once resolved, select **"OpenAIKit"** ✓ only
7. Verify **"Add to Target"** shows **"FaithCheckin"** ✓
8. Click **"Add Package"**
9. **WAIT** for completion
10. You should see "OpenAIKit" in the Package Dependencies list

### ✅ Verification:
- "OpenAIKit" appears in Package Dependencies
- No errors in the list

### ⏸️ STOP HERE - You're done with required packages!

---

## Optional Package 3: RevenueCat (Only if needed)

If your code uses RevenueCat:

1. URL: `https://github.com/RevenueCat/purchases-ios`
2. Select **"RevenueCat"** ✓ ONLY
3. **DO NOT** select "RevenueCatUI" ❌

---

## 🚨 If Package Resolution Gets Stuck

If you see it "resolving" for more than 2 minutes:

1. **STOP IMMEDIATELY** - Press **⌘Q** to force quit Xcode
2. Don't wait for it to finish - this is the infinite loop issue
3. Clear caches:
   - Open Terminal
   - Run these commands:
     ```bash
     rm -rf ~/Library/Developer/Xcode/DerivedData/*
     rm -rf ~/Library/Caches/org.swift.swiftpm
     ```
4. Restart Xcode
5. Try again, but be patient - wait for each step

---

## After Adding Packages

1. Try building the project: **⌘B**
2. If you see import errors, verify packages are in the list
3. If you see other errors, share them and we'll fix them

---

## What to Do Next

After both packages are successfully added:
- ✅ Verify they're in Package Dependencies
- ✅ Try building: **⌘B**
- ✅ Share any build errors if they occur
