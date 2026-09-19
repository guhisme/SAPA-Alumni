import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Cari...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: 60,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}
