import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/transcription_screen.dart';
import 'constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Simplified connectivity check
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    print('Connectivity Result: $connectivityResult');
  } catch (e) {
    print('Connectivity Error: $e');
  }

  await Firebase.initializeApp();
  runApp(const MyApp());
}

Future<bool> _checkInternetConnectivity() async {
  try {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    
    switch (result) {
      case ConnectivityResult.wifi:
        print('Connected to WiFi');
        return true;
      case ConnectivityResult.mobile:
        print('Connected to Mobile Network');
        return true;
      case ConnectivityResult.none:
        print('No Internet Connection');
        return false;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
        print('Connected via alternative network');
        return true;
    }
  } catch (e) {
    print('Connectivity Check Error: $e');
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio to Text',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force dark mode for testing
      home: const AuthScreen(),
    );
  }
}

// New AuthWrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const AuthScreen();
          } else {
            return const HomeScreen();
          }
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
