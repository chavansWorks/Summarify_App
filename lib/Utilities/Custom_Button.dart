import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed; // Make onPressed nullable
  final Color color; // Color for text/icon
  final Color backgroundColor; // Background color
  final double borderRadius;
  final double padding;
  final TextStyle textStyle;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final bool isGradient;
  final List<Color>? gradientColors;
  final bool isCircular;
  final bool isIconOnly;

  const CustomButton({
    Key? key,
    this.text,
    this.onPressed, // Allow it to be null
    this.color = Colors.blue,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 8.0,
    this.padding = 16.0,
    this.textStyle = const TextStyle(color: Colors.white, fontSize: 16.0),
    this.isOutlined = false,
    this.isLoading = false, // Allow loading state
    this.icon,
    this.isGradient = false,
    this.gradientColors,
    this.isCircular = false,
    this.isIconOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Style for the button based on the button's properties
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: color,
      backgroundColor: isLoading
          ? Colors.blue
          : (isOutlined ? Colors.transparent : backgroundColor),
      padding: EdgeInsets.all(padding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCircular ? 50.0 : borderRadius),
        side: isOutlined ? BorderSide(color: color) : BorderSide.none,
      ),
      elevation: isOutlined ? 0 : 2, // Elevation for outlined buttons
    );

    final Widget buttonChild = isLoading
        ? CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(textStyle.color!),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !isIconOnly) ...[
                Icon(icon, color: textStyle.color),
                if (text != null) SizedBox(width: 8),
              ],
              if (text != null) Text(text!, style: textStyle),
              if (icon != null && isIconOnly)
                Icon(icon, color: textStyle.color),
            ],
          );

    if (isGradient && gradientColors != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors!),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ElevatedButton(
          style: buttonStyle.copyWith(
            foregroundColor: MaterialStateProperty.all(Colors.transparent),
            shadowColor: MaterialStateProperty.all(Colors.transparent),
          ),
          onPressed: isLoading ? null : onPressed, // Disable when loading
          child: buttonChild,
        ),
      );
    }

    return ElevatedButton(
      style: buttonStyle,
      onPressed: isLoading || onPressed == null
          ? null
          : onPressed, // Disable if loading or onPressed is null
      child: buttonChild,
    );
  }
}
