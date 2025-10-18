# App Icon Setup

To update your app icon:

1. **Create your icon image**: Based on your description, create a 1024x1024 PNG image with:
   - A green stick figure in a running pose (matching #4caf50)
   - A circular progress ring (70-75% green, 25-30% light gray)
   - White background
   - The figure should be centered and clearly visible

2. **Save the image**: Save your icon as `app_icon.png` in this directory (`assets/icon/app_icon.png`)

3. **Generate all sizes**: Run the following command from your project root:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons:main
   ```

4. **Clean and rebuild**: 
   ```bash
   flutter clean
   flutter pub get
   flutter build android  # or flutter build ios
   ```

## Icon Requirements

- **Size**: 1024x1024 pixels (minimum)
- **Format**: PNG with transparency support
- **Background**: White or transparent
- **Colors**: Green (#4caf50) for the figure and progress ring, light gray for uncompleted progress

The flutter_launcher_icons package will automatically generate all the required sizes for:
- Android (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (all required sizes from 20x20 to 1024x1024)
- Web (192x192, 512x512)
- Windows and macOS

## Current Configuration

The icon generation is configured in `pubspec.yaml` with:
- Web background: white (#ffffff)
- Web theme color: green (#4caf50)
- Android launcher name: "launcher_icon"
- All platforms enabled
