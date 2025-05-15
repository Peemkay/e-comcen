import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dispatch_tracking.dart';
import '../models/sync_message.dart';
import 'dispatch_service.dart';
import 'dispatcher_service.dart';
import 'websocket_service.dart';

/// Service for synchronizing data between the main app and the dispatcher app
class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DispatchService _dispatchService = DispatchService();
  final DispatcherService _dispatcherService = DispatcherService();
  final WebSocketService _webSocketService = WebSocketService();

  // Sync interval in minutes (fallback for when WebSocket is not available)
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
  bool get isConnected =>
      _webSocketService.isServerRunning || _webSocketService.isClientConnected;

  // Initialize the service
  Future<void> initialize() async {
    // Start WebSocket server (for main app)
    await _webSocketService.startServer();

    // Load message queue
    await _webSocketService.loadMessageQueue();

    // Listen for WebSocket messages
    _setupWebSocketListeners();

    // Start periodic sync as fallback
    _startPeriodicSync();
  }

  // Setup WebSocket listeners
  void _setupWebSocketListeners() {
    _webSocketService.messageStream.listen((message) {
      _handleSyncMessage(message);
    });
  }

  // Handle incoming sync message
  Future<void> _handleSyncMessage(SyncMessage message) async {
    try {
      switch (message.type) {
        case SyncMessageType.dispatchStatusChanged:
          await _handleDispatchStatusChanged(message);
          break;
        case SyncMessageType.dispatchLocationUpdated:
          await _handleDispatchLocationUpdated(message);
          break;
        case SyncMessageType.dispatchDelivered:
          await _handleDispatchDelivered(message);
          break;
        case SyncMessageType.dispatchReturned:
          await _handleDispatchReturned(message);
          break;
        case SyncMessageType.dispatcherStatusChanged:
          await _handleDispatcherStatusChanged(message);
          break;
        case SyncMessageType.ping:
          _sendPongMessage(message.senderId);
          break;
        default:
          // Other message types handled elsewhere
          break;
      }

      // Update sync status
      _lastSyncTime = DateTime.now();
      _lastSyncStatus = 'Received ${message.type} message';
    } catch (e) {
      debugPrint('Error handling sync message: $e');
      _lastSyncStatus = 'Error handling message: $e';
    }
  }

  // Start periodic sync (fallback for when WebSocket is not available)
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

  // Sync data between apps (fallback method when WebSocket is not available)
  Future<bool> syncData() async {
    if (_isSyncing) {
      return false; // Already syncing
    }

    // If WebSocket is connected, prefer that method
    if (_webSocketService.isServerRunning ||
        _webSocketService.isClientConnected) {
      return true;
    }

    _isSyncing = true;

    try {
      // Fallback to file-based synchronization

      // 1. Export dispatches to a shared location
      await _exportDispatches();

      // 2. Export dispatchers to a shared location
      await _exportDispatchers();

      // 3. Import any updates from the shared location
      await _importUpdates();

      // Update sync status
      _lastSyncTime = DateTime.now();
      _lastSyncStatus = 'Sync completed successfully (file-based)';

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
      final updatesFile =
          File('${directory.path}/ecomcen_dispatch_updates.json');

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
      // First try to send via WebSocket
      if (_webSocketService.isClientConnected) {
        final message = SyncMessage(
          type: SyncMessageType.dispatchStatusChanged,
          data: {
            'dispatchId': dispatchId,
            'newStatus': newStatus,
            'notes': notes,
            'location': location,
            'handlerId': handlerId,
          },
          timestamp: DateTime.now(),
          senderId: handlerId,
        );

        final sent = await _webSocketService.sendMessage(message);
        if (sent) {
          return true;
        }
      }

      // Fallback to file-based method
      final directory = await getApplicationDocumentsDirectory();
      final updatesFile =
          File('${directory.path}/ecomcen_dispatch_updates.json');

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

  // Handle dispatch status changed message
  Future<void> _handleDispatchStatusChanged(SyncMessage message) async {
    final dispatchId = message.data['dispatchId'];
    final newStatus = message.data['newStatus'];
    final notes = message.data['notes'];
    final location = message.data['location'];
    final handlerId = message.data['handlerId'];

    // Update dispatch status
    await _dispatchService.updateDispatchStatus(
      dispatchId,
      DispatchStatus.fromString(newStatus),
      notes: notes,
      location: location,
      handlerId: handlerId,
    );

    // Broadcast to other clients if this is the server
    if (_webSocketService.isServerRunning && message.broadcastToOthers) {
      _webSocketService.broadcastMessage(message);
    }
  }

  // Handle dispatch location updated message
  Future<void> _handleDispatchLocationUpdated(SyncMessage message) async {
    final dispatchId = message.data['dispatchId'];
    final newLocation = message.data['location'];
    final handlerId = message.data['handlerId'];
    final notes = message.data['notes'];

    // Update dispatch location
    await _dispatchService.updateDispatchStatus(
      dispatchId,
      DispatchStatus.inTransit, // Keep the same status, just update location
      notes: notes,
      location: newLocation,
      handlerId: handlerId,
    );

    // Broadcast to other clients if this is the server
    if (_webSocketService.isServerRunning && message.broadcastToOthers) {
      _webSocketService.broadcastMessage(message);
    }
  }

  // Handle dispatch delivered message
  Future<void> _handleDispatchDelivered(SyncMessage message) async {
    final dispatchId = message.data['dispatchId'];
    final receiverName = message.data['receiverName'];
    final receiverRank = message.data['receiverRank'];
    final receiverId = message.data['receiverId'];
    final location = message.data['location'];
    final handlerId = message.data['handlerId'];
    final notes = message.data['notes'];

    // Update dispatch status to delivered
    await _dispatchService.updateDispatchStatus(
      dispatchId,
      DispatchStatus.delivered,
      notes: '$notes\nReceived by: $receiverRank $receiverName ($receiverId)',
      location: location,
      handlerId: handlerId,
    );

    // Broadcast to other clients if this is the server
    if (_webSocketService.isServerRunning && message.broadcastToOthers) {
      _webSocketService.broadcastMessage(message);
    }
  }

  // Handle dispatch returned message
  Future<void> _handleDispatchReturned(SyncMessage message) async {
    final dispatchId = message.data['dispatchId'];
    final reason = message.data['reason'];
    final location = message.data['location'];
    final handlerId = message.data['handlerId'];

    // Update dispatch status to returned
    await _dispatchService.updateDispatchStatus(
      dispatchId,
      DispatchStatus.returned,
      notes: 'Returned: $reason',
      location: location,
      handlerId: handlerId,
    );

    // Broadcast to other clients if this is the server
    if (_webSocketService.isServerRunning && message.broadcastToOthers) {
      _webSocketService.broadcastMessage(message);
    }
  }

  // Handle dispatcher status changed message
  Future<void> _handleDispatcherStatusChanged(SyncMessage message) async {
    final dispatcherId = message.data['dispatcherId'];
    final newStatus = message.data['status'];
    final location = message.data['location'];

    // Update dispatcher status
    // This would be implemented in a real app
    debugPrint(
        'Dispatcher $dispatcherId status changed to $newStatus at $location');

    // Broadcast to other clients if this is the server
    if (_webSocketService.isServerRunning && message.broadcastToOthers) {
      _webSocketService.broadcastMessage(message);
    }
  }

  // Send pong message in response to ping
  void _sendPongMessage(String? recipientId) {
    if (!_webSocketService.isServerRunning &&
        !_webSocketService.isClientConnected) {
      return;
    }

    final message = SyncMessage(
      type: SyncMessageType.pong,
      data: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      timestamp: DateTime.now(),
      broadcastToOthers: false,
    );

    if (_webSocketService.isServerRunning) {
      _webSocketService.broadcastMessage(message);
    } else if (_webSocketService.isClientConnected) {
      _webSocketService.sendMessage(message);
    }
  }

  // Dispose resources
  void dispose() {
    stopPeriodicSync();
    _webSocketService.dispose();
  }
}
