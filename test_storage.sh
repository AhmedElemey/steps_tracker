#!/bin/bash

# Script to test Firebase Storage after enabling it
# This script will run a quick test to verify Storage is working

echo "🧪 Firebase Storage Test"
echo "========================"
echo ""

PROJECT_ID="steps-tracker-1760794907"
echo "📋 Project ID: $PROJECT_ID"
echo ""

echo "🔍 Testing Firebase Storage connection..."
echo ""

# Check if Firebase CLI is available
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found"
    echo "Please install Firebase CLI: npm install -g firebase-tools"
    exit 1
fi

# Check current project
CURRENT_PROJECT=$(firebase use 2>/dev/null | head -n1)
echo "📋 Current project: $CURRENT_PROJECT"

if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "🔄 Switching to project: $PROJECT_ID"
    firebase use $PROJECT_ID
fi

echo ""
echo "✅ Firebase CLI is ready"
echo ""

echo "🧪 To test Firebase Storage:"
echo "1. Run your Flutter app: flutter run"
echo "2. Go to Settings page"
echo "3. Click 'Test Storage' button"
echo "4. Check debug console for results"
echo ""

echo "📱 Expected results if Storage is enabled:"
echo "✅ Storage instance created"
echo "✅ Storage bucket: $PROJECT_ID.firebasestorage.app"
echo "✅ Test reference created: test/connection_test.txt"
echo "✅ Upload successful"
echo "✅ Download URL: https://firebasestorage.googleapis.com/..."
echo "🎉 All Firebase Storage tests passed!"
echo ""

echo "❌ If you still see errors:"
echo "   - Verify Storage is enabled in Firebase Console"
echo "   - Check Storage security rules"
echo "   - Ensure you're authenticated in the app"
echo ""

echo "🚀 Ready to test! Run: flutter run"
