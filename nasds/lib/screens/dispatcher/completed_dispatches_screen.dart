import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dispatch.dart';
import '../../providers/dispatcher_provider.dart';

class CompletedDispatchesScreen extends StatelessWidget {
  const CompletedDispatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DispatcherProvider>(
      builder: (context, dispatcherProvider, child) {
        final completedDispatches = dispatcherProvider.completedDispatches;

        return Scaffold(
          body: dispatcherProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : completedDispatches.isEmpty
                  ? const Center(
                      child: Text(
                        'No completed dispatches',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: completedDispatches.length,
                      itemBuilder: (context, index) {
                        final dispatch = completedDispatches[index];
                        return _buildDispatchCard(context, dispatch);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildDispatchCard(BuildContext context, Dispatch dispatch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dispatch
                        .getStatusColor()
                        .withAlpha(25), // 0.1 * 255 = 25
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    dispatch.getStatusIcon(),
                    color: dispatch.getStatusColor(),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Ref: ${dispatch.referenceNumber}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: dispatch
                        .getPriorityColor()
                        .withAlpha(25), // 0.1 * 255 = 25
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dispatch.priority,
                    style: TextStyle(
                      color: dispatch.getPriorityColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
                      const Text(
                        'From',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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
                      const Text(
                        'To',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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
                      const Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dispatch.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dispatch.getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completed Date',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dispatch.formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (dispatch.handledBy.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Handled by: ${dispatch.handledBy}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
