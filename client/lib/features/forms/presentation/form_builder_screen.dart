import 'package:flutter/material.dart';

import 'create_form_screen.dart';

/// Backward-compatible alias for the modern create form screen.
class FormBuilderScreen extends StatelessWidget {
  const FormBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) => const CreateFormScreen();
}
