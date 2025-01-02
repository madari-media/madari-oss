import 'package:flutter/material.dart';

import '../screen/email_settings_screen.dart';
import '../screen/help_screen.dart';
import '../screen/notification_screen.dart';
import '../screen/payment_screen.dart';
import '../screen/profile_setting.dart';
import '../screen/security_screen.dart';

class AccountNavigation {
  static void navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  static void navigateToEmailSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailSettingsScreen()),
    );
  }

  static void navigateToSecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityScreen()),
    );
  }

  static void navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  static void navigateToPayments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentScreen()),
    );
  }

  static void navigateToHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }
}
