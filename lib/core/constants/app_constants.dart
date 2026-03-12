import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'QuoteSnap';
  static const String appVersion = '1.0.0';

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.antigravity.quote_snap';
  static const String shareAppText =
      'Check out QuoteSnap to manage your contractor business: '
      'https://play.google.com/store/apps/details?id=com.antigravity.quote_snap';

  static const String privacyPolicyTitle = 'Privacy Policy';
  static const String termsOfServiceTitle = 'Terms of Service';
  static const String privacyPolicyBody =
      'QuoteSnap stores the data you enter, including clients, quotes, and '
      'notes. Data is stored locally on your device and may be synced to '
      'Firebase when you are signed in. We do not sell personal data. We '
      'share data only with service providers required to run the app, such as '
      'Firebase and Crashlytics. You can export or delete your data from '
      'Settings at any time. If you have questions, contact '
      'support@quotesnap.app.';
  static const String termsOfServiceBody =
      'By using QuoteSnap, you agree to use the app for lawful business '
      'purposes and to keep your account credentials secure. You are '
      'responsible for the accuracy of the quotes you create and the data you '
      'enter. QuoteSnap is provided on an \"as is\" basis without warranties '
      'of any kind. To the maximum extent allowed by law, we are not liable '
      'for indirect, incidental, or consequential damages. We may update the '
      'app and these terms from time to time.';
  
  static const int freeTierQuoteLimit = 5;

  static const List<String> jobTypes = [
    'Plumbing', 'Electrical', 'Painting', 
    'Carpentry', 'HVAC', 'Windows', 'Roofing', 'Other'
  ];

  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
}

class AppColors {
  // Primary color
  static const Color primary = Color(0xFFEC5B13);
  
  // Surface & Background
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1C1F2A);
  
  // Feedback (Optional but useful based on previous setup)
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
}

class AppSpacing {
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
}
