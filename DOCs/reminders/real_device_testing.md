# Real Device Testing Guide for Reminder System

## Overview

This guide provides comprehensive instructions for testing the Reminder System on physical iOS and Android devices. Real device testing is essential for validating notification delivery, alarm functionality, and background behavior that cannot be fully tested in simulators/emulators.

## Prerequisites

### Required Tools

#### iOS Testing
- **macOS** with Xcode 14.0 or later
- **Physical iPhone** running iOS 14.0 or later
- **Apple Developer Account** (free or paid)
- **USB cable** for device connection
- **CocoaPods** installed (`sudo gem install cocoapods`)

#### Android Testing
- **Android Studio** Arctic Fox or later
- **Physical Android device** running Android 8.0 (API 26) or later
- **USB cable** for device connection
- **USB debugging enabled** on device
- **Flutter SDK** properly configured

### Device Setup

#### iOS Device Setup
1. Connect iPhone to Mac via USB
2. Trust the computer on iPhone when prompted
3. In Xcode, add your Apple ID (Xcode → Preferences → Accounts)
4. Enable Developer Mode on iPhone (Settings → Privacy & Security → Developer Mode)

#### Android Device Setup
1. Enable Developer Options:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Go to Settings → Developer Options
   - Enable "USB Debugging"
3. Connect device via USB
4. Accept USB debugging authorization on device

## iOS Testing Instructions

### Step 1: Build and Deploy

1. **Open Project in Xcode:**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Select Your Device:**
   - In Xcode, select your connected iPhone from the device dropdown (top toolbar)

3. **Configure Signing:**
   - Select "Runner" project in navigator
   - Select "Runner" target
   - Go to "Signing & Capabilities" tab
   - Select your team from dropdown
   - Xcode will automatically create a provisioning profile

4. **Verify Background Modes:**
   - In "Signing & Capabilities" tab
   - Ensure "Background Modes" capability is added
   - Verify "Remote notifications" is checked

5. **Build and Run:**
   ```bash
   # From project root
   flutter run --release
   ```
   Or click the "Run" button in Xcode

6. **Trust Developer Certificate:**
   - On iPhone: Settings → General → VPN & Device Management
   - Tap your developer certificate
   - Tap "Trust [Your Name]"

### Step 2: Grant Permissions

1. Launch the app on your iPhone
2. Navigate to Reminders screen
3. When prompted, tap "Allow" for notification permissions
4. Verify permissions in Settings → Numu → Notifications

### Step 3: Test Scenarios

#### Test 1: Basic Notification Delivery

**Objective:** Verify standard notifications work

**Steps:**
1. Create a new reminder:
   - Title: "Test Notification"
   - Type: Notification
   - Schedule: One-time, 2 minutes from now
2. Save the reminder
3. Lock your iPhone
4. Wait for notification to appear
5. Verify notification shows correct title
6. Tap notification
7. Verify app opens to reminders screen

**Expected Result:** Notification appears on lock screen and notification center, tapping opens app

#### Test 2: Full-Screen Alarm

**Objective:** Verify full-screen alarms work

**Steps:**
1. Create a new reminder:
   - Title: "Test Alarm"
   - Type: Full-Screen Alarm
   - Schedule: One-time, 2 minutes from now
2. Save the reminder
3. Lock your iPhone
4. Wait for alarm to trigger
5. Verify full-screen alarm appears
6. Tap "Dismiss" button
7. Verify alarm is dismissed

**Expected Result:** Full-screen alarm appears with sound, requires explicit dismissal

#### Test 3: Background Delivery (App Closed)

**Objective:** Verify notifications work when app is completely closed

**Steps:**
1. Create a reminder scheduled for 3 minutes from now
2. Save the reminder
3. Close the app completely (swipe up from app switcher)
4. Lock your iPhone
5. Wait for notification
6. Verify notification appears

**Expected Result:** Notification appears even with app closed

#### Test 4: Background Delivery (App in Background)

**Objective:** Verify notifications work when app is backgrounded

**Steps:**
1. Create a reminder scheduled for 2 minutes from now
2. Save the reminder
3. Press home button (app goes to background)
4. Wait for notification
5. Verify notification appears

**Expected Result:** Notification appears with app in background

#### Test 5: Notification Tap Navigation

**Objective:** Verify tapping notification navigates correctly

**Steps:**
1. Create a habit-linked reminder for 2 minutes from now
2. Save and close app
3. Wait for notification
4. Tap notification
5. Verify app opens to habit detail screen

**Expected Result:** App opens to correct screen based on linked entity

#### Test 6: Repeating Reminders

**Objective:** Verify daily reminders reschedule correctly

**Steps:**
1. Create a daily reminder:
   - Title: "Daily Test"
   - Schedule: Daily at current time + 2 minutes
2. Save the reminder
3. Wait for first notification
4. Check reminder list
5. Verify next trigger time is set for tomorrow

**Expected Result:** Reminder triggers and automatically reschedules for next day

#### Test 7: Multiple Reminders

**Objective:** Verify multiple reminders work simultaneously

**Steps:**
1. Create 5 reminders with 1-minute intervals
2. Save all reminders
3. Lock device
4. Wait and verify all 5 notifications appear

**Expected Result:** All notifications appear at correct times

#### Test 8: Device Restart Persistence

**Objective:** Verify reminders persist after device restart

**Steps:**
1. Create a reminder scheduled for 10 minutes from now
2. Note the scheduled time
3. Restart your iPhone
4. Open app after restart
5. Verify reminder still exists with correct schedule
6. Wait for notification

**Expected Result:** Reminder persists and triggers after restart

#### Test 9: Time Zone Change

**Objective:** Verify reminders handle time zone changes

**Steps:**
1. Create a reminder for specific time tomorrow
2. Change device time zone (Settings → General → Date & Time)
3. Open app
4. Verify reminder time adjusted correctly

**Expected Result:** Reminder time updates based on new time zone

#### Test 10: iOS Notification Limit

**Objective:** Verify behavior with iOS 64 notification limit

**Steps:**
1. Create 70 reminders scheduled over next 7 days
2. Verify app handles gracefully
3. Check that reminders reschedule on app launch

**Expected Result:** App schedules up to 64, reschedules others on launch

### Step 4: Troubleshooting iOS Issues

#### Notifications Not Appearing

**Possible Causes:**
- Permissions not granted
- Do Not Disturb enabled
- Notification settings disabled for app

**Solutions:**
1. Check Settings → Notifications → Numu
2. Ensure "Allow Notifications" is ON
3. Check Focus modes (Do Not Disturb)
4. Verify notification style is set to "Banners" or "Alerts"

#### Full-Screen Alarms Not Working

**Possible Causes:**
- Missing USE_FULL_SCREEN_INTENT permission
- iOS restrictions on full-screen content

**Solutions:**
1. Verify Info.plist has correct background modes
2. Check that app has notification permissions
3. Ensure device is not in Low Power Mode

#### App Crashes on Launch

**Possible Causes:**
- Code signing issues
- Missing dependencies
- Database migration errors

**Solutions:**
1. Clean build: `flutter clean && flutter pub get`
2. Rebuild: `flutter run --release`
3. Check Xcode console for error messages
4. Verify all pods installed: `cd ios && pod install`

#### Notifications Not Persisting After Restart

**Possible Causes:**
- Background modes not configured
- Notification scheduling not called on app launch

**Solutions:**
1. Verify Background Modes capability in Xcode
2. Check that `rescheduleAllReminders()` is called in `main.dart`
3. Review AppDelegate.swift configuration

## Android Testing Instructions

### Step 1: Build and Install

1. **Connect Android Device:**
   ```bash
   # Verify device is connected
   flutter devices
   ```

2. **Build APK:**
   ```bash
   # Build release APK
   flutter build apk --release
   ```

3. **Install on Device:**
   ```bash
   # Install APK
   flutter install
   ```
   
   Or run directly:
   ```bash
   flutter run --release
   ```

### Step 2: Grant Permissions

1. Launch the app on your Android device
2. Navigate to Reminders screen
3. When prompted, tap "Allow" for notification permissions (Android 13+)
4. For full-screen alarms, grant "Display over other apps" permission if prompted
5. For exact alarms, grant "Alarms & reminders" permission (Android 12+)

### Step 3: Test Scenarios

#### Test 1: Basic Notification Delivery

**Objective:** Verify standard notifications work

**Steps:**
1. Create a new reminder:
   - Title: "Test Notification"
   - Type: Notification
   - Schedule: One-time, 2 minutes from now
2. Save the reminder
3. Lock your device
4. Wait for notification to appear
5. Verify notification shows correct title
6. Tap notification
7. Verify app opens to reminders screen

**Expected Result:** Notification appears in notification shade, tapping opens app

#### Test 2: Full-Screen Alarm

**Objective:** Verify full-screen alarms work

**Steps:**
1. Create a new reminder:
   - Title: "Test Alarm"
   - Type: Full-Screen Alarm
   - Schedule: One-time, 2 minutes from now
2. Save the reminder
3. Lock your device
4. Wait for alarm to trigger
5. Verify full-screen alarm appears over lock screen
6. Tap "Dismiss" button
7. Verify alarm is dismissed

**Expected Result:** Full-screen alarm appears with sound, wakes screen, requires dismissal

#### Test 3: Background Delivery (App Closed)

**Objective:** Verify notifications work when app is force-stopped

**Steps:**
1. Create a reminder scheduled for 3 minutes from now
2. Save the reminder
3. Force stop the app (Settings → Apps → Numu → Force Stop)
4. Lock your device
5. Wait for notification
6. Verify notification appears

**Expected Result:** Notification appears even with app force-stopped

#### Test 4: Background Delivery (App in Background)

**Objective:** Verify notifications work when app is backgrounded

**Steps:**
1. Create a reminder scheduled for 2 minutes from now
2. Save the reminder
3. Press home button (app goes to background)
4. Wait for notification
5. Verify notification appears

**Expected Result:** Notification appears with app in background

#### Test 5: Notification Tap Navigation

**Objective:** Verify tapping notification navigates correctly

**Steps:**
1. Create a task-linked reminder for 2 minutes from now
2. Save and close app
3. Wait for notification
4. Tap notification
5. Verify app opens to task detail screen

**Expected Result:** App opens to correct screen based on linked entity

#### Test 6: Repeating Reminders

**Objective:** Verify weekly reminders reschedule correctly

**Steps:**
1. Create a weekly reminder:
   - Title: "Weekly Test"
   - Schedule: Weekly on current day, current time + 2 minutes
2. Save the reminder
3. Wait for first notification
4. Check reminder list
5. Verify next trigger time is set for next week

**Expected Result:** Reminder triggers and automatically reschedules for next week

#### Test 7: Multiple Reminders

**Objective:** Verify multiple reminders work simultaneously

**Steps:**
1. Create 10 reminders with 1-minute intervals
2. Save all reminders
3. Lock device
4. Wait and verify all 10 notifications appear

**Expected Result:** All notifications appear at correct times (Android has no limit)

#### Test 8: Device Restart Persistence

**Objective:** Verify reminders persist after device restart

**Steps:**
1. Create a reminder scheduled for 10 minutes from now
2. Note the scheduled time
3. Restart your Android device
4. Open app after restart
5. Verify reminder still exists with correct schedule
6. Wait for notification

**Expected Result:** Reminder persists and triggers after restart (requires BOOT_COMPLETED receiver)

#### Test 9: Doze Mode Testing

**Objective:** Verify reminders work in Doze mode

**Steps:**
1. Create a reminder for 5 minutes from now
2. Lock device and leave undisturbed
3. Wait for device to enter Doze mode (may take 30+ minutes)
4. Verify notification still appears

**Expected Result:** Notification appears even in Doze mode (requires SCHEDULE_EXACT_ALARM)

#### Test 10: Different Android Versions

**Objective:** Verify compatibility across Android versions

**Steps:**
1. Test on Android 8.0 (API 26) - notification channels
2. Test on Android 12 (API 31) - exact alarm permissions
3. Test on Android 13 (API 33) - runtime notification permissions
4. Verify all features work on each version

**Expected Result:** App works correctly on all supported Android versions

### Step 4: Troubleshooting Android Issues

#### Notifications Not Appearing

**Possible Causes:**
- Permissions not granted
- Notification channel disabled
- Battery optimization killing app
- Do Not Disturb enabled

**Solutions:**
1. Check Settings → Apps → Numu → Notifications
2. Ensure notification channel is enabled
3. Disable battery optimization: Settings → Apps → Numu → Battery → Unrestricted
4. Check Do Not Disturb settings
5. Verify POST_NOTIFICATIONS permission granted (Android 13+)

#### Full-Screen Alarms Not Working

**Possible Causes:**
- Missing USE_FULL_SCREEN_INTENT permission
- Display over other apps permission not granted
- Device manufacturer restrictions

**Solutions:**
1. Verify AndroidManifest.xml has USE_FULL_SCREEN_INTENT permission
2. Grant "Display over other apps" permission
3. Check manufacturer-specific settings (Samsung, Xiaomi, etc.)
4. Disable battery optimization for the app

#### Exact Alarms Not Triggering

**Possible Causes:**
- SCHEDULE_EXACT_ALARM permission not granted (Android 12+)
- Battery optimization enabled
- App in restricted background mode

**Solutions:**
1. Grant "Alarms & reminders" permission (Android 12+)
2. Settings → Apps → Numu → Battery → Unrestricted
3. Check Settings → Apps → Special app access → Alarms & reminders

#### Notifications Not Persisting After Restart

**Possible Causes:**
- BOOT_COMPLETED receiver not configured
- App not rescheduling on launch

**Solutions:**
1. Verify AndroidManifest.xml has BOOT_COMPLETED receiver
2. Check that `rescheduleAllReminders()` is called in `main.dart`
3. Ensure RECEIVE_BOOT_COMPLETED permission is granted

#### App Crashes on Notification Tap

**Possible Causes:**
- Intent handling not configured
- Navigation context issues

**Solutions:**
1. Check MainActivity.kt notification intent handling
2. Verify navigation routes are properly configured
3. Review logcat for error messages: `adb logcat | grep Flutter`

#### Battery Optimization Issues

**Possible Causes:**
- Manufacturer-specific battery optimization
- Aggressive background restrictions

**Solutions:**
1. Disable battery optimization for Numu
2. Add app to "Never sleeping apps" list (Samsung)
3. Disable "Adaptive Battery" for the app
4. Check manufacturer-specific settings:
   - **Samsung**: Settings → Apps → Numu → Battery → Optimize battery usage → All → Numu → Don't optimize
   - **Xiaomi**: Settings → Apps → Manage apps → Numu → Battery saver → No restrictions
   - **Huawei**: Settings → Apps → Numu → Battery → App launch → Manage manually

## Platform-Specific Limitations

### iOS Limitations

1. **64 Notification Limit:**
   - iOS allows maximum 64 scheduled notifications
   - App must reschedule on launch to refresh queue
   - Prioritize upcoming reminders

2. **Background Execution:**
   - Limited background processing time
   - Notifications may be delayed if app is suspended
   - Use background modes for better reliability

3. **Notification Grouping:**
   - iOS automatically groups notifications from same app
   - Cannot fully customize grouping behavior

4. **Silent Notifications:**
   - Limited to specific use cases
   - Require background modes configuration

### Android Limitations

1. **Manufacturer Variations:**
   - Different manufacturers have different battery optimization policies
   - Some devices aggressively kill background apps
   - May require user to manually disable optimizations

2. **Doze Mode:**
   - Device enters Doze mode when idle
   - Exact alarms still work but may be delayed
   - Use SCHEDULE_EXACT_ALARM permission

3. **Notification Channels:**
   - User can disable specific notification channels
   - Cannot programmatically re-enable disabled channels
   - Must guide user to settings

4. **Android Version Differences:**
   - Android 12+ requires explicit exact alarm permission
   - Android 13+ requires runtime notification permission
   - Must handle different permission flows

## Common Test Scenarios

### Scenario 1: Daily Habit Reminder

**Setup:**
1. Create a habit: "Morning Exercise" with time window 7:00 AM - 8:00 AM
2. Create reminder linked to habit:
   - Type: Notification
   - Schedule: Daily, use habit time window, 15 minutes before
3. Save reminder

**Expected Behavior:**
- Notification appears at 6:45 AM daily
- Notification text: "Do Morning Exercise"
- Tapping opens habit detail screen
- Reminder only triggers on habit's active days

### Scenario 2: Task Due Date Reminder

**Setup:**
1. Create a task: "Submit Report" with due date tomorrow at 5:00 PM
2. Create reminder linked to task:
   - Type: Full-Screen Alarm
   - Schedule: 1 hour before due date
3. Save reminder

**Expected Behavior:**
- Full-screen alarm appears tomorrow at 4:00 PM
- Alarm text: "Submit Report"
- Tapping opens task detail screen
- If task due date changes, reminder updates automatically

### Scenario 3: Standalone Weekly Reminder

**Setup:**
1. Create standalone reminder:
   - Title: "Team Meeting"
   - Type: Notification
   - Schedule: Weekly on Monday at 9:00 AM
2. Save reminder

**Expected Behavior:**
- Notification appears every Monday at 9:00 AM
- Tapping opens reminders list screen
- Continues indefinitely until disabled or deleted

## Testing Checklist

### Pre-Release Testing

- [ ] All permissions requested and handled gracefully
- [ ] Notifications appear on lock screen
- [ ] Notifications appear in notification center/shade
- [ ] Notification tap navigation works correctly
- [ ] Full-screen alarms display correctly
- [ ] Full-screen alarms require explicit dismissal
- [ ] Alarm sound plays correctly
- [ ] Reminders persist after app restart
- [ ] Reminders persist after device restart
- [ ] Background delivery works (app closed)
- [ ] Background delivery works (app backgrounded)
- [ ] Repeating reminders reschedule correctly
- [ ] One-time reminders mark as inactive after trigger
- [ ] Habit-linked reminders inherit configuration
- [ ] Task-linked reminders update with due date changes
- [ ] Cascade delete works (habit/task deletion)
- [ ] Time zone changes handled correctly
- [ ] Multiple reminders work simultaneously
- [ ] Edit reminder updates scheduling
- [ ] Delete reminder cancels notifications
- [ ] Toggle active/inactive works correctly

### Platform-Specific Testing

#### iOS
- [ ] Tested on iOS 14, 15, 16, 17
- [ ] Notification permissions flow works
- [ ] Background modes configured correctly
- [ ] 64 notification limit handled gracefully
- [ ] Works with Do Not Disturb
- [ ] Works with Focus modes
- [ ] Notification grouping acceptable

#### Android
- [ ] Tested on Android 8, 10, 12, 13, 14
- [ ] Notification channels configured correctly
- [ ] Runtime permissions work (Android 13+)
- [ ] Exact alarm permissions work (Android 12+)
- [ ] Battery optimization disabled or handled
- [ ] Works in Doze mode
- [ ] BOOT_COMPLETED receiver works
- [ ] Tested on multiple manufacturers (Samsung, Google, Xiaomi)

## Debugging Tips

### iOS Debugging

1. **View Console Logs:**
   - Open Xcode
   - Window → Devices and Simulators
   - Select your device
   - View device logs

2. **Check Notification Delivery:**
   - Use Xcode's notification debugging
   - Set breakpoints in AppDelegate.swift

3. **Verify Background Modes:**
   - Check Xcode project capabilities
   - Review Info.plist entries

### Android Debugging

1. **View Logcat:**
   ```bash
   adb logcat | grep Flutter
   ```

2. **Check Notification Channels:**
   ```bash
   adb shell dumpsys notification
   ```

3. **Verify Permissions:**
   ```bash
   adb shell dumpsys package com.baseet.numu | grep permission
   ```

4. **Test Exact Alarms:**
   ```bash
   adb shell dumpsys alarm
   ```

## Best Practices

1. **Always test on physical devices** - Simulators/emulators don't accurately represent notification behavior
2. **Test with app closed** - Most users will receive notifications with app closed
3. **Test across multiple devices** - Different manufacturers have different behaviors
4. **Test battery optimization scenarios** - Real-world usage involves battery optimization
5. **Test time zone changes** - Users travel and change time zones
6. **Test device restarts** - Reminders must persist across restarts
7. **Test permission denial** - Handle gracefully when users deny permissions
8. **Document issues** - Keep track of platform-specific quirks and workarounds

## Support Resources

### iOS
- [Apple Notification Documentation](https://developer.apple.com/documentation/usernotifications)
- [Background Execution Guide](https://developer.apple.com/documentation/backgroundtasks)
- [Xcode Debugging Guide](https://developer.apple.com/documentation/xcode/debugging)

### Android
- [Android Notification Guide](https://developer.android.com/develop/ui/views/notifications)
- [Exact Alarms Documentation](https://developer.android.com/about/versions/12/behavior-changes-12#exact-alarm-permission)
- [Battery Optimization Guide](https://developer.android.com/topic/performance/power)
- [Don't Kill My App](https://dontkillmyapp.com/) - Manufacturer-specific battery optimization info

### Flutter
- [flutter_local_notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
