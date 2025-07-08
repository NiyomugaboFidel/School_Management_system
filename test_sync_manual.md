# Manual Testing Guide for Sync System

## Overview
This guide helps you test the new offline-first sync system to ensure it works correctly.

## Pre-Testing Setup

1. **Clear any existing data** (optional):
   - Uninstall and reinstall the app
   - Or clear app data from device settings

2. **Ensure Firebase is configured**:
   - Check that `firebase_options.dart` exists
   - Verify Firebase project is set up correctly

## Test Scenarios

### Test 1: Offline Functionality
**Goal**: Verify app works completely offline

**Steps**:
1. Turn off internet connection (WiFi + Mobile data)
2. Open the app
3. Navigate to Settings → System Testing → Test Sync System
4. Verify the system initializes without errors
5. Try marking attendance for a student
6. Verify attendance is saved locally
7. Check that sync status shows "No internet connection"

**Expected Results**:
- ✅ App opens without errors
- ✅ Sync system initializes successfully
- ✅ Attendance marking works
- ✅ Data is saved locally
- ✅ No Firebase errors

### Test 2: Online Sync
**Goal**: Verify sync works when online

**Steps**:
1. Turn on internet connection
2. Open the app
3. Navigate to Settings → System Testing → Test Sync System
4. Click "Test Sync" button
5. Check the logs for sync status
6. Navigate to Dashboard and try manual sync
7. Check Firebase console for synced data

**Expected Results**:
- ✅ Sync system detects internet connection
- ✅ Firebase initializes successfully
- ✅ Data syncs to Firebase
- ✅ Firebase console shows new documents
- ✅ Sync status updates correctly

### Test 3: Real-time Attendance Sync
**Goal**: Verify attendance syncs in real-time

**Steps**:
1. Ensure internet connection is on
2. Open the app
3. Mark attendance for a student (any method: manual, QR, NFC)
4. Check Firebase console immediately
5. Verify attendance appears in Firebase

**Expected Results**:
- ✅ Attendance is saved locally first
- ✅ Attendance syncs to Firebase automatically
- ✅ Firebase shows attendance record with correct data
- ✅ No sync errors in console

### Test 4: Multi-user Support
**Goal**: Verify multiple devices can work simultaneously

**Steps**:
1. Install app on two different devices
2. Mark attendance on both devices
3. Check Firebase console for both records
4. Verify device IDs are different
5. Check for any conflicts

**Expected Results**:
- ✅ Both devices can mark attendance
- ✅ Firebase shows records from both devices
- ✅ Device IDs are unique
- ✅ No data conflicts

### Test 5: Offline to Online Transition
**Goal**: Verify seamless transition from offline to online

**Steps**:
1. Turn off internet
2. Mark several attendance records
3. Turn on internet
4. Check if data syncs automatically
5. Verify all records appear in Firebase

**Expected Results**:
- ✅ Attendance works offline
- ✅ Data syncs when connection restored
- ✅ All records appear in Firebase
- ✅ No data loss

## Troubleshooting

### Common Issues

1. **"SyncService doesn't have an unnamed constructor"**
   - Solution: Use `SyncService.instance` instead of `SyncService()`

2. **"FirebaseConnectionTester undefined"**
   - Solution: Use the test Firebase page directly

3. **"AttendanceStatus invalid arguments"**
   - Solution: Use `attendance.status.value` instead of `attendance.status`

4. **"No data in Firebase"**
   - Check internet connection
   - Verify Firebase configuration
   - Check sync logs for errors

### Debug Steps

1. **Check Console Logs**:
   ```
   flutter logs
   ```

2. **Check Sync Status**:
   - Go to Dashboard
   - Look at sync status section
   - Check for error messages

3. **Check Firebase Console**:
   - Go to Firestore Database
   - Look for `school_data` collection
   - Check `attendance` subcollection

4. **Use Test Pages**:
   - Settings → System Testing → Test Sync System
   - Settings → System Testing → Test Firebase Connection

## Expected Firebase Structure

After successful sync, Firebase should have:

```
school_data/
  school_001/
    attendance/
      attendance_1_1234567890/
        - local_id: 1
        - student_id: 123
        - date: "2024-01-01"
        - status: "Present"
        - marked_by: "Teacher"
        - device_id: "device_1234567890_1234"
        - user_id: "user_123"
    students/
      student_123/
        - local_id: 123
        - full_name: "John Doe"
        - ...
    users/
      user_123/
        - local_id: 123
        - username: "teacher1"
        - ...
    sync_logs/
      - success: true
      - message: "Full sync completed"
      - timestamp: "2024-01-01T10:00:00Z"
```

## Success Criteria

The sync system is working correctly if:

1. ✅ App works completely offline
2. ✅ No Firebase initialization errors
3. ✅ Attendance syncs in real-time when online
4. ✅ Data appears in Firebase console
5. ✅ Multiple devices can work simultaneously
6. ✅ No data loss during offline/online transitions
7. ✅ Proper error handling and user feedback

## Next Steps

If all tests pass:
1. Deploy to production
2. Monitor sync performance
3. Add more sophisticated conflict resolution
4. Implement background sync scheduling

If tests fail:
1. Check error logs
2. Verify Firebase configuration
3. Test with different devices
4. Contact support if issues persist 