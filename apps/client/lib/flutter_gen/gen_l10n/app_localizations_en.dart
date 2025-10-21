// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'A la carte';

  @override
  String get welcomeTitle => 'Welcome to A la carte';

  @override
  String get welcomeSubtitle => 'Your personal rating and preference hub';

  @override
  String get yourPreferenceLists => 'Your Preference Lists';

  @override
  String get moreCategoriesTitle => 'More Categories';

  @override
  String get moreCategoriesSubtitle => 'Additional categories coming soon';

  @override
  String itemsAvailable(int count) {
    return '$count items available';
  }

  @override
  String inYourList(int count) {
    return '$count in your list';
  }

  @override
  String get cheese => 'Cheese';

  @override
  String get settings => 'Settings';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get checkingConnection => 'Checking connection';

  @override
  String get offlineMessage =>
      'Offline - Your reference lists may not be up to date';

  @override
  String get connectedToAlacarte => 'Connected to A la carte';

  @override
  String get noInternetConnection => 'Connection lost - Working offline';

  @override
  String get userSelection => 'User Selection';

  @override
  String get createUser => 'Create User';

  @override
  String get editUser => 'Edit User';

  @override
  String get userName => 'User Name';

  @override
  String get name => 'Name';

  @override
  String get type => 'Type';

  @override
  String get origin => 'Origin';

  @override
  String get producer => 'Producer';

  @override
  String get description => 'Description';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get create => 'Create';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String allItems(String itemType) {
    return 'All ${itemType}s';
  }

  @override
  String get myList => 'My List';

  @override
  String get rating => 'Rating';

  @override
  String get myRating => 'My Rating';

  @override
  String get sharedRatings => 'Shared Ratings';

  @override
  String get rateItem => 'Rate Item';

  @override
  String get addRating => 'Add Rating';

  @override
  String get editRating => 'Edit Rating';

  @override
  String get notes => 'Notes';

  @override
  String get score => 'Score';

  @override
  String get back => 'Back';

  @override
  String get home => 'Home';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get refresh => 'Refresh';

  @override
  String get chooseProfileSubtitle =>
      'Choose your profile to access your ratings and preferences';

  @override
  String get searchProfiles => 'Search profiles...';

  @override
  String get createNewProfile => 'Create New Profile';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String deleteProfileConfirmation(String profileName) {
    return 'Are you sure you want to delete the profile \"$profileName\"?';
  }

  @override
  String get noProfilesFound => 'No profiles found';

  @override
  String get tryDifferentSearch => 'Try searching with a different name';

  @override
  String currentlyUsing(String userName) {
    return 'Currently using: $userName. Tap a different profile to switch or tap the selected one to continue.';
  }

  @override
  String get offlineProfileChanges =>
      'Offline - Profile changes may not be saved until reconnected';

  @override
  String get createYourProfile => 'Create Your Profile';

  @override
  String get editYourProfile => 'Edit Your Profile';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get profileHelpCreate =>
      'Your profile helps you track your cheese ratings and preferences.';

  @override
  String get profileHelpEdit => 'Update your profile information.';

  @override
  String get currentProfile => 'Current Profile';

  @override
  String get profileManagement => 'Profile Management';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Update your profile information';

  @override
  String get switchProfile => 'Switch Profile';

  @override
  String get switchProfileSubtitle => 'Change to a different profile';

  @override
  String get deleteProfileSubtitle => 'Permanently delete this profile';

  @override
  String get deleteWarning =>
      'This action cannot be undone. All data associated with this profile will be permanently deleted.';

  @override
  String get noProfileSelected =>
      'No profile selected. Please select a profile first.';

  @override
  String get backToApp => 'Back to App';

  @override
  String get noProfilesYet => 'No Profiles Yet';

  @override
  String get noProfilesMessage =>
      'No profiles found. Create your first profile to get started!';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get nameMaxLength => 'Name must be less than 50 characters';

  @override
  String get nameInvalidCharacters =>
      'Name can only contain letters, spaces, hyphens, and apostrophes';

  @override
  String get backToHub => 'Back to Hub';

  @override
  String myItemList(String itemType) {
    return 'My $itemType List';
  }

  @override
  String addItem(String itemType) {
    return 'Add $itemType';
  }

  @override
  String get moreCategoriesComingSoon => 'More Categories Coming Soon';

  @override
  String shared(int count) {
    return 'Shared ($count)';
  }

  @override
  String moreRatings(int count) {
    return '+$count more';
  }

  @override
  String rateThisItem(String itemType) {
    return 'Rate this $itemType';
  }

  @override
  String comingSoon(String itemType) {
    return '$itemType Coming Soon';
  }

  @override
  String noItemsAvailable(String itemType) {
    return 'No ${itemType}s Available';
  }

  @override
  String addFirstItem(String itemType) {
    return 'Add the first $itemType to start building your reference list';
  }

  @override
  String addFirstItemButton(String itemType) {
    return 'Add First $itemType';
  }

  @override
  String yourReferenceList(String itemType) {
    return 'Your $itemType Reference List';
  }

  @override
  String itemsWithRatings(int count) {
    return '$count items with your ratings and recommendations';
  }

  @override
  String yourListEmpty(String itemType) {
    return 'Your $itemType List is Empty';
  }

  @override
  String rateItemsToBuild(String itemType) {
    return 'Rate ${itemType}s to build your reference list';
  }

  @override
  String exploreItems(String itemType) {
    return 'Explore ${itemType}s';
  }

  @override
  String get itemNotFound => 'Item Not Found';

  @override
  String get goBack => 'Go Back';

  @override
  String get offlineRatingData => 'Offline - Rating data may not be up to date';

  @override
  String rateItemName(String itemName) {
    return 'Rate $itemName';
  }

  @override
  String get offlineLoadingMessage =>
      'Loading... Connection required for full functionality';

  @override
  String get connectionError => 'Connection error - Please check your network';

  @override
  String get offlineCachedData => 'Offline mode - Showing cached data';

  @override
  String get myNotes => 'My Notes:';

  @override
  String haventRatedYet(String itemName) {
    return 'You haven\'t rated $itemName yet';
  }

  @override
  String get addRatingToBuild =>
      'Add your rating to build your personal reference list';

  @override
  String get noRatingsYet => 'No Ratings Yet';

  @override
  String beFirstToRate(String itemName) {
    return 'Be the first to rate $itemName';
  }

  @override
  String get communityRatings => 'Community Ratings';

  @override
  String ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ratings',
      one: 'rating',
    );
    return '$count $_temp0';
  }

  @override
  String averageRating(String rating) {
    return 'Average: $rating / 5.0';
  }

  @override
  String mostCommonRating(int stars, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ratings',
      one: 'rating',
    );
    return 'Most common: $stars stars ($count $_temp0)';
  }

  @override
  String get noSharedRatings => 'No Recommendations';

  @override
  String noSharedRatingsMessage(String itemName) {
    return 'No one has shared their recommendations for $itemName with you yet';
  }

  @override
  String profileIdLabel(String id) {
    return 'Profile ID: $id';
  }

  @override
  String get editProfileTooltip => 'Edit Profile';

  @override
  String get deleteProfileTooltip => 'Delete Profile';

  @override
  String get newProfile => 'New';

  @override
  String get originLabel => 'Origin';

  @override
  String get producerLabel => 'Producer';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get initializingApp => 'Initializing A la carte...';

  @override
  String get initializationTakingLonger =>
      'This is taking longer than expected...';

  @override
  String get profileDataCorrupted =>
      'Profile data corrupted. Please select your profile again.';

  @override
  String get profileNotFoundOnServer =>
      'Your profile was not found. Please select a valid profile.';

  @override
  String get yourRating => 'Your Rating';

  @override
  String get selectRating => 'Tap to select rating';

  @override
  String get ratingRequired => 'Please select a rating';

  @override
  String get addNotes => 'Add your notes';

  @override
  String get notesHelper => 'Add your personal notes (optional)';

  @override
  String get saveRating => 'Save Rating';

  @override
  String get ratingCreated => 'Rating saved successfully!';

  @override
  String get couldNotSaveRating => 'Could not save rating. Please try again.';

  @override
  String get offlineRatingCreation =>
      'Offline - Changes may not be saved until reconnected';

  @override
  String get noUserSelected => 'No user selected';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get offlineUserSwitch =>
      'Offline - Rating data not available for this user';

  @override
  String editRatingForItem(String itemName) {
    return 'Edit Rating for $itemName';
  }

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get ratingUpdated => 'Rating updated successfully!';

  @override
  String get couldNotUpdateRating =>
      'Could not update rating. Please try again.';

  @override
  String get offlineRatingEdit =>
      'Offline - Changes may not be saved until reconnected';

  @override
  String get ratingNotFound => 'Rating not found';

  @override
  String get editingRatingFor => 'Editing rating for';

  @override
  String originalRating(double rating) {
    return 'Original rating: $rating stars';
  }

  @override
  String get unsavedChanges => 'You have unsaved changes';

  @override
  String get shareRating => 'Share Rating';

  @override
  String get shareWith => 'Share with...';

  @override
  String get shareRatingWith => 'Share Rating With';

  @override
  String get selectUsersToShare => 'Select users to share this rating with';

  @override
  String get shareRatingSuccess => 'Rating shared successfully!';

  @override
  String get shareRatingError => 'Could not share rating. Please try again.';

  @override
  String sharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'people',
      one: 'person',
    );
    return 'Shared with $count $_temp0';
  }

  @override
  String get shareButtonText => 'Share';

  @override
  String get noUsersAvailable => 'No users available to share with';

  @override
  String get loadingUsers => 'Loading users...';

  @override
  String get recommendations => 'Recommendations';

  @override
  String recommendationsFromFriends(int count) {
    return '$count recommendations from friends';
  }

  @override
  String get itemTypeNotSupported => 'Item type not supported yet';

  @override
  String get ratingNotFoundOrNoPermission =>
      'Rating not found or you do not have permission to edit it';

  @override
  String get noPermissionToEdit =>
      'You do not have permission to edit this rating';

  @override
  String get noNotesAdded => 'No notes added';

  @override
  String userFallback(int userId) {
    return 'User $userId';
  }

  @override
  String get deleteRating => 'Delete Rating';

  @override
  String get deleteRatingConfirmation => 'Delete this rating?';

  @override
  String get deleteRatingWarning => 'This action cannot be undone.';

  @override
  String deleteRatingWithSharing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'people',
      one: 'person',
    );
    return 'This will also remove it from $count $_temp0 who have access to your recommendation.';
  }

  @override
  String get deleteRatingGenericSharing =>
      'If this rating has been shared, it will also be removed from other users\' recommendations.';

  @override
  String get ratingDeleted => 'Rating deleted successfully';

  @override
  String get couldNotDeleteRating =>
      'Could not delete rating. Please try again.';

  @override
  String get makePrivate => 'Make Private';

  @override
  String get noChanges => 'No Changes';

  @override
  String addNewItem(String itemType) {
    return 'Add New $itemType';
  }

  @override
  String editItem(String itemName) {
    return 'Edit $itemName';
  }

  @override
  String createItem(String itemType) {
    return 'Create $itemType';
  }

  @override
  String itemCreated(String itemType) {
    return '$itemType created successfully!';
  }

  @override
  String itemUpdated(String itemType) {
    return '$itemType updated successfully!';
  }

  @override
  String couldNotCreateItem(String itemType) {
    return 'Could not create $itemType. Please try again.';
  }

  @override
  String couldNotUpdateItem(String itemType) {
    return 'Could not update $itemType. Please try again.';
  }

  @override
  String itemNameRequired(String itemType) {
    return '$itemType name is required';
  }

  @override
  String itemNameTooShort(String itemType) {
    return '$itemType name must be at least 2 characters';
  }

  @override
  String itemNameTooLong(String itemType) {
    return '$itemType name must be less than 100 characters';
  }

  @override
  String get typeRequired => 'Type is required';

  @override
  String get originRequired => 'Origin is required';

  @override
  String get producerRequired => 'Producer is required';

  @override
  String get selectType => 'Select type...';

  @override
  String get enterOrigin => 'Enter origin';

  @override
  String get enterProducer => 'Enter producer';

  @override
  String get enterDescription => 'Enter description (optional)';

  @override
  String get descriptionTooLong =>
      'Description must be less than 500 characters';

  @override
  String get offlineItemCreation =>
      'Offline - Item may not be saved until reconnected';

  @override
  String get offlineItemEdit =>
      'Offline - Changes may not be saved until reconnected';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Are you sure you want to go back?';

  @override
  String get discard => 'Discard';

  @override
  String get updateInfoBelow => 'Update the information below';

  @override
  String get fillDetailsToAdd =>
      'Fill in the details to add to your collection';

  @override
  String get saving => 'Saving...';

  @override
  String get cheeseTypeHint => 'e.g. Soft, Hard, Semi-soft, Blue';

  @override
  String enterItemName(String itemType) {
    return 'Enter $itemType name';
  }

  @override
  String optionalFieldHelper(int maxLength) {
    return 'Optional - up to $maxLength characters';
  }

  @override
  String editItemType(String itemType) {
    return 'Edit $itemType';
  }

  @override
  String addNewItemType(String itemType) {
    return 'Add New $itemType';
  }

  @override
  String get optional => 'Optional';

  @override
  String get searchCheeseHint => 'Search cheeses by name, type, origin...';

  @override
  String get noResultsFound => 'No Results Found';

  @override
  String get adjustSearchFilters => 'Try adjusting your search or filters';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String filterBy(String category) {
    return 'Filter by $category';
  }

  @override
  String showingResults(int filtered, int total) {
    return 'Showing $filtered of $total items';
  }

  @override
  String searchItemsByName(String itemType) {
    return 'Search ${itemType}s by name...';
  }

  @override
  String get searchByName => 'Search by name...';

  @override
  String get searchCheeseByNameHint => 'Search cheeses by name...';

  @override
  String get myRatingsFilter => 'My Ratings';

  @override
  String get recommendationsFilter => 'Recommendations';

  @override
  String get ratedFilter => 'Rated';

  @override
  String get unratedFilter => 'Unrated';

  @override
  String get allFilterOption => 'All';

  @override
  String get showFilters => 'Show Filters';

  @override
  String get hideFilters => 'Hide Filters';

  @override
  String get userProfile => 'User Profile';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmation =>
      'Are you sure you want to sign out? You will need to sign in again to access your ratings.';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeDescription => 'Use dark theme throughout the app';

  @override
  String get displayLanguage => 'Display Language';

  @override
  String get displayLanguageDescription => 'Choose your preferred language';

  @override
  String get profileAndAccount => 'Profile & Account';

  @override
  String get displayName => 'Display Name';

  @override
  String get tapToSetDisplayName => 'Tap to set display name';

  @override
  String get editDisplayName => 'Edit Display Name';

  @override
  String get displayNameHelper => 'This is how other users will see you';

  @override
  String get displayNameUpdated => 'Display name updated successfully';

  @override
  String get errorUpdatingDisplayName => 'Error updating display name';

  @override
  String get discoverableForSharing => 'Discoverable for Sharing';

  @override
  String get discoverableDescription =>
      'Allow other users to find you when sharing ratings';

  @override
  String get discoverabilityEnabled => 'You are now discoverable for sharing';

  @override
  String get discoverabilityDisabled =>
      'You are no longer discoverable for sharing';

  @override
  String get errorUpdatingSettings => 'Error updating settings';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get learnAboutPrivacy => 'Learn about your data and privacy';

  @override
  String get privacyPolicyContent =>
      'A la carte is designed with privacy first. All your ratings are private by default. You choose exactly which ratings to share and with whom. Your email and full name are never shown to other users.';

  @override
  String get close => 'Close';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDescription =>
      'Permanently delete your account and all data';

  @override
  String get deleteAccountWarning =>
      'This will permanently delete your account and all your data. This action cannot be undone.';

  @override
  String get deleteAccountConsequences =>
      'All your ratings, shared content, and profile information will be permanently removed from A la carte.';

  @override
  String get accountDeleted => 'Account deleted successfully';

  @override
  String get errorDeletingAccount => 'Error deleting account';

  @override
  String get anonymousUser => 'Anonymous User';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get userNotAuthenticated => 'User not authenticated';

  @override
  String get privacyOverview => 'Privacy Overview';

  @override
  String get yourSharingActivity => 'Your Sharing Activity';

  @override
  String sharedRatingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ratings',
      one: 'rating',
    );
    return '$count shared $_temp0';
  }

  @override
  String recipientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'recipients',
      one: 'recipient',
    );
    return '$count $_temp0';
  }

  @override
  String get discoverySettings => 'Discovery Settings';

  @override
  String get discoverabilityExplanation =>
      'Controls who can find you when sharing new ratings';

  @override
  String get discoverabilityDisabledWithExplanation =>
      'You are no longer discoverable. Existing shared ratings remain accessible.';

  @override
  String get bulkPrivacyActions => 'Bulk Privacy Actions';

  @override
  String get makeAllRatingsPrivate => 'Make All Ratings Private';

  @override
  String get makeAllRatingsPrivateDescription =>
      'Remove sharing from all your ratings at once';

  @override
  String get removePersonFromAllShares => 'Remove Person from All Shares';

  @override
  String get removePersonFromAllSharesDescription =>
      'Remove a specific person from all your shared ratings';

  @override
  String get comingSoonLabel => '(Coming Soon)';

  @override
  String get manageIndividualShares => 'Manage Individual Shares';

  @override
  String get noSharedRatingsYet => 'No Shared Ratings Yet';

  @override
  String get noSharedRatingsExplanation =>
      'All your ratings are currently private. Share ratings to help others discover great items!';

  @override
  String sharedWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'people',
      one: 'person',
    );
    return 'Shared with $count $_temp0';
  }

  @override
  String get manageSharingForRating => 'Manage sharing for this rating';

  @override
  String viewAllSharedRatings(int count) {
    return 'View All $count Shared Ratings';
  }

  @override
  String makeAllPrivateWarning(int count) {
    return 'This will remove sharing from all $count of your shared ratings. Recipients will no longer see your recommendations.';
  }

  @override
  String get makeAllPrivateConsequences =>
      'This action cannot be undone. You will need to re-share each rating individually if you change your mind.';

  @override
  String get makingRatingsPrivate => 'Making ratings private...';

  @override
  String get allRatingsMadePrivate => 'All ratings are now private';

  @override
  String get errorMakingRatingsPrivate => 'Error making ratings private';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get useExistingShareDialog =>
      'Use the share button on the rating to manage sharing';

  @override
  String get manageDataSharing =>
      'Manage your data sharing and privacy controls';

  @override
  String get noRecipientsToRemove => 'No recipients to remove';

  @override
  String get selectPersonToRemove =>
      'Select a person to remove from all your shared ratings:';

  @override
  String sharedRatingsWithUser(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ratings',
      one: 'rating',
    );
    return '$count shared $_temp0';
  }

  @override
  String get removeUserFromShares => 'Remove User from Shares';

  @override
  String removeUserWarning(String userName) {
    return 'This will remove $userName from all your shared ratings. They will no longer see your recommendations.';
  }

  @override
  String get removeUser => 'Remove User';

  @override
  String removingUserFromShares(String userName) {
    return 'Removing $userName from shares...';
  }

  @override
  String userRemovedFromShares(String userName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ratings',
      one: 'rating',
    );
    return '$userName removed from $count $_temp0';
  }

  @override
  String get errorRemovingUserFromShares => 'Error removing user from shares';

  @override
  String get sharingPreferencesUpdated =>
      'Sharing preferences updated successfully';

  @override
  String ratingUnsharedFromUsers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'users',
      one: 'user',
    );
    return 'Rating unshared from $count $_temp0';
  }

  @override
  String get managePrivacyAndDiscovery =>
      'Manage your privacy and discovery controls';

  @override
  String get loadingItemDetails => 'Loading item details...';

  @override
  String get bulkPrivacyActionsComingSoon => 'Bulk privacy actions coming soon';

  @override
  String get removePersonFeatureComingSoon =>
      'Remove person feature coming soon';

  @override
  String get cannotManageSharing => 'Cannot manage sharing for this rating';

  @override
  String get errorUpdatingSharing => 'Error updating sharing';

  @override
  String get featureNotImplementedOnServer =>
      'Feature not yet implemented on server';

  @override
  String get invalidDisplayName => 'Invalid display name';

  @override
  String typeDisplayNameToConfirm(String displayName) {
    return 'To confirm deletion, type your display name \"$displayName\" below:';
  }

  @override
  String get deletingAccount => 'Deleting account...';

  @override
  String get deletionMayTakeTime => 'This may take a moment';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get connectionRequired => 'Connection Required';

  @override
  String get offlineOperationBlocked =>
      'This operation requires an internet connection';

  @override
  String get connectAndRetry => 'Please connect to the internet and try again';

  @override
  String get noInternetConnectionTitle => 'No Internet Connection';

  @override
  String get serverUnavailableTitle => 'Server Unavailable';

  @override
  String get connectedTitle => 'Connected';

  @override
  String get noInternetConnectionDescription =>
      'A la carte needs an internet connection to sync your ratings and preferences. Please check your network settings and try again.';

  @override
  String get serverUnavailableDescription =>
      'A la carte server is temporarily unavailable. This might be due to maintenance or a temporary issue. We\'ll keep trying to reconnect.';

  @override
  String get connectionRestoredDescription =>
      'Connection restored! You can now use all features of A la carte.';

  @override
  String get signInRequiresConnection =>
      'Sign in requires an internet connection';

  @override
  String get serverTemporarilyUnavailable =>
      'Server temporarily unavailable. Please try again.';

  @override
  String get connectionFailedCheckNetwork =>
      'Connection failed. Please check your network and try again.';

  @override
  String get settingUpPreferenceHub => 'Setting up your preference hub...';

  @override
  String get verifyingAccount => 'Verifying account...';

  @override
  String get workingOffline => 'Working offline...';

  @override
  String get profileSetupRequired => 'Profile setup required...';

  @override
  String get readyWelcomeBack => 'Ready! Welcome back.';

  @override
  String get signInRequired => 'Sign in required...';

  @override
  String get preparingPreferences => 'Preparing your preferences...';

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get welcomeToAlacarte => 'Welcome to A la carte!';

  @override
  String hiUserSetupProfile(String firstName) {
    return 'Hi $firstName! Let\'s set up your profile.';
  }

  @override
  String get displayNameFieldHelper =>
      'This is how other users will see you when you share ratings';

  @override
  String get displayNameRequired => 'Display name is required';

  @override
  String get displayNameTooShort =>
      'Display name must be at least 2 characters';

  @override
  String get displayNameTooLong =>
      'Display name must be less than 50 characters';

  @override
  String get displayNameAvailable => '✓ Display name is available';

  @override
  String get displayNameTaken => '✗ Display name is already taken';

  @override
  String get couldNotCheckAvailability => '⚠ Could not check availability';

  @override
  String get privacySettingsTitle => 'Privacy Settings';

  @override
  String get discoverableByOthers => 'Discoverable by Others';

  @override
  String get discoverabilityHelper =>
      'Allow other users to find you when sharing ratings. You can change this later in settings.';

  @override
  String get settingUpProfile => 'Setting up profile...';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get yourPrivacyMatters => 'Your Privacy Matters';

  @override
  String get privacyExplanation =>
      'All your ratings are private by default. You choose exactly which ratings to share and with whom. Your email and full name are never shown to other users - only your display name.';

  @override
  String automaticLanguage(String detectedLanguage) {
    return 'Auto ($detectedLanguage)';
  }

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get followsDeviceLanguage => 'Follows device language';

  @override
  String get gin => 'Gin';

  @override
  String get gins => 'Gins';

  @override
  String get profileLabel => 'Profile';

  @override
  String get enterGinName => 'Enter gin name';

  @override
  String get enterProfile => 'Enter flavor profile';

  @override
  String get profileHint => 'e.g., Forestier / boréal, Floral, Épicé';

  @override
  String get profileHelperText => 'Optional - flavor category';

  @override
  String get ginCreated => 'Gin created successfully!';

  @override
  String get ginUpdated => 'Gin updated successfully!';

  @override
  String get ginDeleted => 'Gin deleted successfully!';

  @override
  String get createGin => 'Create Gin';

  @override
  String get editGin => 'Edit Gin';

  @override
  String get addGin => 'Add Gin';

  @override
  String get allGins => 'All Gins';

  @override
  String get myGinList => 'My Gin List';

  @override
  String get filterByProducer => 'Filter by producer';

  @override
  String get filterByOrigin => 'Filter by origin';

  @override
  String get filterByProfile => 'Filter by flavor profile';

  @override
  String get noGinsFound => 'No gins found';

  @override
  String get loadingGins => 'Loading gins...';

  @override
  String get profileRequired => 'Profile is required';

  @override
  String get editItemTooltip => 'Edit item';

  @override
  String get wine => 'Wine';

  @override
  String get wines => 'Wines';

  @override
  String get colorLabel => 'Color';

  @override
  String get country => 'Country';

  @override
  String get region => 'Region';

  @override
  String get grapeLabel => 'Grape Varieties';

  @override
  String get designationLabel => 'Designation';

  @override
  String get alcoholLabel => 'Alcohol';

  @override
  String get sugarLabel => 'Sugar';

  @override
  String get organicLabel => 'Organic';

  @override
  String get enterWineName => 'Enter wine name';

  @override
  String get enterColor => 'Enter color';

  @override
  String get enterCountry => 'e.g., Brazil, Ethiopia, Colombia';

  @override
  String get enterRegion => 'e.g., Yirgacheffe, Huila';

  @override
  String get enterGrape => 'Enter grape varieties';

  @override
  String get enterDesignation => 'Enter designation';

  @override
  String get enterAlcohol => 'Enter alcohol %';

  @override
  String get enterSugar => 'Enter sugar content';

  @override
  String get colorHint => 'e.g., Rouge, Blanc, Rosé, Mousseux, Orange';

  @override
  String get grapeHint => 'e.g., Syrah 50%, Grenache 25%';

  @override
  String get designationHint => 'e.g., AOC, DOC, Rioja, Bordeaux';

  @override
  String get colorRequired => 'Color is required';

  @override
  String get countryRequired => 'Country is required';

  @override
  String get wineCreated => 'Wine created successfully!';

  @override
  String get wineUpdated => 'Wine updated successfully!';

  @override
  String get wineDeleted => 'Wine deleted successfully!';

  @override
  String get createWine => 'Create Wine';

  @override
  String get editWine => 'Edit Wine';

  @override
  String get addWine => 'Add Wine';

  @override
  String get selectColor => 'Select color';

  @override
  String get organicHelper => 'Check if certified organic';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get coffee => 'Coffee';

  @override
  String get coffees => 'Coffees';

  @override
  String get createCoffee => 'Create Coffee';

  @override
  String get editCoffee => 'Edit Coffee';

  @override
  String get coffeeCreated => 'Coffee created successfully!';

  @override
  String get coffeeUpdated => 'Coffee updated successfully!';

  @override
  String get coffeeDeleted => 'Coffee deleted successfully!';

  @override
  String get roasterLabel => 'Roaster';

  @override
  String get roasterRequired => 'Roaster is required';

  @override
  String get enterRoaster => 'Enter roaster name';

  @override
  String get enterCoffeeName => 'Enter coffee name';

  @override
  String get countryLabel => 'Country';

  @override
  String get regionLabel => 'Region';

  @override
  String get farmLabel => 'Farm';

  @override
  String get enterFarm => 'e.g., Finca El Paraíso';

  @override
  String get altitudeLabel => 'Altitude';

  @override
  String get enterAltitude => 'e.g., 1200-1600m';

  @override
  String get altitudeHelper => 'Growing altitude in meters';

  @override
  String get speciesLabel => 'Species';

  @override
  String get selectSpecies => 'Select species';

  @override
  String get varietyLabel => 'Variety';

  @override
  String get enterVariety => 'e.g., Bourbon, Geisha, Caturra';

  @override
  String get varietyHelper => 'Coffee plant variety/cultivar';

  @override
  String get processingMethodLabel => 'Processing Method';

  @override
  String get selectProcessingMethod => 'Select processing method';

  @override
  String get processWashed => 'Washed';

  @override
  String get processNatural => 'Natural';

  @override
  String get processAnaerobic => 'Anaerobic';

  @override
  String get processCarbonicMaceration => 'Carbonic Maceration';

  @override
  String get processWetHulled => 'Wet-Hulled';

  @override
  String get processPulpedNatural => 'Pulped Natural';

  @override
  String get decaffeinatedLabel => 'Decaffeinated';

  @override
  String get decaffeinatedHelper => 'Check if this is decaffeinated coffee';

  @override
  String get roastLevelLabel => 'Roast Level';

  @override
  String get selectRoastLevel => 'Select roast level';

  @override
  String get roastLight => 'Light';

  @override
  String get roastMedium => 'Medium';

  @override
  String get roastDark => 'Dark';

  @override
  String get tastingNotesLabel => 'Tasting Notes';

  @override
  String get enterTastingNotes => 'e.g., chocolate, citrus, floral';

  @override
  String get tastingNotesHelper => 'Comma-separated flavor notes';

  @override
  String get acidityLabel => 'Acidity';

  @override
  String get selectAcidity => 'Select acidity level';

  @override
  String get bodyLabel => 'Body';

  @override
  String get selectBody => 'Select body level';

  @override
  String get bodyLight => 'Light';

  @override
  String get bodyMedium => 'Medium';

  @override
  String get bodyFull => 'Full';

  @override
  String get sweetnessLabel => 'Sweetness';

  @override
  String get selectSweetness => 'Select sweetness level';

  @override
  String get intensityLow => 'Low';

  @override
  String get intensityMedium => 'Medium';

  @override
  String get intensityHigh => 'High';

  @override
  String get fairTradeLabel => 'Fair Trade';

  @override
  String get fairTradeHelper => 'Check if fair trade certified';

  @override
  String get notSpecified => 'Not specified';
}
