import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const LocationPermissionDialog({
    super.key,
    required this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: Color(0xFF2E7D32),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Location Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To accurately track your steps, we need access to your location.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why we need location:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• More accurate step counting\n'
                  '• Better activity recognition\n'
                  '• Improved walking detection',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPermissionDenied?.call();
          },
          child: const Text(
            'Not Now',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _requestLocationPermission();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Allow Location',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      final locationStatus = await Permission.location.request();
      
      final activityStatus = await Permission.activityRecognition.request();
      
      if (locationStatus.isGranted && activityStatus.isGranted) {
        onPermissionGranted();
      } else {
        onPermissionDenied?.call();
      }
    } catch (e) {
      onPermissionDenied?.call();
    }
  }
}

class LocationPermissionService {
  static Future<bool> checkLocationPermission() async {
    final locationStatus = await Permission.location.status;
    final activityStatus = await Permission.activityRecognition.status;
    
    return locationStatus.isGranted && activityStatus.isGranted;
  }
  
  static Future<bool> requestLocationPermission() async {
    final locationStatus = await Permission.location.request();
    final activityStatus = await Permission.activityRecognition.request();
    
    return locationStatus.isGranted && activityStatus.isGranted;
  }
}
