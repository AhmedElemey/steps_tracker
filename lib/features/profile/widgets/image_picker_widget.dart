import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/firestore_image_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

/// Widget for selecting and uploading profile images
/// 
/// This widget provides:
/// - Image selection from gallery or camera
/// - Image preview
/// - Upload progress indicator
/// - Error handling
/// - Image validation
class ImagePickerWidget extends StatefulWidget {
  final UserProfile? userProfile;
  final Function(UserProfile?)? onImageUpdated;
  final double size;
  final bool showUploadButton;

  const ImagePickerWidget({
    super.key,
    this.userProfile,
    this.onImageUpdated,
    this.size = 120.0,
    this.showUploadButton = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageService _imageService = ImageService();
  final ProfileService _profileService = ProfileService();
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile Image Display
        GestureDetector(
          onTap: widget.showUploadButton ? _showImagePickerDialog : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2E7D32),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildProfileImage(colorScheme),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Upload Progress
        if (_isUploading) ...[
          SizedBox(
            width: widget.size,
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: colorScheme.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        
        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        // Upload Button
        if (widget.showUploadButton && !_isUploading) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showImagePickerDialog,
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Change Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileImage(ColorScheme colorScheme) {
    if (_isUploading) {
      return Container(
        color: colorScheme.surfaceContainer,
        child: Center(
          child: CircularProgressIndicator(
            value: _uploadProgress,
            backgroundColor: colorScheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    if (widget.userProfile?.profileImageUrl != null) {
      final imageUrl = widget.userProfile!.profileImageUrl!;
      
      // Handle Firestore base64 images
      if (imageUrl.startsWith('firestore://')) {
        return FutureBuilder<String?>(
          future: _getFirestoreImage(imageUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: colorScheme.surfaceContainer,
                child: Center(
                  child: CircularProgressIndicator(
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ),
              );
            }
            
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                base64Decode(snapshot.data!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(colorScheme);
                },
              );
            }
            
            return _buildDefaultAvatar(colorScheme);
          },
        );
      }
      
      // Handle Firebase Storage URLs
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: colorScheme.surfaceContainer,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                backgroundColor: colorScheme.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(colorScheme);
        },
      );
    }

    return _buildDefaultAvatar(colorScheme);
  }

  Future<String?> _getFirestoreImage(String imageId) async {
    try {
      final firestoreImageService = FirestoreImageService();
      return await firestoreImageService.getProfileImage(imageId);
    } catch (e) {
      debugPrint('Error getting Firestore image: $e');
      return null;
    }
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildImagePickerBottomSheet(),
    );
  }

  Widget _buildImagePickerBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Select Profile Photo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera option
              _buildImageSourceOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              
              // Gallery option
              _buildImageSourceOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Delete current image option
          if (widget.userProfile?.profileImageUrl != null) ...[
            const Divider(),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: colorScheme.error,
              ),
              title: Text(
                'Remove Photo',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteCurrentImage();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _errorMessage = null;
      });

      // Pick image
      final imageFile = await _imageService.pickImage(source: source);
      if (imageFile == null) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'No image selected';
        });
        return;
      }

      // Validate image
      if (!_imageService.validateImageFile(imageFile)) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Invalid image file';
        });
        return;
      }

      // Upload image with progress tracking
      final updatedProfile = await _profileService.uploadProfileImageWithProgress(
        imageFile,
        (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (updatedProfile != null) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _errorMessage = null;
        });
        
        widget.onImageUpdated?.call(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _errorMessage = 'Failed to upload image';
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteCurrentImage() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final updatedProfile = await _profileService.deleteProfileImage();
      
      if (updatedProfile != null) {
        setState(() {
          _isUploading = false;
          _errorMessage = null;
        });
        
        widget.onImageUpdated?.call(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to remove image';
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
}
