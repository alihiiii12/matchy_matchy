import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.readOnly = false,
    this.controller,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final bool readOnly;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  InputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (obscureText) {
      return _ObscureAppTextField(
        label: label,
        hint: hint,
        icon: icon,
        readOnly: readOnly,
        controller: controller,
        keyboardType: keyboardType,
        errorText: errorText,
        onChanged: onChanged,
        textInputAction: textInputAction,
        borderBuilder: _border,
      );
    }

    return _AppTextFieldBody(
      label: label,
      hint: hint,
      icon: icon,
      obscure: false,
      readOnly: readOnly,
      showObscureToggle: false,
      controller: controller,
      keyboardType: keyboardType,
      errorText: errorText,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onToggleObscure: null,
      borderBuilder: _border,
    );
  }
}

class _ObscureAppTextField extends StatefulWidget {
  const _ObscureAppTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.readOnly,
    required this.controller,
    required this.keyboardType,
    required this.errorText,
    required this.onChanged,
    required this.textInputAction,
    required this.borderBuilder,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final bool readOnly;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final InputBorder Function(Color color, {double width}) borderBuilder;

  @override
  State<_ObscureAppTextField> createState() => _ObscureAppTextFieldState();
}

class _ObscureAppTextFieldState extends State<_ObscureAppTextField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    return _AppTextFieldBody(
      label: widget.label,
      hint: widget.hint,
      icon: widget.icon,
      obscure: _obscure,
      readOnly: widget.readOnly,
      showObscureToggle: true,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      borderBuilder: widget.borderBuilder,
    );
  }
}

class _AppTextFieldBody extends StatelessWidget {
  const _AppTextFieldBody({
    required this.label,
    required this.hint,
    required this.icon,
    required this.obscure,
    required this.readOnly,
    required this.showObscureToggle,
    required this.controller,
    required this.keyboardType,
    required this.errorText,
    required this.onChanged,
    required this.textInputAction,
    required this.onToggleObscure,
    required this.borderBuilder,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final bool readOnly;
  final bool showObscureToggle;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onToggleObscure;
  final InputBorder Function(Color color, {double width}) borderBuilder;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          autocorrect: false,
          enableSuggestions: false,
          style: readOnly ? TextStyle(color: AppColors.textSecondary) : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: readOnly,
            fillColor: readOnly ? AppColors.inputFill : null,
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: hasError ? AppColors.error : AppColors.textSecondary,
                    size: 20,
                  )
                : null,
            suffixIcon: showObscureToggle
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            enabledBorder: hasError
                ? borderBuilder(AppColors.error.withValues(alpha: 0.5))
                : borderBuilder(Colors.transparent, width: 0),
            focusedBorder: hasError ? borderBuilder(AppColors.error, width: 1.5) : null,
            errorBorder: borderBuilder(AppColors.error.withValues(alpha: 0.5)),
            focusedErrorBorder: borderBuilder(AppColors.error, width: 1.5),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
