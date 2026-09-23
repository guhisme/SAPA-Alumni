import '../utils/marketplace_assets.dart';

class MarketplaceProduct {
  final String id;
  final String name;
  final String categoryCode;
  final String department;
  final String description;
  final String price;
  final String productImageAsset;
  final String promoBannerAsset;
  final String placeholderColorHex;

  const MarketplaceProduct({
    required this.id,
    required this.name,
    required this.categoryCode,
    required this.department,
    required this.description,
    required this.price,
    required this.productImageAsset,
    required this.promoBannerAsset,
    required this.placeholderColorHex,
  });

  factory MarketplaceProduct.fromMap(String id, Map<String, dynamic> map) =>
      MarketplaceProduct(
        id: id,
        name: map['name'] as String? ?? '',
        categoryCode: map['categoryCode'] as String? ?? '',
        department: map['department'] as String? ?? '',
        description: map['description'] as String? ?? '',
        price: map['price'] as String? ?? 'Hubungi admin',
        productImageAsset: map['productImageAsset'] as String? ?? '',
        promoBannerAsset: map['promoBannerAsset'] as String? ?? '',
        placeholderColorHex: map['placeholderColorHex'] as String? ?? '1565C0',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'categoryCode': categoryCode,
        'department': department,
        'description': description,
        'price': price,
        'productImageAsset': productImageAsset,
        'promoBannerAsset': promoBannerAsset,
        'placeholderColorHex': placeholderColorHex,
      };

  MarketplaceProduct copyWith({String? name, String? price}) =>
      MarketplaceProduct(
        id: id,
        name: name ?? this.name,
        categoryCode: categoryCode,
        department: department,
        description: description,
        price: price ?? this.price,
        productImageAsset: productImageAsset,
        promoBannerAsset: promoBannerAsset,
        placeholderColorHex: placeholderColorHex,
      );

  static const products = [
    MarketplaceProduct(
      id: 'rpl',
      name: 'Jaket RPL',
      categoryCode: 'RPL',
      department: 'Rekayasa Perangkat Lunak',
      description:
          'Jaket jurusan RPL dengan desain eksklusif untuk alumni dan mahasiswa.',
      price: 'Hubungi admin',
      productImageAsset: MarketplaceAssets.productJaketRpl,
      promoBannerAsset: MarketplaceAssets.bannerPromoRpl,
      placeholderColorHex: '1565C0',
    ),
    MarketplaceProduct(
      id: 'dkv',
      name: 'Jaket DKV',
      categoryCode: 'DKV',
      department: 'Desain Komunikasi Visual',
      description:
          'Jaket jurusan DKV dengan desain eksklusif untuk alumni dan mahasiswa.',
      price: 'Hubungi admin',
      productImageAsset: MarketplaceAssets.productJaketDkv,
      promoBannerAsset: MarketplaceAssets.bannerPromoRpl,
      placeholderColorHex: '6A1B9A',
    ),
    MarketplaceProduct(
      id: 'mp',
      name: 'Jaket MP',
      categoryCode: 'MP',
      department: 'Manajemen Perkantoran',
      description:
          'Jaket jurusan MP dengan desain eksklusif untuk alumni dan mahasiswa.',
      price: 'Hubungi admin',
      productImageAsset: MarketplaceAssets.productJaketMp,
      promoBannerAsset: MarketplaceAssets.bannerPromoRpl,
      placeholderColorHex: '00838F',
    ),
    MarketplaceProduct(
      id: 'animasi',
      name: 'Jaket Animasi',
      categoryCode: 'Animasi',
      department: 'Animasi',
      description:
          'Jaket jurusan Animasi dengan desain eksklusif untuk alumni dan mahasiswa.',
      price: 'Hubungi admin',
      productImageAsset: MarketplaceAssets.productJaketAnimasi,
      promoBannerAsset: MarketplaceAssets.bannerPromoAnimasi,
      placeholderColorHex: 'EF6C00',
    ),
    MarketplaceProduct(
      id: 'tkj',
      name: 'Jaket TKJ',
      categoryCode: 'TKJ',
      department: 'Teknik Komputer dan Jaringan',
      description:
          'Jaket jurusan TKJ dengan desain eksklusif untuk alumni dan mahasiswa.',
      price: 'Hubungi admin',
      productImageAsset: MarketplaceAssets.productJaketTkj,
      promoBannerAsset: MarketplaceAssets.bannerPromoRpl,
      placeholderColorHex: '2E7D32',
    ),
    MarketplaceProduct(
      id: 'tja',
      name: 'Jaket TJA',
      categoryCode: 'TJA',
      department: 'Teknik Jaringan Akses',
      description:
          'Jaket jurusan TJA dengan desain eksklusif untuk alumni dan mahasiswa.',
      price: 'Hubungi admin',
      productImageAsset: MarketplaceAssets.productJaketTja,
      promoBannerAsset: MarketplaceAssets.bannerPromoRpl,
      placeholderColorHex: 'C62828',
    ),
  ];
}
