# Profile Image Upload Feature

## Overview

This document describes the implementation of the profile image upload feature that allows users to upload, update, and manage their profile pictures. The feature integrates with Firebase Storage for image storage and Firestore for metadata management.

## Features

### ✅ **Core Functionality**
- **Image Selection**: Choose images from gallery or camera
- **Image Upload**: Upload images to Firebase Storage
- **Image Display**: Display profile images in the settings screen
- **Image Update**: Replace existing profile images
- **Image Deletion**: Remove profile images
- **Progress Tracking**: Real-time upload progress indication
- **Error Handling**: Comprehensive error handling and user feedback

### ✅ **Technical Features**
- **Image Validation**: File type, size, and format validation
- **Image Compression**: Automatic image optimization
- **Storage Management**: Automatic cleanup of old images
- **Security**: Secure Firebase Storage rules
- **Offline Support**: Graceful handling of network issues
- **Performance**: Efficient image loading and caching

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Profile Image System                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ ImagePickerWidget│  │   ImageService  │  │ProfileService│ │
│  │                 │  │                 │  │              │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│           │                     │                    │       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Firebase Storage│  │   Firestore     │  │ AuthController│ │
│  │                 │  │                 │  │              │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Details

### 1. **Dependencies Added**

```yaml
# Firebase Storage for image storage
firebase_storage: ^12.3.2

# Image picker for selecting images
image_picker: ^1.1.2
```

### 2. **UserProfile Model Updates**

```dart
class UserProfile {
  final String id;
  final String name;
  final double weight;
  final String? profileImageUrl;  // ← New field
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Updated methods to handle profileImageUrl
}
```

### 3. **ImageService**

**Location**: `lib/core/services/image_service.dart`

**Key Methods**:
- `pickImage()` - Select image from gallery or camera
- `uploadProfileImage()` - Upload image to Firebase Storage
- `uploadProfileImageWithProgress()` - Upload with progress tracking
- `deleteProfileImage()` - Delete image from storage
- `validateImageFile()` - Validate image file
- `cleanupOldProfileImages()` - Clean up old images

**Features**:
- Image validation (file type, size, format)
- Progress tracking during upload
- Automatic cleanup of old images
- Error handling and logging

### 4. **ProfileService Updates**

**Location**: `lib/features/profile/services/profile_service.dart`

**New Methods**:
- `uploadProfileImage()` - Upload and update profile
- `uploadProfileImageWithProgress()` - Upload with progress
- `deleteProfileImage()` - Delete profile image
- `updateProfile()` - Updated to handle profileImageUrl

**Features**:
- Integration with ImageService
- Firestore profile updates
- Automatic cleanup of old images
- Error handling and validation

### 5. **ImagePickerWidget**

**Location**: `lib/features/profile/widgets/image_picker_widget.dart`

**Features**:
- Circular profile image display
- Image selection from gallery or camera
- Upload progress indicator
- Error message display
- Image preview and validation
- Delete current image option

**UI Components**:
- Profile image display with fallback avatar
- Bottom sheet for image source selection
- Progress bar during upload
- Error message display
- Upload button

### 6. **Settings Page Integration**

**Location**: `lib/features/settings/presentation/pages/settings_page.dart`

**Updates**:
- Added ImagePickerWidget to account section
- Integrated with AuthController for profile updates
- Real-time profile image updates

### 7. **AuthController Updates**

**Location**: `lib/features/auth/controllers/auth_controller.dart`

**New Method**:
- `updateUserProfile()` - Update profile in controller

## Usage

### 1. **Basic Usage**

```dart
// Display profile image picker
ImagePickerWidget(
  userProfile: userProfile,
  onImageUpdated: (updatedProfile) {
    // Handle profile update
    authController.updateUserProfile(updatedProfile);
  },
)
```

### 2. **Custom Configuration**

```dart
ImagePickerWidget(
  userProfile: userProfile,
  size: 150.0,  // Custom size
  showUploadButton: true,  // Show upload button
  onImageUpdated: (updatedProfile) {
    // Handle update
  },
)
```

### 3. **Direct Service Usage**

```dart
// Upload image directly
final imageService = ImageService();
final profileService = ProfileService();

// Pick image
final imageFile = await imageService.pickImage(source: ImageSource.gallery);

// Upload with progress
final updatedProfile = await profileService.uploadProfileImageWithProgress(
  imageFile,
  (progress) => print('Upload progress: ${progress * 100}%'),
);
```

## Firebase Configuration

### 1. **Storage Rules**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /user_profiles/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Additional security
    match /user_profiles/{userId}/{fileName} {
      allow write: if request.auth != null 
        && request.auth.uid == userId
        && resource.contentType.matches('image/.*')
        && resource.size < 10 * 1024 * 1024; // 10MB limit
    }
  }
}
```

### 2. **Storage Structure**

```
user_profiles/
├── {userId}/
│   ├── profile_{userId}_{timestamp}.jpg
│   ├── profile_{userId}_{timestamp}.jpg
│   └── ...
```

### 3. **Firestore Structure**

```javascript
user_profiles/{userId} {
  id: string,
  name: string,
  weight: number,
  profileImageUrl: string,  // ← New field
  createdAt: timestamp,
  updatedAt: timestamp
}
```

## Security Features

### 1. **Authentication**
- Only authenticated users can upload images
- Users can only access their own images
- Secure Firebase Storage rules

### 2. **File Validation**
- File type validation (images only)
- File size limits (10MB maximum)
- File format validation

### 3. **Storage Security**
- User-specific storage paths
- Automatic cleanup of old images
- Secure download URLs

## Error Handling

### 1. **Common Errors**
- Network connectivity issues
- Invalid file formats
- File size exceeded
- Storage quota exceeded
- Authentication failures

### 2. **User Feedback**
- Progress indicators during upload
- Error messages for failed operations
- Success notifications
- Loading states

### 3. **Recovery**
- Automatic retry mechanisms
- Graceful fallbacks
- Error logging for debugging

## Performance Optimizations

### 1. **Image Optimization**
- Automatic image compression
- Resize images to reasonable dimensions
- Optimize file formats

### 2. **Storage Management**
- Automatic cleanup of old images
- Efficient storage structure
- Lazy loading of images

### 3. **Caching**
- Firebase Storage automatic caching
- Efficient image loading
- Progress tracking

## Testing

### 1. **Unit Tests**
- ImageService methods
- ProfileService updates
- Image validation logic

### 2. **Widget Tests**
- ImagePickerWidget functionality
- UI state management
- Error handling

### 3. **Integration Tests**
- End-to-end upload flow
- Firebase Storage integration
- Error scenarios

## Future Enhancements

### 1. **Advanced Features**
- Image cropping and editing
- Multiple image formats support
- Image filters and effects
- Batch image upload

### 2. **Performance**
- Image compression library integration
- Advanced caching strategies
- Background upload processing

### 3. **User Experience**
- Drag and drop image upload
- Image preview before upload
- Undo/redo functionality
- Image history

## Troubleshooting

### 1. **Common Issues**

**Upload Fails**:
- Check internet connectivity
- Verify Firebase Storage rules
- Check file size and format

**Image Not Displaying**:
- Verify image URL in Firestore
- Check Firebase Storage permissions
- Clear app cache

**Permission Denied**:
- Verify user authentication
- Check Firebase Storage rules
- Ensure user has proper permissions

### 2. **Debug Information**

```dart
// Enable debug logging
debugPrint('Image upload progress: $progress');
debugPrint('Image URL: $imageUrl');
debugPrint('Error: $error');
```

### 3. **Firebase Console**
- Check Storage usage
- Monitor upload/download metrics
- Review security rules
- Check error logs

## Conclusion

The profile image upload feature provides a complete solution for managing user profile pictures with:

- **Secure storage** using Firebase Storage
- **Real-time updates** with Firestore integration
- **User-friendly interface** with progress tracking
- **Comprehensive error handling** and validation
- **Performance optimizations** and cleanup
- **Security best practices** and validation

The implementation follows Flutter best practices and provides a robust, scalable solution for profile image management.
