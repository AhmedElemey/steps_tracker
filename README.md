# Steps Tracker

A Flutter app to track daily steps and fitness goals with Firebase integration, built for the Mobile App Development Assignment.

## Assignment Requirements Status

### ✅ Core Requirements (Completed)
- **Firebase Authentication**: Anonymous sign-in on first startup
- **User Profile Form**: Name and weight input with form validation
- **Real-time Step Tracking**: Live step counting with device pedometer
- **Firestore Integration**: Real-time data storage and synchronization
- **Weight Entries Management**: View, edit, delete with alphabetical ordering by date
- **Steps Entries View**: Hourly steps entries with alphabetical ordering by date
- **Real-time Updates**: Live updates when Firestore data changes
- **Sign-out Functionality**: Complete user session management

### ✅ Bonus Features (Completed)
- **Background Tracking**: Step tracking continues when app is in background
- **Bilingual Support**: English and Arabic with RTL/LTR support
- **Dark Mode**: Complete dark theme implementation
- **Profile Images**: Upload and manage profile pictures with Firebase Storage

## Features

- 🔐 **Firebase Authentication**: Anonymous sign-in with secure user management
- 📱 **Real-time Step Tracking**: Live step counting using device pedometer
- 🎯 **Daily Goals**: Set and track daily step targets
- 📊 **Progress Visualization**: Beautiful progress rings and statistics
- 📈 **Step History**: View your step data over time with Firestore integration
- ⚖️ **Weight Management**: Add, edit, and delete weight entries
- 🔄 **Real-time Sync**: Live updates across all devices
- 🌙 **Dark Mode**: Complete dark theme support
- 🌍 **Bilingual**: English and Arabic with RTL support
- 📸 **Profile Images**: Upload and manage profile pictures
- ⚙️ **Settings**: Customize goals, theme, and language preferences
- 💾 **Hybrid Storage**: SQLite for offline + Firestore for cloud sync
- 🎨 **Modern UI**: Clean, intuitive interface with Material Design 3

## Screenshots

The app features a clean, modern interface with:
- Home screen with step counter and progress visualization
- Settings page for goal management
- Bottom navigation for easy access
- Real-time step tracking with status indicators

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- iOS Simulator or Android Emulator (or physical device)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/steps_tracker.git
cd steps_tracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Permissions

The app requires the following permissions:
- **Activity Recognition**: To track steps accurately

On first launch, the app will request these permissions. If permissions are not granted, the app will run in demo mode with mock data.

## Architecture

The app follows a clean architecture pattern with:

- **Features**: Organized by feature (auth, profile, step_tracking, weight, steps, settings)
- **Models**: Data models for user profiles, step data, weight entries, and goals
- **Controllers**: State management using Provider pattern
- **Services**: Business logic, Firebase integration, and API services
- **Presentation**: UI components (pages and widgets)
- **Core**: Shared utilities, database, Firebase services, and constants

## Dependencies

### Core Dependencies
- `provider`: State management
- `sqflite`: Local database storage
- `pedometer`: Step tracking
- `permission_handler`: Permission management

### Firebase Dependencies
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication
- `cloud_firestore`: Real-time database
- `firebase_storage`: File storage

### Additional Features
- `image_picker`: Profile image selection
- `shared_preferences`: Local settings storage
- `intl`: Date and time formatting
- `dio`: HTTP requests

## Firebase Setup

To run this app, you need to:

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication (Anonymous sign-in)
3. Enable Firestore Database
4. Enable Firebase Storage
5. Download and add the configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
6. Update `lib/firebase_options.dart` with your project configuration

## Assignment Completion

This project successfully implements all required features from the Mobile App Development Assignment:

### Core Requirements ✅
- Firebase Auth with anonymous sign-in
- User profile form with name and weight
- Real-time step tracking
- Firestore integration for data storage
- Weight entries management (view, edit, delete)
- Steps entries with hourly tracking
- Real-time updates from Firestore
- Sign-out functionality

### Bonus Features ✅
- Background step tracking
- Bilingual support (English/Arabic with RTL)
- Dark mode implementation
- Profile image upload and management

The app is ready for submission and meets all assignment criteria.

## Demo Mode

If device permissions are not available (e.g., in simulator), the app automatically switches to demo mode with simulated step data, allowing you to explore all features.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created with ❤️ using Flutter