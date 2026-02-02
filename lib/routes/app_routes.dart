import 'package:flutter/material.dart';
import 'package:da_project_1/layout/main_scaffold.dart';
import 'package:da_project_1/screens/auth/login_screen.dart';
import 'package:da_project_1/screens/auth/register_screen.dart';
import 'package:da_project_1/screens/auth/account_under_review_screen.dart';
import 'package:da_project_1/screens/dashboard/dashboard_screen.dart';
import 'package:da_project_1/screens/accounts/accounts_screen.dart';
import 'package:da_project_1/screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String accountUnderReview = '/account_under_review';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String accounts = '/accounts';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (_) => const LoginScreen(),
      register: (_) => const RegisterScreen(),
      accountUnderReview: (_) => const AccountUnderReviewScreen(),
      home: (_) => const MainScaffold(),
      dashboard: (_) => const DashboardScreen(),
      accounts: (_) => const AccountsScreen(),
      settings: (_) => const SettingsScreen(),
    };
  }
}