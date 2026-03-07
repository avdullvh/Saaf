// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Saaf';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get hasAccount => 'Already have an account? Login';

  @override
  String get fullName => 'Full Name';

  @override
  String get logout => 'Logout';

  @override
  String get uploadTitle => 'Classify Palm Tree';

  @override
  String get uploadPrompt => 'Take or upload a photo of the palm frond';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get classifyButton => 'Classify';

  @override
  String get classifying => 'Analysing image...';

  @override
  String get resultTitle => 'Classification Result';

  @override
  String get palmType => 'Palm Type';

  @override
  String get confidence => 'Confidence';

  @override
  String get shareToFeed => 'Share to Community Feed';

  @override
  String get classifyAnother => 'Classify Another';

  @override
  String get feedTitle => 'Community Feed';

  @override
  String likes(int count) {
    return '$count likes';
  }

  @override
  String comments(int count) {
    return '$count comments';
  }

  @override
  String get addComment => 'Add a comment...';

  @override
  String get post => 'Post';

  @override
  String get shareCaption => 'Write a caption (optional)';

  @override
  String get retry => 'Retry';

  @override
  String get noPostsYet =>
      'No posts yet.\nBe the first to share a classification!';

  @override
  String get tabClassify => 'Classify';

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabProfile => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get bio => 'Bio';

  @override
  String get posts => 'Posts';

  @override
  String get noPostsProfile => 'No posts yet';

  @override
  String get addBioHint => 'Tap to add a bio';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String get profileUpdateFailed => 'Failed to update. Please try again.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get postTitle => 'Post';

  @override
  String get noCommentsYet => 'No comments yet. Be the first!';

  @override
  String get commentHint => 'Add a comment…';

  @override
  String get darkMode => 'Switch to Dark Mode';

  @override
  String get lightMode => 'Switch to Light Mode';

  @override
  String get cancel => 'Cancel';

  @override
  String get language => 'Language';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorInvalidCredentials => 'Invalid email or password.';

  @override
  String get errorImagePick => 'Could not load image.';

  @override
  String get successPost => 'Posted to feed successfully!';

  @override
  String get goToFeed => 'Go to Community Feed';

  @override
  String get postSharedMessage => 'Your post is now visible to the community.';
}
