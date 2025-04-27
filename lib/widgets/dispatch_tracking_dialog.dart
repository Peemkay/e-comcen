import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/dispatch.dart';
import '../models/dispatch_tracking.dart';
import '../services/dispatch_service.dart';
import '../screens/dispatches/dispatch_tracking_screen.dart';

class DispatchTrackingDialog extends StatefulWidget {
  const DispatchTrackingDialog({super.key});

  @override
  State<DispatchTrackingDialog> createState() => _DispatchTrackingDialogState();
}

class _DispatchTrackingDialogState extends State<DispatchTrackingDialog> {
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
      final dispatch =
          await _dispatchService.findDispatchByReference(reference);

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

  void _viewDetailedTracking(BuildContext context) {
    if (_dispatch == null) return;

    // Determine dispatch type
    String dispatchType = 'unknown';
    if (_dispatch is IncomingDispatch) {
      dispatchType = 'incoming';
    } else if (_dispatch is OutgoingDispatch) {
      dispatchType = 'outgoing';
    } else if (_dispatch is LocalDispatch) {
      dispatchType = 'local';
    } else if (_dispatch is ExternalDispatch) {
      dispatchType = 'external';
    }

    Navigator.pop(context); // Close the dialog

    // Navigate to detailed tracking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispatchTrackingScreen(
          dispatchId: _dispatch!.id,
          dispatchType: dispatchType,
        ),
      ),
    );
  }

  Widget _buildDispatchDetails(Dispatch dispatch) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dispatch.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _viewDetailedTracking(context),
              icon: const Icon(FontAwesomeIcons.clockRotateLeft, size: 16),
              label: const Text('View Detailed Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
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
    int currentIndex =
        standardFlow.indexWhere((status) => status == currentStatus);
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
                    width: 24,
                    height: 24,
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
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Status line
                  if (index < standardFlow.length - 1)
                    Container(
                      height: 2,
                      color:
                          isActive ? AppTheme.primaryColor : Colors.grey[300],
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Status labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Created',
              style: TextStyle(
                fontSize: 10,
                color: currentIndex >= 0 ? AppTheme.primaryColor : Colors.grey,
                fontWeight:
                    currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'In Progress',
              style: TextStyle(
                fontSize: 10,
                color: currentIndex >= 2 ? AppTheme.primaryColor : Colors.grey,
                fontWeight:
                    currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'Delivered',
              style: TextStyle(
                fontSize: 10,
                color: currentIndex >= 5 ? AppTheme.primaryColor : Colors.grey,
                fontWeight:
                    currentIndex == 5 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'Completed',
              style: TextStyle(
                fontSize: 10,
                color: currentIndex >= 7 ? AppTheme.primaryColor : Colors.grey,
                fontWeight:
                    currentIndex == 7 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        if (dispatch.estimatedDeliveryDate != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(FontAwesomeIcons.clock, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Estimated delivery: ${DateFormat('dd MMM yyyy').format(dispatch.estimatedDeliveryDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
        if (dispatch.currentLocation != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(FontAwesomeIcons.locationDot,
                  size: 14, color: Colors.grey),
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
    return Container(
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
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(status),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.returned:
        return 'This dispatch has been returned to sender.';
      case DispatchStatus.failed:
        return 'Delivery of this dispatch has failed.';
      case DispatchStatus.rejected:
        return 'This dispatch has been rejected by the recipient.';
      case DispatchStatus.delayed:
        return 'This dispatch is currently delayed.';
      default:
        return 'This dispatch is in a special status.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Track Dispatch',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
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
                      prefixIcon:
                          const Icon(FontAwesomeIcons.hashtag, size: 16),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
}
