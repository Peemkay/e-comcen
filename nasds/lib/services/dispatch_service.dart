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

  // Initialize with sample data
  void initialize() {
    if (_incomingDispatches.isEmpty) {
      _generateSampleData();
    }
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
    _addLog(DispatchLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      action: 'Deleted External Dispatch',
      performedBy: 'Admin',
      notes:
          'Deleted external dispatch with reference: ${dispatch.referenceNumber}',
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

  // Generate a communication state report for rear link
  Future<Map<String, dynamic>> generateCommunicationStateReport() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Get relevant logs for communication state
    final commLogs = _comcenLogs
        .where((log) =>
            log.action.toLowerCase().contains('communication') ||
            log.action.toLowerCase().contains('rear link') ||
            log.notes.toLowerCase().contains('communication') ||
            log.notes.toLowerCase().contains('rear link'))
        .toList();

    // Sort by timestamp (newest first)
    commLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

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

    // Return the report data
    return {
      'currentStatus': currentStatus,
      'lastChecked': lastChecked,
      'lastCheckedBy': lastCheckedBy,
      'uptimePercentage': uptimePercentage,
      'totalChecks': totalChecks,
      'logs': commLogs,
    };
  }

  // Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  // Find a dispatch by its reference number
  Future<Dispatch?> findDispatchByReference(String referenceNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Search in all dispatch types
    try {
      // Check incoming dispatches
      final incomingDispatch = _incomingDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == referenceNumber.toLowerCase(),
      );
      return incomingDispatch;
    } catch (_) {}

    try {
      // Check outgoing dispatches
      final outgoingDispatch = _outgoingDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == referenceNumber.toLowerCase(),
      );
      return outgoingDispatch;
    } catch (_) {}

    try {
      // Check local dispatches
      final localDispatch = _localDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == referenceNumber.toLowerCase(),
      );
      return localDispatch;
    } catch (_) {}

    try {
      // Check external dispatches
      final externalDispatch = _externalDispatches.firstWhere(
        (d) => d.referenceNumber.toLowerCase() == referenceNumber.toLowerCase(),
      );
      return externalDispatch;
    } catch (_) {}

    // If no dispatch found, return null
    return null;
  }

  // Generate sample data for testing
  void _generateSampleData() {
    // Sample incoming dispatches
    _incomingDispatches.addAll([
      IncomingDispatch(
        id: '1',
        referenceNumber: 'IN-2023-001',
        subject: 'Weekly Situation Report',
        content: 'Weekly situation report from 3 Division Headquarters.',
        dateTime: DateTime.now().subtract(const Duration(days: 5)),
        priority: 'Normal',
        securityClassification: 'Restricted',
        status: 'Received',
        handledBy: 'Capt. Johnson',
        sender: 'Col. Ahmed',
        senderUnit: '3 Division HQ',
        receivedBy: 'Lt. Okafor',
        receivedDate: DateTime.now().subtract(const Duration(days: 5)),
        logs: [
          DispatchLog(
            id: '101',
            timestamp: DateTime.now().subtract(const Duration(days: 5)),
            action: 'Received',
            performedBy: 'Lt. Okafor',
            notes: 'Received from dispatch rider.',
          ),
          DispatchLog(
            id: '102',
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
            action: 'Processed',
            performedBy: 'Capt. Johnson',
            notes: 'Forwarded to commanding officer.',
          ),
        ],
        // Enhanced tracking properties
        trackingStatus: DispatchStatus.completed,
        enhancedLogs: [
          EnhancedDispatchLog(
            id: '201',
            timestamp: DateTime.now().subtract(const Duration(days: 5)),
            action: 'Created',
            performedBy: DispatchHandler(
              id: '101',
              name: 'Okafor',
              rank: 'Lt.',
              role: 'Dispatch Officer',
              department: 'Signals',
            ),
            oldStatus: null,
            newStatus: DispatchStatus.created,
            notes: 'Dispatch created in the system',
          ),
          EnhancedDispatchLog(
            id: '202',
            timestamp:
                DateTime.now().subtract(const Duration(days: 5, hours: 2)),
            action: 'Received',
            performedBy: DispatchHandler(
              id: '101',
              name: 'Okafor',
              rank: 'Lt.',
              role: 'Dispatch Officer',
              department: 'Signals',
            ),
            oldStatus: DispatchStatus.created,
            newStatus: DispatchStatus.received,
            notes: 'Received from dispatch rider',
            location: '3 Division HQ Reception',
          ),
          EnhancedDispatchLog(
            id: '203',
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
            action: 'Processed',
            performedBy: DispatchHandler(
              id: '102',
              name: 'Johnson',
              rank: 'Capt.',
              role: 'Staff Officer',
              department: 'Signals',
            ),
            oldStatus: DispatchStatus.received,
            newStatus: DispatchStatus.inProgress,
            notes: 'Forwarded to commanding officer',
          ),
          EnhancedDispatchLog(
            id: '204',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            action: 'Acknowledged',
            performedBy: DispatchHandler(
              id: '103',
              name: 'Musa',
              rank: 'Col.',
              role: 'Commanding Officer',
              department: 'Headquarters',
            ),
            oldStatus: DispatchStatus.inProgress,
            newStatus: DispatchStatus.acknowledged,
            notes: 'Acknowledged by commanding officer',
          ),
          EnhancedDispatchLog(
            id: '205',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            action: 'Completed',
            performedBy: DispatchHandler(
              id: '102',
              name: 'Johnson',
              rank: 'Capt.',
              role: 'Staff Officer',
              department: 'Signals',
            ),
            oldStatus: DispatchStatus.acknowledged,
            newStatus: DispatchStatus.completed,
            notes: 'All actions completed',
          ),
        ],
        currentHandler: DispatchHandler(
          id: '102',
          name: 'Johnson',
          rank: 'Capt.',
          role: 'Staff Officer',
          department: 'Signals',
          contactInfo: 'johnson@army.mil.ng',
        ),
      ),
      IncomingDispatch(
        id: '2',
        referenceNumber: 'IN-2023-002',
        subject: 'Operational Order',
        content: 'Operational order for upcoming joint exercise.',
        dateTime: DateTime.now().subtract(const Duration(days: 3)),
        priority: 'Urgent',
        securityClassification: 'Confidential',
        status: 'In Progress',
        handledBy: 'Maj. Ibrahim',
        sender: 'Brig. Gen. Musa',
        senderUnit: 'Army Headquarters',
        receivedBy: 'Capt. Adeyemi',
        receivedDate: DateTime.now().subtract(const Duration(days: 3)),
        logs: [
          DispatchLog(
            id: '103',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            action: 'Received',
            performedBy: 'Capt. Adeyemi',
            notes: 'Received via secure courier.',
          ),
        ],
      ),
    ]);

    // Sample outgoing dispatches
    _outgoingDispatches.addAll([
      OutgoingDispatch(
        id: '3',
        referenceNumber: 'OUT-2023-001',
        subject: 'Equipment Requisition',
        content: 'Requisition for communication equipment.',
        dateTime: DateTime.now().subtract(const Duration(days: 7)),
        priority: 'Normal',
        securityClassification: 'Unclassified',
        status: 'Delivered',
        handledBy: 'Lt. Col. Nnamdi',
        recipient: 'Col. Obasanjo',
        recipientUnit: 'Army Signals School',
        sentBy: 'Maj. Danjuma',
        sentDate: DateTime.now().subtract(const Duration(days: 7)),
        deliveryMethod: 'Physical',
        logs: [
          DispatchLog(
            id: '104',
            timestamp: DateTime.now().subtract(const Duration(days: 7)),
            action: 'Prepared',
            performedBy: 'Maj. Danjuma',
            notes: 'Prepared for delivery.',
          ),
          DispatchLog(
            id: '105',
            timestamp: DateTime.now().subtract(const Duration(days: 6)),
            action: 'Sent',
            performedBy: 'Sgt. Aliyu',
            notes: 'Sent via dispatch rider.',
          ),
          DispatchLog(
            id: '106',
            timestamp: DateTime.now().subtract(const Duration(days: 5)),
            action: 'Delivered',
            performedBy: 'Cpl. Emeka',
            notes: 'Confirmed delivery.',
          ),
        ],
        // Enhanced tracking properties
        trackingStatus: DispatchStatus.inTransit,
        enhancedLogs: [
          EnhancedDispatchLog(
            id: '301',
            timestamp: DateTime.now().subtract(const Duration(days: 7)),
            action: 'Created',
            performedBy: DispatchHandler(
              id: '201',
              name: 'Danjuma',
              rank: 'Maj.',
              role: 'Logistics Officer',
              department: 'Signals',
            ),
            oldStatus: null,
            newStatus: DispatchStatus.created,
            notes: 'Dispatch created in the system',
          ),
          EnhancedDispatchLog(
            id: '302',
            timestamp:
                DateTime.now().subtract(const Duration(days: 7, hours: 2)),
            action: 'Prepared',
            performedBy: DispatchHandler(
              id: '201',
              name: 'Danjuma',
              rank: 'Maj.',
              role: 'Logistics Officer',
              department: 'Signals',
            ),
            oldStatus: DispatchStatus.created,
            newStatus: DispatchStatus.pending,
            notes: 'Prepared for delivery',
          ),
          EnhancedDispatchLog(
            id: '303',
            timestamp: DateTime.now().subtract(const Duration(days: 6)),
            action: 'Dispatched',
            performedBy: DispatchHandler(
              id: '202',
              name: 'Aliyu',
              rank: 'Sgt.',
              role: 'Dispatch Rider',
              department: 'Signals',
            ),
            oldStatus: DispatchStatus.pending,
            newStatus: DispatchStatus.dispatched,
            notes: 'Sent via dispatch rider',
            location: 'HQ Dispatch Office',
          ),
          EnhancedDispatchLog(
            id: '304',
            timestamp:
                DateTime.now().subtract(const Duration(days: 5, hours: 12)),
            action: 'In Transit',
            performedBy: DispatchHandler(
              id: '202',
              name: 'Aliyu',
              rank: 'Sgt.',
              role: 'Dispatch Rider',
              department: 'Signals',
            ),
            oldStatus: DispatchStatus.dispatched,
            newStatus: DispatchStatus.inTransit,
            notes: 'En route to Army Signals School',
            location: 'Checkpoint Alpha',
          ),
        ],
        currentHandler: DispatchHandler(
          id: '202',
          name: 'Aliyu',
          rank: 'Sgt.',
          role: 'Dispatch Rider',
          department: 'Signals',
          contactInfo: 'aliyu@army.mil.ng',
        ),
        currentLocation: 'En route to Army Signals School',
        estimatedDeliveryDate: DateTime.now().add(const Duration(days: 1)),
        route: DispatchRoute(
          id: '101',
          name: 'HQ to Army Signals School',
          waypoints: [
            'HQ Dispatch Office',
            'Checkpoint Alpha',
            'Checkpoint Bravo',
            'Army Signals School'
          ],
          estimatedDeliveryTime: DateTime.now().add(const Duration(days: 1)),
          assignedCourier: DispatchHandler(
            id: '202',
            name: 'Aliyu',
            rank: 'Sgt.',
            role: 'Dispatch Rider',
            department: 'Signals',
          ),
          transportMethod: 'Vehicle',
          status: 'In Progress',
        ),
      ),
      OutgoingDispatch(
        id: '4',
        referenceNumber: 'OUT-2023-002',
        subject: 'Training Schedule',
        content: 'Updated training schedule for Q3 2023.',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        priority: 'Normal',
        securityClassification: 'Restricted',
        status: 'Sent',
        handledBy: 'Capt. Yusuf',
        recipient: 'Lt. Col. Abubakar',
        recipientUnit: '1 Division HQ',
        sentBy: 'Lt. Chukwu',
        sentDate: DateTime.now().subtract(const Duration(days: 2)),
        deliveryMethod: 'Electronic',
        logs: [
          DispatchLog(
            id: '107',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            action: 'Prepared',
            performedBy: 'Lt. Chukwu',
            notes: 'Prepared for electronic delivery.',
          ),
          DispatchLog(
            id: '108',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            action: 'Sent',
            performedBy: 'Lt. Chukwu',
            notes: 'Sent via secure email.',
          ),
        ],
      ),
    ]);

    // Sample local dispatches
    _localDispatches.addAll([
      LocalDispatch(
        id: '5',
        referenceNumber: 'LOC-2023-001',
        subject: 'Staff Meeting Minutes',
        content: 'Minutes from weekly staff meeting.',
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        priority: 'Normal',
        securityClassification: 'Unclassified',
        status: 'Completed',
        handledBy: 'Capt. Okonkwo',
        sender: 'Maj. Bello',
        senderDepartment: 'Operations',
        recipient: 'All Department Heads',
        recipientDepartment: 'All Departments',
        internalReference: 'MEET-2023-12',
        logs: [
          DispatchLog(
            id: '109',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            action: 'Created',
            performedBy: 'Capt. Okonkwo',
            notes: 'Created and distributed.',
          ),
          DispatchLog(
            id: '110',
            timestamp: DateTime.now().subtract(const Duration(hours: 20)),
            action: 'Received',
            performedBy: 'Various Recipients',
            notes: 'Acknowledged by all department heads.',
          ),
        ],
      ),
      LocalDispatch(
        id: '6',
        referenceNumber: 'LOC-2023-002',
        subject: 'Equipment Maintenance Schedule',
        content: 'Updated maintenance schedule for communication equipment.',
        dateTime: DateTime.now().subtract(const Duration(hours: 12)),
        priority: 'Normal',
        securityClassification: 'Unclassified',
        status: 'In Progress',
        handledBy: 'WO Garba',
        sender: 'Lt. Adamu',
        senderDepartment: 'Technical',
        recipient: 'Sgt. Eze',
        recipientDepartment: 'Maintenance',
        internalReference: 'MAINT-2023-05',
        logs: [
          DispatchLog(
            id: '111',
            timestamp: DateTime.now().subtract(const Duration(hours: 12)),
            action: 'Created',
            performedBy: 'Lt. Adamu',
            notes: 'Created maintenance schedule.',
          ),
        ],
      ),
    ]);

    // Sample external dispatches
    _externalDispatches.addAll([
      ExternalDispatch(
        id: '7',
        referenceNumber: 'EXT-2023-001',
        subject: 'Civilian Contractor Access',
        content:
            'Authorization for civilian contractors to access base facilities.',
        dateTime: DateTime.now().subtract(const Duration(days: 4)),
        priority: 'Normal',
        securityClassification: 'Restricted',
        status: 'Completed',
        handledBy: 'Maj. Usman',
        organization: 'TechBuild Nigeria Ltd',
        contactPerson: 'Mr. Olawale Johnson',
        contactDetails: 'olawale.johnson@techbuild.ng, 08012345678',
        isIncoming: false,
        externalReference: 'TB-AUTH-2023-42',
        logs: [
          DispatchLog(
            id: '112',
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
            action: 'Created',
            performedBy: 'Maj. Usman',
            notes: 'Created authorization letter.',
          ),
          DispatchLog(
            id: '113',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            action: 'Sent',
            performedBy: 'Cpl. Musa',
            notes: 'Sent to TechBuild Nigeria Ltd.',
          ),
          DispatchLog(
            id: '114',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            action: 'Acknowledged',
            performedBy: 'Mr. Olawale Johnson',
            notes: 'Receipt acknowledged by contractor.',
          ),
        ],
      ),
      ExternalDispatch(
        id: '8',
        referenceNumber: 'EXT-2023-002',
        subject: 'Equipment Delivery Notification',
        content:
            'Notification of upcoming delivery of communication equipment.',
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        priority: 'Urgent',
        securityClassification: 'Unclassified',
        status: 'Pending',
        handledBy: 'Capt. Abdullahi',
        organization: 'Global Communications Ltd',
        contactPerson: 'Ms. Amina Ibrahim',
        contactDetails: 'amina.ibrahim@globalcomms.com, 08087654321',
        isIncoming: true,
        externalReference: 'GCL-DEL-2023-18',
        logs: [
          DispatchLog(
            id: '115',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            action: 'Received',
            performedBy: 'Capt. Abdullahi',
            notes: 'Received notification from vendor.',
          ),
        ],
      ),
      ExternalDispatch(
        id: '9',
        referenceNumber: 'EXT-2023-003',
        subject: 'Urgent Equipment Transfer Request',
        content:
            'Request for urgent transfer of communication equipment to forward operating base.',
        dateTime: DateTime.now().subtract(const Duration(days: 3)),
        priority: 'Urgent',
        securityClassification: 'Restricted',
        status: 'Failed',
        handledBy: 'Maj. Oladele',
        organization: 'Forward Operating Base Delta',
        contactPerson: 'Lt. Col. Adebayo',
        contactDetails: 'adebayo@army.mil.ng, 08023456789',
        isIncoming: false,
        externalReference: 'FOB-EQ-2023-11',
        logs: [
          DispatchLog(
            id: '120',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            action: 'Created',
            performedBy: 'Maj. Oladele',
            notes: 'Urgent request prepared for immediate dispatch.',
          ),
          DispatchLog(
            id: '121',
            timestamp:
                DateTime.now().subtract(const Duration(days: 3, hours: 4)),
            action: 'Sent',
            performedBy: 'Capt. Adekunle',
            notes: 'Dispatched via military transport.',
          ),
          DispatchLog(
            id: '122',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            action: 'Failed',
            performedBy: 'Lt. Garba',
            notes: 'Delivery failed due to security situation in transit area.',
          ),
        ],
        // Enhanced tracking properties
        trackingStatus: DispatchStatus.failed,
        enhancedLogs: [
          EnhancedDispatchLog(
            id: '401',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            action: 'Created',
            performedBy: DispatchHandler(
              id: '301',
              name: 'Oladele',
              rank: 'Maj.',
              role: 'Operations Officer',
              department: 'Signals Corps',
            ),
            oldStatus: null,
            newStatus: DispatchStatus.created,
            notes: 'Urgent request prepared for immediate dispatch',
          ),
          EnhancedDispatchLog(
            id: '402',
            timestamp:
                DateTime.now().subtract(const Duration(days: 3, hours: 2)),
            action: 'Approved',
            performedBy: DispatchHandler(
              id: '302',
              name: 'Musa',
              rank: 'Col.',
              role: 'Commanding Officer',
              department: 'Signals Corps',
            ),
            oldStatus: DispatchStatus.created,
            newStatus: DispatchStatus.pending,
            notes: 'Request approved for immediate dispatch',
          ),
          EnhancedDispatchLog(
            id: '403',
            timestamp:
                DateTime.now().subtract(const Duration(days: 3, hours: 4)),
            action: 'Dispatched',
            performedBy: DispatchHandler(
              id: '303',
              name: 'Adekunle',
              rank: 'Capt.',
              role: 'Logistics Officer',
              department: 'Signals Corps',
            ),
            oldStatus: DispatchStatus.pending,
            newStatus: DispatchStatus.dispatched,
            notes: 'Dispatched via military transport',
            location: 'HQ Logistics Center',
          ),
          EnhancedDispatchLog(
            id: '404',
            timestamp:
                DateTime.now().subtract(const Duration(days: 2, hours: 6)),
            action: 'Delayed',
            performedBy: DispatchHandler(
              id: '304',
              name: 'Garba',
              rank: 'Lt.',
              role: 'Transport Officer',
              department: 'Signals Corps',
            ),
            oldStatus: DispatchStatus.dispatched,
            newStatus: DispatchStatus.delayed,
            notes: 'Transport delayed due to security concerns in transit area',
            location: 'Checkpoint Charlie',
          ),
          EnhancedDispatchLog(
            id: '405',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            action: 'Failed',
            performedBy: DispatchHandler(
              id: '304',
              name: 'Garba',
              rank: 'Lt.',
              role: 'Transport Officer',
              department: 'Signals Corps',
            ),
            oldStatus: DispatchStatus.delayed,
            newStatus: DispatchStatus.failed,
            notes: 'Delivery failed due to security situation in transit area',
            location: 'Checkpoint Charlie',
          ),
        ],
        currentHandler: DispatchHandler(
          id: '304',
          name: 'Garba',
          rank: 'Lt.',
          role: 'Transport Officer',
          department: 'Signals Corps',
          contactInfo: 'garba@army.mil.ng',
        ),
        currentLocation: 'Checkpoint Charlie',
        isReturned: true,
        returnReason:
            'Unable to proceed due to active insurgent activity in the transit corridor. Equipment being returned to HQ for rerouting.',
      ),
    ]);

    // Generate additional COMCEN logs
    _comcenLogs.addAll([
      DispatchLog(
        id: '201',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        action: 'System Maintenance',
        performedBy: 'System Admin',
        notes: 'Routine system maintenance performed.',
      ),
      DispatchLog(
        id: '202',
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        action: 'User Training',
        performedBy: 'Training Officer',
        notes: 'Conducted user training for new dispatch operators.',
      ),
      DispatchLog(
        id: '203',
        timestamp: DateTime.now().subtract(const Duration(days: 6)),
        action: 'Security Audit',
        performedBy: 'Security Officer',
        notes: 'Conducted quarterly security audit of dispatch procedures.',
      ),
    ]);
  }
}
