import "package:flutter/material.dart";
import "package:pdf/pdf.dart";
import "../utils/printing_service.dart";

class PrintOptionsDialog extends StatefulWidget {
  final LayoutCallback onLayout;
  final String documentName;

  const PrintOptionsDialog({
    Key? key,
    required this.onLayout,
    required this.documentName,
  }) : super(key: key);

  @override
  State<PrintOptionsDialog> createState() => _PrintOptionsDialogState();
}

class _PrintOptionsDialogState extends State<PrintOptionsDialog> {
  final PrintingService _printingService = PrintingService();
  bool _isLoading = true;
  String _errorMessage = "";
  List<Printer> _printers = [];
  Printer? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      final printers = await _printingService.getPrinters();

      setState(() {
        _printers = printers;
        _isLoading = false;
        if (printers.isNotEmpty) {
          _selectedPrinter = printers.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load printers: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Print Options"),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Printing is temporarily disabled due to build issues."),
            const SizedBox(height: 16),
            const Text(
              "Please try again in a future update.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            // Show a dialog indicating printing is disabled
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Printing Disabled"),
                content: const Text(
                    "Printing functionality is temporarily disabled due to build issues. Please try again in a future update."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          },
          child: const Text("Print"),
        ),
      ],
    );
  }
}
