# 📦 Import Cleanup Guide

This guide shows exactly which lines to remove from each file.

---

## File: `lib/Views/auth/screens/signup.dart`

### Lines to Remove:
```dart
// Line 2 - Remove:
import 'package:sqlite_crud_app/Components/button.dart';

// Line 3 - Remove:
import 'package:sqlite_crud_app/Components/textfield.dart';

// Line 5 - Remove:
import 'package:sqlite_crud_app/models/user.dart';
```

---

## File: `lib/Views/settings/screens/settings_screen.dart`

### Lines to Remove:
```dart
// Line 10 - Remove:
import '../../../services/notification_service.dart';
```

---

## File: `lib/permission_service.dart`

### Lines to Remove:
```dart
// Line 2 - Remove:
import 'package:flutter/foundation.dart';
```

---

## File: `lib/services/notification_service.dart`

### Lines to Remove:
```dart
// Line 3 - Remove:
import 'package:shared_preferences/shared_preferences.dart';
```

---

## Quick Fix Command

You can use these sed commands (use with caution):

```bash
# Backup first!
git add -A
git commit -m "Before import cleanup"

# Fix signup.dart
sed -i "/import 'package:sqlite_crud_app\/Components\/button.dart';/d" lib/Views/auth/screens/signup.dart
sed -i "/import 'package:sqlite_crud_app\/Components\/textfield.dart';/d" lib/Views/auth/screens/signup.dart
sed -i "/import 'package:sqlite_crud_app\/models\/user.dart';/d" lib/Views/auth/screens/signup.dart

# Fix settings_screen.dart
sed -i "/import '..\/..\/..\/services\/notification_service.dart';/d" lib/Views/settings/screens/settings_screen.dart

# Fix permission_service.dart
sed -i "/import 'package:flutter\/foundation.dart';/d" lib/permission_service.dart

# Fix notification_service.dart
sed -i "/import 'package:shared_preferences\/shared_preferences.dart';/d" lib/services/notification_service.dart

# Verify
flutter analyze
```

---

## Manual Cleanup (Recommended)

1. Open each file in your editor
2. Find the import line
3. Delete the entire line
4. Save the file
5. Run `flutter analyze` to verify

---

## After Cleanup

Run this to verify all imports are fixed:

```bash
flutter analyze 2>&1 | grep "unused_import"
```

You should see: *No matches found* ✅
