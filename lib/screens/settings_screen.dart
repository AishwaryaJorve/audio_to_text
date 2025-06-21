import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/theme_provider.dart';
import '../services/google_sign_in_service.dart';
import '../screens/auth_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current theme mode
    final currentThemeMode = ref.watch(themeModeProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          // User Profile Section
          if (user != null) UserProfileSection(user: user),

          // Theme Settings Section
          SettingsSectionHeader(title: 'Theme Settings'),
          ThemeSettingsSection(
            currentThemeMode: currentThemeMode, 
            onThemeChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            }
          ),

          // Account Section
          SettingsSectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) async {
    try {
      await GoogleSignInService.signOut();
      // Navigate to auth screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()), 
        (Route<dynamic> route) => false
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
}

class UserProfileSection extends StatelessWidget {
  final User user;

  const UserProfileSection({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user.photoURL != null 
              ? NetworkImage(user.photoURL!) 
              : null,
            child: user.photoURL == null 
              ? Icon(Icons.person, size: 40, color: Theme.of(context).iconTheme.color) 
              : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  user.email ?? 'No email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ThemeSettingsSection extends StatelessWidget {
  final AppThemeMode currentThemeMode;
  final void Function(AppThemeMode?) onThemeChanged;

  const ThemeSettingsSection({
    Key? key, 
    required this.currentThemeMode, 
    required this.onThemeChanged
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<AppThemeMode>(
          title: const Text('System Theme'),
          value: AppThemeMode.system,
          groupValue: currentThemeMode,
          onChanged: onThemeChanged,
        ),
        RadioListTile<AppThemeMode>(
          title: const Text('Light Theme'),
          value: AppThemeMode.light,
          groupValue: currentThemeMode,
          onChanged: onThemeChanged,
        ),
        RadioListTile<AppThemeMode>(
          title: const Text('Dark Theme'),
          value: AppThemeMode.dark,
          groupValue: currentThemeMode,
          onChanged: onThemeChanged,
        ),
      ],
    );
  }
} 