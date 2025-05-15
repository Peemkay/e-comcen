import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

/// Model class for file attachments
class FileAttachment {
  final String id;
  final String path;
  final String name;
  final int size;
  final String mimeType;
  final String referenceType;
  final String referenceId;
  final DateTime uploadDate;

  FileAttachment({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.referenceType,
    required this.referenceId,
    required this.uploadDate,
  });

  // Create from a file
  factory FileAttachment.fromFile({
    required File file,
    required String id,
    required String referenceType,
    required String referenceId,
  }) {
    return FileAttachment(
      id: id,
      path: file.path,
      name: p.basename(file.path),
      size: file.lengthSync(),
      mimeType: _getMimeType(file.path),
      referenceType: referenceType,
      referenceId: referenceId,
      uploadDate: DateTime.now(),
    );
  }

  // Create from JSON
  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      size: json['size'],
      mimeType: json['mimeType'],
      referenceType: json['referenceType'],
      referenceId: json['referenceId'],
      uploadDate: DateTime.parse(json['uploadDate']),
    );
  }

  // Create from Map (for database operations)
  factory FileAttachment.fromMap(Map<String, dynamic> map) {
    return FileAttachment(
      id: map['id'],
      path: map['path'],
      name: map['name'],
      size: map['size'],
      mimeType: map['mimeType'],
      referenceType: map['referenceType'],
      referenceId: map['referenceId'],
      uploadDate: DateTime.parse(map['uploadDate']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'size': size,
      'mimeType': mimeType,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }

  // Convert to Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'size': size,
      'mimeType': mimeType,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }

  // Create a copy with some fields replaced
  FileAttachment copyWith({
    String? id,
    String? path,
    String? name,
    int? size,
    String? mimeType,
    String? referenceType,
    String? referenceId,
    DateTime? uploadDate,
  }) {
    return FileAttachment(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      uploadDate: uploadDate ?? this.uploadDate,
    );
  }

  // Get formatted file size (KB, MB, etc.)
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Get formatted upload date
  String get uploadedAt {
    return DateFormat('yyyy-MM-dd HH:mm').format(uploadDate);
  }

  // Check if file is an image
  bool get isImage {
    return mimeType.startsWith('image/');
  }

  // Helper method to determine MIME type from file extension
  static String _getMimeType(String path) {
    final extension = p.extension(path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
