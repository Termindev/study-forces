import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class FormFieldWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const FormFieldWrapper({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
      child: child,
    );
  }
}
