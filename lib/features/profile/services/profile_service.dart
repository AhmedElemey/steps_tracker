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
    String? profileImageUrl,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final profile = UserProfile(
        id: user.uid,
        name: name,
        weight: weight,
        profileImageUrl: profileImageUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _profilesCollection.doc(user.uid).set(profile.toMap());
      return profile;
    } catch (e) {
      debugPrint('Error creating profile: $e');
      return null;
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final doc = await _profilesCollection.doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile: $e');
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
