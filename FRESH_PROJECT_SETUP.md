# Fresh Xcode Project Setup Guide

Since we're starting with a clean slate, here's the recommended approach to create a fresh Xcode project that will work properly:

## Option 1: Create New Project in Xcode (RECOMMENDED)

### Step 1: Create New Project
1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Click **Next**
5. Configure:
   - **Product Name:** `FaithCheckin`
   - **Team:** (Select your team)
   - **Organization Identifier:** `FGsolutions`
   - **Bundle Identifier:** `FGsolutions.FaithCheckin` (auto-generated)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (we'll use Supabase)
   - **Include Tests:** ✓ (checked)
6. Click **Next**
7. **Save Location:** `/Users/familygalvez/Desktop/AI Projects/FaithCheckin`
   - **IMPORTANT:** Uncheck "Create Git repository" (we already have one)
   - Make sure "Add to" is selected and shows "FaithCheckin"
8. Click **Create**

### Step 2: Replace Default Files
1. Delete the default `FaithCheckinApp.swift` if it exists
2. The existing `FaithCheckin/FaithCheckinApp.swift` should be automatically detected
3. Verify all source files are visible in the project navigator

### Step 3: Configure Project Settings
1. Select the **FaithCheckin** project (blue icon) in the navigator
2. Select the **FaithCheckin** target
3. Go to **General** tab:
   - Verify **Display Name:** `FaithCheckin`
   - Verify **Bundle Identifier:** `FGsolutions.FaithCheckin`
   - **Version:** `1.0`
   - **Build:** `1`
   - **Minimum Deployments:** iOS 17.0

4. Go to **Signing & Capabilities** tab:
   - Select your Team
   - Add the **Centered.entitlements** file:
     - Click **+ Capability** → **Signing & Capabilities**
     - Or manually: In **Build Settings**, search for "Code Signing Entitlements"
     - Set to: `FaithCheckin/Centered.entitlements`

5. Go to **Build Settings** tab:
   - Search for "Info.plist File"
   - Set to: `$(SRCROOT)/FaithCheckin/FaithCheckinApp.swift` (or leave auto-generated)

### Step 4: Add Swift Packages (ONE AT A TIME)

**IMPORTANT:** Add packages one at a time and wait for each to resolve before adding the next.

#### Package 1: Supabase
1. Select the **FaithCheckin** project (blue icon)
2. Select the **FaithCheckin** target
3. Go to **Package Dependencies** tab
4. Click **+** button
5. Enter URL: `https://github.com/supabase/supabase-swift`
6. Click **Add Package**
7. Wait for resolution (this may take 30-60 seconds)
8. Select version: **Up to Next Major Version** (default)
9. Select product: **Supabase** only
10. Click **Add Package**
11. Wait for it to finish before proceeding

#### Package 2: OpenAIKit
1. Still in **Package Dependencies** tab
2. Click **+** button
3. Enter URL: `https://github.com/dylanshine/openai-kit`
4. Click **Add Package**
5. Wait for resolution
6. Select version: **Up to Next Major Version** (default)
7. Select product: **OpenAIKit** only
8. Click **Add Package**
9. Wait for it to finish

#### Package 3: RevenueCat (if needed)
1. Repeat the same process
2. URL: `https://github.com/RevenueCat/purchases-ios`
3. Select product: **RevenueCat** only (NOT RevenueCatUI)

### Step 5: Verify Build
1. Select a simulator (e.g., iPhone 17)
2. Product → Build (⌘B)
3. If there are any errors, fix them one by one

## Option 2: Use Existing Project File (If Option 1 doesn't work)

If you prefer to use the project file I created, we'll need to fix it. The structure might need adjustment for your Xcode version.

## Troubleshooting

### Package Resolution Stuck
- **DO NOT** let it run indefinitely
- Force quit Xcode (⌘Q)
- Clear package caches:
  ```bash
  rm -rf ~/Library/Developer/Xcode/DerivedData/*
  rm -rf ~/Library/Caches/org.swift.swiftpm
  ```
- Restart Xcode
- Try adding packages again one at a time

### Missing Source Files
- Right-click on the **FaithCheckin** folder in Project Navigator
- Select **Add Files to "FaithCheckin"...**
- Navigate to `/Users/familygalvez/Desktop/AI Projects/FaithCheckin/FaithCheckin`
- Select all Swift files and folders
- Make sure "Create groups" is selected
- Click **Add**

### Build Errors
- Clean Build Folder: Product → Clean Build Folder (⇧⌘K)
- Close and reopen Xcode
- Delete DerivedData (see command above)
- Try building again

## What's Already Ready

✅ All source files are in place:
- `FaithCheckin/FaithCheckinApp.swift` (main app entry)
- `FaithCheckin/ContentView.swift`
- `FaithCheckin/Models/` (all model files)
- `FaithCheckin/Services/` (SupabaseService, OpenAIService)
- `FaithCheckin/ViewModels/` (JournalViewModel, AnalyzerViewModel)
- `FaithCheckin/Views/` (all view files)
- `FaithCheckin/Assets.xcassets/` (all assets)
- `FaithCheckin/Config.plist` (API keys - already in .gitignore)
- `FaithCheckin/Centered.entitlements`

✅ Configuration:
- Bundle ID: `FGsolutions.FaithCheckin`
- All code references updated to FaithCheckin
- Colors updated to maroon (#772C2C)
- Christian-focused prompts and content

## Next Steps After Project Setup

1. Verify the project opens in Xcode
2. Add packages one at a time (wait for each to resolve)
3. Build the project
4. Fix any import errors
5. Test the app in simulator
