import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dispatch.dart';
import '../models/dispatch_tracking.dart';
import '../models/dispatcher.dart';
import 'dispatch_service.dart';
import 'dispatcher_service.dart';

/// Service for synchronizing data between the main app and the dispatcher app
class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  
  final DispatchService _dispatchService = DispatchService();
  final DispatcherService _dispatcherService = DispatcherService();
  
  // Sync interval in minutes
  static const int syncIntervalMinutes = 5;
  Timer? _syncTimer;
  
  // Sync status
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String _lastSyncStatus = 'Not synced';
  
  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get lastSyncStatus => _lastSyncStatus;
  
  // Initialize the service
  Future<void> initialize() async {
    // Start periodic sync
    _startPeriodicSync();
  }
  
  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: syncIntervalMinutes),
      (_) => syncData(),
    );
  }
  
  // Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Sync data between apps
  Future<bool> syncData() async {
    if (_isSyncing) {
      return false; // Already syncing
    }
    
    _isSyncing = true;
    
    try {
      // In a real app, this would use a network service or shared database
      // For this demo, we'll simulate by writing to and reading from a file
      
      // 1. Export dispatches to a shared location
      await _exportDispatches();
      
      // 2. Export dispatchers to a shared location
      await _exportDispatchers();
      
      // 3. Import any updates from the shared location
      await _importUpdates();
      
      // Update sync status
      _lastSyncTime = DateTime.now();
      _lastSyncStatus = 'Sync completed successfully';
      
      return true;
    } catch (e) {
      debugPrint('Error syncing data: $e');
      _lastSyncStatus = 'Sync failed: $e';
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  // Export dispatches to a shared location
  Future<void> _exportDispatches() async {
    try {
      // Get all dispatches
      final dispatches = await _dispatchService.getAllDispatches();
      
      // Convert to JSON
      final dispatchesJson = dispatches.map((d) => d.toMap()).toList();
      
      // Write to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ecomcen_dispatches.json');
      await file.writeAsString(jsonEncode(dispatchesJson));
    } catch (e) {
      debugPrint('Error exporting dispatches: $e');
      rethrow;
    }
  }
  
  // Export dispatchers to a shared location
  Future<void> _exportDispatchers() async {
    try {
      // Get all dispatchers
      final dispatchers = await _dispatcherService.getDispatchers();
      
      // Convert to JSON
      final dispatchersJson = dispatchers.map((d) => d.toMap()).toList();
      
      // Write to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ecomcen_dispatchers.json');
      await file.writeAsString(jsonEncode(dispatchersJson));
    } catch (e) {
      debugPrint('Error exporting dispatchers: $e');
      rethrow;
    }
  }
  
  // Import updates from the shared location
  Future<void> _importUpdates() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Check for dispatch updates file
      final updatesFile = File('${directory.path}/ecomcen_dispatch_updates.json');
      
      if (await updatesFile.exists()) {
        // Read and parse updates
        final updatesJson = jsonDecode(await updatesFile.readAsString());
        
        // Process each update
        for (final update in updatesJson) {
          final dispatchId = update['dispatchId'];
          final newStatus = update['newStatus'];
          final notes = update['notes'];
          final location = update['location'];
          final handlerId = update['handlerId'];
          
          // Update dispatch status
          await _dispatchService.updateDispatchStatus(
            dispatchId,
            DispatchStatus.fromString(newStatus),
            notes: notes,
            location: location,
            handlerId: handlerId,
          );
        }
        
        // Delete the updates file after processing
        await updatesFile.delete();
      }
    } catch (e) {
      debugPrint('Error importing updates: $e');
      rethrow;
    }
  }
  
  // Add a dispatch update (called from dispatcher app)
  Future<bool> addDispatchUpdate({
    required String dispatchId,
    required String newStatus,
    required String notes,
    required String location,
    required String handlerId,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final updatesFile = File('${directory.path}/ecomcen_dispatch_updates.json');
      
      // Create update object
      final update = {
        'dispatchId': dispatchId,
        'newStatus': newStatus,
        'notes': notes,
        'location': location,
        'handlerId': handlerId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Read existing updates or create new list
      List<dynamic> updates = [];
      if (await updatesFile.exists()) {
        final content = await updatesFile.readAsString();
        if (content.isNotEmpty) {
          updates = jsonDecode(content);
        }
      }
      
      // Add new update
      updates.add(update);
      
      // Write back to file
      await updatesFile.writeAsString(jsonEncode(updates));
      
      return true;
    } catch (e) {
      debugPrint('Error adding dispatch update: $e');
      return false;
    }
  }
}
