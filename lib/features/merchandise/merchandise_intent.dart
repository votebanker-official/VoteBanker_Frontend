import 'package:shared_preferences/shared_preferences.dart';

import 'models/merchandise_pricing.dart';

/// The product chosen before sign-in, so login can return to that order.
class MerchandiseIntent {
  MerchandiseIntent._();

  static const _slugKey = 'merch.slug';
  static const _quantityKey = 'merch.quantity';
  static String? _slug;
  static int? _quantity;

  static Future<void> remember(String slug, int quantity) async {
    if (slug.trim().isEmpty || !isMerchandiseQuantity(quantity)) return;
    _slug = slug;
    _quantity = quantity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slugKey, slug);
    await prefs.setInt(_quantityKey, quantity);
  }

  static Future<({String slug, int quantity})?> peek() async {
    var slug = _slug;
    var quantity = _quantity;
    if (slug == null || quantity == null) {
      final prefs = await SharedPreferences.getInstance();
      slug = prefs.getString(_slugKey);
      quantity = prefs.getInt(_quantityKey);
      _slug = slug;
      _quantity = quantity;
    }
    if (slug == null ||
        slug.isEmpty ||
        quantity == null ||
        !isMerchandiseQuantity(quantity)) {
      return null;
    }
    return (slug: slug, quantity: quantity);
  }

  static Future<void> clear() async {
    _slug = null;
    _quantity = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_slugKey);
    await prefs.remove(_quantityKey);
  }
}
