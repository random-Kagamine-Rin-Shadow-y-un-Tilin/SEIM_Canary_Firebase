import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seim_canary/models/user_model.dart';
import 'package:bcrypt/bcrypt.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _userCollection;

  FirebaseService._internal() {
    _userCollection = _firestore.collection('Users');
  }

  factory FirebaseService() {
    return _instance;
  }

  // Verificar credenciales de un usuario para login
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      var querySnapshot =
          await _userCollection.where('email', isEqualTo: email).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        var user = doc.data() as Map<String, dynamic>;
        user['id'] = doc.id; // Important for document reference

        final storedPassword = user['password'];
        final isCorrect =
            BCrypt.checkpw(password, storedPassword); // Direct BCrypt check

        return isCorrect ? UserModel.fromJson(user) : null;
      }
      return null;
    } catch (e) {
      print("Error en login: $e");
      return null;
    }
  }

  // Obtener usuario por ID
  Future<UserModel?> getUserById(String id) async {
    try {
      var docSnapshot = await _userCollection.doc(id).get();
      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id; // Include document ID
        return UserModel.fromJson(data);
      }
      throw Exception('Usuario no encontrado');
    } catch (e) {
      print('Error al obtener usuario por ID: $e');
      rethrow;
    }
  }

  // Obtener la contraseña encriptada de un usuario por su ID
  Future<String?> getPasswordByUserId(String userId) async {
    try {
      var docSnapshot = await _userCollection.doc(userId).get();
      return docSnapshot.exists ? docSnapshot['password'] : null;
    } catch (e) {
      print("Error al obtener contraseña del usuario: $e");
      return null;
    }
  }

  // Actualizar contraseña
  Future<void> updatePassword(
      {required String userId, required String newPassword}) async {
    try {
      // Directly use the pre-hashed password without re-hashing
      await _userCollection.doc(userId).update({'password': newPassword});
      print("Contraseña actualizada en la base de datos");
    } catch (e) {
      print("Error al actualizar la contraseña: $e");
    }
  }

  // Obtener todos los usuarios
  Future<List<UserModel>> getUsers() async {
    try {
      var querySnapshot = await _userCollection.get();
      return querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include document ID
        return UserModel.fromJson(data);
      }).toList();
    } catch (e) {
      print("Error al obtener usuarios: $e");
      return [];
    }
  }

  // Agregar usuario
  Future<void> addUser(UserModel user) async {
    try {
      var userDoc = _userCollection.doc(user.id); // Use provided ID
      await userDoc.set(user.toJson());
      print("Usuario registrado exitosamente: ${user.email}");
    } catch (e) {
      print("Error al agregar usuario: $e");
      rethrow;
    }
  }

  // Actualizar usuario
  Future<void> updateUser(String docId, Map<String, dynamic> data) async {
    try {
      print("Intentando actualizar usuario con ID: $docId");
      var docSnapshot = await _userCollection.doc(docId).get();
      if (!docSnapshot.exists) {
        print("Documento no encontrado para el ID: $docId");
        throw Exception('Usuario no encontrado');
      }

      // Print current password hash
      String currentPasswordHash = docSnapshot['password'];
      print("Current password hash: $currentPasswordHash");

      await _userCollection.doc(docId).update(data);

      // Print updated password hash
      var updatedDocSnapshot = await _userCollection.doc(docId).get();
      String updatedPasswordHash = updatedDocSnapshot['password'];
      print("Updated password hash: $updatedPasswordHash");

      print("Usuario actualizado exitosamente: ${data['email']}");
    } catch (e) {
      print('Error al actualizar el usuario: $e');
      rethrow;
    }
  }

  // Verificar si un usuario existe y la contraseña es correcta
  Future<bool> verificarUsuario(String userId, String inputPassword) async {
    try {
      var docSnapshot = await _userCollection.doc(userId).get();
      if (!docSnapshot.exists) return false;

      String storedHash = docSnapshot['password'];
      return BCrypt.checkpw(inputPassword, storedHash);
    } catch (e) {
      print("Error al verificar usuario: $e");
      return false;
    }
  }

  // Eliminar usuario
  Future<void> deleteUser(String userId) async {
    try {
      await _userCollection.doc(userId).delete();
    } catch (e) {
      print('Error al eliminar usuario: $e');
      rethrow;
    }
  }
}
