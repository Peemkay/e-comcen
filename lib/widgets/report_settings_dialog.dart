import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import '../constants/app_theme.dart';

/// Dialog for configuring report settings
class ReportSettingsDialog extends StatefulWidget {
  /// Current report settings
  final Map<String, dynamic> settings;

  /// Callback when settings are updated
  final Function(Map<String, dynamic>) onSettingsUpdated;

  const ReportSettingsDialog({
    super.key,
    required this.settings,
    required this.onSettingsUpdated,
  });

  @override
  State<ReportSettingsDialog> createState() => _ReportSettingsDialogState();
}

class _ReportSettingsDialogState extends State<ReportSettingsDialog> {
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    // Create a copy of the settings to avoid modifying the original
    _settings = Map<String, dynamic>.from(widget.settings);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(FontAwesomeIcons.gear, size: 20),
          const SizedBox(width: 8),
          const Text('Report Settings'),
          const Spacer(),
          IconButton(
            icon: const Icon(FontAwesomeIcons.rotate, size: 16),
            tooltip: 'Reset to defaults',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page settings section
              _buildSectionHeader('Page Settings'),

              // Page size
              _buildDropdownSetting(
                label: 'Page Size',
                value: _getPageSizeString(_settings['pageSize']),
                options: const ['A4', 'Letter', 'Legal'],
                onChanged: (value) {
                  setState(() {
                    _settings['pageSize'] = _getPageSizeFromString(value!);
                  });
                },
              ),

              // Page orientation
              _buildDropdownSetting(
                label: 'Orientation',
                value: _settings['orientation'] == 'portrait'
                    ? 'Portrait'
                    : 'Landscape',
                options: const ['Portrait', 'Landscape'],
                onChanged: (value) {
                  setState(() {
                    _settings['orientation'] =
                        value == 'Portrait' ? 'portrait' : 'landscape';
                  });
                },
              ),

              // Rows per page
              _buildSliderSetting(
                label: 'Rows Per Page',
                value: _settings['rowsPerPage'].toDouble(),
                min: 10,
                max: 50,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    _settings['rowsPerPage'] = value.round();
                  });
                },
              ),

              const Divider(),

              // Display settings section
              _buildSectionHeader('Display Settings'),

              // Show page numbers
              _buildSwitchSetting(
                label: 'Show Page Numbers',
                value: _settings['showPageNumbers'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _settings['showPageNumbers'] = value;
                  });
                },
              ),

              // Show date generated
              _buildSwitchSetting(
                label: 'Show Date Generated',
                value: _settings['showDateGenerated'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _settings['showDateGenerated'] = value;
                  });
                },
              ),

              // Show unit info
              _buildSwitchSetting(
                label: 'Show Unit Information',
                value: _settings['showUnitInfo'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _settings['showUnitInfo'] = value;
                  });
                },
              ),

              // Show signature section
              _buildSwitchSetting(
                label: 'Show Signature Section',
                value: _settings['showSignatureSection'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _settings['showSignatureSection'] = value;
                  });
                },
              ),

              // Show table borders
              _buildSwitchSetting(
                label: 'Show Table Borders',
                value: _settings['showTableBorders'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _settings['showTableBorders'] = value;
                  });
                },
              ),

              // Show alternate row colors
              _buildSwitchSetting(
                label: 'Show Alternate Row Colors',
                value: _settings['showAlternateRowColors'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _settings['showAlternateRowColors'] = value;
                  });
                },
              ),

              // Custom header text
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custom Header Text (Optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter custom header text',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _settings['customHeaderText'] = value;
                        });
                      },
                      controller: TextEditingController(
                          text: _settings['customHeaderText'] ?? ''),
                    ),
                  ],
                ),
              ),

              // Custom footer text
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custom Footer Text (Optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter custom footer text',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _settings['customFooterText'] = value;
                        });
                      },
                      controller: TextEditingController(
                          text: _settings['customFooterText'] ?? ''),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Table settings section
              _buildSectionHeader('Table Settings'),

              // Table border width
              _buildSliderSetting(
                label: 'Table Border Width',
                value: _settings['tableBorderWidth'] ?? 1.0,
                min: 0.5,
                max: 2.0,
                divisions: 3,
                onChanged: (value) {
                  setState(() {
                    _settings['tableBorderWidth'] = value;
                  });
                },
              ),

              // Signature section height
              _buildSliderSetting(
                label: 'Signature Section Height',
                value: _settings['signatureSectionHeight'] ?? 120.0,
                min: 80.0,
                max: 200.0,
                divisions: 6,
                onChanged: (value) {
                  setState(() {
                    _settings['signatureSectionHeight'] = value;
                  });
                },
              ),

              const Divider(),

              // Font settings section
              _buildSectionHeader('Font Settings'),

              // Header font size
              _buildSliderSetting(
                label: 'Header Font Size',
                value: _settings['fontSize']['header'],
                min: 10,
                max: 20,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _settings['fontSize']['header'] = value;
                  });
                },
              ),

              // Title font size
              _buildSliderSetting(
                label: 'Title Font Size',
                value: _settings['fontSize']['title'],
                min: 8,
                max: 18,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _settings['fontSize']['title'] = value;
                  });
                },
              ),

              // Body font size
              _buildSliderSetting(
                label: 'Body Font Size',
                value: _settings['fontSize']['body'],
                min: 8,
                max: 14,
                divisions: 6,
                onChanged: (value) {
                  setState(() {
                    _settings['fontSize']['body'] = value;
                  });
                },
              ),

              // Footer font size
              _buildSliderSetting(
                label: 'Footer Font Size',
                value: _settings['fontSize']['footer'],
                min: 6,
                max: 12,
                divisions: 6,
                onChanged: (value) {
                  setState(() {
                    _settings['fontSize']['footer'] = value;
                  });
                },
              ),

              const Divider(),

              // Security settings section
              _buildSectionHeader('Security Settings'),

              // Enable encryption
              _buildSwitchSetting(
                label: 'Enable Encryption',
                value: _settings['enableEncryption'] ?? false,
                onChanged: (value) {
                  setState(() {
                    _settings['enableEncryption'] = value;
                    if (!value) {
                      _settings['passwordProtected'] = false;
                    }
                  });
                },
              ),

              // Password protection
              if (_settings['enableEncryption'] == true)
                _buildSwitchSetting(
                  label: 'Password Protected',
                  value: _settings['passwordProtected'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _settings['passwordProtected'] = value;
                    });
                  },
                ),

              // Password field
              if (_settings['enableEncryption'] == true &&
                  _settings['passwordProtected'] == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter password',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          setState(() {
                            _settings['password'] = value;
                          });
                        },
                        controller: TextEditingController(
                            text: _settings['password'] ?? ''),
                      ),
                    ],
                  ),
                ),

              // Allow printing
              if (_settings['enableEncryption'] == true)
                _buildSwitchSetting(
                  label: 'Allow Printing',
                  value: _settings['allowPrinting'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _settings['allowPrinting'] = value;
                    });
                  },
                ),

              // Allow copying
              if (_settings['enableEncryption'] == true)
                _buildSwitchSetting(
                  label: 'Allow Copying',
                  value: _settings['allowCopying'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _settings['allowCopying'] = value;
                    });
                  },
                ),

              // Allow modifying
              if (_settings['enableEncryption'] == true)
                _buildSwitchSetting(
                  label: 'Allow Modifying',
                  value: _settings['allowModifying'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _settings['allowModifying'] = value;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSettingsUpdated(_settings);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Apply Settings'),
        ),
      ],
    );
  }

  // Reset settings to defaults
  void _resetToDefaults() {
    setState(() {
      _settings = {
        'pageSize': PdfPageFormat.a4,
        'orientation': 'portrait',
        'margin': const EdgeInsets.all(40.0),
        'headerHeight': 40.0,
        'footerHeight': 30.0,
        'rowsPerPage': 50,
        'fontSize': {
          'header': 16.0,
          'title': 14.0,
          'body': 10.0,
          'footer': 10.0,
        },
        'showPageNumbers': true,
        'showDateGenerated': true,
        'showUnitInfo': true,
        'showSignatureSection': true,
        'showTableBorders': true,
        'showAlternateRowColors': true,
        'tableHeaderColor': PdfColors.grey300,
        'tableBorderColor': PdfColors.black,
        'tableBorderWidth': 1.0,
        'alternateRowColor': PdfColors.grey100,
        'signatureSectionHeight': 120.0,
        'customHeaderText': '',
        'customFooterText': '',
        'companyLogo': null,
        'compressContent': false,
        'enableEncryption': false,
        'passwordProtected': false,
        'password': '',
        'allowPrinting': true,
        'allowCopying': true,
        'allowModifying': false,
      };
    });
  }

  // Build a section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Build a dropdown setting
  Widget _buildDropdownSetting({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // Build a switch setting
  Widget _buildSwitchSetting({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  // Build a slider setting
  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                value.round().toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.round().toString(),
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  // Get page size string from PdfPageFormat
  String _getPageSizeString(PdfPageFormat format) {
    if (format == PdfPageFormat.a4) {
      return 'A4';
    } else if (format == PdfPageFormat.letter) {
      return 'Letter';
    } else if (format == PdfPageFormat.legal) {
      return 'Legal';
    } else {
      return 'A4';
    }
  }

  // Get PdfPageFormat from string
  PdfPageFormat _getPageSizeFromString(String size) {
    switch (size) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'Letter':
        return PdfPageFormat.letter;
      case 'Legal':
        return PdfPageFormat.legal;
      default:
        return PdfPageFormat.a4;
    }
  }
}
