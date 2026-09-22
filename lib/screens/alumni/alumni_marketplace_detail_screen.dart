import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/marketplace_product.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_snackbar.dart';

class AlumniMarketplaceDetailScreen extends StatelessWidget {
  final MarketplaceProduct product;

  const AlumniMarketplaceDetailScreen({super.key, required this.product});

  static const _adminWhatsapp = '6281234567890';

  Future<void> _buyNow(BuildContext context) async {
    final message =
        'Halo Admin SAPA Alumni, saya ingin membeli ${product.name}. '
        'Mohon info harga, ukuran, dan ketersediaan produknya.';
    final uri = Uri.https('wa.me', '/$_adminWhatsapp', {'text': message});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      AppSnackbar.error(context, 'WhatsApp tidak dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                product.productImageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _colorFromHex(product.placeholderColorHex),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined,
                      color: Colors.white, size: 64),
                ),
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
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(product.department,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                const Text('Deskripsi',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(product.description,
                    style: const TextStyle(
                        height: 1.5, color: AppColors.textDark)),
                const SizedBox(height: 18),
                const Text('Harga',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(product.price,
                    style: const TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _buyNow(context),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Beli sekarang via WhatsApp'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorFromHex(String hex) => Color(int.parse('FF$hex', radix: 16));
