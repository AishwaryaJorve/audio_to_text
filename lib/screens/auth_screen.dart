import 'package:audio_to_text/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../services/google_sign_in_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              _buildHeader(context),

              const SizedBox(height: 30),

              // Microphone Icon
              _buildMicrophoneIcon(isDarkMode),

              const SizedBox(height: 32),

              // Social Login Buttons
              _buildSocialLoginButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Capture conversations',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.brightness == Brightness.light 
              ? Colors.black87 
              : Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'live with AI',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMicrophoneIcon(bool isDarkMode) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode 
          ? Colors.blue.shade900.withOpacity(0.3)
          : Colors.blue.shade100,
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode ? Colors.blue.shade700 : Colors.blue,
          ),
          child: Icon(
            Icons.mic,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Apple Login
        _buildSocialButton(
          context: context,
          text: 'Continue with Apple',
          logo: 'assets/icons/apple2_logo.png',
          logoSize: 47,
          onPressed: () {
            Navigator.pushNamed(context, '/home');
          },
        ),
        
        const SizedBox(height: 10),
        
        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDarkMode ? Colors.grey[700] : Colors.grey.shade300
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                'OR',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDarkMode ? Colors.grey[700] : Colors.grey.shade300
              )
            ),
          ],
        ),
        
        const SizedBox(height: 10),

        // Google Login
        _buildSocialButton(
          context: context,
          text: '   Continue with Google',
          logo: 'assets/icons/google_logo.png',
          onPressed: () => _handleGoogleSignIn(context),
          backgroundColor: Colors.white,
          textColor: Colors.black,
        ),
        
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String text,
    required String logo,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    double logoSize = 24,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine background and text colors
    Color buttonBackground = backgroundColor ?? (isDarkMode ? Colors.black : Colors.white);
    Color buttonText = textColor ?? (isDarkMode ? Colors.white : Colors.black);

    return SizedBox(
      height: 45,
      child: ElevatedButton(
        onPressed: () {
          // Use a more robust navigation method
          _handleSignIn(context, onPressed);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonText,
          side: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              logo,
              height: logoSize,
              width: logoSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: logoSize,
                  height: logoSize,
                  color: Colors.grey,
                  child: Icon(Icons.error, size: 18),
                );
              },
            ),
            const SizedBox(width: 12),  // Increased spacing
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: buttonText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method to handle sign-in more safely
  void _handleSignIn(BuildContext context, VoidCallback onPressed) {
    // Wrap the sign-in logic to prevent widget state issues
    Future.microtask(() {
      try {
        onPressed();
      } catch (e) {
        // Use a more robust error handling method
        print('Sign-in error: $e');
        
        // Check if the context is still valid
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _handleGoogleSignIn(BuildContext context) async {
    // Use a more robust navigation method
    try {
      final user = await GoogleSignInService.signInWithGoogle();
      
      // Check if the context is still valid
      if (!context.mounted) return;

      if (user != null) {
        // Use Navigator.pushReplacement to avoid stacking multiple routes
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen())
        );
      } else {
        // Show error safely
        _showErrorSnackBar(context, 'Google Sign-In failed');
      }
    } catch (e) {
      // Show error safely
      _showErrorSnackBar(context, 'An error occurred: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    // Check if the context is still valid before showing SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 