# Firebase Setup Guide

## Fixing "Missing or insufficient permissions" Error

The error you're seeing is because Firestore security rules are blocking write access. Here are the steps to fix it:

### Option 1: Use the Deploy Script (Recommended)

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Deploy the security rules**:
   ```bash
   ./deploy_firestore_rules.sh
   ```

### Option 2: Manual Setup via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/xtap-570bb/firestore/rules)

2. Replace the existing rules with:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Allow read/write access to test_connection collection for testing
       match /test_connection/{document} {
         allow read, write: if true;
       }
       
       // Allow read/write access to notifications collection
       match /notifications/{document} {
         allow read, write: if true;
       }
       
       // Allow read/write access to events collection
       match /events/{document} {
         allow read, write: if true;
       }
       
       // Allow read/write access to global_settings collection
       match /global_settings/{document} {
         allow read, write: if true;
       }
       
       // Allow read/write access to students collection (for sync)
       match /students/{document} {
         allow read, write: if true;
       }
       
       // Allow read/write access to payments collection (for sync)
       match /payments/{document} {
         allow read, write: if true;
       }
       
       // Allow read/write access to attendance collection (for sync)
       match /attendance/{document} {
         allow read, write: if true;
       }
       
       // Allow read/write access to audit_logs collection
       match /audit_logs/{document} {
         allow read, write: if true;
       }
       
       // Default rule - deny all other access
       match /{document=**} {
         allow read, write: if false;
       }
     }
   }
   ```

3. Click "Publish" to save the rules

### Testing the Connection

After updating the rules:

1. **Restart your app** (hot reload might not be enough)
2. **Navigate to the test page**: `/test-firebase`
3. **Click "Test Firebase Connection"** or **"Test Direct Firestore"**
4. **Check the console** for success messages
5. **Check Firestore Database** for new documents in the `test_connection` collection

### Security Note

⚠️ **Important**: These rules allow full read/write access for testing. For production, you should implement proper authentication and more restrictive rules.

### Troubleshooting

- **Still getting permission errors?** Wait a few minutes for rules to propagate
- **Firebase CLI not found?** Install it with `npm install -g firebase-tools`
- **Login issues?** Try `firebase logout` then `firebase login` again
- **Project not found?** Make sure you're using the correct project ID: `xtap-570bb` 