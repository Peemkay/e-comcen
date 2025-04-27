import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../models/dispatch.dart';
import '../models/dispatch_tracking.dart';
import '../services/dispatch_service.dart';

class DispatchTrackerWidget extends StatefulWidget {
  const DispatchTrackerWidget({super.key});

  @override
  State<DispatchTrackerWidget> createState() => _DispatchTrackerWidgetState();
}

class _DispatchTrackerWidgetState extends State<DispatchTrackerWidget> {
  final TextEditingController _referenceController = TextEditingController();
  final DispatchService _dispatchService = DispatchService();
  
  Dispatch? _dispatch;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _trackDispatch() async {
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a reference number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Search for the dispatch in all types
      final dispatch = await _dispatchService.findDispatchByReference(reference);
      
      setState(() {
        _dispatch = dispatch;
        _isLoading = false;
      });
      
      if (dispatch == null) {
        setState(() {
          _errorMessage = 'No dispatch found with this reference number';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.magnifyingGlassLocation,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Track Dispatch Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      hintText: 'Enter reference number',
                      prefixIcon: const Icon(FontAwesomeIcons.hashtag, size: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (_) => _trackDispatch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _trackDispatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Track'),
                ),
              ],
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            
            if (_dispatch != null) ...[
              const SizedBox(height: 24),
              _buildDispatchDetails(_dispatch!),
              const SizedBox(height: 16),
              _buildStatusTracker(_dispatch!),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDispatchDetails(Dispatch dispatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dispatch.subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${dispatch.referenceNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dispatch.getPriorityColor().withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dispatch.priority,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: dispatch.getPriorityColor(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              dispatch.getStatusIcon(),
              size: 16,
              color: dispatch.getStatusColor(),
            ),
            const SizedBox(width: 4),
            Text(
              'Status: ${dispatch.status}',
              style: TextStyle(
                color: dispatch.getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'Handled by: ${dispatch.handledBy}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatusTracker(Dispatch dispatch) {
    // Define the standard dispatch flow
    final List<DispatchStatus> standardFlow = [
      DispatchStatus.created,
      DispatchStatus.pending,
      DispatchStatus.inProgress,
      DispatchStatus.dispatched,
      DispatchStatus.inTransit,
      DispatchStatus.delivered,
      DispatchStatus.received,
      DispatchStatus.completed,
    ];
    
    // Determine current status index
    DispatchStatus currentStatus = DispatchStatus.pending;
    if (dispatch.trackingStatus != null) {
      currentStatus = dispatch.trackingStatus!;
    } else {
      // Try to map the string status to enum
      try {
        currentStatus = DispatchStatus.fromString(dispatch.status);
      } catch (_) {
        // Keep default if not found
      }
    }
    
    // Find the index of current status in the flow
    int currentIndex = standardFlow.indexWhere((status) => status == currentStatus);
    if (currentIndex == -1) {
      // If status is not in standard flow (like returned or failed)
      // Show a special indicator
      return _buildNonStandardStatusIndicator(currentStatus);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dispatch Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(standardFlow.length, (index) {
            final bool isActive = index <= currentIndex;
            final bool isCurrent = index == currentIndex;
            
            return Expanded(
              child: Column(
                children: [
                  // Status circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive 
                          ? standardFlow[index].color 
                          : Colors.grey[300],
                      border: isCurrent 
                          ? Border.all(color: AppTheme.primaryColor, width: 2) 
                          : null,
                    ),
                    child: Icon(
                      standardFlow[index].icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Line connector (except for last item)
                  if (index < standardFlow.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        height: 3,
                        color: index < currentIndex 
                            ? AppTheme.primaryColor 
                            : Colors.grey[300],
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Status label
                  Text(
                    standardFlow[index].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent 
                          ? AppTheme.primaryColor 
                          : (isActive ? Colors.black87 : Colors.grey),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
        
        // Show estimated delivery time if available
        if (dispatch.estimatedDeliveryDate != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Estimated delivery: ${_formatDate(dispatch.estimatedDeliveryDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
        
        // Show current handler if available
        if (dispatch.currentHandler != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(FontAwesomeIcons.userTag, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Current handler: ${dispatch.currentHandler!.rank} ${dispatch.currentHandler!.name} (${dispatch.currentHandler!.role})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
        
        // Show current location if available
        if (dispatch.currentLocation != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(FontAwesomeIcons.locationDot, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Current location: ${dispatch.currentLocation}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildNonStandardStatusIndicator(DispatchStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dispatch Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: status.color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                status.icon,
                color: status.color,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: status.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(status),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Show reason if dispatch is returned or failed
        if (_dispatch?.isReturned == true && _dispatch?.returnReason != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withAlpha(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Return Reason:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_dispatch!.returnReason!),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  String _getStatusDescription(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.delayed:
        return 'The dispatch has been delayed in transit.';
      case DispatchStatus.returned:
        return 'The dispatch has been returned to sender.';
      case DispatchStatus.failed:
        return 'The dispatch delivery has failed.';
      case DispatchStatus.rejected:
        return 'The dispatch has been rejected by the recipient.';
      case DispatchStatus.archived:
        return 'The dispatch has been archived.';
      default:
        return 'Current status of the dispatch.';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
