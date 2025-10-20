import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/rateable_item.dart';

/// Reusable widget for displaying item images with proper fallbacks
class ItemImage extends StatelessWidget {
  final String? imageUrl;
  final String itemType;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ItemImage({
    super.key,
    required this.imageUrl,
    required this.itemType,
    this.size = 60,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context, effectiveBorderRadius);
    }

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: fit,
        placeholder: (context, url) =>
            _buildLoadingPlaceholder(context, effectiveBorderRadius),
        errorWidget: (context, url, error) =>
            _buildPlaceholder(context, effectiveBorderRadius),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, BorderRadius borderRadius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ItemTypeHelper.getItemTypeColor(itemType).withValues(alpha: 0.1),
        borderRadius: borderRadius,
      ),
      child: Icon(
        ItemTypeHelper.getItemTypeIcon(itemType),
        size: size * 0.5,
        color: ItemTypeHelper.getItemTypeColor(itemType).withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(
    BuildContext context,
    BorderRadius borderRadius,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Full-size image widget for detail views
class ItemImageFull extends StatelessWidget {
  final String? imageUrl;
  final String itemType;
  final String itemName;
  final double maxHeight;

  const ItemImageFull({
    super.key,
    required this.imageUrl,
    required this.itemType,
    required this.itemName,
    this.maxHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Hero(
        tag: 'item-image-$imageUrl',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.contain,
            maxHeightDiskCache: 1200,
            placeholder: (context, url) => _buildLoadingPlaceholder(context),
            errorWidget: (context, url, error) => _buildPlaceholder(context),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: Hero(
              tag: 'item-image-$imageUrl',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: ItemTypeHelper.getItemTypeColor(itemType).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ItemTypeHelper.getItemTypeIcon(itemType),
              size: 64,
              color: ItemTypeHelper.getItemTypeColor(
                itemType,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No image',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
