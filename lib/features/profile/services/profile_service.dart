import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseService _firebaseService = FirebaseService();
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

      // Retry logic for Firestore unavailable errors
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
          
          // Wait before retrying
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

      // Retry logic for Firestore unavailable errors
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
          
          // Wait before retrying
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
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final currentProfile = await getProfile();
      if (currentProfile == null) return null;

      final updatedProfile = currentProfile.copyWith(
        name: name,
        weight: weight,
        updatedAt: DateTime.now(),
      );

      await _profilesCollection.doc(user.uid).update(updatedProfile.toMap());
      return updatedProfile;
    } catch (e) {
      debugPrint('Error updating profile: $e');
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
