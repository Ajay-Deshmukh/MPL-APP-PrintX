import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _authService.isUserLoggedIn();
    notifyListeners();
  }

  Future<void> signUp(String name, String email, String password) async {
    if (!email.endsWith('@ves.ac.in')) {
      throw Exception('Please use your VES email address');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await _authService.signUp(name, email, password);
      _isAuthenticated = _user != null;
    } catch (e) {
      _user = null;
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await _authService.login(email, password);
      _isAuthenticated = _user != null;
    } catch (e) {
      _user = null;
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateUserProfile({required String name}) async {
    if (_user != null) {
      _isLoading = true;
      notifyListeners();

      try {
        await _authService.updateUserProfile(_user!.id, name);
        _user = UserModel(
          id: _user!.id,
          name: name,
          email: _user!.email,
          role: _user!.role,
          createdAt: _user!.createdAt,
        );
      } catch (e) {
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user != null) {
      _isLoading = true;
      notifyListeners();

      try {
        await _authService.changePassword(
          email: _user!.email,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      } catch (e) {
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
