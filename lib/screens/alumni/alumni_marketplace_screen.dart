import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/marketplace_product.dart';
import '../../utils/app_colors.dart';
import 'alumni_marketplace_detail_screen.dart';

class AlumniMarketplaceScreen extends StatefulWidget {
  const AlumniMarketplaceScreen({super.key});

  @override
  State<AlumniMarketplaceScreen> createState() =>
      _AlumniMarketplaceScreenState();
}

class _AlumniMarketplaceScreenState extends State<AlumniMarketplaceScreen> {
  final _searchController = TextEditingController();
  final _promoCarouselController = PageController();
  Timer? _promoAutoSlideTimer;
  int _currentPromoIndex = 0;
  String _selectedCategory = 'Semua';

  static const _categories = [
    'Semua',
    'RPL',
    'DKV',
    'MP',
    'Animasi',
    'TKJ',
    'TJA',
  ];

  List<MarketplaceProduct> get _promoProducts => [
        MarketplaceProduct.products[0],
        MarketplaceProduct.products[3],
      ];

  List<MarketplaceProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return MarketplaceProduct.products.where((product) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          product.categoryCode == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.department.toLowerCase().contains(query) ||
          product.categoryCode.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _promoAutoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_promoCarouselController.hasClients) return;
      final next = (_currentPromoIndex + 1) % _promoProducts.length;
      _promoCarouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _promoAutoSlideTimer?.cancel();
    _promoCarouselController.dispose();
    super.dispose();
  }

  void _open(BuildContext context, MarketplaceProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlumniMarketplaceDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketplace'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cari produk atau jurusan',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final category = _categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 176,
            child: PageView.builder(
              controller: _promoCarouselController,
              itemCount: _promoProducts.length,
              onPageChanged: (index) =>
                  setState(() => _currentPromoIndex = index),
              itemBuilder: (_, index) => _PromoBanner(
                product: _promoProducts[index],
                onTap: () => _open(context, _promoProducts[index]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promoProducts.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: _currentPromoIndex == index ? 18 : 6,
                decoration: BoxDecoration(
                  color: _currentPromoIndex == index
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Produk jurusan',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Temukan jaket jurusan pilihanmu.',
            style: TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .72,
            ),
            itemBuilder: (_, index) {
              final product = _filteredProducts[index];
              return _ProductCard(
                  product: product, onTap: () => _open(context, product));
            },
          ),
          if (_filteredProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Produk tidak ditemukan.',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final MarketplaceProduct product;
  final VoidCallback onTap;

  const _PromoBanner({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MarketplaceImage(
              assetPath: product.promoBannerAsset,
              placeholderColor: _colorFromHex(product.placeholderColorHex),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              alignment: Alignment.bottomLeft,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
              child: Text(
                'Promo ${product.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MarketplaceProduct product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      width: double.infinity,
                      child: _MarketplaceImage(
                        assetPath: product.productImageAsset,
                        placeholderColor:
                            _colorFromHex(product.placeholderColorHex),
                      )),
                ),
              ),
              const SizedBox(height: 9),
              Text(product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 3),
              Text(product.department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textGrey)),
              const SizedBox(height: 6),
              const Text('Lihat detail',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceImage extends StatelessWidget {
  final String assetPath;
  final Color placeholderColor;

  const _MarketplaceImage({
    required this.assetPath,
    required this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: placeholderColor,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: Colors.white, size: 42),
      ),
    );
  }
}

Color _colorFromHex(String hex) => Color(int.parse('FF$hex', radix: 16));
