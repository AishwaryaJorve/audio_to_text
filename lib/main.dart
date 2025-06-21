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
  // Ensure Flutter binding is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase first
    await Firebase.initializeApp();

    // Check connectivity
    await _checkConnectivity();
    
    // Run the app
    runApp(const MyApp());
  } catch (e) {
    print('Initialization Error: $e');
    runApp(ErrorApp(error: e));
  }
}

Future<void> _checkConnectivity() async {
  try {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    
    switch (result) {
      case ConnectivityResult.wifi:
        print('Connected to WiFi');
        break;
      case ConnectivityResult.mobile:
        print('Connected to Mobile Network');
        break;
      case ConnectivityResult.none:
        print('No Internet Connection');
        break;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
        print('Connected via alternative network');
        break;
    }
  } catch (e) {
    print('Connectivity Check Error: $e');
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
      themeMode: ThemeMode.light,
      home: AuthWrapper(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final Object? error;

  const ErrorApp({Key? key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'App Initialization Error',
                style: TextStyle(fontSize: 20, color: Colors.red),
              ),
              const SizedBox(height: 20),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
