import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }
  // Signup User
Future<UserModel?> signUp(String name, String email, String password) async {
  print("🔹 Sign-up process started...");
  print("📩 Email: $email");
  
  try {
    print("🔹 Creating user with Firebase Authentication...");
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      print("✅ User created successfully. UID: ${user.uid}");

      UserModel newUser = UserModel(
        id: user.uid,
        name: name,
        email: email,
        role: "User",
        createdAt: Timestamp.now(),
      );

      print("🔹 Storing user in Firestore...");
      await _firestore.collection("users").doc(user.uid).set(newUser.toJson());

      print("✅ User stored in Firestore successfully.");
      return newUser;
    } else {
      print("❌ User creation failed: User object is null.");
    }
  } catch (e) {
    print("❌ Signup Error: $e");
  }

  print("❌ Returning null: Signup failed.");
  return null;
}


  Future<UserModel?> login(String email, String password) async {
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection("users").doc(user.uid).get();
      print("User UID: ${user.uid}");
      print("User Data: ${userData.data()}");

      if (userData.exists && userData.data() != null) {
        return UserModel.fromJson(userData.data() as Map<String, dynamic>);
      } else {
        print("Error: User document does not exist in Firestore.");
      }
    }
  } catch (e) {
    print("Login Error: $e");
  }
  return null;
}


  // Logout User
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;

  Future<void> updateUserProfile(String userId, String name) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Re-authenticate user before password change
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }
}
