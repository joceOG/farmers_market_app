import 'product.dart';

class TransactionItem {
  final int id;
  final int transactionId;
  final int productId;
  final Product? product;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as int,
      transactionId: json['transaction_id'] as int,
      productId: json['product_id'] as int,
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'subtotal': subtotal,
  };
}

/// DTO léger utilisé pour construire une transaction (checkout)
class TransactionItemRequest {
  final int productId;
  final int quantity;

  const TransactionItemRequest({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
  };
}