import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/firestore_image_service.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final ImageService _imageService = ImageService();
  final FirestoreImageService _firestoreImageService = FirestoreImageService();
  final CollectionReference _profilesCollection = 
      FirebaseFirestore.instance.collection('user_profiles');

  Future<UserProfile?> createProfile({
    required String name,
    required double weight,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final profile = UserProfile(
        id: user.uid,
        name: name,
        weight: weight,
        createdAt: now,
        updatedAt: now,
      );

      int retryCount = 0;
      const maxRetries = 3;
      const retryDelay = Duration(seconds: 2);

      while (retryCount < maxRetries) {
        try {
          await _profilesCollection.doc(user.uid).set(profile.toMap());
          return profile;
        } catch (e) {
          retryCount++;
          debugPrint('Error creating profile (attempt $retryCount): $e');
          
          if (retryCount >= maxRetries) {
            rethrow;
          }
          
          await Future.delayed(retryDelay * retryCount);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error creating profile after retries: $e');
      return null;
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      int retryCount = 0;
      const maxRetries = 3;
      const retryDelay = Duration(seconds: 2);

      while (retryCount < maxRetries) {
        try {
          final doc = await _profilesCollection.doc(user.uid).get();
          if (doc.exists) {
            return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
          }
          return null;
        } catch (e) {
          retryCount++;
          debugPrint('Error getting profile (attempt $retryCount): $e');
          
          if (retryCount >= maxRetries) {
            rethrow;
          }
          
          await Future.delayed(retryDelay * retryCount);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile after retries: $e');
      return null;
    }
  }

  Future<UserProfile?> updateProfile({
    String? name,
    double? weight,
    String? profileImageUrl,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final currentProfile = await getProfile();
      if (currentProfile == null) return null;

      final updatedProfile = currentProfile.copyWith(
        name: name,
        weight: weight,
        profileImageUrl: profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await _profilesCollection.doc(user.uid).update(updatedProfile.toMap());
      return updatedProfile;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return null;
    }
  }

  Future<UserProfile?> uploadProfileImage(File imageFile) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final currentProfile = await getProfile();
      if (currentProfile == null) return null;

      String? imageUrl;
      
      try {
        if (_imageService.validateImageFile(imageFile)) {
          imageUrl = await _imageService.uploadProfileImage(imageFile);
          if (imageUrl != null) {
            debugPrint('✅ Image uploaded to Firebase Storage');
          }
        }
      } catch (e) {
        debugPrint('❌ Firebase Storage failed, trying Firestore: $e');
      }

      if (imageUrl == null) {
        try {
          imageUrl = await _firestoreImageService.uploadProfileImage(imageFile);
          if (imageUrl != null) {
            debugPrint('✅ Image uploaded to Firestore as base64');
          }
        } catch (e) {
          debugPrint('❌ Firestore upload also failed: $e');
        }
      }

      if (imageUrl == null) {
        debugPrint('Failed to upload image to both Storage and Firestore');
        return null;
      }

      final updatedProfile = currentProfile.copyWith(
        profileImageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _profilesCollection.doc(user.uid).update(updatedProfile.toMap());

      if (currentProfile.profileImageUrl != null && 
          currentProfile.profileImageUrl!.startsWith('https://')) {
        try {
          await _imageService.cleanupOldProfileImages(imageUrl);
        } catch (e) {
          debugPrint('Error cleaning up old images: $e');
        }
      }

      return updatedProfile;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<UserProfile?> uploadProfileImageWithProgress(
    File imageFile,
    Function(double progress)? onProgress,
  ) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final currentProfile = await getProfile();
      if (currentProfile == null) return null;

      String? imageUrl;
      
      try {
        if (_imageService.validateImageFile(imageFile)) {
          imageUrl = await _imageService.uploadProfileImageWithProgress(
            imageFile,
            onProgress,
          );
          if (imageUrl != null) {
            debugPrint('✅ Image uploaded to Firebase Storage with progress');
          }
        }
      } catch (e) {
        debugPrint('❌ Firebase Storage failed, trying Firestore: $e');
      }

      if (imageUrl == null) {
        try {
          onProgress?.call(0.5);
          imageUrl = await _firestoreImageService.uploadProfileImage(imageFile);
          onProgress?.call(1.0);
          if (imageUrl != null) {
            debugPrint('✅ Image uploaded to Firestore as base64');
          }
        } catch (e) {
          debugPrint('❌ Firestore upload also failed: $e');
        }
      }

      if (imageUrl == null) {
        debugPrint('Failed to upload image to both Storage and Firestore');
        return null;
      }

      final updatedProfile = currentProfile.copyWith(
        profileImageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _profilesCollection.doc(user.uid).update(updatedProfile.toMap());

      if (currentProfile.profileImageUrl != null && 
          currentProfile.profileImageUrl!.startsWith('https://')) {
        try {
          await _imageService.cleanupOldProfileImages(imageUrl);
        } catch (e) {
          debugPrint('Error cleaning up old images: $e');
        }
      }

      return updatedProfile;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<UserProfile?> deleteProfileImage() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final currentProfile = await getProfile();
      if (currentProfile == null || currentProfile.profileImageUrl == null) {
        return null;
      }

      final imageUrl = currentProfile.profileImageUrl!;
      bool deleted = false;

      if (imageUrl.startsWith('firestore://')) {
        deleted = await _firestoreImageService.deleteProfileImage(imageUrl);
        if (deleted) {
          debugPrint('✅ Image deleted from Firestore');
        }
      } else if (imageUrl.startsWith('https://')) {
        try {
          deleted = await _imageService.deleteProfileImage(imageUrl);
          if (deleted) {
            debugPrint('✅ Image deleted from Firebase Storage');
          }
        } catch (e) {
          debugPrint('❌ Failed to delete from Storage: $e');
        }
      }

      final updatedProfile = currentProfile.copyWith(
        profileImageUrl: null,
        updatedAt: DateTime.now(),
      );

      await _profilesCollection.doc(user.uid).update(updatedProfile.toMap());
      return updatedProfile;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return null;
    }
  }

  Stream<UserProfile?> getProfileStream() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _profilesCollection.doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
