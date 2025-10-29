import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'firebase_service.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      debugPrint('Testing Firebase Storage connection...');
      final bucket = _storage.ref().bucket;
      debugPrint('Storage bucket: $bucket');

      if (!validateImageFile(imageFile)) {
        debugPrint('Invalid image file');
        return null;
      }

      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('user_profiles/${user.uid}/$fileName');
      
      debugPrint('Storage reference path: ${storageRef.fullPath}');

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

      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      
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

      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('user_profiles/${user.uid}/$fileName');

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

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      final ref = _storage.refFromURL(imageUrl);
      
      await ref.delete();
      
      debugPrint('Profile image deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return false;
    }
  }

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

  Future<void> cleanupOldProfileImages(String currentImageUrl) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      final listRef = _storage.ref().child('user_profiles/${user.uid}');
      final result = await listRef.listAll();

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

  Future<File?> compressImage(File imageFile) async {
    try {
      return imageFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  bool validateImageFile(File imageFile) {
    try {
      if (!imageFile.existsSync()) {
        debugPrint('Image file does not exist');
        return false;
      }

      final fileSize = imageFile.lengthSync();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        debugPrint('Image file is too large: ${fileSize / 1024 / 1024}MB');
        return false;
      }

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

  double getImageFileSize(File imageFile) {
    try {
      final bytes = imageFile.lengthSync();
      return bytes / (1024 * 1024);
    } catch (e) {
      debugPrint('Error getting image file size: $e');
      return 0.0;
    }
  }

  String getImageFileExtension(File imageFile) {
    try {
      return path.extension(imageFile.path).toLowerCase();
    } catch (e) {
      debugPrint('Error getting image file extension: $e');
      return '';
    }
  }

  String getStorageBucket() {
    try {
      return _storage.ref().bucket;
    } catch (e) {
      debugPrint('Error getting storage bucket: $e');
      return 'Error: $e';
    }
  }

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
