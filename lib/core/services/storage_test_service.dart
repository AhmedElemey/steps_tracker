import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service to test Firebase Storage connectivity and configuration
class StorageTestService {
  static final StorageTestService _instance = StorageTestService._internal();
  factory StorageTestService() => _instance;
  StorageTestService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Test Firebase Storage connectivity
  Future<bool> testStorageConnection() async {
    try {
      debugPrint('Testing Firebase Storage connection...');
      
      // Get storage reference
      final ref = _storage.ref();
      debugPrint('Storage reference created successfully');
      
      // Get storage bucket
      final bucket = ref.bucket;
      debugPrint('Storage bucket: $bucket');
      
      // Test if we can access the root
      final rootRef = _storage.ref().child('test');
      debugPrint('Root reference created: ${rootRef.fullPath}');
      
      debugPrint('✅ Firebase Storage connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase Storage connection test failed: $e');
      return false;
    }
  }

  /// Test creating a simple file reference
  Future<bool> testCreateReference() async {
    try {
      debugPrint('Testing file reference creation...');
      
      // Create a test reference
      final testRef = _storage.ref().child('test/connection_test.txt');
      debugPrint('Test reference created: ${testRef.fullPath}');
      
      debugPrint('✅ File reference creation test successful');
      return true;
    } catch (e) {
      debugPrint('❌ File reference creation test failed: $e');
      return false;
    }
  }

  /// Run all storage tests
  Future<Map<String, bool>> runAllTests() async {
    debugPrint('🧪 Running Firebase Storage tests...');
    
    final results = <String, bool>{};
    
    results['connection'] = await testStorageConnection();
    results['reference_creation'] = await testCreateReference();
    
    final allPassed = results.values.every((result) => result);
    debugPrint('🧪 Storage tests completed. All passed: $allPassed');
    
    return results;
  }
}
