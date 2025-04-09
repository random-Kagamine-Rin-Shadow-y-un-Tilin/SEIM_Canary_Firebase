import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seim_canary/models/user_model.dart';
import 'package:seim_canary/services/current_user.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<UserModel?> signInWithGoogle() async {
  try {
    await _googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return Future.error('Inicio de sesión cancelado');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    final User? firebaseUser = userCredential.user;

    if (firebaseUser != null) {
      final userDoc =
          await _firestore.collection('Users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userData['id'] = firebaseUser.uid;
        final currentUser = UserModel.fromJson(userData);

        // Set the current user
        CurrentUser().user = currentUser;

        return currentUser;
      } else {
        final newUser = UserModel(
          id: firebaseUser.uid,
          username: firebaseUser.displayName ?? 'Usuario',
          email: firebaseUser.email ?? '',
          phone: '',
          password: '',
        );

        await _firestore
            .collection('Users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());

        // Set the current user
        CurrentUser().user = newUser;

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
    try {
      // Revoke access to the current Google account
      await _googleSignIn.disconnect();
    } catch (e) {
      print('Error revoking Google access: $e');
    }

    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
