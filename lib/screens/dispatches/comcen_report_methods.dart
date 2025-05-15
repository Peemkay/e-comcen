// Build filter bar showing current filters
Widget _buildFilterBar() {
  // Format date range for display
  String dateRangeText = 'All Time';
  if (_startDate != null && _endDate != null) {
    final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
    final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
    dateRangeText = '$startFormatted to $endFormatted';
  } else if (_startDate != null) {
    final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
    dateRangeText = 'From $startFormatted';
  } else if (_endDate != null) {
    final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
    dateRangeText = 'Until $endFormatted';
  }

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.filter, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Current Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showFilterDialog,
                child: const Text('Change'),
              ),
            ],
          ),
          const Divider(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text('Date: $_timeRange'),
                avatar: const Icon(Icons.calendar_today, size: 16),
                backgroundColor: Colors.blue.withAlpha(25),
              ),
              if (_timeRange == 'Custom Range')
                Chip(
                  label: Text(dateRangeText),
                  avatar: const Icon(Icons.date_range, size: 16),
                  backgroundColor: Colors.blue.withAlpha(25),
                ),
              Chip(
                label: Text('Type: $_serviceTypeFilter'),
                avatar: const Icon(FontAwesomeIcons.tag, size: 16),
                backgroundColor: Colors.green.withAlpha(25),
              ),
              if (_performedByFilter.isNotEmpty)
                Chip(
                  label: Text('By: $_performedByFilter'),
                  avatar: const Icon(FontAwesomeIcons.user, size: 16),
                  backgroundColor: Colors.purple.withAlpha(25),
                ),
              Chip(
                label: Text('Sort: ${_getSortByText()} (${_sortAscending ? 'Asc' : 'Desc'})'),
                avatar: Icon(
                  _sortAscending
                      ? FontAwesomeIcons.arrowUpWideShort
                      : FontAwesomeIcons.arrowDownWideShort,
                  size: 16,
                ),
                backgroundColor: Colors.orange.withAlpha(25),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Helper to get readable sort text
String _getSortByText() {
  switch (_sortBy) {
    case 'date':
      return 'Date';
    case 'action':
      return 'Action';
    case 'performedBy':
      return 'User';
    default:
      return 'Date';
  }
}

// Build service type breakdown card
Widget _buildServiceTypeBreakdownCard() {
  final servicesByType = _reportData!['servicesByType'] as Map<String, int>;
  final totalServices = _reportData!['totalServices'] as int;
  
  if (servicesByType.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No service data available'),
        ),
      ),
    );
  }
  
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services by Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: servicesByType.length,
            itemBuilder: (context, index) {
              final entry = servicesByType.entries.elementAt(index);
              final serviceType = entry.key;
              final count = entry.value;
              final percentage = totalServices > 0 
                  ? (count / totalServices * 100).toStringAsFixed(1) 
                  : '0';
              
              return _buildServiceTypeItem(
                serviceType, 
                count, 
                '$percentage%',
                _getServiceTypeColor(serviceType),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// Helper to get color for service type
Color _getServiceTypeColor(String serviceType) {
  switch (serviceType.toLowerCase()) {
    case 'communication':
      return Colors.blue;
    case 'creation':
      return Colors.green;
    case 'update':
      return Colors.orange;
    case 'deletion':
      return Colors.red;
    case 'receipt':
      return Colors.purple;
    case 'transmission':
      return Colors.teal;
    case 'system':
      return Colors.grey;
    case 'security':
      return Colors.deepPurple;
    default:
      return Colors.blueGrey;
  }
}

// Build service type item
Widget _buildServiceTypeItem(String type, int count, String percentage, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withAlpha(50)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
