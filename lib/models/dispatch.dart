import 'package:flutter/material.dart';
import 'dispatch_tracking.dart';
import 'file_attachment.dart';

/// Base class for all dispatch types
abstract class Dispatch {
  final String id;
  final String referenceNumber;
  final String subject;
  final String content;
  final DateTime dateTime;
  final String priority; // Normal, Urgent, Flash
  final String
      securityClassification; // Unclassified, Restricted, Confidential, Secret, Top Secret
  final String status; // Pending, In Progress, Delivered, Received, Completed
  final String handledBy;
  final List<String> attachments; // Paths to attachments
  final List<FileAttachment>? fileAttachments; // Full attachment objects
  final List<DispatchLog> logs;

  // Enhanced tracking properties
  final DispatchStatus? trackingStatus;
  final List<EnhancedDispatchLog>? enhancedLogs;
  final List<DeliveryAttempt>? deliveryAttempts;
  final DispatchRoute? route;
  final DateTime? estimatedDeliveryDate;
  final String? currentLocation;
  final bool? isReturned;
  final String? returnReason;
  final DispatchHandler? currentHandler;

  Dispatch({
    required this.id,
    required this.referenceNumber,
    required this.subject,
    required this.content,
    required this.dateTime,
    required this.priority,
    required this.securityClassification,
    required this.status,
    required this.handledBy,
    this.attachments = const [],
    this.fileAttachments,
    this.logs = const [],
    this.trackingStatus,
    this.enhancedLogs,
    this.deliveryAttempts,
    this.route,
    this.estimatedDeliveryDate,
    this.currentLocation,
    this.isReturned,
    this.returnReason,
    this.currentHandler,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap();

  // Get color based on priority
  Color getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'urgent':
        return Colors.orange;
      case 'flash':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  // Get icon based on status
  IconData getStatusIcon() {
    // Use enhanced tracking status if available
    if (trackingStatus != null) {
      return trackingStatus!.icon;
    }

    // Fall back to basic status mapping
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in progress':
        return Icons.sync;
      case 'delivered':
        return Icons.local_shipping;
      case 'received':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      case 'returned':
        return Icons.assignment_return;
      case 'failed':
        return Icons.error;
      default:
        return Icons.pending;
    }
  }

  // Get color based on status
  Color getStatusColor() {
    // Use enhanced tracking status if available
    if (trackingStatus != null) {
      return trackingStatus!.color;
    }

    // Fall back to basic status mapping
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.amber;
      case 'delivered':
        return Colors.green;
      case 'received':
        return Colors.lightGreen;
      case 'completed':
        return Colors.green;
      case 'returned':
        return Colors.red;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Get icon based on priority
  IconData getPriorityIcon() {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
      case 'flash':
        return Icons.priority_high;
      case 'medium':
      case 'normal':
        return Icons.arrow_circle_up;
      case 'low':
      case 'routine':
        return Icons.arrow_circle_down;
      default:
        return Icons.arrow_circle_up;
    }
  }

  // Get formatted date
  String get formattedDate {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Get formatted time
  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Get sender (abstract method to be implemented by subclasses)
  String get sender;

  // Get recipient (abstract method to be implemented by subclasses)
  String get recipient;
}

/// Incoming Dispatch - dispatches received from external sources
class IncomingDispatch extends Dispatch {
  @override
  final String sender; // Renamed to "Delivered by" in UI
  final String senderUnit; // Renamed to "ADDR FROM" in UI
  final String receivedBy;
  final DateTime receivedDate;

  // New fields
  final String originatorsNumber; // Originator's Number
  final String addrTo; // ADDR TO
  final DateTime? timeHandedIn; // THI (Time Handed In)
  final DateTime? timeCleared; // TCL (Time Cleared)

  @override
  String get recipient => 'Internal';

  IncomingDispatch({
    required super.id,
    required super.referenceNumber,
    required super.subject,
    required super.content,
    required super.dateTime,
    required super.priority,
    required super.securityClassification,
    required super.status,
    required super.handledBy,
    required this.sender,
    required this.senderUnit,
    required this.receivedBy,
    required this.receivedDate,
    this.originatorsNumber = '',
    this.addrTo = '',
    this.timeHandedIn,
    this.timeCleared,
    super.attachments,
    super.fileAttachments,
    super.logs,
    super.trackingStatus,
    super.enhancedLogs,
    super.deliveryAttempts,
    super.route,
    super.estimatedDeliveryDate,
    super.currentLocation,
    super.isReturned,
    super.returnReason,
    super.currentHandler,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'originatorsNumber': originatorsNumber,
      'subject': subject,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
      'priority': priority,
      'securityClassification': securityClassification,
      'status': status,
      'handledBy': handledBy,
      'sender': sender, // Delivered by
      'senderUnit': senderUnit, // ADDR FROM
      'addrTo': addrTo, // ADDR TO
      'receivedBy': receivedBy,
      'receivedDate': receivedDate.toIso8601String(),
      'timeHandedIn': timeHandedIn?.toIso8601String(),
      'timeCleared': timeCleared?.toIso8601String(),
      'attachments': attachments,
      'fileAttachments':
          fileAttachments?.map((attachment) => attachment.toMap()).toList(),
      'logs': logs.map((log) => log.toMap()).toList(),
      // Enhanced tracking properties
      'trackingStatus': trackingStatus?.label,
      'enhancedLogs': enhancedLogs?.map((log) => log.toMap()).toList(),
      'deliveryAttempts':
          deliveryAttempts?.map((attempt) => attempt.toMap()).toList(),
      'route': route?.toMap(),
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'currentLocation': currentLocation,
      'isReturned': isReturned,
      'returnReason': returnReason,
      'currentHandler': currentHandler?.toMap(),
    };
  }

  // Create from Map for retrieval
  factory IncomingDispatch.fromMap(Map<String, dynamic> map) {
    return IncomingDispatch(
      id: map['id'],
      referenceNumber: map['referenceNumber'],
      originatorsNumber: map['originatorsNumber'] ?? '',
      subject: map['subject'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
      priority: map['priority'],
      securityClassification: map['securityClassification'],
      status: map['status'],
      handledBy: map['handledBy'],
      sender: map['sender'],
      senderUnit: map['senderUnit'],
      addrTo: map['addrTo'] ?? '',
      receivedBy: map['receivedBy'],
      receivedDate: DateTime.parse(map['receivedDate']),
      timeHandedIn: map['timeHandedIn'] != null
          ? DateTime.parse(map['timeHandedIn'])
          : null,
      timeCleared: map['timeCleared'] != null
          ? DateTime.parse(map['timeCleared'])
          : null,
      attachments: List<String>.from(map['attachments'] ?? []),
      fileAttachments: (map['fileAttachments'] as List?)
          ?.map((attachment) => FileAttachment.fromMap(attachment))
          .toList(),
      logs: (map['logs'] as List?)
              ?.map((log) => DispatchLog.fromMap(log))
              .toList() ??
          [],
      // Enhanced tracking properties
      trackingStatus: map['trackingStatus'] != null
          ? DispatchStatus.fromString(map['trackingStatus'])
          : null,
      enhancedLogs: (map['enhancedLogs'] as List?)
          ?.map((log) => EnhancedDispatchLog.fromMap(log))
          .toList(),
      deliveryAttempts: (map['deliveryAttempts'] as List?)
          ?.map((attempt) => DeliveryAttempt.fromMap(attempt))
          .toList(),
      route: map['route'] != null ? DispatchRoute.fromMap(map['route']) : null,
      estimatedDeliveryDate: map['estimatedDeliveryDate'] != null
          ? DateTime.parse(map['estimatedDeliveryDate'])
          : null,
      currentLocation: map['currentLocation'],
      isReturned: map['isReturned'],
      returnReason: map['returnReason'],
      currentHandler: map['currentHandler'] != null
          ? DispatchHandler.fromMap(map['currentHandler'])
          : null,
    );
  }
}

/// Outgoing Dispatch - dispatches sent to external recipients
class OutgoingDispatch extends Dispatch {
  @override
  final String recipient;
  final String recipientUnit;
  final String sentBy;
  final DateTime sentDate;
  final String deliveryMethod; // Physical, Electronic, Both

  @override
  String get sender => sentBy;

  OutgoingDispatch({
    required super.id,
    required super.referenceNumber,
    required super.subject,
    required super.content,
    required super.dateTime,
    required super.priority,
    required super.securityClassification,
    required super.status,
    required super.handledBy,
    required this.recipient,
    required this.recipientUnit,
    required this.sentBy,
    required this.sentDate,
    required this.deliveryMethod,
    super.attachments,
    super.fileAttachments,
    super.logs,
    super.trackingStatus,
    super.enhancedLogs,
    super.deliveryAttempts,
    super.route,
    super.estimatedDeliveryDate,
    super.currentLocation,
    super.isReturned,
    super.returnReason,
    super.currentHandler,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'subject': subject,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
      'priority': priority,
      'securityClassification': securityClassification,
      'status': status,
      'handledBy': handledBy,
      'recipient': recipient,
      'recipientUnit': recipientUnit,
      'sentBy': sentBy,
      'sentDate': sentDate.toIso8601String(),
      'deliveryMethod': deliveryMethod,
      'attachments': attachments,
      'fileAttachments':
          fileAttachments?.map((attachment) => attachment.toMap()).toList(),
      'logs': logs.map((log) => log.toMap()).toList(),
      // Enhanced tracking properties
      'trackingStatus': trackingStatus?.label,
      'enhancedLogs': enhancedLogs?.map((log) => log.toMap()).toList(),
      'deliveryAttempts':
          deliveryAttempts?.map((attempt) => attempt.toMap()).toList(),
      'route': route?.toMap(),
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'currentLocation': currentLocation,
      'isReturned': isReturned,
      'returnReason': returnReason,
      'currentHandler': currentHandler?.toMap(),
    };
  }

  // Create from Map for retrieval
  factory OutgoingDispatch.fromMap(Map<String, dynamic> map) {
    return OutgoingDispatch(
      id: map['id'],
      referenceNumber: map['referenceNumber'],
      subject: map['subject'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
      priority: map['priority'],
      securityClassification: map['securityClassification'],
      status: map['status'],
      handledBy: map['handledBy'],
      recipient: map['recipient'],
      recipientUnit: map['recipientUnit'],
      sentBy: map['sentBy'],
      sentDate: DateTime.parse(map['sentDate']),
      deliveryMethod: map['deliveryMethod'],
      attachments: List<String>.from(map['attachments'] ?? []),
      fileAttachments: (map['fileAttachments'] as List?)
          ?.map((attachment) => FileAttachment.fromMap(attachment))
          .toList(),
      logs: (map['logs'] as List?)
              ?.map((log) => DispatchLog.fromMap(log))
              .toList() ??
          [],
      // Enhanced tracking properties
      trackingStatus: map['trackingStatus'] != null
          ? DispatchStatus.fromString(map['trackingStatus'])
          : null,
      enhancedLogs: (map['enhancedLogs'] as List?)
          ?.map((log) => EnhancedDispatchLog.fromMap(log))
          .toList(),
      deliveryAttempts: (map['deliveryAttempts'] as List?)
          ?.map((attempt) => DeliveryAttempt.fromMap(attempt))
          .toList(),
      route: map['route'] != null ? DispatchRoute.fromMap(map['route']) : null,
      estimatedDeliveryDate: map['estimatedDeliveryDate'] != null
          ? DateTime.parse(map['estimatedDeliveryDate'])
          : null,
      currentLocation: map['currentLocation'],
      isReturned: map['isReturned'],
      returnReason: map['returnReason'],
      currentHandler: map['currentHandler'] != null
          ? DispatchHandler.fromMap(map['currentHandler'])
          : null,
    );
  }
}

/// Local Dispatch - dispatches within the same unit
class LocalDispatch extends Dispatch {
  @override
  final String sender;
  final String senderDepartment;
  @override
  final String recipient;
  final String recipientDepartment;
  final String internalReference;

  LocalDispatch({
    required super.id,
    required super.referenceNumber,
    required super.subject,
    required super.content,
    required super.dateTime,
    required super.priority,
    required super.securityClassification,
    required super.status,
    required super.handledBy,
    required this.sender,
    required this.senderDepartment,
    required this.recipient,
    required this.recipientDepartment,
    required this.internalReference,
    super.attachments,
    super.fileAttachments,
    super.logs,
    super.trackingStatus,
    super.enhancedLogs,
    super.deliveryAttempts,
    super.route,
    super.estimatedDeliveryDate,
    super.currentLocation,
    super.isReturned,
    super.returnReason,
    super.currentHandler,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'subject': subject,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
      'priority': priority,
      'securityClassification': securityClassification,
      'status': status,
      'handledBy': handledBy,
      'sender': sender,
      'senderDepartment': senderDepartment,
      'recipient': recipient,
      'recipientDepartment': recipientDepartment,
      'internalReference': internalReference,
      'attachments': attachments,
      'fileAttachments':
          fileAttachments?.map((attachment) => attachment.toMap()).toList(),
      'logs': logs.map((log) => log.toMap()).toList(),
      // Enhanced tracking properties
      'trackingStatus': trackingStatus?.label,
      'enhancedLogs': enhancedLogs?.map((log) => log.toMap()).toList(),
      'deliveryAttempts':
          deliveryAttempts?.map((attempt) => attempt.toMap()).toList(),
      'route': route?.toMap(),
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'currentLocation': currentLocation,
      'isReturned': isReturned,
      'returnReason': returnReason,
      'currentHandler': currentHandler?.toMap(),
    };
  }

  // Create from Map for retrieval
  factory LocalDispatch.fromMap(Map<String, dynamic> map) {
    return LocalDispatch(
      id: map['id'],
      referenceNumber: map['referenceNumber'],
      subject: map['subject'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
      priority: map['priority'],
      securityClassification: map['securityClassification'],
      status: map['status'],
      handledBy: map['handledBy'],
      sender: map['sender'],
      senderDepartment: map['senderDepartment'],
      recipient: map['recipient'],
      recipientDepartment: map['recipientDepartment'],
      internalReference: map['internalReference'],
      attachments: List<String>.from(map['attachments'] ?? []),
      fileAttachments: (map['fileAttachments'] as List?)
          ?.map((attachment) => FileAttachment.fromMap(attachment))
          .toList(),
      logs: (map['logs'] as List?)
              ?.map((log) => DispatchLog.fromMap(log))
              .toList() ??
          [],
      // Enhanced tracking properties
      trackingStatus: map['trackingStatus'] != null
          ? DispatchStatus.fromString(map['trackingStatus'])
          : null,
      enhancedLogs: (map['enhancedLogs'] as List?)
          ?.map((log) => EnhancedDispatchLog.fromMap(log))
          .toList(),
      deliveryAttempts: (map['deliveryAttempts'] as List?)
          ?.map((attempt) => DeliveryAttempt.fromMap(attempt))
          .toList(),
      route: map['route'] != null ? DispatchRoute.fromMap(map['route']) : null,
      estimatedDeliveryDate: map['estimatedDeliveryDate'] != null
          ? DateTime.parse(map['estimatedDeliveryDate'])
          : null,
      currentLocation: map['currentLocation'],
      isReturned: map['isReturned'],
      returnReason: map['returnReason'],
      currentHandler: map['currentHandler'] != null
          ? DispatchHandler.fromMap(map['currentHandler'])
          : null,
    );
  }
}

/// External Dispatch - dispatches to/from external organizations (non-military)
class ExternalDispatch extends Dispatch {
  final String organization;
  final String contactPerson;
  final String contactDetails;
  final bool
      isIncoming; // true if received from external org, false if sent to external org
  final String externalReference;

  @override
  String get sender => isIncoming ? organization : 'Nigerian Army Signal';

  @override
  String get recipient => isIncoming ? 'Nigerian Army Signal' : organization;

  ExternalDispatch({
    required super.id,
    required super.referenceNumber,
    required super.subject,
    required super.content,
    required super.dateTime,
    required super.priority,
    required super.securityClassification,
    required super.status,
    required super.handledBy,
    required this.organization,
    required this.contactPerson,
    required this.contactDetails,
    required this.isIncoming,
    required this.externalReference,
    super.attachments,
    super.fileAttachments,
    super.logs,
    super.trackingStatus,
    super.enhancedLogs,
    super.deliveryAttempts,
    super.route,
    super.estimatedDeliveryDate,
    super.currentLocation,
    super.isReturned,
    super.returnReason,
    super.currentHandler,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'subject': subject,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
      'priority': priority,
      'securityClassification': securityClassification,
      'status': status,
      'handledBy': handledBy,
      'organization': organization,
      'contactPerson': contactPerson,
      'contactDetails': contactDetails,
      'isIncoming': isIncoming,
      'externalReference': externalReference,
      'attachments': attachments,
      'fileAttachments':
          fileAttachments?.map((attachment) => attachment.toMap()).toList(),
      'logs': logs.map((log) => log.toMap()).toList(),
      // Enhanced tracking properties
      'trackingStatus': trackingStatus?.label,
      'enhancedLogs': enhancedLogs?.map((log) => log.toMap()).toList(),
      'deliveryAttempts':
          deliveryAttempts?.map((attempt) => attempt.toMap()).toList(),
      'route': route?.toMap(),
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'currentLocation': currentLocation,
      'isReturned': isReturned,
      'returnReason': returnReason,
      'currentHandler': currentHandler?.toMap(),
    };
  }

  // Create from Map for retrieval
  factory ExternalDispatch.fromMap(Map<String, dynamic> map) {
    return ExternalDispatch(
      id: map['id'],
      referenceNumber: map['referenceNumber'],
      subject: map['subject'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
      priority: map['priority'],
      securityClassification: map['securityClassification'],
      status: map['status'],
      handledBy: map['handledBy'],
      organization: map['organization'],
      contactPerson: map['contactPerson'],
      contactDetails: map['contactDetails'],
      isIncoming: map['isIncoming'],
      externalReference: map['externalReference'],
      attachments: List<String>.from(map['attachments'] ?? []),
      fileAttachments: (map['fileAttachments'] as List?)
          ?.map((attachment) => FileAttachment.fromMap(attachment))
          .toList(),
      logs: (map['logs'] as List?)
              ?.map((log) => DispatchLog.fromMap(log))
              .toList() ??
          [],
      // Enhanced tracking properties
      trackingStatus: map['trackingStatus'] != null
          ? DispatchStatus.fromString(map['trackingStatus'])
          : null,
      enhancedLogs: (map['enhancedLogs'] as List?)
          ?.map((log) => EnhancedDispatchLog.fromMap(log))
          .toList(),
      deliveryAttempts: (map['deliveryAttempts'] as List?)
          ?.map((attempt) => DeliveryAttempt.fromMap(attempt))
          .toList(),
      route: map['route'] != null ? DispatchRoute.fromMap(map['route']) : null,
      estimatedDeliveryDate: map['estimatedDeliveryDate'] != null
          ? DateTime.parse(map['estimatedDeliveryDate'])
          : null,
      currentLocation: map['currentLocation'],
      isReturned: map['isReturned'],
      returnReason: map['returnReason'],
      currentHandler: map['currentHandler'] != null
          ? DispatchHandler.fromMap(map['currentHandler'])
          : null,
    );
  }
}

/// Dispatch Log - tracks actions performed on a dispatch
class DispatchLog {
  final String id;
  final DateTime timestamp;
  final String action; // Received, Processed, Forwarded, Delivered, etc.
  final String performedBy;
  final String notes;

  DispatchLog({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.performedBy,
    this.notes = '',
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'performedBy': performedBy,
      'notes': notes,
    };
  }

  // Create from Map for retrieval
  factory DispatchLog.fromMap(Map<String, dynamic> map) {
    return DispatchLog(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      action: map['action'],
      performedBy: map['performedBy'],
      notes: map['notes'] ?? '',
    );
  }
}
