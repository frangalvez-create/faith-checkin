# Build Checklist: Faith Check-in Project

## ✅ Completed Steps
1. ✅ Fresh Xcode project created
2. ✅ Source files added to project
3. ✅ Entitlements configured
4. ✅ **Supabase package added**
5. ✅ **OpenAIKit package added**

---

## 🏗️ Next: Build the Project

### Step 1: Select a Simulator
1. At the top of Xcode, next to the play/stop buttons
2. Click the device selector (should show something like "iPhone 17 Pro" or "Any iOS Device")
3. Select a simulator, e.g.:
   - **iPhone 17 Pro** (or latest available)
   - **iPhone 17** 
   - Any iOS 17+ simulator

### Step 2: Build the Project
1. Press **⌘B** (Command + B) to build
   - Or go to **Product → Build**
2. Watch the bottom status bar for progress
3. Check the Issue Navigator (left sidebar, warning/error icon) for any issues

### Step 3: Review Build Results

#### ✅ If Build Succeeds:
- You'll see "Build Succeeded" in the status bar
- Great! The project is ready to run
- Next: Try running the app (⌘R)

#### ⚠️ If Build Fails:
Common issues and fixes:

##### Issue 1: "No such module 'Supabase'"
- **Fix**: Verify Supabase is in Package Dependencies
  - Select project → Package Dependencies tab
  - Make sure "Supabase" is listed
  - If missing, try File → Packages → Resolve Package Versions

##### Issue 2: "No such module 'OpenAIKit'"
- **Fix**: Same as above, but for OpenAIKit

##### Issue 3: "File not found" or "Cannot find type"
- **Fix**: Make sure all source files are added to target
  - Check Project Navigator
  - Verify Models/, Services/, ViewModels/, Views/ folders are present
  - If missing, right-click → Add Files to add them

##### Issue 4: "Config.plist not found" or API key errors
- **Fix**: Verify Config.plist exists in FaithCheckin/ folder
- The file should contain your API keys (already set up)

##### Issue 5: Missing imports or type errors
- **Fix**: Share the specific error message and I'll help fix it

---

## 📱 After Successful Build: Run the App

1. Select a simulator (if not already selected)
2. Press **⌘R** (or Product → Run)
3. The app should launch in the simulator
4. Test basic functionality:
   - App launches
   - UI appears
   - No crashes on startup

---

## 🐛 Troubleshooting

### If Package Resolution Issues Return
1. Force quit Xcode (⌘Q)
2. Clear caches:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
3. Restart Xcode
4. Try building again

### If Build Takes Too Long
- First build always takes longer (compiling dependencies)
- Subsequent builds will be faster
- If stuck >5 minutes, force quit and clear DerivedData

---

## 📋 Files to Verify Are Present

Make sure these exist in Project Navigator:

### Source Files:
- ✅ `FaithCheckinApp.swift` (main app entry)
- ✅ `ContentView.swift`
- ✅ `Models/` folder (7 files)
- ✅ `Services/` folder (SupabaseService.swift, OpenAIService.swift)
- ✅ `ViewModels/` folder (JournalViewModel.swift, AnalyzerViewModel.swift)
- ✅ `Views/` folder (6 view files)

### Resources:
- ✅ `Assets.xcassets/` (app icons, colors, images)
- ✅ `Config.plist` (API keys - should NOT be committed to git)
- ✅ `Centered.entitlements`

### Tests:
- ✅ `FaithCheckinTests/`
- ✅ `FaithCheckinUITests/`

---

## 🎯 What to Do Now

**Try building the project (⌘B) and let me know:**
- ✅ Build succeeded → Great! Try running it
- ❌ Build failed → Share the error messages and I'll help fix them
