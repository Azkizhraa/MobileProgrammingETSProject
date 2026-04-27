import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String get userId => currentUser?.uid ?? '';
  String get userEmail => currentUser?.email ?? '';
  String get userDisplayName => currentUser?.displayName ?? userEmail;
  String get userPhotoUrl => currentUser?.photoURL ?? '';

  bool _isValidItsEmail(String email) {
    return email.toLowerCase().endsWith('@student.its.ac.id');
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    if (!_isValidItsEmail(email)) {
      throw Exception('Only @student.its.ac.id accounts are allowed.');
    }
    
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    await userCredential.user?.updateDisplayName(email.split('@')[0]);
    return userCredential;
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isValidItsEmail(email)) {
      throw Exception('Only @student.its.ac.id accounts are allowed.');
    }
    
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}