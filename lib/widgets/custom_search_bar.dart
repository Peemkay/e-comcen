import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final TextEditingController? controller;
  final bool autofocus;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.autofocus = false,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearButtonVisibility);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateClearButtonVisibility() {
    final showClear = _controller.text.isNotEmpty;
    if (showClear != _showClearButton) {
      setState(() {
        _showClearButton = showClear;
      });
    }
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _showClearButton
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
