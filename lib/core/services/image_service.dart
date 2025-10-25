import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'firebase_service.dart';

/// Service for handling image uploads, downloads, and management
/// 
/// This service provides functionality for:
/// - Picking images from gallery or camera
/// - Uploading images to Firebase Storage
/// - Downloading images from Firebase Storage
/// - Deleting images from Firebase Storage
/// - Image compression and optimization
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      // Test storage connection first
      debugPrint('Testing Firebase Storage connection...');
      final bucket = _storage.ref().bucket;
      debugPrint('Storage bucket: $bucket');

      // Validate image file
      if (!validateImageFile(imageFile)) {
        debugPrint('Invalid image file');
        return null;
      }

      // Create a unique filename
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('user_profiles/${user.uid}/$fileName');
      
      debugPrint('Storage reference path: ${storageRef.fullPath}');

      // Upload the file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      
      // Check if it's a storage not enabled error
      if (e.toString().contains('object-not-found') || 
          e.toString().contains('404') ||
          e.toString().contains('No object exists')) {
        debugPrint('❌ Firebase Storage is not enabled or configured properly');
        debugPrint('Please enable Firebase Storage in Firebase Console');
        debugPrint('Go to: https://console.firebase.google.com/');
        debugPrint('Select your project: steps-tracker-1760794907');
        debugPrint('Click "Storage" in the left sidebar');
        debugPrint('Click "Get started" to enable Storage');
      }
      
      return null;
    }
  }

  /// Upload image with progress tracking
  Future<String?> uploadProfileImageWithProgress(
    File imageFile,
    Function(double progress)? onProgress,
  ) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      // Create a unique filename
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('user_profiles/${user.uid}/$fileName');

      // Upload the file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  /// Delete profile image from Firebase Storage
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      // Extract the file path from the URL
      final ref = _storage.refFromURL(imageUrl);
      
      // Delete the file
      await ref.delete();
      
      debugPrint('Profile image deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return false;
    }
  }

  /// Get all profile images for a user
  Future<List<String>> getUserProfileImages() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return [];
      }

      final listRef = _storage.ref().child('user_profiles/${user.uid}');
      final result = await listRef.listAll();

      final imageUrls = <String>[];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        imageUrls.add(url);
      }

      return imageUrls;
    } catch (e) {
      debugPrint('Error getting user profile images: $e');
      return [];
    }
  }

  /// Clean up old profile images (keep only the latest one)
  Future<void> cleanupOldProfileImages(String currentImageUrl) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      final listRef = _storage.ref().child('user_profiles/${user.uid}');
      final result = await listRef.listAll();

      // Delete all images except the current one
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        if (url != currentImageUrl) {
          try {
            await item.delete();
            debugPrint('Deleted old profile image: $url');
          } catch (e) {
            debugPrint('Error deleting old image: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old profile images: $e');
    }
  }

  /// Compress image file
  Future<File?> compressImage(File imageFile) async {
    try {
      // For now, we'll return the original file
      // In a production app, you might want to use a library like flutter_image_compress
      // to actually compress the image
      return imageFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Validate image file
  bool validateImageFile(File imageFile) {
    try {
      // Check if file exists
      if (!imageFile.existsSync()) {
        debugPrint('Image file does not exist');
        return false;
      }

      // Check file size (max 10MB)
      final fileSize = imageFile.lengthSync();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        debugPrint('Image file is too large: ${fileSize / 1024 / 1024}MB');
        return false;
      }

      // Check file extension
      final extension = path.extension(imageFile.path).toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
      if (!allowedExtensions.contains(extension)) {
        debugPrint('Invalid image file extension: $extension');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating image file: $e');
      return false;
    }
  }

  /// Get image file size in MB
  double getImageFileSize(File imageFile) {
    try {
      final bytes = imageFile.lengthSync();
      return bytes / (1024 * 1024);
    } catch (e) {
      debugPrint('Error getting image file size: $e');
      return 0.0;
    }
  }

  /// Get image file extension
  String getImageFileExtension(File imageFile) {
    try {
      return path.extension(imageFile.path).toLowerCase();
    } catch (e) {
      debugPrint('Error getting image file extension: $e');
      return '';
    }
  }

  /// Get storage bucket name (for debugging)
  String getStorageBucket() {
    try {
      return _storage.ref().bucket;
    } catch (e) {
      debugPrint('Error getting storage bucket: $e');
      return 'Error: $e';
    }
  }

  /// Test storage connection
  Future<bool> testStorageConnection() async {
    try {
      final bucket = _storage.ref().bucket;
      debugPrint('Storage bucket: $bucket');
      return true;
    } catch (e) {
      debugPrint('Storage connection test failed: $e');
      return false;
    }
  }
}
