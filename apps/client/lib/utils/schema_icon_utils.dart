import 'package:flutter/material.dart';

class SchemaIconUtils {
  static final Map<String, IconData> _iconMap = {
    'LocalPizza': Icons.local_pizza,
    'LocalBar': Icons.local_bar,
    'WineBar': Icons.wine_bar,
    'LocalCafe': Icons.local_cafe,
    'Whatshot': Icons.whatshot,
    'Egg': Icons.egg,
    'Fastfood': Icons.fastfood,
    'Restaurant': Icons.restaurant,
    'LocalDining': Icons.local_dining,
    'Cake': Icons.cake,
    'Icecream': Icons.icecream,
    'Bakery': Icons.bakery_dining,
    'Liquor': Icons.liquor,
    'LocalFlorist': Icons.local_florist,
    'Grass': Icons.grass,
    'Spa': Icons.spa,
    'Science': Icons.science,
    'Bio': Icons.biotech,
    'Help': Icons.help,
    'HelpOutline': Icons.help_outline,
    'Star': Icons.star,
    'StarOutline': Icons.star_outline,
    'Favorite': Icons.favorite,
    'FavoriteOutline': Icons.favorite_border,
    'Check': Icons.check,
    'CheckCircle': Icons.check_circle,
    'Add': Icons.add,
    'Edit': Icons.edit,
    'Delete': Icons.delete,
    'Search': Icons.search,
    'Filter': Icons.filter,
    'Sort': Icons.sort,
    'List': Icons.list,
    'Grid': Icons.grid_view,
    'Settings': Icons.settings,
    'Info': Icons.info,
    'Warning': Icons.warning,
    'Error': Icons.error,
    'Success': Icons.check_circle,
    'Category': Icons.category,
    'Tag': Icons.tag,
    'Label': Icons.label,
    'Description': Icons.description,
    'Image': Icons.image,
    'Photo': Icons.photo,
    'Camera': Icons.camera,
    'Place': Icons.place,
    'Location': Icons.location_on,
    'Public': Icons.public,
    'Business': Icons.business,
    'Factory': Icons.factory,
    'Store': Icons.store,
    'ShoppingCart': Icons.shopping_cart,
    'Person': Icons.person,
    'Group': Icons.group,
    'Home': Icons.home,
    'Work': Icons.work,
    'Build': Icons.build,
    'Code': Icons.code,
    'Cloud': Icons.cloud,
    'Download': Icons.download,
    'Upload': Icons.upload,
    'Share': Icons.share,
    'Link': Icons.link,
    'Attach': Icons.attach_file,
    'Lock': Icons.lock,
    'Visibility': Icons.visibility,
    'VisibilityOff': Icons.visibility_off,
  };

  static IconData getIcon(String iconName) {
    return _iconMap[iconName] ?? Icons.help_outline;
  }

  static Color parseColor(String colorHex) {
    try {
      final hex = colorHex.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return Colors.grey;
  }

  static bool isColorLight(String colorHex) {
    final color = parseColor(colorHex);
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  static Color getContrastColor(String colorHex) {
    return isColorLight(colorHex) ? Colors.black : Colors.white;
  }
}
