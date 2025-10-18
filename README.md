# Steps Tracker

A Flutter app to track daily steps and fitness goals with a beautiful, modern UI.

## Features

- 📱 **Step Tracking**: Real-time step counting using device pedometer
- 🎯 **Daily Goals**: Set and track daily step targets
- 📊 **Progress Visualization**: Beautiful progress rings and statistics
- 📈 **Step History**: View your step data over time
- ⚙️ **Settings**: Customize your goals and preferences
- 💾 **Local Storage**: SQLite database for offline data storage
- 🎨 **Modern UI**: Clean, intuitive interface with Material Design

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

- **Features**: Organized by feature (step_tracking, goals, settings)
- **Models**: Data models for step data and goals
- **Controllers**: State management using Provider pattern
- **Services**: Business logic and API integrations
- **Presentation**: UI components (pages and widgets)
- **Core**: Shared utilities, database, and constants

## Dependencies

- `provider`: State management
- `sqflite`: Local database storage
- `pedometer`: Step tracking
- `permission_handler`: Permission management
- `dio`: HTTP requests
- `intl`: Date formatting

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