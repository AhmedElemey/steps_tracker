import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_service.dart';

/// Alternative image service using Firestore for storage
/// This service stores images as base64 strings in Firestore
/// Use this when Firebase Storage is not available (free tier)
class FirestoreImageService {
  static final FirestoreImageService _instance = FirestoreImageService._internal();
  factory FirestoreImageService() => _instance;
  FirestoreImageService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512, // Smaller size for base64 storage
        maxHeight: 512,
        imageQuality: 70, // Lower quality to reduce size
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

  /// Upload profile image as base64 to Firestore
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      // Validate image file
      if (!_validateImageFile(imageFile)) {
        debugPrint('Invalid image file');
        return null;
      }

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Create a unique identifier
      final imageId = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Store in Firestore
      await _firestore
          .collection('user_images')
          .doc(imageId)
          .set({
        'userId': user.uid,
        'imageData': base64String,
        'contentType': 'image/jpeg',
        'size': bytes.length,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      // Return the image ID as the "URL"
      return 'firestore://$imageId';
    } catch (e) {
      debugPrint('Error uploading profile image to Firestore: $e');
      return null;
    }
  }

  /// Get profile image from Firestore
  Future<String?> getProfileImage(String imageId) async {
    try {
      if (!imageId.startsWith('firestore://')) {
        return null;
      }

      final id = imageId.replaceFirst('firestore://', '');
      final doc = await _firestore
          .collection('user_images')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['imageData'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile image from Firestore: $e');
      return null;
    }
  }

  /// Delete profile image from Firestore
  Future<bool> deleteProfileImage(String imageId) async {
    try {
      if (!imageId.startsWith('firestore://')) {
        return false;
      }

      final id = imageId.replaceFirst('firestore://', '');
      await _firestore
          .collection('user_images')
          .doc(id)
          .delete();

      debugPrint('Profile image deleted from Firestore');
      return true;
    } catch (e) {
      debugPrint('Error deleting profile image from Firestore: $e');
      return false;
    }
  }

  /// Validate image file
  bool _validateImageFile(File imageFile) {
    try {
      // Check if file exists
      if (!imageFile.existsSync()) {
        debugPrint('Image file does not exist');
        return false;
      }

      // Check file size (max 1MB for base64 storage)
      final fileSize = imageFile.lengthSync();
      const maxSize = 1024 * 1024; // 1MB
      if (fileSize > maxSize) {
        debugPrint('Image file is too large: ${fileSize / 1024}KB');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating image file: $e');
      return false;
    }
  }

  /// Get image file size in KB
  double getImageFileSize(File imageFile) {
    try {
      final bytes = imageFile.lengthSync();
      return bytes / 1024;
    } catch (e) {
      debugPrint('Error getting image file size: $e');
      return 0.0;
    }
  }
}
