import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An animated text field that provides visual feedback when focused
class AnimatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry contentPadding;
  final BorderRadius borderRadius;
  final Color? fillColor;
  final Color? focusColor;
  final Color? borderColor;
  final Color? focusBorderColor;
  final Color? errorBorderColor;
  final Color? textColor;
  final Color? labelColor;
  final Color? hintColor;
  final Color? cursorColor;
  final double borderWidth;
  final double focusBorderWidth;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? helperStyle;
  final TextStyle? errorStyle;
  final bool autofocus;
  final AutovalidateMode autovalidateMode;
  final bool showCursor;
  final TextCapitalization textCapitalization;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.focusNode,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 16.0,
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.fillColor,
    this.focusColor,
    this.borderColor,
    this.focusBorderColor,
    this.errorBorderColor,
    this.textColor,
    this.labelColor,
    this.hintColor,
    this.cursorColor,
    this.borderWidth = 1.0,
    this.focusBorderWidth = 2.0,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.helperStyle,
    this.errorStyle,
    this.autofocus = false,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.showCursor = true,
    this.textCapitalization = TextCapitalization.none,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _controller;
  late Animation<double> _borderWidthAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _fillColorAnimation;
  late Animation<double> _labelSizeAnimation;
  late Animation<Offset> _labelPositionAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final theme = Theme.of(context);
    final defaultBorderColor = widget.borderColor ?? theme.dividerColor;
    final defaultFocusBorderColor =
        widget.focusBorderColor ?? theme.primaryColor;
    final defaultFillColor = widget.fillColor ?? theme.cardColor;
    final defaultFocusColor =
        widget.focusColor ?? theme.primaryColor.withAlpha(13); // 0.05 opacity

    _borderWidthAnimation = Tween<double>(
      begin: widget.borderWidth,
      end: widget.focusBorderWidth,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );

    _borderColorAnimation = ColorTween(
      begin: defaultBorderColor,
      end: defaultFocusBorderColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );

    _fillColorAnimation = ColorTween(
      begin: defaultFillColor,
      end: defaultFocusColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );

    _labelSizeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );

    _labelPositionAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.0, -0.5),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _controller.forward();
    } else {
      // Only animate back if the field is empty
      if (widget.controller?.text.isEmpty ?? true) {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    final hasLabel = widget.labelText != null;
    final hasValue = widget.controller?.text.isNotEmpty ?? false;

    // If the field has a value, keep the label in the "focused" position
    if (hasValue && !_isFocused && !_controller.isAnimating) {
      _controller.value = 1.0;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: hasError
                        ? (widget.errorBorderColor ?? Colors.red)
                            .withAlpha(26) // 0.1 opacity
                        : _fillColorAnimation.value,
                    borderRadius: widget.borderRadius,
                    border: Border.all(
                      color: hasError
                          ? (widget.errorBorderColor ?? Colors.red)
                          : _borderColorAnimation.value!,
                      width: _borderWidthAnimation.value,
                    ),
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: widget.onSubmitted,
                    validator: widget.validator,
                    inputFormatters: widget.inputFormatters,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    maxLength: widget.maxLength,
                    enabled: widget.enabled,
                    style: widget.textStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          color: widget.textColor ??
                              theme.textTheme.bodyMedium?.color,
                        ),
                    cursorColor: widget.cursorColor ?? theme.primaryColor,
                    showCursor: widget.showCursor,
                    textCapitalization: widget.textCapitalization,
                    autovalidateMode: widget.autovalidateMode,
                    decoration: InputDecoration(
                      contentPadding: widget.contentPadding,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: hasLabel && (_isFocused || hasValue)
                          ? widget.hintText
                          : null,
                      hintStyle: widget.hintStyle ??
                          theme.textTheme.bodyMedium?.copyWith(
                            color: widget.hintColor ??
                                theme.hintColor.withAlpha(179), // 0.7 opacity
                          ),
                      prefixIcon: widget.prefixIcon,
                      suffixIcon: widget.suffixIcon,
                      helperText: widget.helperText,
                      helperStyle: widget.helperStyle,
                      errorText: widget.errorText,
                      errorStyle: widget.errorStyle,
                      counterText: '',
                    ),
                  ),
                ),
                if (hasLabel)
                  Positioned(
                    left: widget.contentPadding.resolve(TextDirection.ltr).left,
                    top: 0,
                    child: Transform.translate(
                      offset: _labelPositionAnimation.value.scale(
                        widget.contentPadding.resolve(TextDirection.ltr).top,
                        -10,
                      ),
                      child: Transform.scale(
                        scale: _labelSizeAnimation.value,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          color: hasError
                              ? (widget.errorBorderColor ?? Colors.red)
                                  .withAlpha(26) // 0.1 opacity
                              : _fillColorAnimation.value,
                          child: Text(
                            widget.labelText!,
                            style: (_isFocused || hasValue)
                                ? (widget.labelStyle ??
                                    theme.textTheme.bodyMedium?.copyWith(
                                      color: hasError
                                          ? (widget.errorBorderColor ??
                                              Colors.red)
                                          : (widget.labelColor ??
                                              _borderColorAnimation.value),
                                      fontWeight: FontWeight.bold,
                                    ))
                                : (widget.hintStyle ??
                                    theme.textTheme.bodyMedium?.copyWith(
                                      color: widget.hintColor ??
                                          theme.hintColor
                                              .withAlpha(179), // 0.7 opacity
                                    )),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
