// SyncMessage model for handling synchronization between devices
// This model is used for real-time communication between dispatchers and drivers

/// Types of synchronization messages that can be sent between devices
enum SyncMessageType {
  dispatchStatusChanged,
  dispatchLocationUpdated,
  dispatchDelivered,
  dispatchReturned,
  dispatcherStatusChanged,
  ping,
  pong,
  initialSync,
}

class SyncMessage {
  final SyncMessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? senderId;
  final bool broadcastToOthers;

  SyncMessage({
    required this.type,
    this.data = const {},
    DateTime? timestamp,
    this.senderId,
    this.broadcastToOthers = true,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      type: SyncMessageType.values.firstWhere(
        (e) => e.toString() == 'SyncMessageType.${json['type']}',
        orElse: () => SyncMessageType.ping,
      ),
      data: json['data'] ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      senderId: json['senderId'],
      broadcastToOthers: json['broadcastToOthers'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'broadcastToOthers': broadcastToOthers,
    };
  }
}
