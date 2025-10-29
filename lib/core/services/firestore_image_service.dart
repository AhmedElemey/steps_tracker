import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_service.dart';

class FirestoreImageService {
  static final FirestoreImageService _instance = FirestoreImageService._internal();
  factory FirestoreImageService() => _instance;
  FirestoreImageService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      if (!_validateImageFile(imageFile)) {
        debugPrint('Invalid image file');
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      final imageId = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      
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

      return 'firestore://$imageId';
    } catch (e) {
      debugPrint('Error uploading profile image to Firestore: $e');
      return null;
    }
  }

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

  bool _validateImageFile(File imageFile) {
    try {
      if (!imageFile.existsSync()) {
        debugPrint('Image file does not exist');
        return false;
      }

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
