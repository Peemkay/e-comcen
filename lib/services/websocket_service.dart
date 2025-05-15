import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sync_message.dart';
import 'dispatch_service.dart';

/// Service for handling WebSocket communication between main app and dispatcher app
class WebSocketService {
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket server (for main app)
  HttpServer? _server;
  final List<WebSocket> _connectedClients = [];
  
  // WebSocket client (for dispatcher app)
  WebSocket? _clientSocket;
  
  // Message queue for offline operation
  final List<SyncMessage> _messageQueue = [];
  
  // Status
  bool _isServerRunning = false;
  bool _isClientConnected = false;
  
  // Stream controllers
  final StreamController<SyncMessage> _messageStreamController = 
      StreamController<SyncMessage>.broadcast();
  
  // Getters
  bool get isServerRunning => _isServerRunning;
  bool get isClientConnected => _isClientConnected;
  Stream<SyncMessage> get messageStream => _messageStreamController.stream;
  
  // Start WebSocket server (main app)
  Future<bool> startServer({int port = 8080}) async {
    if (_isServerRunning) return true;
    
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _isServerRunning = true;
      
      debugPrint('WebSocket server started on port $port');
      
      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/ecomcen-sync') {
          WebSocketTransformer.upgrade(request).then((WebSocket socket) {
            _handleClientConnection(socket);
          });
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
        }
      });
      
      return true;
    } catch (e) {
      debugPrint('Error starting WebSocket server: $e');
      return false;
    }
  }
  
  // Stop WebSocket server
  Future<void> stopServer() async {
    if (!_isServerRunning) return;
    
    try {
      // Close all client connections
      for (final client in _connectedClients) {
        client.close();
      }
      _connectedClients.clear();
      
      // Close server
      await _server?.close();
      _server = null;
      _isServerRunning = false;
      
      debugPrint('WebSocket server stopped');
    } catch (e) {
      debugPrint('Error stopping WebSocket server: $e');
    }
  }
  
  // Connect to WebSocket server (dispatcher app)
  Future<bool> connectToServer({String host = 'localhost', int port = 8080}) async {
    if (_isClientConnected) return true;
    
    try {
      _clientSocket = await WebSocket.connect('ws://$host:$port/ecomcen-sync');
      _isClientConnected = true;
      
      debugPrint('Connected to WebSocket server at $host:$port');
      
      // Listen for messages
      _clientSocket!.listen(
        (dynamic data) {
          _handleServerMessage(data);
        },
        onDone: () {
          _isClientConnected = false;
          debugPrint('Disconnected from WebSocket server');
          
          // Try to reconnect after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isClientConnected) {
              connectToServer(host: host, port: port);
            }
          });
        },
        onError: (error) {
          _isClientConnected = false;
          debugPrint('WebSocket error: $error');
        },
      );
      
      // Send any queued messages
      _sendQueuedMessages();
      
      return true;
    } catch (e) {
      debugPrint('Error connecting to WebSocket server: $e');
      
      // Queue messages for later sending
      _saveMessageQueue();
      
      // Try to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isClientConnected) {
          connectToServer(host: host, port: port);
        }
      });
      
      return false;
    }
  }
  
  // Disconnect from WebSocket server
  void disconnect() {
    if (!_isClientConnected) return;
    
    try {
      _clientSocket?.close();
      _clientSocket = null;
      _isClientConnected = false;
      
      debugPrint('Disconnected from WebSocket server');
    } catch (e) {
      debugPrint('Error disconnecting from WebSocket server: $e');
    }
  }
  
  // Send message to all clients (from server)
  void broadcastMessage(SyncMessage message) {
    if (!_isServerRunning) return;
    
    final messageJson = jsonEncode(message.toJson());
    
    for (final client in _connectedClients) {
      try {
        client.add(messageJson);
      } catch (e) {
        debugPrint('Error sending message to client: $e');
      }
    }
  }
  
  // Send message to server (from client)
  Future<bool> sendMessage(SyncMessage message) async {
    if (!_isClientConnected) {
      // Queue message for later sending
      _messageQueue.add(message);
      await _saveMessageQueue();
      return false;
    }
    
    try {
      final messageJson = jsonEncode(message.toJson());
      _clientSocket!.add(messageJson);
      return true;
    } catch (e) {
      debugPrint('Error sending message to server: $e');
      
      // Queue message for later sending
      _messageQueue.add(message);
      await _saveMessageQueue();
      
      return false;
    }
  }
  
  // Handle client connection (server side)
  void _handleClientConnection(WebSocket socket) {
    _connectedClients.add(socket);
    
    debugPrint('Client connected. Total clients: ${_connectedClients.length}');
    
    // Listen for messages from this client
    socket.listen(
      (dynamic data) {
        _handleClientMessage(data, socket);
      },
      onDone: () {
        _connectedClients.remove(socket);
        debugPrint('Client disconnected. Total clients: ${_connectedClients.length}');
      },
      onError: (error) {
        _connectedClients.remove(socket);
        debugPrint('Error from client: $error');
      },
    );
    
    // Send initial sync data to the new client
    _sendInitialSyncData(socket);
  }
  
  // Handle message from client (server side)
  void _handleClientMessage(dynamic data, WebSocket client) {
    try {
      final message = SyncMessage.fromJson(jsonDecode(data));
      
      // Process the message
      _messageStreamController.add(message);
      
      // Broadcast to other clients if needed
      if (message.broadcastToOthers) {
        for (final otherClient in _connectedClients) {
          if (otherClient != client) {
            otherClient.add(data);
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling client message: $e');
    }
  }
  
  // Handle message from server (client side)
  void _handleServerMessage(dynamic data) {
    try {
      final message = SyncMessage.fromJson(jsonDecode(data));
      
      // Process the message
      _messageStreamController.add(message);
    } catch (e) {
      debugPrint('Error handling server message: $e');
    }
  }
  
  // Send initial sync data to new client
  Future<void> _sendInitialSyncData(WebSocket client) async {
    try {
      final dispatchService = DispatchService();
      final dispatches = await dispatchService.getAllDispatches();
      
      // Create initial sync message
      final message = SyncMessage(
        type: SyncMessageType.initialSync,
        data: {
          'dispatches': dispatches.map((d) => d.toMap()).toList(),
        },
        timestamp: DateTime.now(),
      );
      
      // Send to client
      client.add(jsonEncode(message.toJson()));
    } catch (e) {
      debugPrint('Error sending initial sync data: $e');
    }
  }
  
  // Send queued messages
  Future<void> _sendQueuedMessages() async {
    if (!_isClientConnected || _messageQueue.isEmpty) return;
    
    final List<SyncMessage> successfullySent = [];
    
    for (final message in _messageQueue) {
      try {
        final messageJson = jsonEncode(message.toJson());
        _clientSocket!.add(messageJson);
        successfullySent.add(message);
      } catch (e) {
        debugPrint('Error sending queued message: $e');
        break;
      }
    }
    
    // Remove successfully sent messages from queue
    _messageQueue.removeWhere((m) => successfullySent.contains(m));
    
    // Save updated queue
    await _saveMessageQueue();
  }
  
  // Save message queue to file
  Future<void> _saveMessageQueue() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ecomcen_message_queue.json');
      
      final queueJson = jsonEncode(_messageQueue.map((m) => m.toJson()).toList());
      await file.writeAsString(queueJson);
    } catch (e) {
      debugPrint('Error saving message queue: $e');
    }
  }
  
  // Load message queue from file
  Future<void> loadMessageQueue() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ecomcen_message_queue.json');
      
      if (await file.exists()) {
        final queueJson = await file.readAsString();
        final queueData = jsonDecode(queueJson) as List<dynamic>;
        
        _messageQueue.clear();
        for (final item in queueData) {
          _messageQueue.add(SyncMessage.fromJson(item));
        }
        
        debugPrint('Loaded ${_messageQueue.length} queued messages');
      }
    } catch (e) {
      debugPrint('Error loading message queue: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    stopServer();
    disconnect();
    _messageStreamController.close();
  }
}
