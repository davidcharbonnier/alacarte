# Settings System Architecture

À la carte features a comprehensive, modular settings system with dedicated privacy controls and reusable UI components.

## 🏗️ Architecture Overview

### **Two-Screen Settings Architecture**

```
Settings Entry Points:
├── User Profile Dropdown → Settings → User Settings Screen
│   ├── App Preferences (Theme, Language)
│   ├── Profile Management (Display Name)
│   ├── Privacy Settings Navigation
│   └── Account Management (Delete Account)
│
└── User Profile Dropdown → Settings → Privacy Settings → Privacy Settings Screen
    ├── Privacy Overview (Sharing Statistics)
    ├── Discovery Settings (User Discoverability)
    ├── Bulk Privacy Actions (Make All Private, Remove Users)
    └── Individual Rating Management (Progressive Loading)
```

### **Settings Widget Library**

À la carte includes a comprehensive widget library for consistent settings UI:

```
lib/widgets/settings/
├── settings_section_header.dart    # Reusable section headers with icons
├── settings_row.dart              # Flexible settings rows with trailing widgets
├── language_toggle.dart           # Dual-language selector (EN/FR)
├── profile_info_widget.dart       # Inline editable profile display
├── loading_banner.dart            # Contextual loading indicators
├── bulk_action_button.dart        # Privacy action buttons
└── rating_item_card.dart          # Rating display with type badges
```

## 🎯 User Settings Screen

### **Features**
- **App Preferences**: Dark mode toggle, language selection (FR/EN)
- **Profile Management**: Inline display name editing with real-time validation
- **Privacy Navigation**: Direct access to comprehensive privacy controls
- **Account Management**: Secure account deletion with confirmation dialogs
- **About Section**: App version and privacy policy information

### **Implementation Highlights**
```dart
// Clean, component-based structure
SettingsSectionHeader(icon: Icons.tune, title: context.l10n.appPreferences),
SettingsRow(
  icon: Icons.dark_mode,
  title: context.l10n.darkMode,
  subtitle: context.l10n.darkModeDescription,
  trailing: Switch(value: isDarkMode, onChanged: toggleDarkMode),
),
LanguageToggle(), // Reusable component
ProfileInfoWidget(user: user, onSaveDisplayName: saveDisplayName), // Inline editing
```

### **Design Principles**
- **Single Card Layout**: All settings organized in one streamlined card
- **Logical Grouping**: App preferences, profile, account, and about sections
- **Minimal Redundancy**: Privacy settings delegated to dedicated screen
- **Consistent Styling**: Uses settings widget library for uniformity

## 🛡️ Privacy Settings Screen

### **Features**
- **Privacy Overview**: Visual sharing activity summary with statistics
- **Discovery Settings**: Control user discoverability for sharing operations
- **Bulk Privacy Actions**: Make all ratings private or remove specific users
- **Individual Rating Management**: Manage sharing for specific ratings
- **Progressive Item Loading**: Smart loading of missing item data
- **Direct Sharing Access**: Open sharing dialogs directly from privacy settings

### **Progressive Item Loading System**

The privacy settings screen features an innovative progressive loading system for multi-item type support:

#### **Architecture**
```dart
// Progressive loading with multi-item type support
class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  // Track loaded items by type - easily extensible
  final Map<String, Set<int>> _loadedItemIds = {
    'cheese': <int>{},
    // Future: 'wine': <int>{}, 'beer': <int>{}, etc.
  };
  
  // Generic loading for any item type
  Future<void> _loadItemsByType(Map<String, Set<int>> missingItems) async {
    switch (itemType) {
      case 'cheese':
        await ref.read(cheeseItemProvider.notifier).loadSpecificItems(itemIds);
        break;
      // Future: Add wine, beer, coffee support
    }
  }
}
```

#### **User Experience Flow**
1. **Immediate Display**: Shows localized fallbacks (\"fromage #1\")
2. **Background Loading**: Fetches missing item data automatically
3. **Progressive Enhancement**: Updates to real names (\"Cheddar (Hard)\")
4. **Loading Feedback**: Shows loading banners and item-level indicators
5. **Type Differentiation**: Small type badges ([FROMAGE]) for multi-item support

#### **Benefits**
- **Zero Backend Dependencies**: Uses existing generic item providers
- **Infinite Scalability**: Works with any future item type
- **Great Performance**: Only loads missing data, leverages existing caches
- **Excellent UX**: Immediate display with progressive enhancement
- **Future-Proof**: Adding wine/beer requires minimal code changes

### **Multi-Item Type Support**

#### **Type Badges**
```dart
// Small, neutral type badges for visual differentiation
Container(
  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
  decoration: BoxDecoration(
    color: Theme.outline.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(2),
  ),
  child: Text(
    itemType.toUpperCase(), // [FROMAGE], [VIN], [BIÈRE]
    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
  ),
)
```

#### **Extensible Design**
Adding new item types requires updates in just 3 locations:
1. **`_loadItemsByType()`** - Add new case for loading provider
2. **`_isItemDataMissing()`** - Add new case for data detection
3. **`_getLocalizedRatingDisplayTitle()`** - Add new cache lookup

## 🧩 Settings Widget Library

### **Component Overview**

#### **SettingsSectionHeader**
```dart
SettingsSectionHeader(
  icon: Icons.shield,
  title: context.l10n.privacyOverview,
  iconColor: AppConstants.primaryColor, // Optional
  textColor: AppConstants.primaryColor, // Optional
)
```

#### **SettingsRow**
```dart
SettingsRow(
  icon: Icons.dark_mode,
  title: context.l10n.darkMode,
  subtitle: context.l10n.darkModeDescription,
  trailing: Switch(...), // Optional
  onTap: () => navigateToDetail(), // Optional
  showArrow: true, // Optional
  isDestructive: false, // Optional - for delete actions
)
```

#### **LanguageToggle**
```dart
const LanguageToggle() // Self-contained FR/EN toggle
```

#### **ProfileInfoWidget**
```dart
ProfileInfoWidget(
  user: currentUser,
  onSaveDisplayName: (displayName) async {
    await authProvider.updateDisplayName(displayName);
  },
)
```

#### **LoadingBanner**
```dart
LoadingBanner(
  message: context.l10n.loadingItemDetails,
  backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1), // Optional
  textColor: AppConstants.primaryColor, // Optional
)
```

#### **BulkActionButton**
```dart
BulkActionButton(
  icon: Icons.lock,
  title: context.l10n.makeAllRatingsPrivate,
  subtitle: context.l10n.makeAllRatingsPrivateDescription,
  buttonColor: AppConstants.warningColor,
  onPressed: () => showMakeAllPrivateDialog(),
  isComingSoon: false, // Optional
)
```

#### **RatingItemCard**
```dart
RatingItemCard(
  rating: rating,
  getDisplayTitle: (rating) => getLocalizedTitle(rating),
  getItemTypeDisplayName: (type) => getTypeDisplayName(type),
  onManageSharing: () => openSharingDialog(rating),
)
```

### **Design Principles**

#### **Consistency**
- All settings components follow the same visual language
- Consistent spacing, colors, and typography
- Standardized interaction patterns

#### **Reusability**
- Components work across different settings screens
- Configurable styling and behavior
- No hardcoded dependencies

#### **Accessibility**
- Proper semantic markup for screen readers
- Keyboard navigation support
- Sufficient color contrast ratios

## 🎨 Visual Design

### **Settings Hierarchy**

#### **User Settings (General)**
```
📱 App Preferences
  ├── 🌙 Dark Mode [Toggle]
  └── 🌍 Display Language [EN/FR Toggle]

👤 Profile & Account  
  ├── 📝 Profile Info [Inline Editing]
  ├── 🛡️ Privacy Settings [→ Navigate]
  └── 🗑️ Delete Account [Destructive Action]

ℹ️ About
  ├── 📋 App Version [Read-only]
  └── 🔒 Privacy Policy [Dialog]
```

#### **Privacy Settings (Specialized)**
```
🛡️ Privacy Overview
  └── 📊 Sharing Activity Summary

🔍 Discovery Settings
  └── 👁️ Discoverable for Sharing [Toggle]

🔒 Bulk Privacy Actions
  ├── 🔐 Make All Ratings Private [Action Button]
  └── 👤 Remove Person from All Shares [Action Button]

📋 Individual Rating Management
  ├── 🧀 Rating Items with Type Badges [FROMAGE]
  ├── 🚀 Progressive Loading [Background Enhancement]
  └── 👥 Direct Sharing Access [Dialog Integration]
```

### **Visual Differentiation**

#### **Type Badges**
- **Minimal Design**: Small, neutral badges with subtle background
- **Multi-Language**: Automatically localized (FROMAGE/CHEESE)
- **Future-Ready**: Supports [VIN], [BIÈRE], [CAFÉ] when added
- **Consistent Styling**: Same design language across all item types

#### **Loading States**
- **Contextual Banners**: Show loading status without blocking UI
- **Progressive Enhancement**: Items update from fallbacks to real names
- **Item-Level Indicators**: Show loading state per item when fetching

## 🚀 Implementation Benefits

### **Code Quality**
- **Reduced Duplication**: Settings components reused across screens
- **Better Testing**: Individual widgets can be unit tested
- **Cleaner Architecture**: Screen files focus on business logic
- **Maintainable**: Easy to modify styling in one location

### **Developer Experience**
- **Faster Development**: New settings screens compose quickly
- **Consistent Patterns**: Same component usage patterns
- **Easy Customization**: Components accept styling parameters
- **Clear Documentation**: Each component has clear interface

### **User Experience**
- **Consistent Interface**: Same look and feel across all settings
- **Professional Polish**: High-quality components throughout
- **Smooth Interactions**: AnimatedSwitcher and loading states
- **Accessible Design**: Screen reader and keyboard support

## 🔧 Usage Examples

### **Creating New Settings Screens**
```dart
// New settings screen using the widget library
class NotificationSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Card(
        child: Column(
          children: [
            SettingsSectionHeader(
              icon: Icons.notifications,
              title: 'Notification Settings',
            ),
            SettingsRow(
              icon: Icons.email,
              title: 'Email Notifications',
              subtitle: 'Receive email updates',
              trailing: Switch(...),
            ),
            SettingsRow(
              icon: Icons.push_pin,
              title: 'Push Notifications',
              subtitle: 'Mobile push notifications',
              trailing: Switch(...),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Adding Item Type Support**
```dart
// Extending privacy settings for wine support
String _getItemTypeDisplayName(String itemType) {
  switch (itemType) {
    case 'cheese':
      return context.l10n.cheese;
    case 'wine':          // ← Just add this
      return 'Vin';       // ← And this
    default:
      return itemType;
  }
}

// Progressive loading automatically handles new types
case 'wine':                                                    // ← Add case
  await ref.read(wineItemProvider.notifier).loadSpecificItems(itemIds); // ← Use provider
  _loadedItemIds['wine']!.addAll(itemIds);                    // ← Track loading
  break;
```

## 📱 Mobile Considerations

### **Responsive Design**
- **Adaptive layouts** work on mobile, tablet, and desktop
- **Touch-friendly** buttons and interactive elements
- **Collapsible sections** for mobile space efficiency
- **Proper spacing** for thumb navigation

### **Performance**
- **Lazy loading** of widget components
- **Efficient rebuilds** with targeted state management
- **Memory optimization** through widget reuse
- **Battery efficiency** with minimal background operations

## 🎯 Future Enhancements

### **Settings System Expansion**
- **Notification Settings** - Email and push notification preferences
- **Appearance Settings** - Advanced theme customization options
- **Data Management** - Export/import user data functionality
- **Advanced Privacy** - Granular sharing permission controls

### **Widget Library Growth**
- **SettingsToggleSection** - Multiple toggles in one section
- **SettingsSlider** - Numeric preference controls
- **SettingsColorPicker** - Theme color customization
- **SettingsDatePicker** - Date/time preference selection

### **Progressive Loading Evolution**
- **Background Sync** - Automatic data updates without user interaction
- **Predictive Loading** - Load likely-needed data before user requests
- **Batch Optimization** - Group API calls for better performance
- **Offline Persistence** - Store loaded item data for offline access

The settings system provides a solid foundation for user preference management while maintaining excellent code quality and user experience standards.
