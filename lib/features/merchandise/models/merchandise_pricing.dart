const merchandiseMinimumQuantity = 50;
const merchandiseQuantityStep = 50;
const merchandiseMaximumQuantity = 100000;
const merchandisePresetQuantities = <int>[50, 100, 150, 200, 250, 500, 1000];

class MerchandisePriceSlab {
  const MerchandisePriceSlab({
    required this.minQuantity,
    required this.unitPricePaise,
  });

  final int minQuantity;
  final int unitPricePaise;

  factory MerchandisePriceSlab.fromJson(Map<String, dynamic> json) {
    return MerchandisePriceSlab(
      minQuantity: _int(json['min_quantity']),
      unitPricePaise: _int(json['unit_price_paise']),
    );
  }
}

class MerchandiseQuote {
  const MerchandiseQuote({
    required this.quantity,
    this.unitPricePaise,
    this.lineTotalPaise,
    this.error,
  });

  final int quantity;
  final int? unitPricePaise;
  final int? lineTotalPaise;
  final String? error;

  bool get configured =>
      error == null && unitPricePaise != null && lineTotalPaise != null;
}

bool isMerchandiseQuantity(int value) {
  return merchandisePresetQuantities.contains(value);
}

List<MerchandisePriceSlab> configuredMerchandiseSlabs(String slug) {
  const unitPricePaise = {
    't-shirt': 19900,
    'scarf': 5000,
    'flag': 10000,
    'badge': 6000,
    'cap': 12000,
    'mug': 8000,
    'poster': 15000,
    'sticker': 2000,
    'keychain': 4000,
    'pen': 1000,
    'bag': 15000,
    'gift-box': 5000,
  };
  final price = unitPricePaise[slug];
  if (price == null) {
    return const [];
  }
  return [
    for (final quantity in merchandisePresetQuantities)
      MerchandisePriceSlab(minQuantity: quantity, unitPricePaise: price),
  ];
}

String merchandiseQuantityLabel(int quantity, List<MerchandisePriceSlab> slabs) {
  final quote = quoteMerchandise(slabs, quantity);
  if (!quote.configured) {
    return '$quantity pieces';
  }
  return '$quantity pieces — ${formatMerchandisePrice(quote.unitPricePaise!)}/piece';
}

int normalizeMerchandiseQuantity(int value) {
  if (isMerchandiseQuantity(value)) {
    return value;
  }
  return merchandiseMinimumQuantity;
}

int? parseMerchandiseQuantity(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || !isMerchandiseQuantity(value)) {
    return null;
  }
  return value;
}

MerchandiseQuote quoteMerchandise(List<MerchandisePriceSlab> slabs, int quantity) {
  if (!isMerchandiseQuantity(quantity)) {
    return MerchandiseQuote(quantity: quantity, error: 'invalid_quantity');
  }
  MerchandisePriceSlab? chosen;
  for (final slab in slabs) {
    if (!isMerchandiseQuantity(slab.minQuantity) || slab.unitPricePaise < 0) {
      continue;
    }
    if (slab.minQuantity <= quantity &&
        (chosen == null || slab.minQuantity >= chosen.minQuantity)) {
      chosen = slab;
    }
  }
  if (chosen == null) {
    return MerchandiseQuote(quantity: quantity, error: 'price_not_configured');
  }
  return MerchandiseQuote(
    quantity: quantity,
    unitPricePaise: chosen.unitPricePaise,
    lineTotalPaise: chosen.unitPricePaise * quantity,
  );
}

String formatMerchandisePrice(int paise) {
  final negative = paise < 0;
  final absolute = paise.abs();
  final rupees = absolute ~/ 100;
  final cents = (absolute % 100).toString().padLeft(2, '0');
  final grouped = _group(rupees.toString());
  if (absolute % 100 == 0) {
    return '${negative ? '-' : ''}₹$grouped';
  }
  return '${negative ? '-' : ''}₹$grouped.$cents';
}

String _group(String digits) {
  if (digits.length <= 3) {
    return digits;
  }
  final last = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) {
    parts.insert(0, rest);
  }
  return '${parts.join(',')},$last';
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}
