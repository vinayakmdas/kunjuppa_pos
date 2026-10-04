import 'package:flutter/foundation.dart';
import '../core/constants/seed_data.dart';
import '../models/business_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  BusinessSettings _settings = DEFAULT_SETTINGS;
  bool _isLoaded = false;

  BusinessSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    loadSettings();
  }

  void loadSettings() {
    _settings = StorageService.getSettings();
    _isLoaded = true;
    notifyListeners();
  }

  void updateSettings(BusinessSettings newSettings) {
    _settings = newSettings;
    StorageService.saveSettings(_settings);
    notifyListeners();
  }

  void resetSettings() {
    _settings = DEFAULT_SETTINGS;
    StorageService.saveSettings(DEFAULT_SETTINGS);
    notifyListeners();
  }
}
