import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    checkAuth();
  }

  void checkAuth() {
    _user = StorageService.getAuthUser();
    _isAuthenticated = _user != null;
    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> login(String email, String password) {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail == 'admin@example.com' && password == 'Admin@123') {
      final demoUser = User(
        id: 'usr-admin-01',
        name: 'Kunjuppa Admin',
        email: 'admin@example.com',
        role: 'admin',
      );
      StorageService.setAuthUser(demoUser);
      _user = demoUser;
      _isAuthenticated = true;
      notifyListeners();
      return {'success': true};
    }

    return {
      'success': false,
      'error': 'Invalid credentials. Use email: admin@example.com and password: Admin@123',
    };
  }

  void logout() {
    StorageService.setAuthUser(null);
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
