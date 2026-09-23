import 'package:flutter/material.dart';

import '../../models/marketplace_product.dart';
import '../../services/marketplace_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_view.dart';

class AdminMarketplaceScreen extends StatefulWidget {
  const AdminMarketplaceScreen({super.key});

  @override
  State<AdminMarketplaceScreen> createState() => _AdminMarketplaceScreenState();
}

class _AdminMarketplaceScreenState extends State<AdminMarketplaceScreen> {
  late final Future<void> _seedFuture =
      MarketplaceService.instance.seedDefaults();

  Future<void> _edit(BuildContext context, MarketplaceProduct product) async {
    final name = TextEditingController(text: product.name);
    final price = TextEditingController(text: product.price);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kelola ${product.categoryCode}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama produk')),
          TextField(
              controller: price,
              decoration:
                  const InputDecoration(labelText: 'Harga / keterangan')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (result == true) {
      await MarketplaceService.instance.save(
          product.copyWith(name: name.text.trim(), price: price.text.trim()));
    }
    name.dispose();
    price.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Marketplace')),
      body: FutureBuilder<void>(
        future: _seedFuture,
        builder: (context, seedSnap) => StreamBuilder<List<MarketplaceProduct>>(
          stream: MarketplaceService.instance.watchProducts(),
          builder: (context, snap) {
            if (seedSnap.connectionState != ConnectionState.done ||
                snap.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final products = snap.data ?? MarketplaceProduct.products;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final product = products[index];
                return ListTile(
                  tileColor: AppColors.surface,
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(product.name),
                  subtitle: Text('${product.categoryCode} - ${product.price}'),
                  trailing: IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(context, product),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
