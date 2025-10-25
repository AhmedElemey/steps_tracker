import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Simple test to verify Firebase Storage is working
class FirebaseStorageTest {
  static Future<void> runStorageTest() async {
    debugPrint('🧪 Starting Firebase Storage Test...');
    
    try {
      // Test 1: Get storage instance
      debugPrint('Test 1: Getting Firebase Storage instance...');
      final storage = FirebaseStorage.instance;
      debugPrint('✅ Storage instance created');
      
      // Test 2: Get bucket info
      debugPrint('Test 2: Getting storage bucket...');
      final bucket = storage.ref().bucket;
      debugPrint('✅ Storage bucket: $bucket');
      
      // Test 3: Create a reference
      debugPrint('Test 3: Creating storage reference...');
      final testRef = storage.ref().child('test/connection_test.txt');
      debugPrint('✅ Test reference created: ${testRef.fullPath}');
      
      // Test 4: Try to upload a simple text file
      debugPrint('Test 4: Testing upload...');
      final testData = 'Hello Firebase Storage!';
      final bytes = Uint8List.fromList(testData.codeUnits);
      
      final uploadTask = testRef.putData(bytes);
      final snapshot = await uploadTask;
      debugPrint('✅ Upload successful');
      
      // Test 5: Get download URL
      debugPrint('Test 5: Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Download URL: $downloadUrl');
      
      // Test 6: Clean up - delete the test file
      debugPrint('Test 6: Cleaning up test file...');
      await snapshot.ref.delete();
      debugPrint('✅ Test file deleted');
      
      debugPrint('🎉 All Firebase Storage tests passed!');
      debugPrint('Firebase Storage is properly configured and working.');
      
    } catch (e) {
      debugPrint('❌ Firebase Storage test failed: $e');
      
      if (e.toString().contains('object-not-found') || 
          e.toString().contains('404') ||
          e.toString().contains('No object exists')) {
        debugPrint('');
        debugPrint('🔧 SOLUTION:');
        debugPrint('Firebase Storage is not enabled in your project.');
        debugPrint('');
        debugPrint('To fix this:');
        debugPrint('1. Go to: https://console.firebase.google.com/');
        debugPrint('2. Select your project: steps-tracker-1760794907');
        debugPrint('3. Click "Storage" in the left sidebar');
        debugPrint('4. Click "Get started" to enable Storage');
        debugPrint('5. Choose "Start in test mode"');
        debugPrint('6. Select a storage location');
        debugPrint('7. Run this test again');
      } else if (e.toString().contains('permission-denied')) {
        debugPrint('');
        debugPrint('🔧 SOLUTION:');
        debugPrint('Firebase Storage security rules are too restrictive.');
        debugPrint('');
        debugPrint('To fix this:');
        debugPrint('1. Go to Firebase Console → Storage → Rules');
        debugPrint('2. Replace the rules with:');
        debugPrint('   rules_version = "2";');
        debugPrint('   service firebase.storage {');
        debugPrint('     match /b/{bucket}/o {');
        debugPrint('       match /{allPaths=**} {');
        debugPrint('         allow read, write: if request.auth != null;');
        debugPrint('       }');
        debugPrint('     }');
        debugPrint('   }');
      } else {
        debugPrint('');
        debugPrint('🔧 SOLUTION:');
        debugPrint('Check your Firebase configuration:');
        debugPrint('1. Verify project ID in firebase_options.dart');
        debugPrint('2. Check internet connection');
        debugPrint('3. Ensure Firebase project is active');
        debugPrint('4. Try running: flutter clean && flutter pub get');
      }
    }
  }
  
  /// Quick test to check if Storage is enabled
  static Future<bool> isStorageEnabled() async {
    try {
      final storage = FirebaseStorage.instance;
      final bucket = storage.ref().bucket;
      debugPrint('Storage bucket: $bucket');
      return bucket.isNotEmpty;
    } catch (e) {
      debugPrint('Storage not enabled: $e');
      return false;
    }
  }
}
