import 'dart:math';
import '../models/dispatcher.dart';
import '../models/user.dart';
import '../models/dispatch.dart';
import '../models/dispatch_tracking.dart';
import 'user_service.dart';
import 'dispatch_service.dart';

/// Service for managing dispatcher data and operations
class DispatcherService {
  // Singleton pattern
  static final DispatcherService _instance = DispatcherService._internal();
  factory DispatcherService() => _instance;
  DispatcherService._internal();
  
  final UserService _userService = UserService();
  final DispatchService _dispatchService = DispatchService();
  
  // In-memory storage for dispatchers
  final List<Dispatcher> _dispatchers = [];
  
  // Initialize with data
  Future<void> initialize() async {
    if (_dispatchers.isEmpty) {
      await _loadDispatchersFromUsers();
    }
  }
  
  // Load dispatchers from users with dispatcher role
  Future<void> _loadDispatchersFromUsers() async {
    final users = await _userService.getUsers();
    final dispatcherUsers = users.where((user) => user.role == UserRole.dispatcher);
    
    for (final user in dispatcherUsers) {
      if (!_dispatchers.any((d) => d.id == user.id)) {
        _dispatchers.add(
          Dispatcher.fromUser(
            user,
            dispatcherCode: _generateDispatcherCode(user),
          ),
        );
      }
    }
  }
  
  // Generate a unique dispatcher code
  String _generateDispatcherCode(User user) {
    final random = Random();
    final prefix = user.rank.substring(0, min(2, user.rank.length)).toUpperCase();
    final suffix = user.name.substring(0, min(3, user.name.length)).toUpperCase();
    final number = random.nextInt(9000) + 1000; // 4-digit number
    
    return '$prefix-$suffix-$number';
  }
  
  // Get all dispatchers
  Future<List<Dispatcher>> getDispatchers() async {
    await initialize();
    return List.from(_dispatchers);
  }
  
  // Get dispatcher by ID
  Future<Dispatcher?> getDispatcherById(String id) async {
    await initialize();
    try {
      return _dispatchers.firstWhere((dispatcher) => dispatcher.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get dispatcher by username
  Future<Dispatcher?> getDispatcherByUsername(String username) async {
    await initialize();
    try {
      return _dispatchers.firstWhere(
        (dispatcher) => dispatcher.username.toLowerCase() == username.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Assign dispatch to dispatcher
  Future<bool> assignDispatch(String dispatchId, String dispatcherId) async {
    final dispatcher = await getDispatcherById(dispatcherId);
    if (dispatcher == null) {
      return false;
    }
    
    // Check if dispatch exists
    final dispatch = await _dispatchService.findDispatchByReference(dispatchId);
    if (dispatch == null) {
      return false;
    }
    
    // Add to assigned dispatches if not already assigned
    if (!dispatcher.assignedDispatches.contains(dispatchId)) {
      final updatedAssignedDispatches = List<String>.from(dispatcher.assignedDispatches)
        ..add(dispatchId);
      
      final updatedDispatcher = dispatcher.copyWith(
        assignedDispatches: updatedAssignedDispatches,
      );
      
      // Update in list
      final index = _dispatchers.indexWhere((d) => d.id == dispatcherId);
      if (index != -1) {
        _dispatchers[index] = updatedDispatcher;
        return true;
      }
    }
    
    return false;
  }
  
  // Mark dispatch as completed by dispatcher
  Future<bool> completeDispatch(
    String dispatchId, 
    String dispatcherId,
    DispatchStatus newStatus,
    String notes,
    String location,
  ) async {
    final dispatcher = await getDispatcherById(dispatcherId);
    if (dispatcher == null) {
      return false;
    }
    
    // Check if dispatch is assigned to this dispatcher
    if (!dispatcher.assignedDispatches.contains(dispatchId)) {
      return false;
    }
    
    // Create a handler from the dispatcher
    final handler = DispatchHandler(
      id: dispatcher.id,
      name: dispatcher.name,
      rank: dispatcher.rank,
      role: 'Dispatcher',
      department: dispatcher.corps,
      contactInfo: '',
    );
    
    // Update dispatch status
    // This would normally update the dispatch in a database
    // For now, we'll just update the dispatcher's lists
    
    // Remove from assigned and add to completed
    final updatedAssignedDispatches = List<String>.from(dispatcher.assignedDispatches)
      ..remove(dispatchId);
    
    final updatedCompletedDispatches = List<String>.from(dispatcher.completedDispatches);
    if (!updatedCompletedDispatches.contains(dispatchId)) {
      updatedCompletedDispatches.add(dispatchId);
    }
    
    final updatedDispatcher = dispatcher.copyWith(
      assignedDispatches: updatedAssignedDispatches,
      completedDispatches: updatedCompletedDispatches,
    );
    
    // Update in list
    final index = _dispatchers.indexWhere((d) => d.id == dispatcherId);
    if (index != -1) {
      _dispatchers[index] = updatedDispatcher;
      return true;
    }
    
    return false;
  }
  
  // Update dispatcher status (active/inactive)
  Future<bool> updateDispatcherStatus(String dispatcherId, bool isActive) async {
    final dispatcher = await getDispatcherById(dispatcherId);
    if (dispatcher == null) {
      return false;
    }
    
    final updatedDispatcher = dispatcher.copyWith(isActive: isActive);
    
    // Update in list
    final index = _dispatchers.indexWhere((d) => d.id == dispatcherId);
    if (index != -1) {
      _dispatchers[index] = updatedDispatcher;
      return true;
    }
    
    return false;
  }
  
  // Get dispatches assigned to a dispatcher
  Future<List<Dispatch>> getAssignedDispatches(String dispatcherId) async {
    final dispatcher = await getDispatcherById(dispatcherId);
    if (dispatcher == null) {
      return [];
    }
    
    final assignedDispatches = <Dispatch>[];
    
    for (final dispatchId in dispatcher.assignedDispatches) {
      final dispatch = await _dispatchService.findDispatchByReference(dispatchId);
      if (dispatch != null) {
        assignedDispatches.add(dispatch);
      }
    }
    
    return assignedDispatches;
  }
  
  // Get completed dispatches by a dispatcher
  Future<List<Dispatch>> getCompletedDispatches(String dispatcherId) async {
    final dispatcher = await getDispatcherById(dispatcherId);
    if (dispatcher == null) {
      return [];
    }
    
    final completedDispatches = <Dispatch>[];
    
    for (final dispatchId in dispatcher.completedDispatches) {
      final dispatch = await _dispatchService.findDispatchByReference(dispatchId);
      if (dispatch != null) {
        completedDispatches.add(dispatch);
      }
    }
    
    return completedDispatches;
  }
}
