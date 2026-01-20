# How to Configure Entitlements in Xcode

## Good News! ✅
The entitlements file is **already configured** in your project file. However, if you want to verify or change it, here are several ways:

## Method 1: Signing & Capabilities Tab (EASIEST)

1. In Xcode, select the **FaithCheckin** project (blue icon) in the Project Navigator
2. Select the **FaithCheckin** target (under "TARGETS")
3. Click on the **"Signing & Capabilities"** tab (at the top)
4. Look at the top of this tab - you should see a section for **Entitlements**
5. If you see **"+ Capability"** button, you can add capabilities here
6. The entitlements file path should be visible here, or you can click **"..."** to select it

## Method 2: Build Settings (Filtered Search)

1. In Xcode, select the **FaithCheckin** project (blue icon)
2. Select the **FaithCheckin** target
3. Click on the **"Build Settings"** tab
4. **IMPORTANT:** At the top, make sure the filter dropdown shows **"All"** (not "Basic" or "Customized")
5. In the search bar at the top right, type: `entitlements` (all lowercase)
6. Look for **"Code Signing Entitlements"** - it should show up
7. The value should be: `FaithCheckin/Centered.entitlements`

## Method 3: Verify It's Already Set (Quick Check)

Since the entitlements are already in the project file, you can skip this step if:
- The project builds without errors
- You can proceed to adding packages (Step 3)

## Method 4: Manual File Addition

If you want to explicitly add the entitlements file:

1. In Project Navigator, right-click on the **FaithCheckin** folder
2. Select **Add Files to "FaithCheckin"...**
3. Navigate to: `FaithCheckin/Centered.entitlements`
4. Make sure **"Add to targets: FaithCheckin"** is checked
5. Click **Add**

## Current Status

Based on the project file, your entitlements are set to:
```
FaithCheckin/Centered.entitlements
```

This is correct! ✅

## Next Steps

If you can't find it in the UI but the file exists, you can **skip Step 2** and proceed to:
- **Step 3: Add Swift Packages**

The entitlements will work correctly since they're already configured in the project file.

## Troubleshooting

**If you get a build error about entitlements:**
1. Make sure `Centered.entitlements` file exists in the `FaithCheckin/` folder
2. In Build Settings, search for "entitlements" and verify the path
3. If the path is wrong, double-click the value and enter: `FaithCheckin/Centered.entitlements`
