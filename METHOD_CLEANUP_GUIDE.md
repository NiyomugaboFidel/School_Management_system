# 🔧 Method & Variable Cleanup Guide

This guide shows exactly which methods and variables to remove.

---

## File: `lib/SQLite/database_helper.dart`

### Line 682: Remove `_verifyPassword` method

```dart
// DELETE THIS ENTIRE METHOD (around line 682):
String _verifyPassword(String password) {
  // ... method implementation ...
}
```

**Why:** This method is declared but never called anywhere in the code.

---

## File: `lib/Views/auth/screens/login.dart`

### Line 868: Remove `_getGreeting` method

```dart
// DELETE THIS ENTIRE METHOD (around line 868):
String _getGreeting() {
  // ... method implementation ...
}
```

**Why:** This method is declared but never called.

---

## File: `lib/scanner/screens/attendance_scanner_widget.dart`

### Line 202: Remove `_getAttendanceNotes` method

```dart
// DELETE THIS ENTIRE METHOD (around line 202):
String _getAttendanceNotes() {
  // ... method implementation ...
}
```

### Line 322: Remove `_getStatusColor` method

```dart
// DELETE THIS ENTIRE METHOD (around line 322):
Color _getStatusColor(String status) {
  // ... method implementation ...
}
```

### Line 335: Remove `_getStatusIcon` method

```dart
// DELETE THIS ENTIRE METHOD (around line 335):
IconData _getStatusIcon(String status) {
  // ... method implementation ...
}
```

**Why:** These methods are declared but never called.

---

## File: `lib/services/auth_services.dart`

### Line 494: Remove unused `db` variable

```dart
// FIND (around line 494):
final db = await database;  // ❌ Variable declared but not used

// OPTIONS:
// 1. If db is needed later, keep it
// 2. If not needed, remove this line entirely
// 3. Or prefix with underscore: final _db = await database;
```

---

## File: `lib/services/backup_service.dart`

### Line 172: Fix or remove `exportFile` variable

```dart
// FIND (around line 172):
final exportFile = ...;  // ❌ Variable declared but not used

// OPTIONS:
// 1. If exportFile is needed, use it
// 2. If not needed, remove the variable
// 3. Or return it if it's meant to be used
```

### Line 209: Fix or remove `backupFile` variable

```dart
// FIND (around line 209):
final backupFile = ...;  // ❌ Variable declared but not used

// OPTIONS:
// 1. If backupFile is needed, use it
// 2. If not needed, remove the variable
// 3. Or return it if it's meant to be used
```

---

## File: `lib/Components/connectivity_status_widget.dart`

### Line 14: Fix or remove `_connectivityStatus` field

```dart
// FIND (around line 14):
final _connectivityStatus = ...;  // ❌ Field declared but not used

// OPTIONS:
// 1. Use this field in the widget
// 2. Remove it if not needed
```

---

## Step-by-Step Cleanup Process

### 1. Backup Your Code
```bash
git add -A
git commit -m "Before method cleanup"
```

### 2. For Each File:

1. **Open the file** in your editor
2. **Go to the line number** mentioned above
3. **Read the method/variable** to understand it
4. **Delete the entire method** (including comments and blank lines)
5. **Save the file**
6. **Run `flutter analyze`** to check for issues

### 3. Verify Cleanup

After each file:
```bash
flutter analyze <filename>
```

After all files:
```bash
flutter analyze
```

---

## Example: Removing a Method

### Before:
```dart
class MyClass {
  void usedMethod() {
    // This is called somewhere
    print("Used");
  }

  void _unusedMethod() {  // ❌ DELETE THIS
    print("Never called");
  }

  void anotherUsedMethod() {
    // This is used
  }
}
```

### After:
```dart
class MyClass {
  void usedMethod() {
    // This is called somewhere
    print("Used");
  }

  // _unusedMethod removed ✅

  void anotherUsedMethod() {
    // This is used
  }
}
```

---

## Verification Commands

### Check for unused elements:
```bash
flutter analyze 2>&1 | grep "unused_element"
```

### Check for unused fields:
```bash
flutter analyze 2>&1 | grep "unused_field"
```

### Check for unused local variables:
```bash
flutter analyze 2>&1 | grep "unused_local_variable"
```

### Check all unused code:
```bash
flutter analyze 2>&1 | grep -E "(unused_element|unused_field|unused_local_variable)"
```

---

## Expected Result

After cleanup, these commands should return **no results** or significantly fewer warnings.

```bash
flutter analyze 2>&1 | grep "unused"
```

Expected: Minimal or no warnings ✅

---

## Safety Tips

1. ✅ Always commit before making changes
2. ✅ Clean up one file at a time
3. ✅ Test after each file
4. ✅ Run `flutter analyze` after each change
5. ✅ Keep backups
6. ⚠️ Don't delete methods that look unused but might be called via reflection
7. ⚠️ Don't delete callback methods (like `initState`, `dispose`)

---

## If Something Breaks

```bash
# Undo your changes
git checkout <filename>

# Or undo all changes
git reset --hard HEAD
```

Then try again more carefully!
