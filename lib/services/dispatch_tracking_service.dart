import 'dart:math';
import '../models/dispatch.dart';
import '../models/dispatch_tracking.dart';
import 'dispatch_service.dart';

/// Service for tracking dispatch progress and handling
class DispatchTrackingService {
  // Singleton pattern
  static final DispatchTrackingService _instance = DispatchTrackingService._internal();
  factory DispatchTrackingService() => _instance;
  DispatchTrackingService._internal();

  final DispatchService _dispatchService = DispatchService();

  // Update the status of an incoming dispatch
  void updateIncomingDispatchStatus(
    String dispatchId,
    DispatchStatus newStatus,
    DispatchHandler handler, {
    String notes = '',
    String? location,
    List<String>? attachments,
  }) {
    final dispatches = _dispatchService.getIncomingDispatches();
    final index = dispatches.indexWhere((d) => d.id == dispatchId);
    
    if (index != -1) {
      final dispatch = dispatches[index];
      final oldStatus = dispatch.trackingStatus;
      
      // Create enhanced log entry
      final logEntry = EnhancedDispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: 'Status Updated: ${oldStatus?.label ?? dispatch.status} → ${newStatus.label}',
        performedBy: handler,
        notes: notes,
        oldStatus: oldStatus,
        newStatus: newStatus,
        location: location,
        attachments: attachments,
      );
      
      // Create updated dispatch with new status
      final updatedDispatch = IncomingDispatch(
        id: dispatch.id,
        referenceNumber: dispatch.referenceNumber,
        subject: dispatch.subject,
        content: dispatch.content,
        dateTime: dispatch.dateTime,
        priority: dispatch.priority,
        securityClassification: dispatch.securityClassification,
        status: newStatus.label, // Update the status string
        handledBy: handler.name, // Update the handler
        sender: dispatch.sender,
        senderUnit: dispatch.senderUnit,
        receivedBy: dispatch.receivedBy,
        receivedDate: dispatch.receivedDate,
        attachments: dispatch.attachments,
        logs: [
          ...dispatch.logs,
          DispatchLog(
            id: _generateId(),
            timestamp: DateTime.now(),
            action: 'Status Updated to ${newStatus.label}',
            performedBy: handler.name,
            notes: notes,
          ),
        ],
        // Enhanced tracking properties
        trackingStatus: newStatus,
        enhancedLogs: [
          ...(dispatch.enhancedLogs ?? []),
          logEntry,
        ],
        deliveryAttempts: dispatch.deliveryAttempts,
        route: dispatch.route,
        estimatedDeliveryDate: dispatch.estimatedDeliveryDate,
        currentLocation: location ?? dispatch.currentLocation,
        isReturned: newStatus == DispatchStatus.returned ? true : dispatch.isReturned,
        returnReason: newStatus == DispatchStatus.returned ? notes : dispatch.returnReason,
        currentHandler: handler,
      );
      
      // Update the dispatch in the service
      _dispatchService.updateIncomingDispatch(updatedDispatch);
    }
  }

  // Update the status of an outgoing dispatch
  void updateOutgoingDispatchStatus(
    String dispatchId,
    DispatchStatus newStatus,
    DispatchHandler handler, {
    String notes = '',
    String? location,
    List<String>? attachments,
  }) {
    final dispatches = _dispatchService.getOutgoingDispatches();
    final index = dispatches.indexWhere((d) => d.id == dispatchId);
    
    if (index != -1) {
      final dispatch = dispatches[index];
      final oldStatus = dispatch.trackingStatus;
      
      // Create enhanced log entry
      final logEntry = EnhancedDispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: 'Status Updated: ${oldStatus?.label ?? dispatch.status} → ${newStatus.label}',
        performedBy: handler,
        notes: notes,
        oldStatus: oldStatus,
        newStatus: newStatus,
        location: location,
        attachments: attachments,
      );
      
      // Create updated dispatch with new status
      final updatedDispatch = OutgoingDispatch(
        id: dispatch.id,
        referenceNumber: dispatch.referenceNumber,
        subject: dispatch.subject,
        content: dispatch.content,
        dateTime: dispatch.dateTime,
        priority: dispatch.priority,
        securityClassification: dispatch.securityClassification,
        status: newStatus.label, // Update the status string
        handledBy: handler.name, // Update the handler
        recipient: dispatch.recipient,
        recipientUnit: dispatch.recipientUnit,
        sentBy: dispatch.sentBy,
        sentDate: dispatch.sentDate,
        deliveryMethod: dispatch.deliveryMethod,
        attachments: dispatch.attachments,
        logs: [
          ...dispatch.logs,
          DispatchLog(
            id: _generateId(),
            timestamp: DateTime.now(),
            action: 'Status Updated to ${newStatus.label}',
            performedBy: handler.name,
            notes: notes,
          ),
        ],
        // Enhanced tracking properties
        trackingStatus: newStatus,
        enhancedLogs: [
          ...(dispatch.enhancedLogs ?? []),
          logEntry,
        ],
        deliveryAttempts: dispatch.deliveryAttempts,
        route: dispatch.route,
        estimatedDeliveryDate: dispatch.estimatedDeliveryDate,
        currentLocation: location ?? dispatch.currentLocation,
        isReturned: newStatus == DispatchStatus.returned ? true : dispatch.isReturned,
        returnReason: newStatus == DispatchStatus.returned ? notes : dispatch.returnReason,
        currentHandler: handler,
      );
      
      // Update the dispatch in the service
      _dispatchService.updateOutgoingDispatch(updatedDispatch);
    }
  }

  // Record a delivery attempt for an outgoing dispatch
  void recordDeliveryAttempt(
    String dispatchId,
    DispatchHandler attemptedBy,
    bool successful, {
    String notes = '',
    String? location,
    String? reason,
  }) {
    final dispatches = _dispatchService.getOutgoingDispatches();
    final index = dispatches.indexWhere((d) => d.id == dispatchId);
    
    if (index != -1) {
      final dispatch = dispatches[index];
      
      // Create delivery attempt
      final attempt = DeliveryAttempt(
        id: _generateId(),
        timestamp: DateTime.now(),
        attemptedBy: attemptedBy,
        successful: successful,
        notes: notes,
        location: location,
        reason: reason,
      );
      
      // Determine new status based on attempt result
      final newStatus = successful ? DispatchStatus.delivered : DispatchStatus.failed;
      
      // Create enhanced log entry
      final logEntry = EnhancedDispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: successful ? 'Delivery Successful' : 'Delivery Failed',
        performedBy: attemptedBy,
        notes: notes,
        oldStatus: dispatch.trackingStatus,
        newStatus: newStatus,
        location: location,
      );
      
      // Create updated dispatch with new delivery attempt
      final updatedDispatch = OutgoingDispatch(
        id: dispatch.id,
        referenceNumber: dispatch.referenceNumber,
        subject: dispatch.subject,
        content: dispatch.content,
        dateTime: dispatch.dateTime,
        priority: dispatch.priority,
        securityClassification: dispatch.securityClassification,
        status: successful ? 'Delivered' : 'Failed',
        handledBy: dispatch.handledBy,
        recipient: dispatch.recipient,
        recipientUnit: dispatch.recipientUnit,
        sentBy: dispatch.sentBy,
        sentDate: dispatch.sentDate,
        deliveryMethod: dispatch.deliveryMethod,
        attachments: dispatch.attachments,
        logs: [
          ...dispatch.logs,
          DispatchLog(
            id: _generateId(),
            timestamp: DateTime.now(),
            action: successful ? 'Delivery Successful' : 'Delivery Failed',
            performedBy: attemptedBy.name,
            notes: notes,
          ),
        ],
        // Enhanced tracking properties
        trackingStatus: newStatus,
        enhancedLogs: [
          ...(dispatch.enhancedLogs ?? []),
          logEntry,
        ],
        deliveryAttempts: [
          ...(dispatch.deliveryAttempts ?? []),
          attempt,
        ],
        route: dispatch.route,
        estimatedDeliveryDate: dispatch.estimatedDeliveryDate,
        currentLocation: location ?? dispatch.currentLocation,
        isReturned: !successful && reason != null ? true : dispatch.isReturned,
        returnReason: !successful && reason != null ? reason : dispatch.returnReason,
        currentHandler: attemptedBy,
      );
      
      // Update the dispatch in the service
      _dispatchService.updateOutgoingDispatch(updatedDispatch);
    }
  }

  // Assign a route to an outgoing dispatch
  void assignRoute(
    String dispatchId,
    String routeName,
    List<String> waypoints,
    DateTime estimatedDeliveryTime,
    DispatchHandler courier,
    String transportMethod,
  ) {
    final dispatches = _dispatchService.getOutgoingDispatches();
    final index = dispatches.indexWhere((d) => d.id == dispatchId);
    
    if (index != -1) {
      final dispatch = dispatches[index];
      
      // Create route
      final route = DispatchRoute(
        id: _generateId(),
        name: routeName,
        waypoints: waypoints,
        estimatedDeliveryTime: estimatedDeliveryTime,
        assignedCourier: courier,
        transportMethod: transportMethod,
        status: 'Planned',
      );
      
      // Create enhanced log entry
      final logEntry = EnhancedDispatchLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        action: 'Route Assigned',
        performedBy: courier,
        notes: 'Route: $routeName, Transport: $transportMethod',
        oldStatus: dispatch.trackingStatus,
        newStatus: DispatchStatus.inTransit,
      );
      
      // Create updated dispatch with new route
      final updatedDispatch = OutgoingDispatch(
        id: dispatch.id,
        referenceNumber: dispatch.referenceNumber,
        subject: dispatch.subject,
        content: dispatch.content,
        dateTime: dispatch.dateTime,
        priority: dispatch.priority,
        securityClassification: dispatch.securityClassification,
        status: 'In Transit',
        handledBy: dispatch.handledBy,
        recipient: dispatch.recipient,
        recipientUnit: dispatch.recipientUnit,
        sentBy: dispatch.sentBy,
        sentDate: dispatch.sentDate,
        deliveryMethod: dispatch.deliveryMethod,
        attachments: dispatch.attachments,
        logs: [
          ...dispatch.logs,
          DispatchLog(
            id: _generateId(),
            timestamp: DateTime.now(),
            action: 'Route Assigned',
            performedBy: courier.name,
            notes: 'Route: $routeName, Transport: $transportMethod',
          ),
        ],
        // Enhanced tracking properties
        trackingStatus: DispatchStatus.inTransit,
        enhancedLogs: [
          ...(dispatch.enhancedLogs ?? []),
          logEntry,
        ],
        deliveryAttempts: dispatch.deliveryAttempts,
        route: route,
        estimatedDeliveryDate: estimatedDeliveryTime,
        currentLocation: waypoints.isNotEmpty ? waypoints.first : dispatch.currentLocation,
        isReturned: dispatch.isReturned,
        returnReason: dispatch.returnReason,
        currentHandler: courier,
      );
      
      // Update the dispatch in the service
      _dispatchService.updateOutgoingDispatch(updatedDispatch);
    }
  }

  // Update route status and location
  void updateRouteStatus(
    String dispatchId,
    String routeStatus,
    String currentLocation,
    DispatchHandler handler, {
    DateTime? actualDeliveryTime,
    String notes = '',
  }) {
    final dispatches = _dispatchService.getOutgoingDispatches();
    final index = dispatches.indexWhere((d) => d.id == dispatchId);
    
    if (index != -1) {
      final dispatch = dispatches[index];
      
      if (dispatch.route != null) {
        // Determine new dispatch status based on route status
        DispatchStatus newStatus;
        switch (routeStatus.toLowerCase()) {
          case 'completed':
            newStatus = DispatchStatus.delivered;
            break;
          case 'in progress':
            newStatus = DispatchStatus.inTransit;
            break;
          case 'cancelled':
            newStatus = DispatchStatus.returned;
            break;
          default:
            newStatus = DispatchStatus.inTransit;
        }
        
        // Create updated route
        final updatedRoute = DispatchRoute(
          id: dispatch.route!.id,
          name: dispatch.route!.name,
          waypoints: dispatch.route!.waypoints,
          estimatedDeliveryTime: dispatch.route!.estimatedDeliveryTime,
          assignedCourier: dispatch.route!.assignedCourier,
          transportMethod: dispatch.route!.transportMethod,
          status: routeStatus,
          actualDeliveryTime: actualDeliveryTime ?? dispatch.route!.actualDeliveryTime,
        );
        
        // Create enhanced log entry
        final logEntry = EnhancedDispatchLog(
          id: _generateId(),
          timestamp: DateTime.now(),
          action: 'Route Updated: $routeStatus',
          performedBy: handler,
          notes: notes,
          oldStatus: dispatch.trackingStatus,
          newStatus: newStatus,
          location: currentLocation,
        );
        
        // Create updated dispatch with updated route
        final updatedDispatch = OutgoingDispatch(
          id: dispatch.id,
          referenceNumber: dispatch.referenceNumber,
          subject: dispatch.subject,
          content: dispatch.content,
          dateTime: dispatch.dateTime,
          priority: dispatch.priority,
          securityClassification: dispatch.securityClassification,
          status: newStatus.label,
          handledBy: dispatch.handledBy,
          recipient: dispatch.recipient,
          recipientUnit: dispatch.recipientUnit,
          sentBy: dispatch.sentBy,
          sentDate: dispatch.sentDate,
          deliveryMethod: dispatch.deliveryMethod,
          attachments: dispatch.attachments,
          logs: [
            ...dispatch.logs,
            DispatchLog(
              id: _generateId(),
              timestamp: DateTime.now(),
              action: 'Route Updated: $routeStatus',
              performedBy: handler.name,
              notes: notes,
            ),
          ],
          // Enhanced tracking properties
          trackingStatus: newStatus,
          enhancedLogs: [
            ...(dispatch.enhancedLogs ?? []),
            logEntry,
          ],
          deliveryAttempts: dispatch.deliveryAttempts,
          route: updatedRoute,
          estimatedDeliveryDate: dispatch.estimatedDeliveryDate,
          currentLocation: currentLocation,
          isReturned: routeStatus.toLowerCase() == 'cancelled' ? true : dispatch.isReturned,
          returnReason: routeStatus.toLowerCase() == 'cancelled' ? notes : dispatch.returnReason,
          currentHandler: handler,
        );
        
        // Update the dispatch in the service
        _dispatchService.updateOutgoingDispatch(updatedDispatch);
      }
    }
  }

  // Mark a dispatch as returned
  void markDispatchReturned(
    String dispatchId,
    String dispatchType,
    DispatchHandler handler,
    String reason, {
    String? location,
    String notes = '',
  }) {
    switch (dispatchType.toLowerCase()) {
      case 'incoming':
        final dispatches = _dispatchService.getIncomingDispatches();
        final index = dispatches.indexWhere((d) => d.id == dispatchId);
        
        if (index != -1) {
          final dispatch = dispatches[index];
          
          // Create enhanced log entry
          final logEntry = EnhancedDispatchLog(
            id: _generateId(),
            timestamp: DateTime.now(),
            action: 'Dispatch Returned',
            performedBy: handler,
            notes: 'Reason: $reason\n$notes',
            oldStatus: dispatch.trackingStatus,
            newStatus: DispatchStatus.returned,
            location: location,
          );
          
          // Create updated dispatch
          final updatedDispatch = IncomingDispatch(
            id: dispatch.id,
            referenceNumber: dispatch.referenceNumber,
            subject: dispatch.subject,
            content: dispatch.content,
            dateTime: dispatch.dateTime,
            priority: dispatch.priority,
            securityClassification: dispatch.securityClassification,
            status: 'Returned',
            handledBy: handler.name,
            sender: dispatch.sender,
            senderUnit: dispatch.senderUnit,
            receivedBy: dispatch.receivedBy,
            receivedDate: dispatch.receivedDate,
            attachments: dispatch.attachments,
            logs: [
              ...dispatch.logs,
              DispatchLog(
                id: _generateId(),
                timestamp: DateTime.now(),
                action: 'Dispatch Returned',
                performedBy: handler.name,
                notes: 'Reason: $reason\n$notes',
              ),
            ],
            // Enhanced tracking properties
            trackingStatus: DispatchStatus.returned,
            enhancedLogs: [
              ...(dispatch.enhancedLogs ?? []),
              logEntry,
            ],
            deliveryAttempts: dispatch.deliveryAttempts,
            route: dispatch.route,
            estimatedDeliveryDate: dispatch.estimatedDeliveryDate,
            currentLocation: location ?? dispatch.currentLocation,
            isReturned: true,
            returnReason: reason,
            currentHandler: handler,
          );
          
          // Update the dispatch in the service
          _dispatchService.updateIncomingDispatch(updatedDispatch);
        }
        break;
        
      case 'outgoing':
        final dispatches = _dispatchService.getOutgoingDispatches();
        final index = dispatches.indexWhere((d) => d.id == dispatchId);
        
        if (index != -1) {
          final dispatch = dispatches[index];
          
          // Create enhanced log entry
          final logEntry = EnhancedDispatchLog(
            id: _generateId(),
            timestamp: DateTime.now(),
            action: 'Dispatch Returned',
            performedBy: handler,
            notes: 'Reason: $reason\n$notes',
            oldStatus: dispatch.trackingStatus,
            newStatus: DispatchStatus.returned,
            location: location,
          );
          
          // Create updated dispatch
          final updatedDispatch = OutgoingDispatch(
            id: dispatch.id,
            referenceNumber: dispatch.referenceNumber,
            subject: dispatch.subject,
            content: dispatch.content,
            dateTime: dispatch.dateTime,
            priority: dispatch.priority,
            securityClassification: dispatch.securityClassification,
            status: 'Returned',
            handledBy: handler.name,
            recipient: dispatch.recipient,
            recipientUnit: dispatch.recipientUnit,
            sentBy: dispatch.sentBy,
            sentDate: dispatch.sentDate,
            deliveryMethod: dispatch.deliveryMethod,
            attachments: dispatch.attachments,
            logs: [
              ...dispatch.logs,
              DispatchLog(
                id: _generateId(),
                timestamp: DateTime.now(),
                action: 'Dispatch Returned',
                performedBy: handler.name,
                notes: 'Reason: $reason\n$notes',
              ),
            ],
            // Enhanced tracking properties
            trackingStatus: DispatchStatus.returned,
            enhancedLogs: [
              ...(dispatch.enhancedLogs ?? []),
              logEntry,
            ],
            deliveryAttempts: dispatch.deliveryAttempts,
            route: dispatch.route,
            estimatedDeliveryDate: dispatch.estimatedDeliveryDate,
            currentLocation: location ?? dispatch.currentLocation,
            isReturned: true,
            returnReason: reason,
            currentHandler: handler,
          );
          
          // Update the dispatch in the service
          _dispatchService.updateOutgoingDispatch(updatedDispatch);
        }
        break;
        
      // Add cases for local and external dispatches as needed
    }
  }

  // Get all returned dispatches
  List<Dispatch> getReturnedDispatches() {
    final List<Dispatch> returnedDispatches = [];
    
    // Get returned incoming dispatches
    returnedDispatches.addAll(
      _dispatchService.getIncomingDispatches().where((d) => 
        d.isReturned == true || 
        d.status.toLowerCase() == 'returned' ||
        d.trackingStatus == DispatchStatus.returned
      )
    );
    
    // Get returned outgoing dispatches
    returnedDispatches.addAll(
      _dispatchService.getOutgoingDispatches().where((d) => 
        d.isReturned == true || 
        d.status.toLowerCase() == 'returned' ||
        d.trackingStatus == DispatchStatus.returned
      )
    );
    
    // Get returned local dispatches
    returnedDispatches.addAll(
      _dispatchService.getLocalDispatches().where((d) => 
        d.isReturned == true || 
        d.status.toLowerCase() == 'returned' ||
        d.trackingStatus == DispatchStatus.returned
      )
    );
    
    // Get returned external dispatches
    returnedDispatches.addAll(
      _dispatchService.getExternalDispatches().where((d) => 
        d.isReturned == true || 
        d.status.toLowerCase() == 'returned' ||
        d.trackingStatus == DispatchStatus.returned
      )
    );
    
    return returnedDispatches;
  }

  // Get all failed delivery attempts
  List<DeliveryAttempt> getFailedDeliveryAttempts() {
    final List<DeliveryAttempt> failedAttempts = [];
    
    // Check outgoing dispatches for failed delivery attempts
    for (final dispatch in _dispatchService.getOutgoingDispatches()) {
      if (dispatch.deliveryAttempts != null) {
        failedAttempts.addAll(
          dispatch.deliveryAttempts!.where((attempt) => !attempt.successful)
        );
      }
    }
    
    return failedAttempts;
  }

  // Get dispatches by handler
  List<Dispatch> getDispatchesByHandler(String handlerName) {
    final List<Dispatch> handlerDispatches = [];
    
    // Check incoming dispatches
    handlerDispatches.addAll(
      _dispatchService.getIncomingDispatches().where((d) => 
        d.handledBy.toLowerCase() == handlerName.toLowerCase() ||
        (d.currentHandler != null && 
         d.currentHandler!.name.toLowerCase() == handlerName.toLowerCase())
      )
    );
    
    // Check outgoing dispatches
    handlerDispatches.addAll(
      _dispatchService.getOutgoingDispatches().where((d) => 
        d.handledBy.toLowerCase() == handlerName.toLowerCase() ||
        (d.currentHandler != null && 
         d.currentHandler!.name.toLowerCase() == handlerName.toLowerCase())
      )
    );
    
    // Check local dispatches
    handlerDispatches.addAll(
      _dispatchService.getLocalDispatches().where((d) => 
        d.handledBy.toLowerCase() == handlerName.toLowerCase() ||
        (d.currentHandler != null && 
         d.currentHandler!.name.toLowerCase() == handlerName.toLowerCase())
      )
    );
    
    // Check external dispatches
    handlerDispatches.addAll(
      _dispatchService.getExternalDispatches().where((d) => 
        d.handledBy.toLowerCase() == handlerName.toLowerCase() ||
        (d.currentHandler != null && 
         d.currentHandler!.name.toLowerCase() == handlerName.toLowerCase())
      )
    );
    
    return handlerDispatches;
  }

  // Get dispatches by current location
  List<Dispatch> getDispatchesByLocation(String location) {
    final List<Dispatch> locationDispatches = [];
    
    // Check incoming dispatches
    locationDispatches.addAll(
      _dispatchService.getIncomingDispatches().where((d) => 
        d.currentLocation != null && 
        d.currentLocation!.toLowerCase().contains(location.toLowerCase())
      )
    );
    
    // Check outgoing dispatches
    locationDispatches.addAll(
      _dispatchService.getOutgoingDispatches().where((d) => 
        d.currentLocation != null && 
        d.currentLocation!.toLowerCase().contains(location.toLowerCase())
      )
    );
    
    // Check local dispatches
    locationDispatches.addAll(
      _dispatchService.getLocalDispatches().where((d) => 
        d.currentLocation != null && 
        d.currentLocation!.toLowerCase().contains(location.toLowerCase())
      )
    );
    
    // Check external dispatches
    locationDispatches.addAll(
      _dispatchService.getExternalDispatches().where((d) => 
        d.currentLocation != null && 
        d.currentLocation!.toLowerCase().contains(location.toLowerCase())
      )
    );
    
    return locationDispatches;
  }

  // Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }
}
