# Xcode Setup Guide for Faith Check-in

## Quick Start

1. **Open the Project**
   - Navigate to: `/Users/familygalvez/Desktop/AI Projects/FaithCheckin/`
   - Double-click `FaithCheckin.xcodeproj` to open in Xcode
   - OR use: `open FaithCheckin.xcodeproj` in Terminal

## Project Configuration

### Current Settings
- **Project Name:** FaithCheckin
- **Bundle Identifier:** `FGsolutions.FaithCheckin`
- **Version:** 1.0 (CURRENT_PROJECT_VERSION: 1)
- **Marketing Version:** 2.0
- **Development Team:** 5997H9ZW4N (configured)
- **Code Signing:** Automatic

### Swift Package Dependencies
The project uses Swift Package Manager with these dependencies:
1. **openai-kit** - https://github.com/dylanshine/openai-kit
2. **supabase-swift** - https://github.com/supabase/supabase-swift
3. **purchases-ios-spm** (RevenueCat) - https://github.com/RevenueCat/purchases-ios-spm.git

These should resolve automatically when you open the project.

## Setup Steps

### 1. Open Project in Xcode
```bash
cd "/Users/familygalvez/Desktop/AI Projects/FaithCheckin"
open FaithCheckin.xcodeproj
```

### 2. Resolve Package Dependencies
- Xcode should automatically resolve packages when you open the project
- If not, go to: **File → Packages → Resolve Package Versions**
- Wait for packages to download (may take a few minutes)

### 3. Verify Config.plist
- Ensure `Config.plist` is in the `FaithCheckin/` directory
- Contains:
  - `OpenAIAPIKey`
  - `SupabaseURL`: `https://huhfwtgblapyorltmvyw.supabase.co`
  - `SupabaseAPIKey`: `sb_publishable_XTCccaBrDtO2fi6V221X0Q_-krCBA33`
- **Important:** This file is in `.gitignore` and won't be committed

### 4. Select Build Target
- **Scheme:** FaithCheckin
- **Destination:** Choose a simulator or connected device
  - Recommended: iPhone 15 Pro (or latest iOS simulator)
  - iOS Deployment Target: Check project settings (likely iOS 15.0+)

### 5. Build the Project
- Press `Cmd + B` to build
- Or: **Product → Build**
- First build may take several minutes as packages compile

### 6. Run the App
- Press `Cmd + R` to run
- Or: **Product → Run**
- The app should launch in the selected simulator/device

## Common Issues & Solutions

### Issue: Package Dependencies Not Resolving
**Solution:**
1. Go to **File → Packages → Reset Package Caches**
2. Then **File → Packages → Resolve Package Versions**
3. Clean build folder: **Product → Clean Build Folder** (`Cmd + Shift + K`)

### Issue: Config.plist Not Found Error
**Solution:**
1. Verify `Config.plist` exists in `FaithCheckin/` directory
2. Check it's included in the target:
   - Select `Config.plist` in Project Navigator
   - Check "Target Membership" in File Inspector
   - Ensure "FaithCheckin" target is checked

### Issue: Code Signing Errors
**Solution:**
1. Go to **Project Settings → Signing & Capabilities**
2. Ensure "Automatically manage signing" is checked
3. Select your Development Team
4. Verify Bundle Identifier: `FGsolutions.FaithCheckin`

### Issue: Build Errors Related to Supabase/OpenAI
**Solution:**
1. Ensure you have internet connection (packages need to download)
2. Check package versions are compatible
3. Try: **File → Packages → Update to Latest Package Versions**

### Issue: Entitlements File Not Found
**Solution:**
- The entitlements file path has been fixed to: `FaithCheckin/Centered.entitlements`
- If you see errors, verify the file exists at this path

## Project Structure

```
FaithCheckin/
├── FaithCheckinApp.swift          # Main app entry point
├── ContentView.swift               # Main UI view
├── Config.plist                    # API keys (not in git)
├── Centered.entitlements           # App entitlements
├── Models/                         # Data models
├── Services/                        # Supabase & OpenAI services
├── ViewModels/                     # View models
├── Views/                          # SwiftUI views
└── Assets.xcassets/                # Images and assets
```

## Testing Checklist

Once the app builds successfully:

1. **Authentication Flow**
   - Email OTP sign-up
   - OTP verification
   - Session persistence

2. **Journal Entries**
   - Guided questions display
   - Open question entry
   - Follow-up questions
   - AI insights generation

3. **UI Elements**
   - All tabs (Journal, Favorites, Analyzer, Profile)
   - Info popups (Q, Q3, Q4)
   - Settings view
   - Color theme (maroon #772C2C)

4. **Database**
   - Guided questions loading (64 questions)
   - Journal entries saving
   - User profile updates

## Next Steps After Building

1. Test authentication flow
2. Verify guided questions are loading from database
3. Test journal entry creation
4. Verify AI responses are working
5. Check all UI elements display correctly
6. Test on physical device if needed

## Notes

- The app uses Supabase for backend (database, auth)
- OpenAI API for AI responses (requires API key in Config.plist)
- All sensitive credentials are in Config.plist (excluded from git)
- Asset names remain as "Centered" but images are updated to Faith Check-in theme
