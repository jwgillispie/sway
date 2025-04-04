// lib/ui/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine colors based on theme and props
    final bgColor = backgroundColor ?? 
        (isOutlined ? Colors.transparent : theme.colorScheme.primary);
    final txtColor = textColor ?? 
        (isOutlined ? theme.colorScheme.primary : Colors.white);
    
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: txtColor,
            side: BorderSide(color: theme.colorScheme.primary),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: txtColor,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          );
    
    final buttonChild = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(txtColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon),
                SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
    
    return SizedBox(
      height: 54,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: Center(child: buttonChild),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: Center(child: buttonChild),
            ),
    );
  }
}