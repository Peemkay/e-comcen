import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing navigation state and history
class NavigationProvider extends ChangeNotifier {
  static const String _lastRouteKey = 'last_active_route';
  static const String _routeHistoryKey = 'route_history';
  static const int _maxHistorySize = 10;

  String _currentRoute = '/';
  String _lastActiveRoute = '/home';
  List<String> _routeHistory = [];

  // Getters
  String get currentRoute => _currentRoute;
  String get lastActiveRoute => _lastActiveRoute;
  List<String> get routeHistory => List.unmodifiable(_routeHistory);

  // Initialize navigation provider
  Future<void> initialize() async {
    await _loadNavigationState();
  }

  // Set current route
  void setCurrentRoute(String route) {
    if (_currentRoute == route) return;

    _currentRoute = route;
    _addToHistory(route);
    _saveNavigationState();
    notifyListeners();
  }

  // Set last active route
  void setLastActiveRoute(String route) {
    if (_lastActiveRoute == route) return;

    _lastActiveRoute = route;
    _saveNavigationState();
    notifyListeners();
  }

  // Add route to history
  void _addToHistory(String route) {
    // Don't add duplicate consecutive routes
    if (_routeHistory.isNotEmpty && _routeHistory.last == route) {
      return;
    }

    _routeHistory.add(route);

    // Limit history size
    if (_routeHistory.length > _maxHistorySize) {
      _routeHistory.removeAt(0);
    }
  }

  // Clear navigation history
  void clearHistory() {
    _routeHistory.clear();
    _saveNavigationState();
    notifyListeners();
  }

  // Load navigation state from shared preferences
  Future<void> _loadNavigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load last active route
      final lastRoute = prefs.getString(_lastRouteKey);
      if (lastRoute != null) {
        _lastActiveRoute = lastRoute;
      }
      
      // Load route history
      final historyString = prefs.getStringList(_routeHistoryKey);
      if (historyString != null) {
        _routeHistory = historyString;
      }
    } catch (e) {
      debugPrint('Error loading navigation state: $e');
    }
  }

  // Save navigation state to shared preferences
  Future<void> _saveNavigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save last active route
      await prefs.setString(_lastRouteKey, _lastActiveRoute);
      
      // Save route history
      await prefs.setStringList(_routeHistoryKey, _routeHistory);
    } catch (e) {
      debugPrint('Error saving navigation state: $e');
    }
  }

  // Get the previous route
  String? getPreviousRoute() {
    if (_routeHistory.length < 2) {
      return null;
    }
    return _routeHistory[_routeHistory.length - 2];
  }

  // Navigate back
  bool canNavigateBack() {
    return _routeHistory.length > 1;
  }
}
