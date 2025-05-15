import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';
import '../../utils/responsive_util.dart';
import 'dispatch_tracking_screen.dart';

class TrackDispatchScreen extends StatefulWidget {
  const TrackDispatchScreen({super.key});

  @override
  State<TrackDispatchScreen> createState() => _TrackDispatchScreenState();
}

class _TrackDispatchScreenState extends State<TrackDispatchScreen> {
  final DispatchService _dispatchService = DispatchService();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _internalReferenceController =
      TextEditingController();

  Dispatch? _dispatch;
  String? _errorMessage;
  bool _isLoading = false;
  bool _showInternalReference = false;
  List<Dispatch> _recentlyTrackedDispatches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentlyTrackedDispatches();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _internalReferenceController.dispose();
    super.dispose();
  }

  // Load recently tracked dispatches
  void _loadRecentlyTrackedDispatches() {
    // In a real app, this would load from local storage or a database
    // For now, we'll just use a sample list
    setState(() {
      _recentlyTrackedDispatches = [];
    });
  }

  // Track dispatch by reference number
  Future<void> _trackDispatch() async {
    final reference = _showInternalReference
        ? _internalReferenceController.text.trim()
        : _referenceController.text.trim();

    if (reference.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a reference number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dispatch = null;
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
      } else {
        // Add to recently tracked dispatches
        if (!_recentlyTrackedDispatches.any((d) => d.id == dispatch.id)) {
          setState(() {
            _recentlyTrackedDispatches = [
              dispatch,
              ..._recentlyTrackedDispatches
            ];
            if (_recentlyTrackedDispatches.length > 5) {
              _recentlyTrackedDispatches =
                  _recentlyTrackedDispatches.sublist(0, 5);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // View detailed tracking
  void _viewDetailedTracking(Dispatch dispatch) {
    // Determine dispatch type
    String dispatchType = 'unknown';
    if (dispatch is IncomingDispatch) {
      dispatchType = 'incoming';
    } else if (dispatch is OutgoingDispatch) {
      dispatchType = 'outgoing';
    } else if (dispatch is LocalDispatch) {
      dispatchType = 'local';
    } else if (dispatch is ExternalDispatch) {
      dispatchType = 'external';
    }

    // Navigate to detailed tracking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispatchTrackingScreen(
          dispatchId: dispatch.id,
          dispatchType: dispatchType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Dispatch'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.magnifyingGlass,
                            size: 24, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Track Your Dispatch',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Enter the reference number to track your dispatch',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Toggle between reference types
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Reference Number'),
                            selected: !_showInternalReference,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _showInternalReference = false;
                                });
                              }
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: AppTheme.primaryColor.withAlpha(50),
                            labelStyle: TextStyle(
                              color: !_showInternalReference
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                              fontWeight: !_showInternalReference
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Internal Reference'),
                            selected: _showInternalReference,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _showInternalReference = true;
                                });
                              }
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: AppTheme.primaryColor.withAlpha(50),
                            labelStyle: TextStyle(
                              color: _showInternalReference
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                              fontWeight: _showInternalReference
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search field
                    if (!_showInternalReference)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _referenceController,
                              decoration: InputDecoration(
                                hintText:
                                    'Enter reference number (e.g., IN-2023-001)',
                                prefixIcon: const Icon(FontAwesomeIcons.hashtag,
                                    size: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
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
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _internalReferenceController,
                              decoration: InputDecoration(
                                hintText:
                                    'Enter internal reference (e.g., IR-2023-001)',
                                prefixIcon: const Icon(
                                    FontAwesomeIcons.fileLines,
                                    size: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Dispatch details
            if (_dispatch != null) ...[
              const Text(
                'Dispatch Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDispatchDetailsCard(_dispatch!),
            ],

            const SizedBox(height: 24),

            // Recently tracked dispatches
            if (_recentlyTrackedDispatches.isNotEmpty) ...[
              const Text(
                'Recently Tracked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_recentlyTrackedDispatches
                  .map((dispatch) => _buildRecentDispatchCard(dispatch))
                  .toList()),
            ],
          ],
        ),
      ),
    );
  }

  // Build dispatch details card
  Widget _buildDispatchDetailsCard(Dispatch dispatch) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dispatch.getPriorityColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dispatch.getPriorityColor().withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getDispatchTypeIcon(dispatch),
                    color: dispatch.getPriorityColor(),
                  ),
                ),
                const SizedBox(width: 12),
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
                      ),
                      Text(
                        'Ref: ${dispatch.referenceNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        dispatch.sender,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        dispatch.recipient,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(dispatch.dateTime),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            dispatch.getStatusIcon(),
                            size: 16,
                            color: dispatch.getStatusColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dispatch.status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dispatch.getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewDetailedTracking(dispatch),
                icon: const Icon(FontAwesomeIcons.clockRotateLeft, size: 16),
                label: const Text('View Detailed Tracking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build recent dispatch card
  Widget _buildRecentDispatchCard(Dispatch dispatch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: dispatch.getStatusColor().withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getDispatchTypeIcon(dispatch),
            color: dispatch.getStatusColor(),
            size: 16,
          ),
        ),
        title: Text(
          dispatch.referenceNumber,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${dispatch.subject} • ${DateFormat('dd MMM yyyy').format(dispatch.dateTime)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          dispatch.status,
          style: TextStyle(
            color: dispatch.getStatusColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          setState(() {
            _dispatch = dispatch;
            _errorMessage = null;
          });
        },
      ),
    );
  }

  // Get icon for dispatch type
  IconData _getDispatchTypeIcon(Dispatch dispatch) {
    if (dispatch is IncomingDispatch) {
      return FontAwesomeIcons.envelopeOpenText;
    } else if (dispatch is OutgoingDispatch) {
      return FontAwesomeIcons.paperPlane;
    } else if (dispatch is LocalDispatch) {
      return FontAwesomeIcons.buildingUser;
    } else if (dispatch is ExternalDispatch) {
      return FontAwesomeIcons.globe;
    } else {
      return FontAwesomeIcons.envelope;
    }
  }
}
