import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nasds/providers/lock_screen_provider.dart';
import 'package:provider/provider.dart';

/// A widget that displays a lock icon button in the app bar
/// When pressed, it locks the screen
class LockIconButton extends StatelessWidget {
  const LockIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(FontAwesomeIcons.lock, size: 18),
      tooltip: 'Lock Screen',
      onPressed: () {
        // Lock the screen
        Provider.of<LockScreenProvider>(context, listen: false).lockScreen();

        // Show a snackbar to confirm
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screen locked - Enter your credentials to unlock'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
  }
}
