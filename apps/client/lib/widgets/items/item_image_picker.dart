import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alc_client/flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/rateable_item.dart';
import '../../utils/constants.dart';

/// Image picker widget for item forms
class ItemImagePicker extends StatelessWidget {
  final String? currentImageUrl;
  final File? selectedImage;
  final String itemType;
  final bool enabled;
  final Function(File?) onImageSelected;
  final VoidCallback? onImageRemoved;

  const ItemImagePicker({
    super.key,
    this.currentImageUrl,
    this.selectedImage,
    required this.itemType,
    required this.enabled,
    required this.onImageSelected,
    this.onImageRemoved,
  });

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // Show options: camera or gallery
    final l10n = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      onImageSelected(File(image.path));
    }
  }

  Future<void> _confirmRemoveImage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeImage),
        content: Text(l10n.removeImageConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange[700]),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true && onImageRemoved != null) {
      onImageRemoved!();
      onImageSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImage =
        selectedImage != null ||
        (currentImageUrl != null && currentImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: AppConstants.iconS,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              '${l10n.imageLabel}:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const Spacer(),
            Text(
              l10n.optional,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),

        // Image preview or placeholder
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.grey[100]
                  : ItemTypeHelper.getItemTypeColor(itemType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: hasImage
                  ? (selectedImage != null
                        ? Image.file(selectedImage!, fit: BoxFit.contain)
                        : Image.network(
                            currentImageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder(context);
                            },
                          ))
                  : _buildPlaceholder(context),
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacingM),

        // Pick/Change image button
        if (enabled)
          Center(
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(context),
                  icon: Icon(
                    hasImage ? Icons.edit : Icons.add_photo_alternate,
                    size: AppConstants.iconM,
                  ),
                  label: Text(hasImage ? l10n.changeImage : l10n.addImage),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: BorderSide(color: AppConstants.primaryColor),
                  ),
                ),
                // Remove image button (only show if image exists)
                if (hasImage && onImageRemoved != null) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  OutlinedButton.icon(
                    onPressed: () => _confirmRemoveImage(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: AppConstants.iconM,
                    ),
                    label: Text(l10n.removeImage),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[700]!),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ItemTypeHelper.getItemTypeIcon(itemType),
            size: 64,
            color: ItemTypeHelper.getItemTypeColor(itemType).withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noImage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: AppConstants.fontS,
            ),
          ),
        ],
      ),
    );
  }
}
