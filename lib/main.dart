import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';

late FirebaseApp _firebaseApp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase init error: $e');
  }
  
  // Initialize notifications in background
  NotificationService().initialize().ignore();
  
  runApp(const CCWSLiteApp());
}

class CCWSLiteApp extends StatelessWidget {
  const CCWSLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCWS Vision',
      debugShowCheckedModeBanner: false,
      theme: T.theme,
      home: const _AuthWrapper(),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A3D42), Color(0xFF0D5C63), Color(0xFF0A3D42)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }
        
        // Error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        
        // Logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        // Not logged in
        return const LoginScreen();
      },
    );
  }
}
