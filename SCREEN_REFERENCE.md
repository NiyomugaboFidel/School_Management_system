# 📱 Screen Reference Guide

## Attendance Screens - Quick Reference

### 1. **AttendanceScanScreen** 🎯 (FOR SCANNING)
**File:** `lib/Views/attendance/screens/attendance_scan_screen.dart`

**Purpose:** Scan student cards (NFC/QR) to mark attendance

**When to use:**
- ✅ When you want to scan cards to mark attendance
- ✅ From FAB action button → Attendance
- ✅ From quick action buttons

**How to navigate:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AttendanceScanScreen(),
  ),
);
```

**Features:**
- NFC scanner
- QR/Barcode scanner
- Real-time attendance marking
- Scan result feedback
- Uses `ScanActionManager` context

---

### 2. **AttendanceScreen** 📋 (FOR VIEWING/MANAGING)
**File:** `lib/Views/home/screens/attendance_screen.dart`

**Purpose:** View and manage attendance records

**When to use:**
- ✅ View attendance history
- ✅ Manage attendance records
- ✅ Edit/update attendance
- ✅ Filter by class/date
- ✅ View statistics

**How to navigate:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AttendanceScreen(),
  ),
);
```

**Features:**
- Tab-based interface
- Class selection
- Student list with attendance status
- Today's attendance summary
- Search and filter

---

## Quick Decision Guide

```
❓ Need to scan cards to mark attendance?
   → Use: AttendanceScanScreen()

❓ Need to view/edit attendance records?
   → Use: AttendanceScreen()

❓ User clicks FAB → Attendance action?
   → Use: AttendanceScanScreen() ✅ (Current setup)

❓ User clicks "View Attendance" or "Attendance History"?
   → Use: AttendanceScreen()
```

---

## Current Navigation Setup

### From FAB (Service Action Sheet):
```dart
// lib/Components/service_action_sheet.dart
if (action == ScanAction.attendance) {
  ScanActionManager().setAction(action);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AttendanceScanScreen(), // ✅ Correct
    ),
  );
}
```

### For Viewing Records (From Recent Page):
```dart
// In recent_records_screen.dart or dashboard
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AttendanceScreen(), // ✅ For management
  ),
);
```

---

## Other Important Screens

### 3. **ScannerMainScreen**
**File:** `lib/scanner/screens/scanner_screen.dart`
- Low-level scanner wrapper
- Used by AttendanceScanScreen
- Don't navigate to this directly

### 4. **AttendanceScannerWidget**
**File:** `lib/scanner/screens/attendance_scanner_widget.dart`
- The actual scanner UI component
- Used inside ScannerMainScreen
- Don't navigate to this directly

### 5. **RecentRecordsScreen**
**File:** `lib/Views/recent/recent_records_screen.dart`
- Shows recent attendance with calendar
- For viewing history by date
- Includes calendar-based filtering

---

## Typical User Flows

### Flow 1: Quick Attendance Marking (Most Common)
```
User opens app
   ↓
Clicks FAB (center button)
   ↓
Sees Service Action Sheet
   ↓
Clicks "Attendance"
   ↓
Opens AttendanceScanScreen ✅
   ↓
Scans student card
   ↓
Attendance marked!
```

### Flow 2: View/Manage Attendance
```
User opens app
   ↓
Goes to Recent tab
   ↓
Clicks "Attendance" card
   ↓
Opens RecentRecordsScreen (with calendar)
   OR
Opens AttendanceScreen (with class list)
```

### Flow 3: View Today's Records
```
User opens app
   ↓
Sees Dashboard
   ↓
Views "Today's Attendance" section
   ↓
Clicks "View All" or similar
   ↓
Opens AttendanceScreen
```

---

## Error Prevention Tips

❌ **DON'T:**
```dart
// Missing const
AttendanceScanScreen()

// Wrong screen for scanning
AttendanceScreen() // This is for viewing, not scanning
```

✅ **DO:**
```dart
// For scanning (from FAB)
const AttendanceScanScreen()

// For viewing (from menu/recent)
AttendanceScreen()
```

---

## Adding Context with ScanActionManager

Always set the scan action before navigating to scanner:

```dart
// Set what action we're performing
ScanActionManager().setAction(ScanAction.attendance);

// Then navigate to scanner
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AttendanceScanScreen(),
  ),
);

// The scanner will know it's for attendance!
```

---

## Summary Table

| Screen | Purpose | Use For | Navigation |
|--------|---------|---------|------------|
| **AttendanceScanScreen** | Scan cards | Marking attendance | From FAB → Attendance |
| **AttendanceScreen** | View/Manage | Viewing records | From Recent/Menu |
| **RecentRecordsScreen** | View history | Calendar-based view | From Recent tab |
| **ScannerMainScreen** | Low-level | Internal use | Don't navigate directly |

---

**Last Updated:** 2025-10-05  
**Status:** ✅ All navigation working correctly
