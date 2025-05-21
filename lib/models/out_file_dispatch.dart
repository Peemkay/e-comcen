import 'package:cloud_firestore/cloud_firestore.dart';

class OutFileDispatch {
  final String id;
  final String referenceNumber;
  final String originatorsNumber;
  final String subject;
  final String? content;
  final DateTime dispatchDate;
  final String priority;
  final String securityClassification;
  final String status;
  final String senderUnit;
  final String? senderUnitId;
  final String recipientUnit;
  final String? recipientUnitId;
  final String handledBy;
  final String? receivedBy;
  final DateTime? timeHandedIn;
  final DateTime? timeCleared;
  final String deliveryMethod;
  final String? trackingNumber;
  final String? remarks;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  OutFileDispatch({
    required this.id,
    required this.referenceNumber,
    required this.originatorsNumber,
    required this.subject,
    this.content,
    required this.dispatchDate,
    required this.priority,
    required this.securityClassification,
    required this.status,
    required this.senderUnit,
    this.senderUnitId,
    required this.recipientUnit,
    this.recipientUnitId,
    required this.handledBy,
    this.receivedBy,
    this.timeHandedIn,
    this.timeCleared,
    required this.deliveryMethod,
    this.trackingNumber,
    this.remarks,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory OutFileDispatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OutFileDispatch(
      id: doc.id,
      referenceNumber: data['referenceNumber'] ?? '',
      originatorsNumber: data['originatorsNumber'] ?? '',
      subject: data['subject'] ?? '',
      content: data['content'],
      dispatchDate: (data['dispatchDate'] as Timestamp).toDate(),
      priority: data['priority'] ?? 'Routine',
      securityClassification: data['securityClassification'] ?? 'Unclassified',
      status: data['status'] ?? 'Pending',
      senderUnit: data['senderUnit'] ?? '',
      senderUnitId: data['senderUnitId'],
      recipientUnit: data['recipientUnit'] ?? '',
      recipientUnitId: data['recipientUnitId'],
      handledBy: data['handledBy'] ?? '',
      receivedBy: data['receivedBy'],
      timeHandedIn: data['timeHandedIn'] != null
          ? (data['timeHandedIn'] as Timestamp).toDate()
          : null,
      timeCleared: data['timeCleared'] != null
          ? (data['timeCleared'] as Timestamp).toDate()
          : null,
      deliveryMethod: data['deliveryMethod'] ?? 'Messenger',
      trackingNumber: data['trackingNumber'],
      remarks: data['remarks'],
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'referenceNumber': referenceNumber,
      'originatorsNumber': originatorsNumber,
      'subject': subject,
      'content': content,
      'dispatchDate': Timestamp.fromDate(dispatchDate),
      'priority': priority,
      'securityClassification': securityClassification,
      'status': status,
      'senderUnit': senderUnit,
      'senderUnitId': senderUnitId,
      'recipientUnit': recipientUnit,
      'recipientUnitId': recipientUnitId,
      'handledBy': handledBy,
      'receivedBy': receivedBy,
      'timeHandedIn':
          timeHandedIn != null ? Timestamp.fromDate(timeHandedIn!) : null,
      'timeCleared':
          timeCleared != null ? Timestamp.fromDate(timeCleared!) : null,
      'deliveryMethod': deliveryMethod,
      'trackingNumber': trackingNumber,
      'remarks': remarks,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  OutFileDispatch copyWith({
    String? id,
    String? referenceNumber,
    String? originatorsNumber,
    String? subject,
    String? content,
    DateTime? dispatchDate,
    String? priority,
    String? securityClassification,
    String? status,
    String? senderUnit,
    String? senderUnitId,
    String? recipientUnit,
    String? recipientUnitId,
    String? handledBy,
    String? receivedBy,
    DateTime? timeHandedIn,
    DateTime? timeCleared,
    String? deliveryMethod,
    String? trackingNumber,
    String? remarks,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OutFileDispatch(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      originatorsNumber: originatorsNumber ?? this.originatorsNumber,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      dispatchDate: dispatchDate ?? this.dispatchDate,
      priority: priority ?? this.priority,
      securityClassification:
          securityClassification ?? this.securityClassification,
      status: status ?? this.status,
      senderUnit: senderUnit ?? this.senderUnit,
      senderUnitId: senderUnitId ?? this.senderUnitId,
      recipientUnit: recipientUnit ?? this.recipientUnit,
      recipientUnitId: recipientUnitId ?? this.recipientUnitId,
      handledBy: handledBy ?? this.handledBy,
      receivedBy: receivedBy ?? this.receivedBy,
      timeHandedIn: timeHandedIn ?? this.timeHandedIn,
      timeCleared: timeCleared ?? this.timeCleared,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      remarks: remarks ?? this.remarks,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
