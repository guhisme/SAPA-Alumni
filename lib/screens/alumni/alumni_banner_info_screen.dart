import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_colors.dart';

class AlumniBannerInfoScreen extends StatelessWidget {
  final String title;
  final String provider;
  final String description;
  final String requirements;
  final String benefits;
  final String assetPath;
  final String link;

  const AlumniBannerInfoScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.description,
    this.requirements = '',
    this.benefits = '',
    required this.assetPath,
    this.link = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Informasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Container(
                color: AppColors.surface,
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 8),
                _DetailRow(label: 'Penyelenggara', value: provider),
                const Divider(height: 26),
                _Section(title: 'Deskripsi', content: description),
                if (requirements.isNotEmpty) _Section(title: 'Persyaratan', content: requirements),
                if (benefits.isNotEmpty) _Section(title: 'Manfaat', content: benefits),
                if (link.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openLink(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Buka informasi resmi'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.parse(link.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan tidak dapat dibuka.')),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 105, child: Text(label, style: const TextStyle(color: AppColors.textGrey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(height: 1.6, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
