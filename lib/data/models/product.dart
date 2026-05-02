import 'category.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double priceFcfa;
  final int categoryId;
  final Category? category;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.priceFcfa,
    required this.categoryId,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // ✅ FIX : Laravel retourne price_fcfa en String "4500.00"
    // On parse proprement qu'il soit String ou num
    final raw = json['price_fcfa'];
    final double price = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '0') ?? 0.0;

    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceFcfa: price,
      categoryId: json['category_id'] as int,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price_fcfa': priceFcfa,
    'category_id': categoryId,
  };

  /// Prix formaté en FCFA (ex: "4 500 F")
  String get formattedPrice =>
      '${priceFcfa.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]} ',
      )} F';

  @override
  String toString() => 'Product(id: $id, name: $name, price: $priceFcfa)';
}