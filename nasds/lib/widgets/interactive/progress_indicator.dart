import 'package:flutter/material.dart';

/// A custom progress indicator widget
class CustomProgressIndicator extends StatefulWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color valueColor;
  final Widget? child;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showValue;
  final TextStyle? valueTextStyle;
  final String? label;
  final TextStyle? labelStyle;
  final bool animate;

  const CustomProgressIndicator({
    super.key,
    this.value = 0.0,
    this.size = 100.0,
    this.strokeWidth = 10.0,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.valueColor = Colors.blue,
    this.child,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOut,
    this.showValue = false,
    this.valueTextStyle,
    this.label,
    this.labelStyle,
    this.animate = true,
  })  : assert(value >= 0.0 && value <= 1.0);

  @override
  State<CustomProgressIndicator> createState() => _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );
    
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
    
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(CustomProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _oldValue) {
      _animation = Tween<double>(
        begin: _oldValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.animationCurve,
        ),
      );
      
      if (widget.animate) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
      
      _oldValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: widget.backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.backgroundColor),
                ),
              ),
              
              // Value circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor),
                ),
              ),
              
              // Child widget or value text
              if (widget.child != null)
                widget.child!
              else if (widget.showValue)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_animation.value * 100).toInt()}%',
                      style: widget.valueTextStyle ??
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.valueColor,
                          ),
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        widget.label!,
                        style: widget.labelStyle ??
                            theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A linear progress indicator with animation and labels
class CustomLinearProgressIndicator extends StatefulWidget {
  final double value;
  final double height;
  final Color backgroundColor;
  final Color valueColor;
  final BorderRadius borderRadius;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showValue;
  final TextStyle? valueTextStyle;
  final String? label;
  final TextStyle? labelStyle;
  final bool animate;
  final EdgeInsetsGeometry padding;
  final bool showShadow;

  const CustomLinearProgressIndicator({
    super.key,
    this.value = 0.0,
    this.height = 10.0,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.valueColor = Colors.blue,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOut,
    this.showValue = false,
    this.valueTextStyle,
    this.label,
    this.labelStyle,
    this.animate = true,
    this.padding = EdgeInsets.zero,
    this.showShadow = false,
  })  : assert(value >= 0.0 && value <= 1.0);

  @override
  State<CustomLinearProgressIndicator> createState() =>
      _CustomLinearProgressIndicatorState();
}

class _CustomLinearProgressIndicatorState
    extends State<CustomLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );
    
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
    
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(CustomLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _oldValue) {
      _animation = Tween<double>(
        begin: _oldValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.animationCurve,
        ),
      );
      
      if (widget.animate) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
      
      _oldValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null || widget.showValue) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: widget.labelStyle ??
                            theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    if (widget.showValue)
                      Text(
                        '${(_animation.value * 100).toInt()}%',
                        style: widget.valueTextStyle ??
                            theme.textTheme.bodyMedium?.copyWith(
                              color: widget.valueColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],
              Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: widget.borderRadius,
                  boxShadow: widget.showShadow
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2.0,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (_animation.value * 100).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.valueColor,
                          borderRadius: widget.borderRadius,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 100 - (_animation.value * 100).toInt(),
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A step progress indicator for multi-step processes
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;
  final Widget Function(int, bool, bool)? stepBuilder;
  final Widget Function(int, int)? labelBuilder;
  final bool showLabels;
  final TextStyle? labelStyle;
  final double lineThickness;
  final double spacing;
  final Axis direction;
  final bool animate;
  final Duration animationDuration;
  final Curve animationCurve;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.size = 30.0,
    this.activeColor = Colors.blue,
    this.inactiveColor = const Color(0xFFEEEEEE),
    this.completedColor = Colors.green,
    this.stepBuilder,
    this.labelBuilder,
    this.showLabels = true,
    this.labelStyle,
    this.lineThickness = 2.0,
    this.spacing = 60.0,
    this.direction = Axis.horizontal,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOut,
  })  : assert(currentStep >= 0 && currentStep <= totalSteps),
        assert(totalSteps > 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return direction == Axis.horizontal
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildSteps(theme),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildSteps(theme),
              ),
            ],
          );
  }

  List<Widget> _buildSteps(ThemeData theme) {
    final List<Widget> steps = [];
    
    for (int i = 0; i < totalSteps; i++) {
      final bool isActive = i == currentStep - 1;
      final bool isCompleted = i < currentStep - 1;
      
      // Add step
      steps.add(
        _buildStepWithLabel(
          i,
          isActive,
          isCompleted,
          theme,
        ),
      );
      
      // Add line between steps
      if (i < totalSteps - 1) {
        steps.add(
          _buildLine(
            isCompleted,
            theme,
          ),
        );
      }
    }
    
    return steps;
  }

  Widget _buildStepWithLabel(
    int index,
    bool isActive,
    bool isCompleted,
    ThemeData theme,
  ) {
    final Widget step = stepBuilder != null
        ? stepBuilder!(index + 1, isActive, isCompleted)
        : _defaultStepBuilder(index + 1, isActive, isCompleted, theme);
    
    if (!showLabels) {
      return step;
    }
    
    final Widget label = labelBuilder != null
        ? labelBuilder!(index + 1, totalSteps)
        : _defaultLabelBuilder(index + 1, theme);
    
    return direction == Axis.horizontal
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              step,
              const SizedBox(height: 8.0),
              label,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              step,
              const SizedBox(width: 8.0),
              label,
            ],
          );
  }

  Widget _defaultStepBuilder(
    int step,
    bool isActive,
    bool isCompleted,
    ThemeData theme,
  ) {
    final Color color = isCompleted
        ? completedColor
        : isActive
            ? activeColor
            : inactiveColor;
    
    return animate
        ? TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ),
            duration: animationDuration,
            curve: animationCurve,
            builder: (context, value, child) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withOpacity(value),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: size * 0.6,
                        )
                      : Text(
                          step.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isActive ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          )
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isCompleted || isActive ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2.0,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: size * 0.6,
                    )
                  : Text(
                      step.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isActive ? Colors.white : color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
  }

  Widget _defaultLabelBuilder(int step, ThemeData theme) {
    return Text(
      'Step $step',
      style: labelStyle ?? theme.textTheme.bodySmall,
    );
  }

  Widget _buildLine(bool isCompleted, ThemeData theme) {
    final Color color = isCompleted ? completedColor : inactiveColor;
    
    return direction == Axis.horizontal
        ? Container(
            width: spacing,
            height: lineThickness,
            color: color,
          )
        : Container(
            width: lineThickness,
            height: spacing,
            color: color,
          );
  }
}
