import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/services/profile_service.dart';

class AuthController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final ProfileService _profileService = ProfileService();

  User? _user;
  UserProfile? _userProfile;
  bool _isInitialLoading = true;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isInitialLoading || _isLoading;
  String get errorMessage => _errorMessage;
  bool get isSignedIn => _user != null;
  bool get hasProfile => _userProfile != null;

  AuthController() {
    _initialize();
  }

  Future<void> _initialize() async {
    _user = _firebaseService.currentUser;
    if (_user != null) {
      await _loadUserProfile();
    }
    
    _isInitialLoading = false;
    notifyListeners();
    
    _firebaseService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    
    try {
      _userProfile = await _profileService.getProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final userCredential = await _firebaseService.signInAnonymously();
      if (userCredential != null) {
        _user = userCredential.user;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to sign in anonymously. Please check your internet connection and try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      _errorMessage = 'Error signing in: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProfile({
    required String name,
    required double weight,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final profile = await _profileService.createProfile(
        name: name,
        weight: weight,
      );

      if (profile != null) {
        _userProfile = profile;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating profile: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      await _firebaseService.signOut();
      _user = null;
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error signing out: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }
}
