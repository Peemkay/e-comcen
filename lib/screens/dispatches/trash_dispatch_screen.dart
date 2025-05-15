import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';
import '../../widgets/dispatch_detail_dialog.dart';

class TrashDispatchScreen extends StatefulWidget {
  const TrashDispatchScreen({super.key});

  @override
  State<TrashDispatchScreen> createState() => _TrashDispatchScreenState();
}

class _TrashDispatchScreenState extends State<TrashDispatchScreen> {
  final DispatchService _dispatchService = DispatchService();
  List<Dispatch> _trashDispatches = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTrashDispatches();
  }

  void _loadTrashDispatches() {
    setState(() {
      _isLoading = true;
    });

    // Get trash dispatches
    _trashDispatches = _dispatchService.getTrashDispatches();

    setState(() {
      _isLoading = false;
    });
  }

  // Filter dispatches based on search query
  List<Dispatch> get _filteredDispatches {
    if (_searchQuery.isEmpty) {
      return _trashDispatches;
    }

    final query = _searchQuery.toLowerCase();
    return _trashDispatches.where((dispatch) {
      return dispatch.referenceNumber.toLowerCase().contains(query) ||
          dispatch.subject.toLowerCase().contains(query) ||
          dispatch.content.toLowerCase().contains(query);
    }).toList();
  }

  // Restore a dispatch from trash
  void _restoreDispatch(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Dispatch'),
        content: const Text('Are you sure you want to restore this dispatch?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _dispatchService.restoreDispatch(id);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dispatch restored successfully'),
                  backgroundColor: Colors.green,
                ),
              );

              _loadTrashDispatches();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // Permanently delete a dispatch
  void _permanentlyDeleteDispatch(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: const Text(
          'Are you sure you want to permanently delete this dispatch? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _dispatchService.permanentlyDeleteDispatch(id);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dispatch permanently deleted'),
                  backgroundColor: Colors.red,
                ),
              );

              _loadTrashDispatches();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // Empty trash
  void _emptyTrash() {
    if (_trashDispatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trash is already empty'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash'),
        content: Text(
          'Are you sure you want to permanently delete all ${_trashDispatches.length} dispatches? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _dispatchService.emptyTrash();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trash emptied successfully'),
                  backgroundColor: Colors.red,
                ),
              );

              _loadTrashDispatches();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  // Show dispatch details
  void _showDispatchDetails(Dispatch dispatch) {
    showDialog(
      context: context,
      builder: (context) => DispatchDetailDialog(
        dispatch: dispatch,
        isTrash: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowsRotate),
            onPressed: _loadTrashDispatches,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.trashCan),
            onPressed: _emptyTrash,
            tooltip: 'Empty Trash',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search trash...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Empty state
                if (_trashDispatches.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.trashCan,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Trash is Empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Deleted dispatches will appear here',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: _filteredDispatches.isEmpty
                        ? Center(
                            child: Text(
                              'No dispatches match your search',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredDispatches.length,
                            itemBuilder: (context, index) {
                              final dispatch = _filteredDispatches[index];
                              return _buildDispatchItem(dispatch);
                            },
                          ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDispatchItem(Dispatch dispatch) {
    // Determine icon and color based on dispatch type
    IconData typeIcon;
    Color typeColor;
    String typeText;

    if (dispatch is IncomingDispatch) {
      typeIcon = FontAwesomeIcons.envelopeOpenText;
      typeColor = Colors.blue;
      typeText = 'Incoming';
    } else if (dispatch is OutgoingDispatch) {
      typeIcon = FontAwesomeIcons.paperPlane;
      typeColor = Colors.green;
      typeText = 'Outgoing';
    } else if (dispatch is LocalDispatch) {
      typeIcon = FontAwesomeIcons.buildingUser;
      typeColor = Colors.orange;
      typeText = 'Local';
    } else {
      typeIcon = FontAwesomeIcons.globe;
      typeColor = Colors.purple;
      typeText = 'External';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          dispatch.subject,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Ref: ${dispatch.referenceNumber}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Deleted on: ${DateFormat('dd MMM yyyy HH:mm').format(dispatch.logs.last.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeText,
                style: TextStyle(
                  fontSize: 10,
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.arrowRotateLeft,
                  color: Colors.green),
              onPressed: () => _restoreDispatch(dispatch.id),
              tooltip: 'Restore',
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
              onPressed: () => _permanentlyDeleteDispatch(dispatch.id),
              tooltip: 'Delete Permanently',
            ),
          ],
        ),
        onTap: () => _showDispatchDetails(dispatch),
      ),
    );
  }
}
