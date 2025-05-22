import 'dart:math';
import '../models/dispatch.dart';
import '../models/dispatch_tracking.dart';

/// Service for managing dispatch data
class DispatchService {
  // Singleton pattern
  static final DispatchService _instance = DispatchService._internal();
  factory DispatchService() => _instance;
  DispatchService._internal();

  // In-memory storage for dispatches (in a real app, this would use a database)
  final List<IncomingDispatch> _incomingDispatches = [];
  final List<OutgoingDispatch> _outgoingDispatches = [];
  final List<LocalDispatch> _localDispatches = [];
  final List<ExternalDispatch> _externalDispatches = [];
  final List<DispatchLog> _comcenLogs = [];

  // Storage for trash dispatches
  final List<Dispatch> _trashDispatches = [];

  // Initialize the service
  void initialize() {
    // In a production app, this would load dispatches from a database
    // For now, we'll just initialize the collections
  }

  // Get all incoming dispatches
  List<IncomingDispatch> getIncomingDispatches() {
    return List.from(_incomingDispatches);
  }

  // Get all outgoing dispatches
  List<OutgoingDispatch> getOutgoingDispatches() {
    return List.from(_outgoingDispatches);
  }

  // Get all local dispatches
  List<LocalDispatch> getLocalDispatches() {
    return List.from(_localDispatches);
  }

  // Get all external dispatches
  List<ExternalDispatch> getExternalDispatches() {
    return List.from(_externalDispatches);
  }

  // Get all COMCEN logs
  List<DispatchLog> getComcenLogs() {
    return List.from(_comcenLogs);
  }

  // Get all dispatches (for synchronization)
  Future<List<Dispatch>> getAllDispatches() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Combine all dispatch types
    List<Dispatch> allDispatches = [];
    allDispatches.addAll(_incomingDispatches);
    allDispatches.addAll(_outgoingDispatches);
    allDispatches.addAll(_localDispatches);
    allDispatches.addAll(_externalDispatches);

    return allDispatches;
  }

  // Update dispatch status
  Future<bool> updateDispatchStatus(
    String dispatchId,
    DispatchStatus newStatus, {
    String? notes,
    String? location,
    String? handlerId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Find the dispatch in all collections
    Dispatch? dispatch;
    String dispatchType = '';

    // Check in incoming dispatches
    try {
      dispatch = _incomingDispatches.firstWhere((d) => d.id == dispatchId);
      dispatchType = 'incoming';
    } catch (_) {}

    // Check in outgoing dispatches
    if (dispatch == null) {
      try {
        dispatch = _outgoingDispatches.firstWhere((d) => d.id == dispatchId);
        dispatchType = 'outgoing';
      } catch (_) {}
    }

    // Check in local dispatches
    if (dispatch == null) {
      try {
        dispatch = _localDispatches.firstWhere((d) => d.id == dispatchId);
        dispatchType = 'local';
      } catch (_) {}
    }

    // Check in external dispatches
    if (dispatch == null) {
      try {
        dispatch = _externalDispatches.firstWhere((d) => d.id == dispatchId);
        dispatchType = 'external';
      } catch (_) {}
    }

    // If dispatch not found, return false
    if (dispatch == null) {
      return false;
    }

    // Create a new log entry
    final log = DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Status Updated',
      performedBy: handlerId ?? 'System',
      notes: notes ?? 'Status updated to ${newStatus.toString()}',
    );

    // Add log to dispatch
    dispatch.logs.add(log);

    // Since status is final, we need to create a new dispatch with the updated status
    // Update dispatch in the appropriate collection
    switch (dispatchType) {
      case 'incoming':
        final incomingDispatch = dispatch as IncomingDispatch;
        final updatedDispatch = IncomingDispatch(
          id: incomingDispatch.id,
          referenceNumber: incomingDispatch.referenceNumber,
          subject: incomingDispatch.subject,
          content: incomingDispatch.content,
          dateTime: incomingDispatch.dateTime,
          priority: incomingDispatch.priority,
          securityClassification: incomingDispatch.securityClassification,
          status: newStatus.toString(), // Update the status here
          handledBy: incomingDispatch.handledBy,
          sender: incomingDispatch.sender,
          senderUnit: incomingDispatch.senderUnit,
          receivedBy: incomingDispatch.receivedBy,
          receivedDate: incomingDispatch.receivedDate,
          attachments: incomingDispatch.attachments,
          logs: incomingDispatch.logs,
          trackingStatus: newStatus, // Update tracking status too
          enhancedLogs: incomingDispatch.enhancedLogs,
          deliveryAttempts: incomingDispatch.deliveryAttempts,
          route: incomingDispatch.route,
          estimatedDeliveryDate: incomingDispatch.estimatedDeliveryDate,
          currentLocation: location ?? incomingDispatch.currentLocation,
          isReturned: incomingDispatch.isReturned,
          returnReason: incomingDispatch.returnReason,
          currentHandler: incomingDispatch.currentHandler,
        );
        updateIncomingDispatch(updatedDispatch);
        break;
      case 'outgoing':
        final outgoingDispatch = dispatch as OutgoingDispatch;
        final updatedDispatch = OutgoingDispatch(
          id: outgoingDispatch.id,
          referenceNumber: outgoingDispatch.referenceNumber,
          subject: outgoingDispatch.subject,
          content: outgoingDispatch.content,
          dateTime: outgoingDispatch.dateTime,
          priority: outgoingDispatch.priority,
          securityClassification: outgoingDispatch.securityClassification,
          status: newStatus.toString(), // Update the status here
          handledBy: outgoingDispatch.handledBy,
          recipient: outgoingDispatch.recipient,
          recipientUnit: outgoingDispatch.recipientUnit,
          sentBy: outgoingDispatch.sentBy,
          sentDate: outgoingDispatch.sentDate,
          deliveryMethod: outgoingDispatch.deliveryMethod,
          attachments: outgoingDispatch.attachments,
          logs: outgoingDispatch.logs,
          trackingStatus: newStatus, // Update tracking status too
          enhancedLogs: outgoingDispatch.enhancedLogs,
          deliveryAttempts: outgoingDispatch.deliveryAttempts,
          route: outgoingDispatch.route,
          estimatedDeliveryDate: outgoingDispatch.estimatedDeliveryDate,
          currentLocation: location ?? outgoingDispatch.currentLocation,
          isReturned: outgoingDispatch.isReturned,
          returnReason: outgoingDispatch.returnReason,
          currentHandler: outgoingDispatch.currentHandler,
        );
        updateOutgoingDispatch(updatedDispatch);
        break;
      case 'local':
        final localDispatch = dispatch as LocalDispatch;
        final updatedDispatch = LocalDispatch(
          id: localDispatch.id,
          referenceNumber: localDispatch.referenceNumber,
          subject: localDispatch.subject,
          content: localDispatch.content,
          dateTime: localDispatch.dateTime,
          priority: localDispatch.priority,
          securityClassification: localDispatch.securityClassification,
          status: newStatus.toString(), // Update the status here
          handledBy: localDispatch.handledBy,
          sender: localDispatch.sender,
          senderDepartment: localDispatch.senderDepartment,
          recipient: localDispatch.recipient,
          recipientDepartment: localDispatch.recipientDepartment,
          internalReference: localDispatch.internalReference,
          attachments: localDispatch.attachments,
          logs: localDispatch.logs,
          trackingStatus: newStatus, // Update tracking status too
          enhancedLogs: localDispatch.enhancedLogs,
          deliveryAttempts: localDispatch.deliveryAttempts,
          route: localDispatch.route,
          estimatedDeliveryDate: localDispatch.estimatedDeliveryDate,
          currentLocation: location ?? localDispatch.currentLocation,
          isReturned: localDispatch.isReturned,
          returnReason: localDispatch.returnReason,
          currentHandler: localDispatch.currentHandler,
        );
        updateLocalDispatch(updatedDispatch);
        break;
      case 'external':
        final externalDispatch = dispatch as ExternalDispatch;
        final updatedDispatch = ExternalDispatch(
          id: externalDispatch.id,
          referenceNumber: externalDispatch.referenceNumber,
          subject: externalDispatch.subject,
          content: externalDispatch.content,
          dateTime: externalDispatch.dateTime,
          priority: externalDispatch.priority,
          securityClassification: externalDispatch.securityClassification,
          status: newStatus.toString(), // Update the status here
          handledBy: externalDispatch.handledBy,
          organization: externalDispatch.organization,
          contactPerson: externalDispatch.contactPerson,
          contactDetails: externalDispatch.contactDetails,
          isIncoming: externalDispatch.isIncoming,
          externalReference: externalDispatch.externalReference,
          attachments: externalDispatch.attachments,
          logs: externalDispatch.logs,
          trackingStatus: newStatus, // Update tracking status too
          enhancedLogs: externalDispatch.enhancedLogs,
          deliveryAttempts: externalDispatch.deliveryAttempts,
          route: externalDispatch.route,
          estimatedDeliveryDate: externalDispatch.estimatedDeliveryDate,
          currentLocation: location ?? externalDispatch.currentLocation,
          isReturned: externalDispatch.isReturned,
          returnReason: externalDispatch.returnReason,
          currentHandler: externalDispatch.currentHandler,
        );
        updateExternalDispatch(updatedDispatch);
        break;
    }

    return true;
  }

  // Get tracking logs for a specific dispatch
  Future<List<EnhancedDispatchLog>> getDispatchTrackingLogs(
    String dispatchId,
    String dispatchType,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Get the dispatch based on type
    Dispatch? dispatch;
    try {
      switch (dispatchType) {
        case 'incoming':
          dispatch = _incomingDispatches.firstWhere(
            (d) => d.id == dispatchId,
          );
          break;
        case 'outgoing':
          dispatch = _outgoingDispatches.firstWhere(
            (d) => d.id == dispatchId,
          );
          break;
        case 'local':
          dispatch = _localDispatches.firstWhere(
            (d) => d.id == dispatchId,
          );
          break;
        case 'external':
          dispatch = _externalDispatches.firstWhere(
            (d) => d.id == dispatchId,
          );
          break;
      }
    } catch (e) {
      // Dispatch not found
      dispatch = null;
    }

    // If dispatch has enhanced logs, return them
    if (dispatch?.enhancedLogs != null) {
      return dispatch!.enhancedLogs!;
    }

    // Otherwise, convert regular logs to enhanced logs
    final logs = <EnhancedDispatchLog>[];

    if (dispatch != null) {
      for (var log in dispatch.logs) {
        logs.add(
          EnhancedDispatchLog(
            id: log.id,
            timestamp: log.timestamp,
            action: log.action,
            performedBy: DispatchHandler(
              id: '1',
              name: log.performedBy,
              rank: 'Unknown',
              role: 'Handler',
              department: 'Signals',
            ),
            notes: log.notes,
          ),
        );
      }
    }

    return logs;
  }

  // Add a new incoming dispatch
  void addIncomingDispatch(IncomingDispatch dispatch) {
    _incomingDispatches.add(dispatch);
    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Added Incoming Dispatch',
      performedBy: 'Admin',
      notes:
          'Added incoming dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Add a new outgoing dispatch
  void addOutgoingDispatch(OutgoingDispatch dispatch) {
    _outgoingDispatches.add(dispatch);
    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Added Outgoing Dispatch',
      performedBy: 'Admin',
      notes:
          'Added outgoing dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Add a new local dispatch
  void addLocalDispatch(LocalDispatch dispatch) {
    _localDispatches.add(dispatch);
    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Added Local Dispatch',
      performedBy: 'Admin',
      notes: 'Added local dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Add a new external dispatch
  void addExternalDispatch(ExternalDispatch dispatch) {
    _externalDispatches.add(dispatch);
    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Added External Dispatch',
      performedBy: 'Admin',
      notes:
          'Added external dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Update an incoming dispatch
  void updateIncomingDispatch(IncomingDispatch updatedDispatch) {
    final index =
        _incomingDispatches.indexWhere((d) => d.id == updatedDispatch.id);
    if (index != -1) {
      _incomingDispatches[index] = updatedDispatch;
      _addLog(DispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: 'Updated Incoming Dispatch',
        performedBy: 'Admin',
        notes:
            'Updated incoming dispatch with reference: ${updatedDispatch.referenceNumber}',
      ));
    }
  }

  // Update an outgoing dispatch
  void updateOutgoingDispatch(OutgoingDispatch updatedDispatch) {
    final index =
        _outgoingDispatches.indexWhere((d) => d.id == updatedDispatch.id);
    if (index != -1) {
      _outgoingDispatches[index] = updatedDispatch;
      _addLog(DispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: 'Updated Outgoing Dispatch',
        performedBy: 'Admin',
        notes:
            'Updated outgoing dispatch with reference: ${updatedDispatch.referenceNumber}',
      ));
    }
  }

  // Update a local dispatch
  void updateLocalDispatch(LocalDispatch updatedDispatch) {
    final index =
        _localDispatches.indexWhere((d) => d.id == updatedDispatch.id);
    if (index != -1) {
      _localDispatches[index] = updatedDispatch;
      _addLog(DispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: 'Updated Local Dispatch',
        performedBy: 'Admin',
        notes:
            'Updated local dispatch with reference: ${updatedDispatch.referenceNumber}',
      ));
    }
  }

  // Update an external dispatch
  void updateExternalDispatch(ExternalDispatch updatedDispatch) {
    final index =
        _externalDispatches.indexWhere((d) => d.id == updatedDispatch.id);
    if (index != -1) {
      _externalDispatches[index] = updatedDispatch;
      _addLog(DispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: 'Updated External Dispatch',
        performedBy: 'Admin',
        notes:
            'Updated external dispatch with reference: ${updatedDispatch.referenceNumber}',
      ));
    }
  }

  // Delete an incoming dispatch
  void deleteIncomingDispatch(String id) {
    final dispatch = _incomingDispatches.firstWhere((d) => d.id == id);
    _incomingDispatches.removeWhere((d) => d.id == id);

    // Add to trash
    _trashDispatches.add(dispatch);

    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Deleted Incoming Dispatch',
      performedBy: 'Admin',
      notes:
          'Deleted incoming dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Delete an outgoing dispatch
  void deleteOutgoingDispatch(String id) {
    final dispatch = _outgoingDispatches.firstWhere((d) => d.id == id);
    _outgoingDispatches.removeWhere((d) => d.id == id);

    // Add to trash
    _trashDispatches.add(dispatch);

    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Deleted Outgoing Dispatch',
      performedBy: 'Admin',
      notes:
          'Deleted outgoing dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Delete a local dispatch
  void deleteLocalDispatch(String id) {
    final dispatch = _localDispatches.firstWhere((d) => d.id == id);
    _localDispatches.removeWhere((d) => d.id == id);

    // Add to trash
    _trashDispatches.add(dispatch);

    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Deleted Local Dispatch',
      performedBy: 'Admin',
      notes:
          'Deleted local dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Delete an external dispatch
  void deleteExternalDispatch(String id) {
    final dispatch = _externalDispatches.firstWhere((d) => d.id == id);
    _externalDispatches.removeWhere((d) => d.id == id);

    // Add to trash
    _trashDispatches.add(dispatch);

    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Deleted External Dispatch',
      performedBy: 'Admin',
      notes:
          'Deleted external dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Get all trash dispatches
  List<Dispatch> getTrashDispatches() {
    return List.from(_trashDispatches);
  }

  // Restore a dispatch from trash
  void restoreDispatch(String id) {
    final dispatch = _trashDispatches.firstWhere((d) => d.id == id);

    // Add back to appropriate list
    if (dispatch is IncomingDispatch) {
      _incomingDispatches.add(dispatch);
    } else if (dispatch is OutgoingDispatch) {
      _outgoingDispatches.add(dispatch);
    } else if (dispatch is LocalDispatch) {
      _localDispatches.add(dispatch);
    } else if (dispatch is ExternalDispatch) {
      _externalDispatches.add(dispatch);
    }

    // Remove from trash
    _trashDispatches.removeWhere((d) => d.id == id);

    // Add log
    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Restored Dispatch',
      performedBy: 'Admin',
      notes: 'Restored dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Permanently delete a dispatch from trash
  void permanentlyDeleteDispatch(String id) {
    final dispatch = _trashDispatches.firstWhere((d) => d.id == id);
    _trashDispatches.removeWhere((d) => d.id == id);

    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Permanently Deleted Dispatch',
      performedBy: 'Admin',
      notes:
          'Permanently deleted dispatch with reference: ${dispatch.referenceNumber}',
    ));
  }

  // Empty trash (delete all dispatches in trash)
  void emptyTrash() {
    final count = _trashDispatches.length;
    _trashDispatches.clear();

    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Emptied Trash',
      performedBy: 'Admin',
      notes: 'Permanently deleted $count dispatches from trash',
    ));
  }

  // Add a log entry to COMCEN logs
  void _addLog(DispatchLog log) {
    _comcenLogs.add(log);
  }

  // Add a new COMCEN log directly
  void addComcenLog(DispatchLog log) {
    _comcenLogs.add(log);
  }

  // Update an existing COMCEN log
  void updateComcenLog(DispatchLog updatedLog) {
    final index = _comcenLogs.indexWhere((log) => log.id == updatedLog.id);
    if (index != -1) {
      _comcenLogs[index] = updatedLog;
    }
  }

  // Delete a COMCEN log
  void deleteComcenLog(String id) {
    _comcenLogs.removeWhere((log) => log.id == id);
  }

  // Generate a communication state report for rear link with filtering options
  Future<Map<String, dynamic>> generateCommunicationStateReport({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceType,
    String? performedBy,
    String? sortBy,
    bool sortAscending = false,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Start with all logs
    List<DispatchLog> filteredLogs = List.from(_comcenLogs);

    // Apply date range filter if provided
    if (startDate != null) {
      filteredLogs = filteredLogs
          .where((log) =>
              log.timestamp.isAfter(startDate) ||
              log.timestamp.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      // Add one day to include the end date fully
      final adjustedEndDate = endDate.add(const Duration(days: 1));
      filteredLogs = filteredLogs
          .where((log) => log.timestamp.isBefore(adjustedEndDate))
          .toList();
    }

    // Apply service type filter if provided
    if (serviceType != null && serviceType.isNotEmpty && serviceType != 'All') {
      filteredLogs = filteredLogs
          .where((log) =>
              log.action.toLowerCase().contains(serviceType.toLowerCase()) ||
              log.notes.toLowerCase().contains(serviceType.toLowerCase()))
          .toList();
    }

    // Apply performed by filter if provided
    if (performedBy != null && performedBy.isNotEmpty) {
      filteredLogs = filteredLogs
          .where((log) =>
              log.performedBy.toLowerCase().contains(performedBy.toLowerCase()))
          .toList();
    }

    // Apply sorting
    if (sortBy != null) {
      switch (sortBy) {
        case 'date':
          filteredLogs.sort((a, b) => sortAscending
              ? a.timestamp.compareTo(b.timestamp)
              : b.timestamp.compareTo(a.timestamp));
          break;
        case 'action':
          filteredLogs.sort((a, b) => sortAscending
              ? a.action.compareTo(b.action)
              : b.action.compareTo(a.action));
          break;
        case 'performedBy':
          filteredLogs.sort((a, b) => sortAscending
              ? a.performedBy.compareTo(b.performedBy)
              : b.performedBy.compareTo(a.performedBy));
          break;
        default:
          // Default sort by date (newest first)
          filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } else {
      // Default sort by date (newest first)
      filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // Get communication-specific logs for status determination
    final commLogs = filteredLogs
        .where((log) =>
            log.action.toLowerCase().contains('communication') ||
            log.action.toLowerCase().contains('communication link') ||
            log.action.toLowerCase().contains('network status') ||
            log.notes.toLowerCase().contains('communication') ||
            log.notes.toLowerCase().contains('network'))
        .toList();

    // Get the latest status
    String currentStatus = 'Unknown';
    DateTime lastChecked = DateTime.now();
    String lastCheckedBy = 'System';

    if (commLogs.isNotEmpty) {
      final latestLog = commLogs.first;
      lastChecked = latestLog.timestamp;
      lastCheckedBy = latestLog.performedBy;

      if (latestLog.notes.toLowerCase().contains('up') ||
          latestLog.notes.toLowerCase().contains('operational') ||
          latestLog.notes.toLowerCase().contains('working')) {
        currentStatus = 'Operational';
      } else if (latestLog.notes.toLowerCase().contains('down') ||
          latestLog.notes.toLowerCase().contains('failed') ||
          latestLog.notes.toLowerCase().contains('not working')) {
        currentStatus = 'Down';
      } else if (latestLog.notes.toLowerCase().contains('intermittent') ||
          latestLog.notes.toLowerCase().contains('unstable')) {
        currentStatus = 'Intermittent';
      } else if (latestLog.notes.toLowerCase().contains('maintenance')) {
        currentStatus = 'Under Maintenance';
      }
    }

    // Calculate uptime percentage (simplified example)
    int totalChecks = commLogs.length;
    int upChecks = commLogs
        .where((log) =>
            log.notes.toLowerCase().contains('up') ||
            log.notes.toLowerCase().contains('operational') ||
            log.notes.toLowerCase().contains('working'))
        .length;

    double uptimePercentage =
        totalChecks > 0 ? (upChecks / totalChecks) * 100 : 0;

    // Count services by type
    Map<String, int> servicesByType = {};
    for (var log in filteredLogs) {
      String serviceType = _determineServiceType(log);
      servicesByType[serviceType] = (servicesByType[serviceType] ?? 0) + 1;
    }

    // Return the enhanced report data
    return {
      'currentStatus': currentStatus,
      'lastChecked': lastChecked,
      'lastCheckedBy': lastCheckedBy,
      'uptimePercentage': uptimePercentage,
      'totalChecks': totalChecks,
      'logs': filteredLogs,
      'servicesByType': servicesByType,
      'totalServices': filteredLogs.length,
      'startDate': startDate,
      'endDate': endDate,
      'serviceType': serviceType,
      'performedBy': performedBy,
    };
  }

  // Helper method to determine service type from a log
  String _determineServiceType(DispatchLog log) {
    final action = log.action.toLowerCase();
    final notes = log.notes.toLowerCase();

    // Check action first
    if (action.contains('communication link status')) {
      return 'Communication Link Status';
    } else if (action.contains('network status')) {
      return 'Network Status';
    } else if (action.contains('system maintenance')) {
      return 'System Maintenance';
    } else if (action.contains('security audit')) {
      return 'Security Audit';
    } else if (action.contains('communication')) {
      return 'Communication';
    }

    // Then check notes for more context
    else if (notes.contains('communication link') ||
        notes.contains('link status')) {
      return 'Communication Link Status';
    } else if (notes.contains('network status') ||
        notes.contains('network check')) {
      return 'Network Status';
    } else if (notes.contains('system maintenance')) {
      return 'System Maintenance';
    } else if (notes.contains('security audit')) {
      return 'Security Audit';
    }

    // Then check more generic patterns
    else if (action.contains('add') || action.contains('creat')) {
      return 'Creation';
    } else if (action.contains('updat') || action.contains('edit')) {
      return 'Update';
    } else if (action.contains('delet')) {
      return 'Deletion';
    } else if (action.contains('receiv')) {
      return 'Receipt';
    } else if (action.contains('sent') || action.contains('send')) {
      return 'Transmission';
    } else if (action.contains('system') || action.contains('maintenance')) {
      return 'System Maintenance';
    } else if (action.contains('security') || action.contains('audit')) {
      return 'Security Audit';
    } else {
      return 'Other';
    }
  }

  // Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  // Find a dispatch by its reference number or originator's number
  Future<Dispatch?> findDispatchByReference(String searchNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Search in all dispatch types by reference number
    try {
      // Check incoming dispatches by reference number
      final incomingDispatch = _incomingDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == searchNumber.toLowerCase(),
      );
      return incomingDispatch;
    } catch (_) {}

    try {
      // Check outgoing dispatches by reference number
      final outgoingDispatch = _outgoingDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == searchNumber.toLowerCase(),
      );
      return outgoingDispatch;
    } catch (_) {}

    try {
      // Check local dispatches by reference number
      final localDispatch = _localDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == searchNumber.toLowerCase(),
      );
      return localDispatch;
    } catch (_) {}

    try {
      // Check external dispatches by reference number
      final externalDispatch = _externalDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == searchNumber.toLowerCase(),
      );
      return externalDispatch;
    } catch (_) {}

    // If not found by reference number, search by originator's number
    try {
      // Check incoming dispatches by originator's number
      final incomingDispatch = _incomingDispatches.firstWhere(
        (d) =>
            d.originatorsNumber.toLowerCase() == searchNumber.toLowerCase() &&
            d.originatorsNumber.isNotEmpty,
      );
      return incomingDispatch;
    } catch (_) {}

    try {
      // Check outgoing dispatches by originator's number (if applicable)
      final outgoingDispatch = _outgoingDispatches.firstWhere(
        (d) =>
            d is IncomingDispatch &&
            (d as IncomingDispatch).originatorsNumber.toLowerCase() ==
                searchNumber.toLowerCase() &&
            (d as IncomingDispatch).originatorsNumber.isNotEmpty,
      );
      return outgoingDispatch;
    } catch (_) {}

    // If no dispatch found, return null
    return null;
  }

  // Find dispatches by reference number or originator's number (returns multiple matches)
  Future<List<Dispatch>> findDispatchesByReference(String searchNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    List<Dispatch> results = [];

    // Search in all dispatch types
    // Add incoming dispatches that match
    results.addAll(_incomingDispatches.where((d) =>
        d.referenceNumber.toLowerCase().contains(searchNumber.toLowerCase()) ||
        (d.originatorsNumber.isNotEmpty &&
            d.originatorsNumber
                .toLowerCase()
                .contains(searchNumber.toLowerCase()))));

    // Add outgoing dispatches that match
    results.addAll(_outgoingDispatches.where((d) =>
        d.referenceNumber.toLowerCase().contains(searchNumber.toLowerCase())));

    // Add local dispatches that match
    results.addAll(_localDispatches.where((d) =>
        d.referenceNumber.toLowerCase().contains(searchNumber.toLowerCase())));

    // Add external dispatches that match
    results.addAll(_externalDispatches.where((d) =>
        d.referenceNumber.toLowerCase().contains(searchNumber.toLowerCase())));

    return results;
  }
}
