# Firebase Storage Troubleshooting Guide

## Current Error Analysis

The error you're experiencing:
```
StorageException: Object does not exist at location.
Code: -13010 HttpResult: 404
The server has terminated the upload session
```

This indicates that **Firebase Storage is not properly enabled** in your Firebase project.

## Step-by-Step Solution

### 1. **Enable Firebase Storage (CRITICAL)**

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `steps-tracker-1760794907`
3. **Navigate to Storage**: Click "Storage" in the left sidebar
4. **If you see "Get started" button**: Click it to enable Storage
5. **Choose security rules**: Select "Start in test mode" for now
6. **Choose location**: Select the same location as your Firestore (usually `us-central1`)

### 2. **Verify Storage is Enabled**

After enabling, you should see:
- A Storage dashboard with usage statistics
- A "Files" tab showing uploaded files
- A "Rules" tab for security configuration

### 3. **Update Storage Security Rules**

Go to Storage → Rules tab and replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload profile images
    match /user_profiles/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. **Test Storage Connection**

I've created a test service to verify the connection. Add this to your app temporarily:

```dart
// Add this to your main.dart or any page for testing
import 'package:firebase_storage/firebase_storage.dart';

void testStorage() async {
  try {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref();
    print('Storage bucket: ${ref.bucket}');
    print('Storage app: ${storage.app.name}');
    
    // Test creating a reference
    final testRef = storage.ref().child('test/connection_test.txt');
    print('Test reference created: ${testRef.fullPath}');
    
    print('✅ Firebase Storage is working!');
  } catch (e) {
    print('❌ Firebase Storage error: $e');
  }
}
```

## Alternative Solutions

### Option 1: Use Firestore for Image URLs (Temporary)

If Storage continues to have issues, you can temporarily store images as base64 in Firestore:

```dart
// Temporary solution - store image as base64
Future<String?> uploadImageAsBase64(File imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    
    // Store in Firestore instead of Storage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .update({
        'profileImageBase64': base64String,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'base64://$base64String';
    }
    return null;
  } catch (e) {
    print('Error uploading as base64: $e');
    return null;
  }
}
```

### Option 2: Use Local Storage (Temporary)

Store images locally until Storage is fixed:

```dart
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<String?> saveImageLocally(File imageFile) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final localPath = '${directory.path}/$fileName';
    
    await imageFile.copy(localPath);
    return localPath;
  } catch (e) {
    print('Error saving locally: $e');
    return null;
  }
}
```

## Debugging Steps

### 1. **Check Firebase Project Configuration**

Verify in Firebase Console:
- Project ID: `steps-tracker-1760794907`
- Storage bucket: `steps-tracker-1760794907.firebasestorage.app`
- Storage is enabled and shows usage dashboard

### 2. **Check App Configuration**

Verify in your `firebase_options.dart`:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyAW7_hdiCYkKNOpqYtMcwgtn91vseUYkuc',
  appId: '1:1961490031:android:caa803ff7ffb24b676bf9a',
  messagingSenderId: '1961490031',
  projectId: 'steps-tracker-1760794907',
  storageBucket: 'steps-tracker-1760794907.firebasestorage.app', // ← This should match
);
```

### 3. **Test with Simple Upload**

Try this minimal test:

```dart
import 'package:firebase_storage/firebase_storage.dart';

Future<void> testSimpleUpload() async {
  try {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('test/simple_test.txt');
    
    // Create a simple text file
    final data = 'Hello Firebase Storage!';
    final bytes = utf8.encode(data);
    
    final uploadTask = ref.putData(bytes);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    print('✅ Upload successful: $downloadUrl');
  } catch (e) {
    print('❌ Upload failed: $e');
  }
}
```

## Common Issues and Solutions

### Issue 1: "Storage not enabled"
**Solution**: Enable Storage in Firebase Console

### Issue 2: "Permission denied"
**Solution**: Update Storage security rules

### Issue 3: "Bucket not found"
**Solution**: Check project ID and bucket name in firebase_options.dart

### Issue 4: "Network error"
**Solution**: Check internet connection and Firebase project status

## Verification Checklist

- [ ] Firebase Storage is enabled in Console
- [ ] Storage security rules are configured
- [ ] Project ID matches in firebase_options.dart
- [ ] Storage bucket name is correct
- [ ] User is authenticated
- [ ] Network connection is working
- [ ] Firebase project is active (not suspended)

## Next Steps

1. **Enable Firebase Storage** in Console (most important)
2. **Update security rules** as shown above
3. **Test with simple upload** to verify connection
4. **Try profile image upload** again
5. **Check debug console** for detailed error messages

If Storage is properly enabled and you still get errors, the issue might be with the project configuration or network connectivity.
