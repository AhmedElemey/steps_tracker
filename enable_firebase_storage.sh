#!/bin/bash

# Script to help enable Firebase Storage
# This script will guide you through enabling Firebase Storage

echo "🔧 Firebase Storage Setup Helper"
echo "================================"
echo ""

# Get project ID
PROJECT_ID="steps-tracker-1760794907"
echo "📋 Project ID: $PROJECT_ID"
echo ""

# Check if Firebase CLI is available
if command -v firebase &> /dev/null; then
    echo "✅ Firebase CLI is available"
    CURRENT_PROJECT=$(firebase use 2>/dev/null | head -n1)
    echo "📋 Current project: $CURRENT_PROJECT"
    echo ""
else
    echo "❌ Firebase CLI not found"
    echo "Please install Firebase CLI: npm install -g firebase-tools"
    exit 1
fi

echo "⚠️  Firebase CLI does not have a direct command to enable Storage."
echo "📝 You need to enable it manually in Firebase Console."
echo ""

echo "🔗 Steps to enable Firebase Storage:"
echo "1. Go to: https://console.firebase.google.com/"
echo "2. Select project: $PROJECT_ID"
echo "3. Click 'Storage' in the left sidebar"
echo "4. Click 'Get started' to enable Storage"
echo "5. Choose 'Start in test mode'"
echo "6. Select a storage location (same as Firestore)"
echo "7. Click 'Done'"
echo ""

echo "🧪 After enabling, test with:"
echo "   - Run your app: flutter run"
echo "   - Go to Settings"
echo "   - Click 'Test Storage' button"
echo "   - Check debug console for results"
echo ""

echo "📋 Storage Security Rules (after enabling):"
echo "Go to Storage → Rules tab and replace with:"
echo ""
echo "rules_version = '2';"
echo "service firebase.storage {"
echo "  match /b/{bucket}/o {"
echo "    match /user_profiles/{userId}/{allPaths=**} {"
echo "      allow read, write: if request.auth != null && request.auth.uid == userId;"
echo "    }"
echo "  }"
echo "}"
echo ""

echo "🚀 Ready to test! After enabling Storage, run:"
echo "   flutter run"
echo "   # Then test the profile image upload feature"
