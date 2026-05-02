part of 'product_bloc.dart';

// ── Cart item ──────────────────────────────────────────────────
class CartItem {
  final Map<String, dynamic> product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get _price {
    final raw = product['price_fcfa'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0.0;
  }

  double get subtotal => _price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

// ── Navigation stack entry ─────────────────────────────────────
class NavEntry {
  final String label;
  final Map<String, dynamic>? category;
  const NavEntry({required this.label, this.category});
}

// ── States ────────────────────────────────────────────────────
abstract class ProductState {
  final List<CartItem> cart;
  final String paymentMethod;
  final double interestRate;
  final Map<String, dynamic>? selectedFarmer;
  final List<NavEntry> navStack;

  const ProductState({
    this.cart = const [],
    this.paymentMethod = 'cash',
    this.interestRate = 0.30,
    this.selectedFarmer,
    this.navStack = const [],
  });

  double get cartTotal =>
      cart.fold(0, (sum, item) => sum + item.subtotal);

  double get creditedAmount =>
      paymentMethod == 'credit' ? cartTotal * (1 + interestRate) : cartTotal;

  int get cartCount =>
      cart.fold(0, (sum, item) => sum + item.quantity);
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductCategoriesLoading extends ProductState {
  const ProductCategoriesLoading({
    super.cart,
    super.paymentMethod,
    super.interestRate,
    super.selectedFarmer,
    super.navStack,
  });
}

class ProductCategoriesLoaded extends ProductState {
  final List<Map<String, dynamic>> rootCategories;

  const ProductCategoriesLoaded({
    required this.rootCategories,
    super.cart,
    super.paymentMethod,
    super.interestRate,
    super.selectedFarmer,
    super.navStack,
  });
}

class ProductSubcategoryView extends ProductState {
  final Map<String, dynamic> parentCategory;
  final List<Map<String, dynamic>> subcategories;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> allProducts;
  final Map<String, dynamic>? activeSubcategory;
  final bool isLoadingProducts;

  const ProductSubcategoryView({
    required this.parentCategory,
    required this.subcategories,
    required this.products,
    required this.allProducts,
    this.activeSubcategory,
    this.isLoadingProducts = false,
    super.cart,
    super.paymentMethod,
    super.interestRate,
    super.selectedFarmer,
    super.navStack,
  });

  ProductSubcategoryView copyWithProducts({
    List<Map<String, dynamic>>? products,
    Map<String, dynamic>? activeSubcategory,
    bool clearActive = false,
    bool? isLoadingProducts,
    List<CartItem>? cart,
  }) {
    return ProductSubcategoryView(
      parentCategory: parentCategory,
      subcategories: subcategories,
      products: products ?? this.products,
      allProducts: allProducts,
      activeSubcategory:
      clearActive ? null : (activeSubcategory ?? this.activeSubcategory),
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      cart: cart ?? this.cart,
      paymentMethod: paymentMethod,
      interestRate: interestRate,
      selectedFarmer: selectedFarmer,
      navStack: navStack,
    );
  }
}

class ProductCheckoutView extends ProductState {
  const ProductCheckoutView({
    super.cart,
    super.paymentMethod,
    super.interestRate,
    super.selectedFarmer,
    super.navStack,
  });
}

class ProductCheckoutLoading extends ProductState {
  const ProductCheckoutLoading({
    super.cart,
    super.paymentMethod,
    super.interestRate,
    super.selectedFarmer,
    super.navStack,
  });
}

class ProductCheckoutSuccess extends ProductState {
  final Map<String, dynamic> transaction;

  /// true si la transaction était en mode crédit
  /// → une dette a été créée dans /debts
  final bool isCredit;

  const ProductCheckoutSuccess({
    required this.transaction,
    required this.isCredit,
    super.navStack,
  });
}

class ProductError extends ProductState {
  final String message;

  const ProductError({
    required this.message,
    super.cart,
    super.paymentMethod,
    super.interestRate,
    super.selectedFarmer,
    super.navStack,
  });
}