# iOS Xcode Configuration for Reminders

This document provides instructions for completing the iOS platform configuration for the reminder system. Some configuration steps require manual actions in Xcode.

## Completed Configurations

The following configurations have been automatically applied to the iOS project:

### 1. Info.plist Updates ✅
- Added `UIBackgroundModes` with `remote-notification` support
- Added `NSUserNotificationsUsageDescription` with permission explanation text

### 2. AppDelegate.swift Updates ✅
- Configured notification categories for reminders
- Implemented notification response handling
- Implemented foreground notification presentation
- Set up UNUserNotificationCenter delegate

## Manual Xcode Configuration Required

The following steps must be completed manually in Xcode:

### Step 1: Open the Xcode Project

1. Navigate to the `ios` folder in your project
2. Open `Runner.xcworkspace` (NOT `Runner.xcodeproj`) in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

### Step 2: Enable Background Modes Capability

1. In Xcode, select the **Runner** project in the Project Navigator (left sidebar)
2. Select the **Runner** target under TARGETS
3. Click on the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **Background Modes**
6. In the Background Modes section, check the following option:
   - ☑️ **Remote notifications**

### Step 3: Verify Configuration

After enabling Background Modes, verify that:

1. A new `Runner.entitlements` file is created in the `ios/Runner` folder
2. The entitlements file contains the background modes configuration
3. The Xcode project builds without errors

### Step 4: Test on Physical Device

Notifications and alarms must be tested on a physical iOS device (not simulator):

1. Connect your iPhone or iPad to your Mac
2. Select your device in Xcode's device selector
3. Build and run the app (⌘R)
4. Grant notification permissions when prompted
5. Create test reminders with near-future trigger times
6. Lock the device and verify notifications appear

## Troubleshooting

### Issue: Background Modes capability not appearing

**Solution:** Ensure you have a valid Apple Developer account configured in Xcode and that your project has proper code signing set up.

### Issue: Notifications not appearing on device

**Possible causes:**
1. Notification permissions not granted - Check Settings > Numu > Notifications
2. Do Not Disturb mode is enabled
3. Testing on simulator instead of physical device
4. App is in foreground (notifications should still appear with current configuration)

### Issue: Build errors after adding capability

**Solution:** Clean the build folder (⌘⇧K) and rebuild the project.

## Additional Notes

- The iOS notification system has a limit of 64 scheduled notifications
- The reminder system will reschedule notifications on app launch to work within this limit
- Full-screen alarms may require additional configuration depending on the alarm plugin used
- Background notification delivery is handled by iOS and may be delayed based on system conditions

## Next Steps

After completing the Xcode configuration:

1. Test notification delivery on a physical device
2. Verify notification tap navigation works correctly
3. Test background notification delivery (app closed)
4. Test foreground notification presentation
5. Proceed to task 16 (Android configuration)

## References

- [Apple Documentation: Background Modes](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes)
- [Apple Documentation: User Notifications](https://developer.apple.com/documentation/usernotifications)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
