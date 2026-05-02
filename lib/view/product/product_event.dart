part of 'product_bloc.dart';

abstract class ProductEvent {}

/// Chargement initial : catégories racines
class ProductLoadCategories extends ProductEvent {
  final String token;
  ProductLoadCategories({required this.token});
}

/// Drill-down dans une catégorie (racine ou sous-catégorie)
class ProductCategorySelected extends ProductEvent {
  final String token;
  final Map<String, dynamic> category;
  ProductCategorySelected({required this.token, required this.category});
}

/// Sélection d'une sous-catégorie (pill) pour filtrer les produits
class ProductSubcategoryFilterChanged extends ProductEvent {
  final String token;
  final Map<String, dynamic>? subcategory; // null = tous
  ProductSubcategoryFilterChanged({required this.token, this.subcategory});
}

/// Retour en arrière dans la navigation
class ProductNavigateBack extends ProductEvent {}

/// Ajout d'un produit au panier
class ProductAddToCart extends ProductEvent {
  final Map<String, dynamic> product;
  ProductAddToCart({required this.product});
}

/// Retrait d'un produit du panier
class ProductRemoveFromCart extends ProductEvent {
  final int productId;
  ProductRemoveFromCart({required this.productId});
}

/// Modification de la quantité d'un produit dans le panier
class ProductUpdateCartQty extends ProductEvent {
  final int productId;
  final int quantity;
  ProductUpdateCartQty({required this.productId, required this.quantity});
}

/// Changement du mode de paiement
class ProductPaymentMethodChanged extends ProductEvent {
  final String method; // 'cash' | 'credit'
  ProductPaymentMethodChanged({required this.method});
}

/// Changement du taux d'intérêt
class ProductInterestRateChanged extends ProductEvent {
  final double rate;
  ProductInterestRateChanged({required this.rate});
}

/// Sélection du farmer pour la commande
class ProductFarmerSelected extends ProductEvent {
  final Map<String, dynamic> farmer;
  ProductFarmerSelected({required this.farmer});
}

/// Validation de la commande
class ProductCheckoutRequested extends ProductEvent {
  final String token;
  ProductCheckoutRequested({required this.token});
}

/// Reset après succès commande
class ProductCheckoutReset extends ProductEvent {}