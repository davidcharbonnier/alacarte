// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'A la carte';

  @override
  String get welcomeTitle => 'Bienvenue sur A la carte';

  @override
  String get welcomeSubtitle =>
      'Votre centre personnel d\'évaluations et de préférences';

  @override
  String get yourPreferenceLists => 'Vos Listes de Préférences';

  @override
  String get moreCategoriesTitle => 'Plus de Catégories';

  @override
  String get moreCategoriesSubtitle => 'D\'autres catégories arrivent bientôt';

  @override
  String itemsAvailable(int count) {
    return '$count articles disponibles';
  }

  @override
  String inYourList(int count) {
    return '$count dans votre liste';
  }

  @override
  String get cheese => 'Fromage';

  @override
  String get settings => 'Paramètres';

  @override
  String get profileSettings => 'Paramètres du Profil';

  @override
  String get toggleTheme => 'Changer le thème';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';

  @override
  String get checkingConnection => 'Vérification de la connexion';

  @override
  String get offlineMessage =>
      'Hors ligne - Vos listes de références peuvent ne pas être à jour';

  @override
  String get connectedToAlacarte => 'Connecté à A la carte';

  @override
  String get noInternetConnection => 'Connexion perdue - Mode hors ligne';

  @override
  String get userSelection => 'Sélection d\'Utilisateur';

  @override
  String get createUser => 'Créer un Utilisateur';

  @override
  String get editUser => 'Modifier l\'Utilisateur';

  @override
  String get userName => 'Nom d\'Utilisateur';

  @override
  String get name => 'Nom';

  @override
  String get type => 'Type';

  @override
  String get origin => 'Origine';

  @override
  String get producer => 'Producteur';

  @override
  String get description => 'Description';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get create => 'Créer';

  @override
  String get search => 'Rechercher';

  @override
  String get filter => 'Filtrer';

  @override
  String get clearFilters => 'Effacer les Filtres';

  @override
  String allItems(String itemType) {
    return 'Tous les ${itemType}s';
  }

  @override
  String get myList => 'Ma Liste';

  @override
  String get rating => 'Évaluation';

  @override
  String get myRating => 'Mon Évaluation';

  @override
  String get sharedRatings => 'Évaluations Partagées';

  @override
  String get rateItem => 'Évaluer l\'Article';

  @override
  String get addRating => 'Ajouter une Évaluation';

  @override
  String get editRating => 'Modifier l\'Évaluation';

  @override
  String get notes => 'Notes';

  @override
  String get score => 'Score';

  @override
  String get back => 'Retour';

  @override
  String get home => 'Accueil';

  @override
  String get error => 'Erreur';

  @override
  String get loading => 'Chargement...';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get refresh => 'Actualiser';

  @override
  String get chooseProfileSubtitle =>
      'Choisissez votre profil pour accéder à vos évaluations et préférences';

  @override
  String get searchProfiles => 'Rechercher des profils...';

  @override
  String get createNewProfile => 'Créer un Nouveau Profil';

  @override
  String get deleteProfile => 'Supprimer le Profil';

  @override
  String deleteProfileConfirmation(String profileName) {
    return 'Êtes-vous sûr de vouloir supprimer le profil \"$profileName\" ?';
  }

  @override
  String get noProfilesFound => 'Aucun profil trouvé';

  @override
  String get tryDifferentSearch =>
      'Essayez de rechercher avec un nom différent';

  @override
  String currentlyUsing(String userName) {
    return 'Actuellement utilisé : $userName. Appuyez sur un profil différent pour changer ou appuyez sur celui sélectionné pour continuer.';
  }

  @override
  String get offlineProfileChanges =>
      'Hors ligne - Les modifications du profil peuvent ne pas être sauvegardées jusqu\'à la reconnexion';

  @override
  String get createYourProfile => 'Créer Votre Profil';

  @override
  String get editYourProfile => 'Modifier Votre Profil';

  @override
  String get nameHint => 'Entrez votre nom';

  @override
  String get profileHelpCreate =>
      'Votre profil vous aide à suivre vos évaluations et préférences de fromages.';

  @override
  String get profileHelpEdit =>
      'Mettez à jour les informations de votre profil.';

  @override
  String get currentProfile => 'Profil Actuel';

  @override
  String get profileManagement => 'Gestion du Profil';

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get editProfileSubtitle =>
      'Mettez à jour les informations de votre profil';

  @override
  String get switchProfile => 'Changer de Profil';

  @override
  String get switchProfileSubtitle => 'Passer à un profil différent';

  @override
  String get deleteProfileSubtitle => 'Supprimer définitivement ce profil';

  @override
  String get deleteWarning =>
      'Cette action ne peut pas être annulée. Toutes les données associées à ce profil seront définitivement supprimées.';

  @override
  String get noProfileSelected =>
      'Aucun profil sélectionné. Veuillez d\'abord sélectionner un profil.';

  @override
  String get backToApp => 'Retour à l\'Application';

  @override
  String get noProfilesYet => 'Aucun Profil Encore';

  @override
  String get noProfilesMessage =>
      'Aucun profil trouvé. Créez votre premier profil pour commencer !';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get nameMinLength => 'Le nom doit contenir au moins 2 caractères';

  @override
  String get nameMaxLength => 'Le nom doit contenir moins de 50 caractères';

  @override
  String get nameInvalidCharacters =>
      'Le nom ne peut contenir que des lettres, des espaces, des tirets et des apostrophes';

  @override
  String get backToHub => 'Retour au Centre';

  @override
  String myItemList(String itemType) {
    return 'Ma Liste de ${itemType}s';
  }

  @override
  String addItem(String itemType) {
    return 'Ajouter $itemType';
  }

  @override
  String get moreCategoriesComingSoon => 'Plus de Catégories Bientôt';

  @override
  String shared(int count) {
    return 'Partagé ($count)';
  }

  @override
  String moreRatings(int count) {
    return '+$count de plus';
  }

  @override
  String rateThisItem(String itemType) {
    return 'Évaluer ce $itemType';
  }

  @override
  String comingSoon(String itemType) {
    return '$itemType Bientôt Disponible';
  }

  @override
  String noItemsAvailable(String itemType) {
    return 'Aucun $itemType Disponible';
  }

  @override
  String addFirstItem(String itemType) {
    return 'Ajoutez le premier $itemType pour commencer à construire votre liste de référence';
  }

  @override
  String addFirstItemButton(String itemType) {
    return 'Ajouter le Premier $itemType';
  }

  @override
  String yourReferenceList(String itemType) {
    return 'Votre Liste de Référence $itemType';
  }

  @override
  String itemsWithRatings(int count) {
    return '$count articles avec vos évaluations et recommandations';
  }

  @override
  String yourListEmpty(String itemType) {
    return 'Votre Liste de ${itemType}s est Vide';
  }

  @override
  String rateItemsToBuild(String itemType) {
    return 'Évaluez des ${itemType}s pour construire votre liste de référence';
  }

  @override
  String exploreItems(String itemType) {
    return 'Explorer les ${itemType}s';
  }

  @override
  String get itemNotFound => 'Article Non Trouvé';

  @override
  String get goBack => 'Retour';

  @override
  String get offlineRatingData =>
      'Hors ligne - Les données d\'évaluation peuvent ne pas être à jour';

  @override
  String rateItemName(String itemName) {
    return 'Évaluer $itemName';
  }

  @override
  String get offlineLoadingMessage =>
      'Chargement... Connexion requise pour toutes les fonctionnalités';

  @override
  String get connectionError =>
      'Erreur de connexion - Veuillez vérifier votre réseau';

  @override
  String get offlineCachedData =>
      'Mode hors ligne - Affichage des données en cache';

  @override
  String get myNotes => 'Mes Notes :';

  @override
  String haventRatedYet(String itemName) {
    return 'Vous n\'avez pas encore évalué $itemName';
  }

  @override
  String get addRatingToBuild =>
      'Ajoutez votre évaluation pour construire votre liste de référence personnelle';

  @override
  String get noRatingsYet => 'Aucune Évaluation Encore';

  @override
  String beFirstToRate(String itemName) {
    return 'Soyez le premier à évaluer $itemName';
  }

  @override
  String get communityRatings => 'Évaluations de la Communauté';

  @override
  String ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'évaluations',
      one: 'évaluation',
    );
    return '$count $_temp0';
  }

  @override
  String averageRating(String rating) {
    return 'Moyenne : $rating / 5.0';
  }

  @override
  String mostCommonRating(int stars, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'évaluations',
      one: 'évaluation',
    );
    return 'Plus fréquent : $stars étoiles ($count $_temp0)';
  }

  @override
  String get noSharedRatings => 'Aucune Recommandation';

  @override
  String noSharedRatingsMessage(String itemName) {
    return 'Personne n\'a encore partagé ses recommandations pour $itemName avec vous';
  }

  @override
  String profileIdLabel(String id) {
    return 'ID du Profil : $id';
  }

  @override
  String get editProfileTooltip => 'Modifier le Profil';

  @override
  String get deleteProfileTooltip => 'Supprimer le Profil';

  @override
  String get newProfile => 'Nouveau';

  @override
  String get originLabel => 'Origine';

  @override
  String get producerLabel => 'Producteur';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get initializingApp => 'Initialisation d\'A la carte...';

  @override
  String get initializationTakingLonger =>
      'Ceci prend plus de temps que prévu...';

  @override
  String get profileDataCorrupted =>
      'Données du profil corrompues. Veuillez sélectionner votre profil à nouveau.';

  @override
  String get profileNotFoundOnServer =>
      'Votre profil n\'a pas été trouvé. Veuillez sélectionner un profil valide.';

  @override
  String get yourRating => 'Votre Évaluation';

  @override
  String get selectRating => 'Touchez pour sélectionner une note';

  @override
  String get ratingRequired => 'Veuillez sélectionner une note';

  @override
  String get addNotes => 'Ajoutez vos notes';

  @override
  String get notesHelper => 'Ajoutez vos notes personnelles (optionnel)';

  @override
  String get saveRating => 'Enregistrer l\'Évaluation';

  @override
  String get ratingCreated => 'Évaluation enregistrée avec succès !';

  @override
  String get couldNotSaveRating =>
      'Impossible d\'enregistrer l\'évaluation. Veuillez réessayer.';

  @override
  String get offlineRatingCreation =>
      'Hors ligne - Les modifications peuvent ne pas être sauvegardées jusqu\'à la reconnexion';

  @override
  String get noUserSelected => 'Aucun utilisateur sélectionné';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get offlineUserSwitch =>
      'Hors ligne - Données d\'évaluation non disponibles pour cet utilisateur';

  @override
  String editRatingForItem(String itemName) {
    return 'Modifier l\'Évaluation pour $itemName';
  }

  @override
  String get saveChanges => 'Enregistrer les Modifications';

  @override
  String get ratingUpdated => 'Évaluation mise à jour avec succès !';

  @override
  String get couldNotUpdateRating =>
      'Impossible de mettre à jour l\'évaluation. Veuillez réessayer.';

  @override
  String get offlineRatingEdit =>
      'Hors ligne - Les modifications peuvent ne pas être sauvegardées jusqu\'à la reconnexion';

  @override
  String get ratingNotFound => 'Évaluation non trouvée';

  @override
  String get editingRatingFor => 'Modification de l\'évaluation pour';

  @override
  String originalRating(double rating) {
    return 'Évaluation originale : $rating étoiles';
  }

  @override
  String get unsavedChanges => 'Vous avez des modifications non sauvegardées';

  @override
  String get shareRating => 'Partager l\'Évaluation';

  @override
  String get shareWith => 'Partager avec...';

  @override
  String get shareRatingWith => 'Partager l\'Évaluation Avec';

  @override
  String get selectUsersToShare =>
      'Sélectionnez les utilisateurs avec qui partager cette évaluation';

  @override
  String get shareRatingSuccess => 'Évaluation partagée avec succès !';

  @override
  String get shareRatingError =>
      'Impossible de partager l\'évaluation. Veuillez réessayer.';

  @override
  String sharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personnes',
      one: 'personne',
    );
    return 'Partagé avec $count $_temp0';
  }

  @override
  String get shareButtonText => 'Partager';

  @override
  String get noUsersAvailable => 'Aucun utilisateur disponible pour le partage';

  @override
  String get loadingUsers => 'Chargement des utilisateurs...';

  @override
  String get recommendations => 'Recommandations';

  @override
  String recommendationsFromFriends(int count) {
    return '$count recommandations d\'amis';
  }

  @override
  String get itemTypeNotSupported =>
      'Type d\'article pas encore pris en charge';

  @override
  String get ratingNotFoundOrNoPermission =>
      'Évaluation non trouvée ou vous n\'avez pas la permission de la modifier';

  @override
  String get noPermissionToEdit =>
      'Vous n\'avez pas la permission de modifier cette évaluation';

  @override
  String get noNotesAdded => 'Aucune note ajoutée';

  @override
  String userFallback(int userId) {
    return 'Utilisateur $userId';
  }

  @override
  String get deleteRating => 'Supprimer l\'Évaluation';

  @override
  String get deleteRatingConfirmation => 'Supprimer cette évaluation ?';

  @override
  String get deleteRatingWarning => 'Cette action ne peut pas être annulée.';

  @override
  String deleteRatingWithSharing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personnes',
      one: 'personne',
    );
    return 'Cela la supprimera également de $count $_temp0 qui ont accès à votre recommandation.';
  }

  @override
  String get deleteRatingGenericSharing =>
      'Si cette évaluation a été partagée, elle sera également supprimée des recommandations d\'autres utilisateurs.';

  @override
  String get ratingDeleted => 'Évaluation supprimée avec succès';

  @override
  String get couldNotDeleteRating =>
      'Impossible de supprimer l\'évaluation. Veuillez réessayer.';

  @override
  String get makePrivate => 'Rendre Privé';

  @override
  String get noChanges => 'Aucun Changement';

  @override
  String addNewItem(String itemType) {
    return 'Ajouter Nouveau $itemType';
  }

  @override
  String editItem(String itemName) {
    return 'Modifier $itemName';
  }

  @override
  String createItem(String itemType) {
    return 'Créer $itemType';
  }

  @override
  String itemCreated(String itemType) {
    return '$itemType créé avec succès !';
  }

  @override
  String itemUpdated(String itemType) {
    return '$itemType mis à jour avec succès !';
  }

  @override
  String couldNotCreateItem(String itemType) {
    return 'Impossible de créer le $itemType. Veuillez réessayer.';
  }

  @override
  String couldNotUpdateItem(String itemType) {
    return 'Impossible de mettre à jour le $itemType. Veuillez réessayer.';
  }

  @override
  String itemNameRequired(String itemType) {
    return 'Le nom du $itemType est requis';
  }

  @override
  String itemNameTooShort(String itemType) {
    return 'Le nom du $itemType doit contenir au moins 2 caractères';
  }

  @override
  String itemNameTooLong(String itemType) {
    return 'Le nom du $itemType doit contenir moins de 100 caractères';
  }

  @override
  String get typeRequired => 'Le type est requis';

  @override
  String get originRequired => 'L\'origine est requise';

  @override
  String get producerRequired => 'Le producteur est requis';

  @override
  String get selectType => 'Sélectionner le type...';

  @override
  String get enterOrigin => 'Entrer l\'origine';

  @override
  String get enterProducer => 'Entrer le producteur';

  @override
  String get enterDescription => 'Entrer la description (optionnel)';

  @override
  String get descriptionTooLong =>
      'La description doit contenir moins de 500 caractères';

  @override
  String get offlineItemCreation =>
      'Hors ligne - L\'article peut ne pas être sauvegardé jusqu\'à la reconnexion';

  @override
  String get offlineItemEdit =>
      'Hors ligne - Les modifications peuvent ne pas être sauvegardées jusqu\'à la reconnexion';

  @override
  String get unsavedChangesMessage =>
      'Vous avez des modifications non sauvegardées. Êtes-vous sûr de vouloir revenir ?';

  @override
  String get discard => 'Abandonner';

  @override
  String get updateInfoBelow => 'Mettez à jour les informations ci-dessous';

  @override
  String get fillDetailsToAdd =>
      'Remplissez les détails pour ajouter à votre collection';

  @override
  String get saving => 'Sauvegarde...';

  @override
  String get cheeseTypeHint => 'ex: Mou, Dur, Mi-dur, Bleu';

  @override
  String enterItemName(String itemType) {
    return 'Entrer le nom du $itemType';
  }

  @override
  String optionalFieldHelper(int maxLength) {
    return 'Optionnel - jusqu\'à $maxLength caractères';
  }

  @override
  String editItemType(String itemType) {
    return 'Modifier $itemType';
  }

  @override
  String addNewItemType(String itemType) {
    return 'Ajouter Nouveau $itemType';
  }

  @override
  String get optional => 'Optionnel';

  @override
  String get searchCheeseHint =>
      'Rechercher fromages par nom, type, origine...';

  @override
  String get noResultsFound => 'Aucun Résultat Trouvé';

  @override
  String get adjustSearchFilters =>
      'Essayez d\'ajuster votre recherche ou vos filtres';

  @override
  String get clearAllFilters => 'Effacer Tous les Filtres';

  @override
  String filterBy(String category) {
    return 'Filtrer par $category';
  }

  @override
  String showingResults(int filtered, int total) {
    return 'Affichage de $filtered sur $total articles';
  }

  @override
  String searchItemsByName(String itemType) {
    return 'Rechercher ${itemType}s par nom...';
  }

  @override
  String get searchByName => 'Rechercher par nom...';

  @override
  String get searchCheeseByNameHint => 'Rechercher fromages par nom...';

  @override
  String get myRatingsFilter => 'Mes Évaluations';

  @override
  String get recommendationsFilter => 'Recommandations';

  @override
  String get ratedFilter => 'Évalué';

  @override
  String get unratedFilter => 'Non évalué';

  @override
  String get allFilterOption => 'Tous';

  @override
  String get showFilters => 'Afficher les Filtres';

  @override
  String get hideFilters => 'Masquer les Filtres';

  @override
  String get userProfile => 'Profil Utilisateur';

  @override
  String get signOut => 'Se Déconnecter';

  @override
  String get signOutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ? Vous devrez vous reconnecter pour accéder à vos évaluations.';

  @override
  String get appPreferences => 'Préférences de l\'App';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get darkModeDescription =>
      'Utiliser le thème sombre dans toute l\'application';

  @override
  String get displayLanguage => 'Langue d\'Affichage';

  @override
  String get displayLanguageDescription => 'Choisissez votre langue préférée';

  @override
  String get profileAndAccount => 'Profil & Compte';

  @override
  String get displayName => 'Nom d\'Affichage';

  @override
  String get tapToSetDisplayName => 'Touchez pour définir le nom d\'affichage';

  @override
  String get editDisplayName => 'Modifier le Nom d\'Affichage';

  @override
  String get displayNameHelper =>
      'C\'est ainsi que les autres utilisateurs vous verront';

  @override
  String get displayNameUpdated => 'Nom d\'affichage mis à jour avec succès';

  @override
  String get errorUpdatingDisplayName =>
      'Erreur lors de la mise à jour du nom d\'affichage';

  @override
  String get discoverableForSharing => 'Découvrable pour le Partage';

  @override
  String get discoverableDescription =>
      'Permettre aux autres utilisateurs de vous trouver lors du partage d\'évaluations';

  @override
  String get discoverabilityEnabled =>
      'Vous êtes maintenant découvrable pour le partage';

  @override
  String get discoverabilityDisabled =>
      'Vous n\'êtes plus découvrable pour le partage';

  @override
  String get errorUpdatingSettings =>
      'Erreur lors de la mise à jour des paramètres';

  @override
  String get about => 'À Propos';

  @override
  String get appVersion => 'Version de l\'App';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get learnAboutPrivacy =>
      'En savoir plus sur vos données et votre confidentialité';

  @override
  String get privacyPolicyContent =>
      'A la carte est conçu avec la confidentialité en priorité. Toutes vos évaluations sont privées par défaut. Vous choisissez exactement quelles évaluations partager et avec qui. Votre email et nom complet ne sont jamais montrés aux autres utilisateurs.';

  @override
  String get close => 'Fermer';

  @override
  String get dangerZone => 'Zone Dangereuse';

  @override
  String get deleteAccount => 'Supprimer le Compte';

  @override
  String get deleteAccountDescription =>
      'Supprimer définitivement votre compte et toutes les données';

  @override
  String get deleteAccountWarning =>
      'Cela supprimera définitivement votre compte et toutes vos données. Cette action ne peut pas être annulée.';

  @override
  String get deleteAccountConsequences =>
      'Toutes vos évaluations, contenu partagé et informations de profil seront définitivement supprimés d\'A la carte.';

  @override
  String get accountDeleted => 'Compte supprimé avec succès';

  @override
  String get errorDeletingAccount => 'Erreur lors de la suppression du compte';

  @override
  String get anonymousUser => 'Utilisateur Anonyme';

  @override
  String get privacySettings => 'Paramètres de Confidentialité';

  @override
  String get userNotAuthenticated => 'Utilisateur non authentifié';

  @override
  String get privacyOverview => 'Aperçu de la Confidentialité';

  @override
  String get yourSharingActivity => 'Votre Activité de Partage';

  @override
  String sharedRatingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'évaluations partagées',
      one: 'évaluation partagée',
    );
    return '$count $_temp0';
  }

  @override
  String recipientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'destinataires',
      one: 'destinataire',
    );
    return '$count $_temp0';
  }

  @override
  String get discoverySettings => 'Paramètres de Découverte';

  @override
  String get discoverabilityExplanation =>
      'Contrôle qui peut vous trouver lors du partage de nouvelles évaluations';

  @override
  String get discoverabilityDisabledWithExplanation =>
      'Vous n\'êtes plus découvrable. Les évaluations partagées existantes restent accessibles.';

  @override
  String get bulkPrivacyActions => 'Actions de Confidentialité en Lot';

  @override
  String get makeAllRatingsPrivate => 'Rendre Toutes les Évaluations Privées';

  @override
  String get makeAllRatingsPrivateDescription =>
      'Supprimer le partage de toutes vos évaluations en une fois';

  @override
  String get removePersonFromAllShares =>
      'Retirer une Personne de Tous les Partages';

  @override
  String get removePersonFromAllSharesDescription =>
      'Retirer une personne spécifique de toutes vos évaluations partagées';

  @override
  String get comingSoonLabel => '(Bientôt Disponible)';

  @override
  String get manageIndividualShares => 'Gérer les Partages Individuels';

  @override
  String get noSharedRatingsYet => 'Aucune Évaluation Partagée';

  @override
  String get noSharedRatingsExplanation =>
      'Toutes vos évaluations sont actuellement privées. Partagez des évaluations pour aider les autres à découvrir de bons articles !';

  @override
  String sharedWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personnes',
      one: 'personne',
    );
    return 'Partagé avec $count $_temp0';
  }

  @override
  String get manageSharingForRating => 'Gérer le partage pour cette évaluation';

  @override
  String viewAllSharedRatings(int count) {
    return 'Voir Toutes les $count Évaluations Partagées';
  }

  @override
  String makeAllPrivateWarning(int count) {
    return 'Cela supprimera le partage de toutes vos $count évaluations partagées. Les destinataires ne verront plus vos recommandations.';
  }

  @override
  String get makeAllPrivateConsequences =>
      'Cette action ne peut pas être annulée. Vous devrez re-partager chaque évaluation individuellement si vous changez d\'avis.';

  @override
  String get makingRatingsPrivate => 'Privatisation des évaluations...';

  @override
  String get allRatingsMadePrivate =>
      'Toutes les évaluations sont maintenant privées';

  @override
  String get errorMakingRatingsPrivate =>
      'Erreur lors de la privatisation des évaluations';

  @override
  String get featureComingSoon => 'Fonctionnalité bientôt disponible';

  @override
  String get useExistingShareDialog =>
      'Utilisez le bouton de partage sur l\'évaluation pour gérer le partage';

  @override
  String get manageDataSharing =>
      'Gérer vos contrôles de partage de données et de confidentialité';

  @override
  String get noRecipientsToRemove => 'Aucun destinataire à supprimer';

  @override
  String get selectPersonToRemove =>
      'Sélectionnez une personne à retirer de toutes vos évaluations partagées :';

  @override
  String sharedRatingsWithUser(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'évaluations partagées',
      one: 'évaluation partagée',
    );
    return '$count $_temp0';
  }

  @override
  String get removeUserFromShares => 'Retirer l\'Utilisateur des Partages';

  @override
  String removeUserWarning(String userName) {
    return 'Cela retirera $userName de toutes vos évaluations partagées. Cette personne ne verra plus vos recommandations.';
  }

  @override
  String get removeUser => 'Retirer l\'Utilisateur';

  @override
  String removingUserFromShares(String userName) {
    return 'Suppression de $userName des partages...';
  }

  @override
  String userRemovedFromShares(String userName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'évaluations',
      one: 'évaluation',
    );
    return '$userName retiré de $count $_temp0';
  }

  @override
  String get errorRemovingUserFromShares =>
      'Erreur lors de la suppression de l\'utilisateur des partages';

  @override
  String get sharingPreferencesUpdated =>
      'Préférences de partage mises à jour avec succès';

  @override
  String ratingUnsharedFromUsers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personnes',
      one: 'personne',
    );
    return 'Évaluation non partagée avec $count $_temp0';
  }

  @override
  String get managePrivacyAndDiscovery =>
      'Gérer vos contrôles de confidentialité et de découverte';

  @override
  String get loadingItemDetails => 'Chargement des détails des articles...';

  @override
  String get bulkPrivacyActionsComingSoon =>
      'Actions de confidentialité en lot bientôt disponibles';

  @override
  String get removePersonFeatureComingSoon =>
      'Fonction de suppression de personne bientôt disponible';

  @override
  String get cannotManageSharing =>
      'Impossible de gérer le partage pour cette évaluation';

  @override
  String get errorUpdatingSharing => 'Erreur lors de la mise à jour du partage';

  @override
  String get featureNotImplementedOnServer =>
      'Fonctionnalité pas encore implémentée sur le serveur';

  @override
  String get invalidDisplayName => 'Nom d\'affichage invalide';

  @override
  String typeDisplayNameToConfirm(String displayName) {
    return 'Pour confirmer la suppression, tapez votre nom d\'affichage \"$displayName\" ci-dessous :';
  }

  @override
  String get deletingAccount => 'Suppression du compte...';

  @override
  String get deletionMayTakeTime => 'Cela peut prendre un moment';

  @override
  String get thisActionCannotBeUndone =>
      'Cette action ne peut pas être annulée.';

  @override
  String get retry => 'Réessayer';

  @override
  String get ok => 'OK';

  @override
  String get connectionRequired => 'Connexion Requise';

  @override
  String get offlineOperationBlocked =>
      'Cette opération nécessite une connexion internet';

  @override
  String get connectAndRetry =>
      'Veuillez vous connecter à internet et réessayer';

  @override
  String get noInternetConnectionTitle => 'Pas de Connexion Internet';

  @override
  String get serverUnavailableTitle => 'Serveur Indisponible';

  @override
  String get connectedTitle => 'Connecté';

  @override
  String get noInternetConnectionDescription =>
      'A la carte a besoin d\'une connexion internet pour synchroniser vos évaluations et préférences. Veuillez vérifier vos paramètres réseau et réessayer.';

  @override
  String get serverUnavailableDescription =>
      'Le serveur d\'A la carte est temporairement indisponible. Cela pourrait être dû à une maintenance ou un problème temporaire. Nous continuons d\'essayer de nous reconnecter.';

  @override
  String get connectionRestoredDescription =>
      'Connexion rétablie ! Vous pouvez maintenant utiliser toutes les fonctionnalités d\'A la carte.';

  @override
  String get signInRequiresConnection =>
      'Se connecter nécessite une connexion internet';

  @override
  String get serverTemporarilyUnavailable =>
      'Serveur temporairement indisponible. Veuillez réessayer.';

  @override
  String get connectionFailedCheckNetwork =>
      'Échec de connexion. Veuillez vérifier votre réseau et réessayer.';

  @override
  String get settingUpPreferenceHub =>
      'Configuration de votre centre de préférences...';

  @override
  String get verifyingAccount => 'Vérification du compte...';

  @override
  String get workingOffline => 'Mode hors ligne...';

  @override
  String get profileSetupRequired => 'Configuration du profil requise...';

  @override
  String get readyWelcomeBack => 'Prêt ! Bon retour.';

  @override
  String get signInRequired => 'Connexion requise...';

  @override
  String get preparingPreferences => 'Préparation de vos préférences...';

  @override
  String get completeYourProfile => 'Complétez Votre Profil';

  @override
  String get welcomeToAlacarte => 'Bienvenue sur A la carte !';

  @override
  String hiUserSetupProfile(String firstName) {
    return 'Salut $firstName ! Configurons votre profil.';
  }

  @override
  String get displayNameFieldHelper =>
      'C\'est ainsi que les autres utilisateurs vous verront lorsque vous partagez des évaluations';

  @override
  String get displayNameRequired => 'Le nom d\'affichage est requis';

  @override
  String get displayNameTooShort =>
      'Le nom d\'affichage doit contenir au moins 2 caractères';

  @override
  String get displayNameTooLong =>
      'Le nom d\'affichage doit contenir moins de 50 caractères';

  @override
  String get displayNameAvailable => '✓ Nom d\'affichage disponible';

  @override
  String get displayNameTaken => '✗ Nom d\'affichage déjà pris';

  @override
  String get couldNotCheckAvailability =>
      '⚠ Impossible de vérifier la disponibilité';

  @override
  String get privacySettingsTitle => 'Paramètres de Confidentialité';

  @override
  String get discoverableByOthers => 'Découvrable par les Autres';

  @override
  String get discoverabilityHelper =>
      'Permettre aux autres utilisateurs de vous trouver lors du partage d\'évaluations. Vous pouvez changer cela plus tard dans les paramètres.';

  @override
  String get settingUpProfile => 'Configuration du profil...';

  @override
  String get completeProfile => 'Compléter le Profil';

  @override
  String get yourPrivacyMatters => 'Votre Confidentialité Compte';

  @override
  String get privacyExplanation =>
      'Toutes vos évaluations sont privées par défaut. Vous choisissez exactement quelles évaluations partager et avec qui. Votre email et nom complet ne sont jamais montrés aux autres utilisateurs - seulement votre nom d\'affichage.';

  @override
  String automaticLanguage(String detectedLanguage) {
    return 'Auto ($detectedLanguage)';
  }

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get followsDeviceLanguage => 'Suit la langue de l\'appareil';

  @override
  String get gin => 'Gin';

  @override
  String get gins => 'Gins';

  @override
  String get profileLabel => 'Profil';

  @override
  String get enterGinName => 'Entrer le nom du gin';

  @override
  String get enterProfile => 'Entrer le profil aromatique';

  @override
  String get profileHint => 'ex: Forestier / boréal, Floral, Épicé';

  @override
  String get profileHelperText => 'Optionnel - catégorie de saveur';

  @override
  String get ginCreated => 'Gin créé avec succès !';

  @override
  String get ginUpdated => 'Gin mis à jour avec succès !';

  @override
  String get ginDeleted => 'Gin supprimé avec succès !';

  @override
  String get createGin => 'Créer un Gin';

  @override
  String get editGin => 'Modifier le Gin';

  @override
  String get addGin => 'Ajouter un Gin';

  @override
  String get allGins => 'Tous les Gins';

  @override
  String get myGinList => 'Ma Liste de Gins';

  @override
  String get filterByProducer => 'Filtrer par producteur';

  @override
  String get filterByOrigin => 'Filtrer par origine';

  @override
  String get filterByProfile => 'Filtrer par profil';

  @override
  String get noGinsFound => 'Aucun gin trouvé';

  @override
  String get loadingGins => 'Chargement des gins...';

  @override
  String get profileRequired => 'Le profil est requis';

  @override
  String get editItemTooltip => 'Modifier l\'article';

  @override
  String get wine => 'Vin';

  @override
  String get wines => 'Vins';

  @override
  String get colorLabel => 'Couleur';

  @override
  String get country => 'Pays';

  @override
  String get region => 'Région';

  @override
  String get grapeLabel => 'Cépages';

  @override
  String get designationLabel => 'Appellation';

  @override
  String get alcoholLabel => 'Alcool';

  @override
  String get sugarLabel => 'Sucre';

  @override
  String get organicLabel => 'Biologique';

  @override
  String get enterWineName => 'Entrer le nom du vin';

  @override
  String get enterColor => 'Entrer la couleur';

  @override
  String get enterCountry => 'ex: Brésil, Éthiopie, Colombie';

  @override
  String get enterRegion => 'ex: Yirgacheffe, Huila';

  @override
  String get enterGrape => 'Entrer les cépages';

  @override
  String get enterDesignation => 'Entrer l\'appellation';

  @override
  String get enterAlcohol => 'Entrer le % d\'alcool';

  @override
  String get enterSugar => 'Entrer le taux de sucre';

  @override
  String get colorHint => 'ex: Rouge, Blanc, Rosé, Mousseux, Orange';

  @override
  String get grapeHint => 'ex: Syrah 50%, Grenache 25%';

  @override
  String get designationHint => 'ex: AOC, DOC, Rioja, Bordeaux';

  @override
  String get colorRequired => 'La couleur est requise';

  @override
  String get countryRequired => 'Le pays est requis';

  @override
  String get wineCreated => 'Vin créé avec succès !';

  @override
  String get wineUpdated => 'Vin mis à jour avec succès !';

  @override
  String get wineDeleted => 'Vin supprimé avec succès !';

  @override
  String get createWine => 'Créer un Vin';

  @override
  String get editWine => 'Modifier le Vin';

  @override
  String get addWine => 'Ajouter un Vin';

  @override
  String get selectColor => 'Sélectionner la couleur';

  @override
  String get organicHelper => 'Cochez si certifié biologique';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get coffee => 'Café';

  @override
  String get coffees => 'Cafés';

  @override
  String get createCoffee => 'Créer un café';

  @override
  String get editCoffee => 'Modifier le café';

  @override
  String get coffeeCreated => 'Café créé avec succès !';

  @override
  String get coffeeUpdated => 'Café mis à jour avec succès !';

  @override
  String get coffeeDeleted => 'Café supprimé avec succès !';

  @override
  String get roasterLabel => 'Torréfacteur';

  @override
  String get roasterRequired => 'Le torréfacteur est requis';

  @override
  String get enterRoaster => 'Entrez le nom du torréfacteur';

  @override
  String get enterCoffeeName => 'Entrez le nom du café';

  @override
  String get countryLabel => 'Pays';

  @override
  String get regionLabel => 'Région';

  @override
  String get farmLabel => 'Ferme';

  @override
  String get enterFarm => 'ex: Finca El Paraíso';

  @override
  String get altitudeLabel => 'Altitude';

  @override
  String get enterAltitude => 'ex: 1200-1600m';

  @override
  String get altitudeHelper => 'Altitude de culture en mètres';

  @override
  String get speciesLabel => 'Espèce';

  @override
  String get selectSpecies => 'Sélectionner l\'espèce';

  @override
  String get varietyLabel => 'Variété';

  @override
  String get enterVariety => 'ex: Bourbon, Geisha, Caturra';

  @override
  String get varietyHelper => 'Variété/cultivar du plant de café';

  @override
  String get processingMethodLabel => 'Méthode de traitement';

  @override
  String get selectProcessingMethod => 'Sélectionner la méthode';

  @override
  String get processWashed => 'Lavé';

  @override
  String get processNatural => 'Nature';

  @override
  String get processAnaerobic => 'Anaérobie';

  @override
  String get processCarbonicMaceration => 'Macération Carbonique';

  @override
  String get processWetHulled => 'Décortiqué Humide';

  @override
  String get processPulpedNatural => 'Nature Dépulpé';

  @override
  String get decaffeinatedLabel => 'Décaféiné';

  @override
  String get decaffeinatedHelper => 'Cochez si c\'est du café décaféiné';

  @override
  String get roastLevelLabel => 'Niveau de torréfaction';

  @override
  String get selectRoastLevel => 'Sélectionner le niveau';

  @override
  String get roastLight => 'Pâle';

  @override
  String get roastMedium => 'Moyen';

  @override
  String get roastDark => 'Foncé';

  @override
  String get tastingNotesLabel => 'Notes de dégustation';

  @override
  String get enterTastingNotes => 'ex: chocolat, agrumes, floral';

  @override
  String get tastingNotesHelper => 'Notes de saveur séparées par des virgules';

  @override
  String get acidityLabel => 'Acidité';

  @override
  String get selectAcidity => 'Sélectionner le niveau d\'acidité';

  @override
  String get bodyLabel => 'Corps';

  @override
  String get selectBody => 'Sélectionner le corps';

  @override
  String get bodyLight => 'Léger';

  @override
  String get bodyMedium => 'Moyen';

  @override
  String get bodyFull => 'Corsé';

  @override
  String get sweetnessLabel => 'Douceur';

  @override
  String get selectSweetness => 'Sélectionner la douceur';

  @override
  String get intensityLow => 'Faible';

  @override
  String get intensityMedium => 'Moyen';

  @override
  String get intensityHigh => 'Élevé';

  @override
  String get fairTradeLabel => 'Commerce équitable';

  @override
  String get fairTradeHelper => 'Cochez si certifié commerce équitable';

  @override
  String get notSpecified => 'Non spécifié';

  @override
  String get selectImageSource => 'Sélectionner la source de l\'image';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Caméra';

  @override
  String get removeImage => 'Supprimer l\'image';

  @override
  String get removeImageConfirmation =>
      'Êtes-vous sûr de vouloir supprimer cette image ?';

  @override
  String get remove => 'Supprimer';

  @override
  String get imageLabel => 'Image';

  @override
  String get changeImage => 'Modifier l\'image';

  @override
  String get addImage => 'Ajouter une image';

  @override
  String get noImage => 'Aucune image';
}
