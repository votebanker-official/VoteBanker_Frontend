import 'merchandise_pricing.dart';

class MerchandiseProduct {
  const MerchandiseProduct({
    required this.slug,
    required this.name,
    required this.description,
    required this.sizes,
    required this.colors,
    this.priceSlabs = const [],
    this.minimumOrderQuantity = 50,
    this.available = true,
  });

  final String slug;
  final String name;
  final String description;
  final List<String> sizes;
  final List<String> colors;
  final List<MerchandisePriceSlab> priceSlabs;
  final int minimumOrderQuantity;
  final bool available;

  factory MerchandiseProduct.fromJson(Map<String, dynamic> json) {
    return MerchandiseProduct(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sizes: _strings(json['sizes']),
      colors: _strings(json['colors']),
      priceSlabs: _slabs(json['price_slabs']),
      minimumOrderQuantity: json['minimum_order_quantity'] as int? ?? 50,
      available: json['available'] != false && json['active'] != false,
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [for (final item in value) item.toString()];
  }

  static List<MerchandisePriceSlab> _slabs(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is Map)
          MerchandisePriceSlab.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}

class MerchandiseOrder {
  const MerchandiseOrder({
    required this.id,
    required this.productName,
    required this.campaignLine,
    required this.quantity,
    required this.status,
    this.size = '',
    this.color = '',
    this.campaignPhoto = '',
    this.unitPricePaise,
    this.lineTotalPaise,
  });

  final String id;
  final String productName;
  final String campaignLine;
  final int quantity;
  final String status;
  final String size;
  final String color;
  final String campaignPhoto;
  final int? unitPricePaise;
  final int? lineTotalPaise;

  factory MerchandiseOrder.fromJson(Map<String, dynamic> json) {
    return MerchandiseOrder(
      id: json['id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      campaignLine: json['campaign_line'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'requested',
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
      campaignPhoto: json['campaign_photo'] as String? ?? '',
      unitPricePaise: _optionalInt(json['unit_price_paise']),
      lineTotalPaise: _optionalInt(json['line_total_paise']),
    );
  }

  static int? _optionalInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      return null;
    }
    return int.tryParse('$value');
  }
}
