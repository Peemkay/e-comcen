import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/dispatch.dart';
import '../../providers/dispatcher_provider.dart';
import '../../services/auth_service.dart';
import 'assigned_dispatches_screen.dart';
import 'completed_dispatches_screen.dart';
import 'dispatch_update_screen.dart';

class DispatcherHomeScreen extends StatefulWidget {
  const DispatcherHomeScreen({super.key});

  @override
  State<DispatcherHomeScreen> createState() => _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends State<DispatcherHomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final dispatcherProvider =
        Provider.of<DispatcherProvider>(context, listen: false);
    await dispatcherProvider.initialize();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _authService.logout();
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(
                context,
                AppConstants.loginRoute,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DispatcherProvider>(
      builder: (context, dispatcherProvider, child) {
        final dispatcher = dispatcherProvider.currentDispatcher;
        final assignedDispatches = dispatcherProvider.assignedDispatches;
        final completedDispatches = dispatcherProvider.completedDispatches;

        // List of screens to display
        final List<Widget> screens = [
          _buildDashboard(dispatcher?.name ?? 'Dispatcher', assignedDispatches,
              completedDispatches),
          const AssignedDispatchesScreen(),
          const CompletedDispatchesScreen(),
          _buildProfileScreen(dispatcher?.name ?? 'Dispatcher'),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('E-COMCEN DSM'),
            backgroundColor: AppTheme.primaryColor,
            actions: [
              // Sync button
              IconButton(
                icon: dispatcherProvider.isSyncing
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Icon(Icons.sync),
                onPressed: dispatcherProvider.isSyncing
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final result = await dispatcherProvider.syncData();
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                result
                                    ? 'Synchronized with E-COMCEN'
                                    : 'Sync failed. Try again later.',
                              ),
                              backgroundColor:
                                  result ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                tooltip: 'Sync with E-COMCEN',
              ),

              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: dispatcherProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.listCheck),
                label: 'Assigned',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.clipboardCheck),
                label: 'Completed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  Widget _buildDashboard(String dispatcherName,
      List<Dispatch> assignedDispatches, List<Dispatch> completedDispatches) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Card(
            elevation: 4,
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
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        radius: 24,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $dispatcherName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Dispatch Service Manager',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Assigned',
                        assignedDispatches.length.toString(),
                        FontAwesomeIcons.listCheck,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Completed',
                        completedDispatches.length.toString(),
                        FontAwesomeIcons.clipboardCheck,
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent assigned dispatches
          const Text(
            'Recent Assigned Dispatches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          assignedDispatches.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No assigned dispatches',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: assignedDispatches
                      .take(3)
                      .map((dispatch) => _buildDispatchCard(dispatch))
                      .toList(),
                ),

          const SizedBox(height: 24),

          // Recent completed dispatches
          const Text(
            'Recent Completed Dispatches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          completedDispatches.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No completed dispatches',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: completedDispatches
                      .take(3)
                      .map((dispatch) => _buildDispatchCard(dispatch))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDispatchCard(Dispatch dispatch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: dispatch.getStatusColor().withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            dispatch.getStatusIcon(),
            color: dispatch.getStatusColor(),
          ),
        ),
        title: Text(
          dispatch.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Ref: ${dispatch.referenceNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DispatchUpdateScreen(dispatch: dispatch),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileScreen(String dispatcherName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    radius: 40,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dispatcherName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Dispatcher',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildProfileItem(
                    'Dispatcher Code',
                    Provider.of<DispatcherProvider>(context)
                            .currentDispatcher
                            ?.dispatcherCode ??
                        'N/A',
                    Icons.badge,
                  ),
                  _buildProfileItem(
                    'Status',
                    Provider.of<DispatcherProvider>(context)
                                .currentDispatcher
                                ?.isActive ??
                            false
                        ? 'Active'
                        : 'Inactive',
                    Icons.circle,
                    color: Provider.of<DispatcherProvider>(context)
                                .currentDispatcher
                                ?.isActive ??
                            false
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildProfileItem(
                    'Unit',
                    Provider.of<DispatcherProvider>(context)
                            .currentDispatcher
                            ?.unit ??
                        'N/A',
                    Icons.business,
                  ),
                  _buildProfileItem(
                    'Rank',
                    Provider.of<DispatcherProvider>(context)
                            .currentDispatcher
                            ?.rank ??
                        'N/A',
                    Icons.military_tech,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Status toggle
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Active Status'),
              subtitle: const Text(
                  'Toggle your availability for dispatch assignments'),
              value: Provider.of<DispatcherProvider>(context)
                      .currentDispatcher
                      ?.isActive ??
                  false,
              onChanged: (value) {
                Provider.of<DispatcherProvider>(context, listen: false)
                    .updateStatus(value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(height: 24),

          // App info
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('E-COMCEN DSM (Dispatch Service Manager)'),
                  Text('Version: 1.0.0'),
                  Text('© 2023 Nigerian Army Signal'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String title, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
