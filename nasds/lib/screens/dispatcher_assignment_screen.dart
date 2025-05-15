import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dispatcher_assignment_provider.dart';
import '../providers/translation_provider.dart';
import '../widgets/app_bar/custom_app_bar.dart';
import '../constants/app_theme.dart';
import '../models/dispatch.dart';
import '../models/user.dart';

/// Screen for viewing dispatcher assignments
class DispatcherAssignmentScreen extends StatefulWidget {
  const DispatcherAssignmentScreen({super.key});

  @override
  State<DispatcherAssignmentScreen> createState() => _DispatcherAssignmentScreenState();
}

class _DispatcherAssignmentScreenState extends State<DispatcherAssignmentScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DispatcherAssignmentProvider>(context, listen: false);
      if (!provider.isInitialized && !provider.isInitializing) {
        provider.initialize();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final dispatcherAssignmentProvider = Provider.of<DispatcherAssignmentProvider>(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: translationProvider.translate('dispatcher_assignments'),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dispatcherAssignmentProvider.refreshData(),
            tooltip: translationProvider.translate('refresh'),
          ),
        ],
      ),
      body: dispatcherAssignmentProvider.isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, dispatcherAssignmentProvider),
    );
  }
  
  Widget _buildContent(BuildContext context, DispatcherAssignmentProvider provider) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    
    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssignmentModeCard(context, provider),
            const SizedBox(height: 16.0),
            _buildUnassignedDispatchesCard(context, provider),
            const SizedBox(height: 16.0),
            _buildDispatcherWorkloadCard(context, provider),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAssignmentModeCard(BuildContext context, DispatcherAssignmentProvider provider) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translationProvider.translate('assignment_mode'),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(
                  provider.isAutoAssignEnabled ? Icons.auto_awesome : Icons.person,
                  color: AppTheme.primaryColor,
                  size: 32.0,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isAutoAssignEnabled
                            ? translationProvider.translate('auto_assignment_enabled')
                            : translationProvider.translate('manual_assignment_enabled'),
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.isAutoAssignEnabled
                            ? translationProvider.translate('auto_assignment_description')
                            : translationProvider.translate('manual_assignment_description'),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnassignedDispatchesCard(BuildContext context, DispatcherAssignmentProvider provider) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final unassignedDispatches = provider.unassignedDispatches;
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  translationProvider.translate('unassigned_dispatches'),
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    unassignedDispatches.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (unassignedDispatches.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    translationProvider.translate('no_unassigned_dispatches'),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: unassignedDispatches.length,
                itemBuilder: (context, index) => _buildDispatchItem(
                  context,
                  unassignedDispatches[index],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDispatchItem(BuildContext context, Dispatch dispatch) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    
    return ListTile(
      title: Text(
        dispatch.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${translationProvider.translate('reference')}: ${dispatch.referenceNumber} • ${translationProvider.translate('type')}: ${translationProvider.translate(dispatch.type.name)}',
      ),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          _getDispatchTypeIcon(dispatch.type),
          color: Colors.white,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => _showDispatchDetails(context, dispatch),
    );
  }
  
  IconData _getDispatchTypeIcon(DispatchType type) {
    switch (type) {
      case DispatchType.incoming:
        return Icons.call_received;
      case DispatchType.outgoing:
        return Icons.call_made;
      case DispatchType.local:
        return Icons.location_on;
      case DispatchType.external:
        return Icons.public;
      default:
        return Icons.mail;
    }
  }
  
  Widget _buildDispatcherWorkloadCard(BuildContext context, DispatcherAssignmentProvider provider) {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final dispatchers = provider.availableDispatchers;
    final workloads = provider.dispatcherWorkloads;
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translationProvider.translate('dispatcher_workloads'),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            if (dispatchers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    translationProvider.translate('no_available_dispatchers'),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dispatchers.length,
                itemBuilder: (context, index) => _buildDispatcherItem(
                  context,
                  dispatchers[index],
                  workloads[dispatchers[index].id] ?? 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDispatcherItem(BuildContext context, User dispatcher, int workload) {
    return ListTile(
      title: Text(
        dispatcher.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        dispatcher.rank,
      ),
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondaryColor,
        child: Text(
          dispatcher.name.substring(0, 1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      trailing: Chip(
        label: Text(
          workload.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _getWorkloadColor(workload),
      ),
      onTap: () => _showDispatcherDetails(context, dispatcher, workload),
    );
  }
  
  Color _getWorkloadColor(int workload) {
    if (workload <= 2) {
      return Colors.green;
    } else if (workload <= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  void _showDispatchDetails(BuildContext context, Dispatch dispatch) {
    final translationProvider = Provider.of<TranslationProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dispatch.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                translationProvider.translate('reference'),
                dispatch.referenceNumber,
              ),
              _buildDetailItem(
                translationProvider.translate('type'),
                translationProvider.translate(dispatch.type.name),
              ),
              _buildDetailItem(
                translationProvider.translate('status'),
                translationProvider.translate(dispatch.status.name),
              ),
              _buildDetailItem(
                translationProvider.translate('priority'),
                translationProvider.translate(dispatch.priority.name),
              ),
              _buildDetailItem(
                translationProvider.translate('date'),
                dispatch.dateTime.toString(),
              ),
              _buildDetailItem(
                translationProvider.translate('description'),
                dispatch.description,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translationProvider.translate('close')),
          ),
        ],
      ),
    );
  }
  
  void _showDispatcherDetails(BuildContext context, User dispatcher, int workload) {
    final translationProvider = Provider.of<TranslationProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dispatcher.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                translationProvider.translate('rank'),
                dispatcher.rank,
              ),
              _buildDetailItem(
                translationProvider.translate('unit'),
                dispatcher.unit ?? translationProvider.translate('not_assigned'),
              ),
              _buildDetailItem(
                translationProvider.translate('workload'),
                '$workload ${translationProvider.translate('dispatches')}',
              ),
              _buildDetailItem(
                translationProvider.translate('status'),
                dispatcher.isAvailable
                    ? translationProvider.translate('available')
                    : translationProvider.translate('unavailable'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translationProvider.translate('close')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}
