import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../widgets/common_widgets.dart';

/// A widget for uploading profile images
class ImageUploadWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String gender;
  final Function(XFile) onImageSelected;
  final Function()? onImageRemoved;
  final double size;

  const ImageUploadWidget({
    super.key,
    this.currentImageUrl,
    required this.gender,
    required this.onImageSelected,
    this.onImageRemoved,
    this.size = AppSizing.avatarLg,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isUploading = true;
        });

        await widget.onImageSelected(image);

        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kDividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Choose Photo Source',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
                  ),
                  child: const Icon(Icons.camera_alt, color: kPrimaryColor),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
                  ),
                  child: const Icon(Icons.photo_library, color: kSecondaryColor),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from existing photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if ((widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) ||
                  _selectedImage != null) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: kErrorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
                    ),
                    child: const Icon(Icons.delete, color: kErrorColor),
                  ),
                  title: const Text('Remove Photo'),
                  subtitle: const Text('Delete current profile photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                    if (widget.onImageRemoved != null) {
                      widget.onImageRemoved!();
                    }
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Avatar display
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: kPrimaryColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildAvatarContent(),
          ),
        ),

        // Upload indicator
        if (_isUploading)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),

        // Edit icon button
        if (!_isUploading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: kPrimaryColor,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: _showImageSourceDialog,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    Icons.camera_alt,
                    size: widget.size / 5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    // Show newly selected image
    if (_selectedImage != null) {
      return CircleAvatar(
        radius: widget.size / 2,
        backgroundImage: kIsWeb
            ? NetworkImage(_selectedImage!.path)
            : FileImage(File(_selectedImage!.path)) as ImageProvider,
      );
    }

    // Show current image from URL
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return AppAvatar(
        imageUrl: widget.currentImageUrl,
        gender: widget.gender,
        size: widget.size,
      );
    }

    // Show placeholder
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: getGenderColor(widget.gender, light: true),
      child: Icon(
        widget.gender.toLowerCase() == 'male' ? Icons.person : Icons.person_outline,
        size: widget.size / 2,
        color: getGenderColor(widget.gender),
      ),
    );
  }
}

/// A simple image preview dialog
class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  static void show(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(
        imageUrl: imageUrl,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(title),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Flexible(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
