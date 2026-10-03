class MerchandiseProduct {
  const MerchandiseProduct({
    required this.slug,
    required this.name,
    required this.description,
    required this.sizes,
    required this.colors,
  });

  final String slug;
  final String name;
  final String description;
  final List<String> sizes;
  final List<String> colors;

  factory MerchandiseProduct.fromJson(Map<String, dynamic> json) {
    return MerchandiseProduct(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sizes: _strings(json['sizes']),
      colors: _strings(json['colors']),
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [for (final item in value) item.toString()];
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
  });

  final String id;
  final String productName;
  final String campaignLine;
  final int quantity;
  final String status;
  final String size;
  final String color;

  factory MerchandiseOrder.fromJson(Map<String, dynamic> json) {
    return MerchandiseOrder(
      id: json['id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      campaignLine: json['campaign_line'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'requested',
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }
}
