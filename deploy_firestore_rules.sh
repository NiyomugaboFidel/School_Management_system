#!/bin/bash

echo "🚀 Deploying Firestore security rules..."

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please login first:"
    echo "firebase login"
    exit 1
fi

# Deploy the rules
echo "📝 Deploying firestore.rules to project: xtap-570bb"
firebase deploy --only firestore:rules --project xtap-570bb

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully!"
    echo "🔓 Your app should now be able to write to Firestore"
    echo "🧪 Try running the Firebase test again"
else
    echo "❌ Failed to deploy Firestore rules"
    echo "💡 You can also manually update rules in Firebase Console:"
    echo "   https://console.firebase.google.com/project/xtap-570bb/firestore/rules"
fi 