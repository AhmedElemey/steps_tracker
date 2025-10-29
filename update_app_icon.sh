

echo "🚀 Updating app icon for Steps Tracker..."

if [ ! -f "assets/icon/app_icon.png" ]; then
    echo "❌ Error: app_icon.png not found in assets/icon/ directory"
    echo "Please create your 1024x1024 PNG icon and save it as assets/icon/app_icon.png"
    echo "See assets/icon/README.md for requirements"
    exit 1
fi

echo "✅ Icon file found: assets/icon/app_icon.png"

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "🎨 Generating app icons for all platforms..."
flutter pub run flutter_launcher_icons:main

echo "🧹 Cleaning build cache..."
flutter clean

echo "📦 Getting dependencies after clean..."
flutter pub get

echo "✅ App icon update complete!"
echo ""
echo "Next steps:"
echo "1. Run 'flutter build android' to build for Android"
echo "2. Run 'flutter build ios' to build for iOS"
echo "3. Test the app to see your new icon"
echo ""
echo "The new icon should now appear on all platforms!"
