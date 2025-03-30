import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;


  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated; // ✅ Add this getter

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // Function to check authentication status
  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _authService.isUserLoggedIn();
    notifyListeners();
  }

  // Sign Up
  Future<void> signUp(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    _user = await _authService.signUp(name, email, password);
    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    _user = await _authService.login(email, password);
    _isLoading = false;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void updateUserProfile({required String name, required String email}) {
  if (_user != null) {
    _user = UserModel(
      id: _user!.id,
      name: name,
      email: email,
      role: _user!.role, // Preserve existing role
      createdAt: _user!.createdAt, // Preserve existing createdAt timestamp
    );
    notifyListeners();
  }
}

}
