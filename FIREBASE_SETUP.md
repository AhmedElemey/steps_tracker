# Firebase Setup Guide for Steps Tracker

This guide will help you set up Firebase for your Steps Tracker app.

## Prerequisites

1. A Google account
2. Flutter development environment set up
3. Firebase CLI installed (`npm install -g firebase-tools`)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `steps-tracker-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Firebase to Your Flutter App

### Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Configure Firebase for your app

```bash
flutterfire configure
```

This command will:
- Automatically detect your Flutter project
- Create Firebase apps for each platform (iOS, Android, Web, etc.)
- Generate the `firebase_options.dart` file with your project configuration
- Add necessary configuration files to your project

## Step 3: Enable Firebase Services

### Authentication
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Anonymous" authentication

### Firestore Database
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database

### Storage (Optional)
1. In Firebase Console, go to "Storage"
2. Click "Get started"
3. Choose "Start in test mode"
4. Select a location for your storage

## Step 4: Update Firebase Rules

### Firestore Rules
Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles - users can only access their own profile
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Step entries - users can only access their own entries
    match /step_entries/{entryId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Weight entries - users can only access their own entries
    match /weight_entries/{entryId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Goals - users can only access their own goals
    match /goals/{goalId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### Storage Rules (for profile images)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images - users can only access their own images
    match /user_profiles/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Additional security: validate file types and sizes
    match /user_profiles/{userId}/{fileName} {
      allow write: if request.auth != null 
        && request.auth.uid == userId
        && resource.contentType.matches('image/.*')
        && resource.size < 10 * 1024 * 1024; // 10MB limit
    }
  }
}
```

## Step 5: Update Your App Configuration

After running `flutterfire configure`, your `firebase_options.dart` file will be automatically updated with the correct configuration. The placeholder values in the current file will be replaced with your actual project credentials.

## Step 6: Test Your Setup

1. Run your Flutter app: `flutter run`
2. Try creating a profile (this will create an anonymous user)
3. Check Firebase Console to see if data is being created

## Firebase Collections Structure

Your app will create the following collections in Firestore:

### user_profiles
- Document ID: `{userId}`
- Fields: `id`, `name`, `weight`, `profileImageUrl`, `createdAt`, `updatedAt`

### step_entries
- Document ID: `{userId}_{date}`
- Fields: `id`, `userId`, `date`, `steps`, `distance`, `calories`, `createdAt`, `updatedAt`

### weight_entries
- Document ID: `{userId}_{date}`
- Fields: `id`, `userId`, `date`, `weight`, `notes`, `createdAt`, `updatedAt`

### goals
- Document ID: `{auto-generated-id}`
- Fields: `id`, `userId`, `type`, `title`, `description`, `targetValue`, `currentValue`, `startDate`, `endDate`, `status`, `createdAt`, `updatedAt`

## Features Implemented

✅ **Authentication**
- Anonymous authentication
- User session management
- Automatic sign-in on app launch

✅ **Data Models**
- UserProfile model
- StepEntry model
- WeightEntry model
- Goal model with progress tracking

✅ **Firebase Services**
- ProfileService for user profiles
- StepsFirebaseService for step tracking
- WeightFirebaseService for weight tracking
- GoalsFirebaseService for goal management

✅ **Offline Support**
- Firestore offline persistence enabled
- Automatic sync when connection is restored
- Local-first approach with cloud backup

✅ **Real-time Updates**
- Stream-based data listening
- Automatic UI updates when data changes

## Next Steps

1. Run `flutterfire configure` to set up your project
2. Update the Firebase rules as shown above
3. Test the app with your Firebase project
4. Consider adding more authentication methods (email/password, Google, etc.)
5. Implement push notifications for goal reminders
6. Add data export/import functionality

## Troubleshooting

### Common Issues

1. **"Firebase not initialized" error**
   - Make sure you've run `flutterfire configure`
   - Check that `firebase_options.dart` has correct values

2. **Permission denied errors**
   - Check your Firestore rules
   - Ensure user is authenticated before accessing data

3. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Make sure all Firebase dependencies are properly installed

### Getting Help

- Check the [Firebase Flutter documentation](https://firebase.flutter.dev/)
- Visit the [FlutterFire GitHub repository](https://github.com/firebase/flutterfire)
- Join the [Firebase Discord community](https://discord.gg/firebase)
