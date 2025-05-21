import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// A widget that restarts the app by navigating to the login screen
class RestartAppWidget extends StatefulWidget {
  const RestartAppWidget({super.key});

  @override
  State<RestartAppWidget> createState() => _RestartAppWidgetState();
}

class _RestartAppWidgetState extends State<RestartAppWidget> {
  @override
  void initState() {
    super.initState();
    // Navigate to login screen after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppConstants.loginRoute,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
