import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seim_canary/models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return Future.error('Inicio de sesión cancelado');
      }

      // Obtain the Google Sign-In authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Check if the user exists in Firestore
        final userDoc = await _firestore.collection('Users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          // Convert Firestore data to UserModel
          final userData = userDoc.data() as Map<String, dynamic>;
          userData['id'] = firebaseUser.uid; // Add the UID to the data
          return UserModel.fromJson(userData);
        } else {
          // If user doesn't exist in Firestore, create a new entry
          final newUser = UserModel(
            id: firebaseUser.uid,
            username: firebaseUser.displayName ?? 'Usuario',
            email: firebaseUser.email ?? '',
            phone: '', // Default empty phone
            password: '', // Password is not stored for Google users
          );

          await _firestore.collection('Users').doc(firebaseUser.uid).set(newUser.toJson());
          return newUser;
        }
      }
      return null;
    } catch (e) {
      print('Error al autenticar con Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}