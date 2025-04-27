import 'package:flutter/material.dart';
import '../models/dispatcher.dart';
import '../models/dispatch.dart';
import '../models/dispatch_tracking.dart';
import '../services/dispatcher_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

/// Provider for dispatcher functionality
class DispatcherProvider extends ChangeNotifier {
  final DispatcherService _dispatcherService = DispatcherService();
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  bool _isLoading = false;
  bool _isSyncing = false;
  Dispatcher? _currentDispatcher;
  List<Dispatch> _assignedDispatches = [];
  List<Dispatch> _completedDispatches = [];
  DateTime? _lastSyncTime;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  Dispatcher? get currentDispatcher => _currentDispatcher;
  List<Dispatch> get assignedDispatches => _assignedDispatches;
  List<Dispatch> get completedDispatches => _completedDispatches;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);

    try {
      await _dispatcherService.initialize();
      await _syncService.initialize();

      // If user is logged in and is a dispatcher, load their data
      if (_authService.isLoggedIn && _authService.isDispatcher) {
        await _loadCurrentDispatcher();
      }
    } catch (e) {
      debugPrint('Error initializing dispatcher provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sync data with main app
  Future<bool> syncData() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _syncService.syncData();

      if (result) {
        _lastSyncTime = DateTime.now();

        // Reload data after sync
        if (_currentDispatcher != null) {
          await _loadAssignedDispatches();
          await _loadCompletedDispatches();
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error syncing data: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Load current dispatcher data
  Future<void> _loadCurrentDispatcher() async {
    if (_authService.currentUser == null) return;

    _setLoading(true);

    try {
      final dispatcher = await _dispatcherService
          .getDispatcherById(_authService.currentUser!.id);

      if (dispatcher != null) {
        _currentDispatcher = dispatcher;
        await _loadAssignedDispatches();
        await _loadCompletedDispatches();
      }
    } catch (e) {
      debugPrint('Error loading current dispatcher: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load assigned dispatches
  Future<void> _loadAssignedDispatches() async {
    if (_currentDispatcher == null) return;

    _setLoading(true);

    try {
      _assignedDispatches = await _dispatcherService
          .getAssignedDispatches(_currentDispatcher!.id);
    } catch (e) {
      debugPrint('Error loading assigned dispatches: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load completed dispatches
  Future<void> _loadCompletedDispatches() async {
    if (_currentDispatcher == null) return;

    _setLoading(true);

    try {
      _completedDispatches = await _dispatcherService
          .getCompletedDispatches(_currentDispatcher!.id);
    } catch (e) {
      debugPrint('Error loading completed dispatches: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Complete a dispatch
  Future<bool> completeDispatch(
    String dispatchId,
    DispatchStatus newStatus,
    String notes,
    String location,
  ) async {
    if (_currentDispatcher == null) return false;

    _setLoading(true);

    try {
      // Update in dispatcher service
      final result = await _dispatcherService.completeDispatch(
        dispatchId,
        _currentDispatcher!.id,
        newStatus,
        notes,
        location,
      );

      if (result) {
        // Add update to sync service
        await _syncService.addDispatchUpdate(
          dispatchId: dispatchId,
          newStatus: newStatus.label,
          notes: notes,
          location: location,
          handlerId: _currentDispatcher!.id,
        );

        // Sync data with main app
        await syncData();

        // Reload data
        await _loadCurrentDispatcher();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error completing dispatch: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update dispatcher status
  Future<bool> updateStatus(bool isActive) async {
    if (_currentDispatcher == null) return false;

    _setLoading(true);

    try {
      final result = await _dispatcherService.updateDispatcherStatus(
        _currentDispatcher!.id,
        isActive,
      );

      if (result) {
        // Reload data
        await _loadCurrentDispatcher();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating dispatcher status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
