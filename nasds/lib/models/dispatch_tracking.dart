import 'package:flutter/material.dart';

/// Enum for dispatch status with more granular tracking
enum DispatchStatus {
  // Initial statuses
  created('Created', Icons.create, Colors.blue),
  pending('Pending', Icons.pending, Colors.orange),

  // Processing statuses
  inProgress('In Progress', Icons.sync, Colors.amber),
  forwarded('Forwarded', Icons.forward, Colors.indigo),

  // Delivery statuses
  dispatched('Dispatched', Icons.local_shipping, Colors.deepPurple),
  inTransit('In Transit', Icons.directions, Colors.teal),
  delivered('Delivered', Icons.local_shipping_outlined, Colors.green),
  received('Received', Icons.check_circle_outline, Colors.lightGreen),
  acknowledged('Acknowledged', Icons.thumb_up, Colors.green),

  // Completion statuses
  completed('Completed', Icons.done_all, Colors.green),
  archived('Archived', Icons.archive, Colors.grey),

  // Problem statuses
  delayed('Delayed', Icons.access_time, Colors.orange),
  failed('Failed', Icons.error_outline, Colors.red),
  returned('Returned', Icons.assignment_return, Colors.red),
  rejected('Rejected', Icons.not_interested, Colors.red);

  final String label;
  final IconData icon;
  final Color color;

  const DispatchStatus(this.label, this.icon, this.color);

  // Factory method to create from string
  static DispatchStatus fromString(String status) {
    final lowerStatus = status.toLowerCase();

    // Try exact match first
    try {
      return DispatchStatus.values.firstWhere(
        (value) => value.label.toLowerCase() == lowerStatus,
      );
    } catch (e) {
      // If no exact match, try partial match
      if (lowerStatus.contains('progress')) {
        return DispatchStatus.inProgress;
      } else if (lowerStatus.contains('deliver')) {
        return DispatchStatus.delivered;
      } else if (lowerStatus.contains('transit')) {
        return DispatchStatus.inTransit;
      } else if (lowerStatus.contains('receiv')) {
        return DispatchStatus.received;
      } else if (lowerStatus.contains('complet')) {
        return DispatchStatus.completed;
      } else if (lowerStatus.contains('fail')) {
        return DispatchStatus.failed;
      } else if (lowerStatus.contains('return')) {
        return DispatchStatus.returned;
      } else if (lowerStatus.contains('reject')) {
        return DispatchStatus.rejected;
      } else if (lowerStatus.contains('delay')) {
        return DispatchStatus.delayed;
      }

      // Default to pending if no match
      return DispatchStatus.pending;
    }
  }

  @override
  String toString() => label;
}

/// Class to track dispatch handlers
class DispatchHandler {
  final String id;
  final String name;
  final String rank;
  final String role; // e.g., "Dispatcher", "Receiver", "Courier", "Supervisor"
  final String department;
  final String contactInfo;

  DispatchHandler({
    required this.id,
    required this.name,
    required this.rank,
    required this.role,
    required this.department,
    this.contactInfo = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rank': rank,
      'role': role,
      'department': department,
      'contactInfo': contactInfo,
    };
  }

  factory DispatchHandler.fromMap(Map<String, dynamic> map) {
    return DispatchHandler(
      id: map['id'],
      name: map['name'],
      rank: map['rank'],
      role: map['role'],
      department: map['department'],
      contactInfo: map['contactInfo'] ?? '',
    );
  }
}

/// Enhanced dispatch log with more detailed tracking
class EnhancedDispatchLog {
  final String id;
  final DateTime timestamp;
  final String action;
  final DispatchHandler performedBy;
  final String notes;
  final DispatchStatus? oldStatus;
  final DispatchStatus? newStatus;
  final String? location;
  final List<String>? attachments;

  EnhancedDispatchLog({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.performedBy,
    this.notes = '',
    this.oldStatus,
    this.newStatus,
    this.location,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'performedBy': performedBy.toMap(),
      'notes': notes,
      'oldStatus': oldStatus?.label,
      'newStatus': newStatus?.label,
      'location': location,
      'attachments': attachments,
    };
  }

  factory EnhancedDispatchLog.fromMap(Map<String, dynamic> map) {
    return EnhancedDispatchLog(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      action: map['action'],
      performedBy: DispatchHandler.fromMap(map['performedBy']),
      notes: map['notes'] ?? '',
      oldStatus: map['oldStatus'] != null
          ? DispatchStatus.fromString(map['oldStatus'])
          : null,
      newStatus: map['newStatus'] != null
          ? DispatchStatus.fromString(map['newStatus'])
          : null,
      location: map['location'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
    );
  }
}

/// Class to track delivery attempts
class DeliveryAttempt {
  final String id;
  final DateTime timestamp;
  final DispatchHandler attemptedBy;
  final bool successful;
  final String notes;
  final String? location;
  final String? reason; // Reason for failure if unsuccessful

  DeliveryAttempt({
    required this.id,
    required this.timestamp,
    required this.attemptedBy,
    required this.successful,
    this.notes = '',
    this.location,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'attemptedBy': attemptedBy.toMap(),
      'successful': successful,
      'notes': notes,
      'location': location,
      'reason': reason,
    };
  }

  factory DeliveryAttempt.fromMap(Map<String, dynamic> map) {
    return DeliveryAttempt(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      attemptedBy: DispatchHandler.fromMap(map['attemptedBy']),
      successful: map['successful'],
      notes: map['notes'] ?? '',
      location: map['location'],
      reason: map['reason'],
    );
  }
}

/// Class to track dispatch routing
class DispatchRoute {
  final String id;
  final String name;
  final List<String> waypoints;
  final DateTime estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DispatchHandler assignedCourier;
  final String transportMethod; // e.g., "Vehicle", "Motorcycle", "Foot"
  final String
      status; // e.g., "Planned", "In Progress", "Completed", "Cancelled"

  DispatchRoute({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.estimatedDeliveryTime,
    required this.assignedCourier,
    required this.transportMethod,
    required this.status,
    this.actualDeliveryTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'waypoints': waypoints,
      'estimatedDeliveryTime': estimatedDeliveryTime.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'assignedCourier': assignedCourier.toMap(),
      'transportMethod': transportMethod,
      'status': status,
    };
  }

  factory DispatchRoute.fromMap(Map<String, dynamic> map) {
    return DispatchRoute(
      id: map['id'],
      name: map['name'],
      waypoints: List<String>.from(map['waypoints']),
      estimatedDeliveryTime: DateTime.parse(map['estimatedDeliveryTime']),
      actualDeliveryTime: map['actualDeliveryTime'] != null
          ? DateTime.parse(map['actualDeliveryTime'])
          : null,
      assignedCourier: DispatchHandler.fromMap(map['assignedCourier']),
      transportMethod: map['transportMethod'],
      status: map['status'],
    );
  }
}
