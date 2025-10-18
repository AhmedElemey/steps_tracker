import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  User? get currentUser => auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _configureFirestore();
  }

  void _configureFirestore() {
    // Enable offline persistence
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await auth.signInAnonymously();
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Stream<User?> get authStateChanges => auth.authStateChanges();
}
