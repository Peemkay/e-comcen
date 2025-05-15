// Build services log card
Widget _buildServicesLogCard() {
  final logs = _reportData!['logs'] as List<DispatchLog>;
  
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Services Log',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${logs.length} entries',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(),
          logs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No logs found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 10 ? 10 : logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogItem(log);
                  },
                ),
          if (logs.length > 10)
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () {
                  // Show all logs in a dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('All Services'),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 500,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return _buildLogItem(log);
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(FontAwesomeIcons.list, size: 16),
                label: const Text('View All Services'),
              ),
            ),
        ],
      ),
    ),
  );
}

// Build log item
Widget _buildLogItem(DispatchLog log) {
  IconData actionIcon;
  Color actionColor;
  
  // Determine icon and color based on action
  if (log.action.toLowerCase().contains('add') ||
      log.action.toLowerCase().contains('creat')) {
    actionIcon = FontAwesomeIcons.plus;
    actionColor = Colors.green;
  } else if (log.action.toLowerCase().contains('updat') ||
      log.action.toLowerCase().contains('edit')) {
    actionIcon = FontAwesomeIcons.penToSquare;
    actionColor = Colors.blue;
  } else if (log.action.toLowerCase().contains('delet')) {
    actionIcon = FontAwesomeIcons.trash;
    actionColor = Colors.red;
  } else if (log.action.toLowerCase().contains('receiv')) {
    actionIcon = FontAwesomeIcons.inbox;
    actionColor = Colors.purple;
  } else if (log.action.toLowerCase().contains('sent') ||
      log.action.toLowerCase().contains('send')) {
    actionIcon = FontAwesomeIcons.paperPlane;
    actionColor = Colors.orange;
  } else if (log.action.toLowerCase().contains('system')) {
    actionIcon = FontAwesomeIcons.gear;
    actionColor = Colors.grey;
  } else if (log.action.toLowerCase().contains('communication') ||
      log.action.toLowerCase().contains('rear link')) {
    actionIcon = FontAwesomeIcons.towerBroadcast;
    actionColor = Colors.deepPurple;
  } else {
    actionIcon = FontAwesomeIcons.clockRotateLeft;
    actionColor = Colors.teal;
  }
  
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: actionColor.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(actionIcon, color: actionColor, size: 16),
    ),
    title: Text(log.action),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('dd MMM yyyy HH:mm').format(log.timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (log.notes.isNotEmpty)
          Text(
            log.notes,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
    trailing: Text(
      log.performedBy,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    ),
    onTap: () {
      // Show log details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Service Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(FontAwesomeIcons.tag),
                  title: const Text('Action'),
                  subtitle: Text(log.action),
                ),
                ListTile(
                  leading: const Icon(FontAwesomeIcons.userGear),
                  title: const Text('Performed By'),
                  subtitle: Text(log.performedBy),
                ),
                ListTile(
                  leading: const Icon(FontAwesomeIcons.clock),
                  title: const Text('Timestamp'),
                  subtitle: Text(DateFormat('dd MMM yyyy HH:mm:ss').format(log.timestamp)),
                ),
                if (log.notes.isNotEmpty)
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.noteSticky),
                    title: const Text('Notes'),
                    subtitle: Text(log.notes),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    },
  );
}
