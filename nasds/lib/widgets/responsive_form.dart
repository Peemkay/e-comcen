import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';

/// A responsive form widget that adapts its layout based on screen size.
///
/// This widget provides a consistent form layout with responsive spacing
/// and input fields that adapt to different screen sizes.
class ResponsiveForm extends StatelessWidget {
  /// The form key for validation
  final GlobalKey<FormState> formKey;
  
  /// The list of form fields
  final List<Widget> children;
  
  /// Optional padding around the form
  final EdgeInsetsGeometry? padding;
  
  /// Optional spacing between form fields
  final double? fieldSpacing;
  
  /// Optional callback when the form is submitted
  final VoidCallback? onSubmit;
  
  /// Optional submit button text
  final String submitButtonText;
  
  /// Whether the form is currently loading/processing
  final bool isLoading;
  
  /// Optional cancel button text (if provided, a cancel button will be shown)
  final String? cancelButtonText;
  
  /// Optional callback when the cancel button is pressed
  final VoidCallback? onCancel;

  /// Creates a responsive form.
  const ResponsiveForm({
    super.key,
    required this.formKey,
    required this.children,
    this.padding,
    this.fieldSpacing,
    this.onSubmit,
    this.submitButtonText = 'Submit',
    this.isLoading = false,
    this.cancelButtonText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive values
    final responsivePadding = padding ?? 
        AppTheme.getResponsivePadding(context, factor: 1.0);
    final responsiveFieldSpacing = fieldSpacing ?? 
        AppTheme.getResponsiveSpacing(context, factor: 1.0);
    
    // Create the form with responsive spacing
    return Form(
      key: formKey,
      child: Padding(
        padding: responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add spacing between form fields
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                SizedBox(height: responsiveFieldSpacing),
            ],
            
            // Add spacing before buttons
            SizedBox(height: responsiveFieldSpacing * 1.5),
            
            // Buttons row
            Row(
              children: [
                // Cancel button if provided
                if (cancelButtonText != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : onCancel,
                      style: AppTheme.secondaryButtonStyle,
                      child: Text(cancelButtonText!),
                    ),
                  ),
                  SizedBox(width: responsiveFieldSpacing),
                ],
                
                // Submit button
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    style: AppTheme.primaryButtonStyle,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(submitButtonText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A responsive text form field that adapts its size based on screen size.
class ResponsiveTextFormField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;
  
  /// The label text
  final String labelText;
  
  /// Optional hint text
  final String? hintText;
  
  /// Optional prefix icon
  final IconData? prefixIcon;
  
  /// Optional suffix icon
  final IconData? suffixIcon;
  
  /// Optional suffix icon button
  final VoidCallback? onSuffixIconPressed;
  
  /// Optional validator function
  final String? Function(String?)? validator;
  
  /// Whether the field is obscured (for passwords)
  final bool obscureText;
  
  /// The keyboard type
  final TextInputType keyboardType;
  
  /// The text input action
  final TextInputAction textInputAction;
  
  /// Optional callback when the field is submitted
  final Function(String)? onFieldSubmitted;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Optional maximum number of lines
  final int? maxLines;
  
  /// Optional minimum number of lines
  final int? minLines;
  
  /// Optional maximum length
  final int? maxLength;
  
  /// Whether to auto-focus the field
  final bool autofocus;

  /// Creates a responsive text form field.
  const ResponsiveTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a small screen
    final isSmallScreen = AppTheme.isMobileDevice(context);
    
    // Create the text form field with responsive properties
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: isSmallScreen ? 18 : 20,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  size: isSmallScreen ? 18 : 20,
                ),
                onPressed: onSuffixIconPressed,
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.getResponsiveSpacing(context, factor: 1.0),
          vertical: AppTheme.getResponsiveSpacing(context, factor: 0.75),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: TextStyle(
        fontSize: AppTheme.getResponsiveFontSize(context),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      autofocus: autofocus,
    );
  }
}

/// A responsive dropdown form field that adapts its size based on screen size.
class ResponsiveDropdownFormField<T> extends StatelessWidget {
  /// The currently selected value
  final T? value;
  
  /// The list of items to display
  final List<DropdownMenuItem<T>> items;
  
  /// Callback when the value changes
  final void Function(T?) onChanged;
  
  /// The label text
  final String labelText;
  
  /// Optional hint text
  final String? hintText;
  
  /// Optional prefix icon
  final IconData? prefixIcon;
  
  /// Optional validator function
  final String? Function(T?)? validator;
  
  /// Whether the field is enabled
  final bool enabled;

  /// Creates a responsive dropdown form field.
  const ResponsiveDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a small screen
    final isSmallScreen = AppTheme.isMobileDevice(context);
    
    // Create the dropdown form field with responsive properties
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: isSmallScreen ? 18 : 20,
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.getResponsiveSpacing(context, factor: 1.0),
          vertical: AppTheme.getResponsiveSpacing(context, factor: 0.75),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: TextStyle(
        fontSize: AppTheme.getResponsiveFontSize(context),
      ),
      icon: Icon(
        FontAwesomeIcons.chevronDown,
        size: isSmallScreen ? 14 : 16,
      ),
      validator: validator,
      isExpanded: true,
      dropdownColor: Colors.white,
    );
  }
}

/// A responsive date picker form field that adapts its size based on screen size.
class ResponsiveDatePickerFormField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;
  
  /// The label text
  final String labelText;
  
  /// Optional hint text
  final String? hintText;
  
  /// The initial date
  final DateTime initialDate;
  
  /// The first date that can be selected
  final DateTime firstDate;
  
  /// The last date that can be selected
  final DateTime lastDate;
  
  /// Callback when the date changes
  final Function(DateTime) onDateSelected;
  
  /// Optional validator function
  final String? Function(String?)? validator;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Optional date format
  final String? dateFormat;

  /// Creates a responsive date picker form field.
  const ResponsiveDatePickerFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.validator,
    this.enabled = true,
    this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    // Create the date picker form field with responsive properties
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: const Icon(FontAwesomeIcons.calendar),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.getResponsiveSpacing(context, factor: 1.0),
          vertical: AppTheme.getResponsiveSpacing(context, factor: 0.75),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: TextStyle(
        fontSize: AppTheme.getResponsiveFontSize(context),
      ),
      readOnly: true,
      onTap: enabled
          ? () async {
              // Show date picker
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primaryColor,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              
              // Update the controller and call the callback if a date was picked
              if (pickedDate != null) {
                onDateSelected(pickedDate);
              }
            }
          : null,
      validator: validator,
    );
  }
}
