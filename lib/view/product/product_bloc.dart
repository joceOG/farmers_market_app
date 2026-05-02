import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/api_client.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ApiClient _apiClient;

  ApiClient get apiClient => _apiClient;

  List<Map<String, dynamic>> _rootCategories = [];

  ProductBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const ProductInitial()) {
    on<ProductLoadCategories>(_onLoadCategories);
    on<ProductCategorySelected>(_onCategorySelected);
    on<ProductSubcategoryFilterChanged>(_onSubcategoryFilter);
    on<ProductNavigateBack>(_onNavigateBack);
    on<ProductAddToCart>(_onAddToCart);
    on<ProductRemoveFromCart>(_onRemoveFromCart);
    on<ProductUpdateCartQty>(_onUpdateQty);
    on<ProductPaymentMethodChanged>(_onPaymentMethod);
    on<ProductInterestRateChanged>(_onInterestRate);
    on<ProductFarmerSelected>(_onFarmerSelected);
    on<ProductCheckoutRequested>(_onCheckout);
    on<ProductCheckoutReset>(_onReset);
  }

  // ── Charger catégories racines ─────────────────────────────────
  Future<void> _onLoadCategories(
      ProductLoadCategories event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductCategoriesLoading(
      cart: state.cart,
      paymentMethod: state.paymentMethod,
      interestRate: state.interestRate,
      selectedFarmer: state.selectedFarmer,
    ));
    try {
      final raw = await _apiClient.get('categories', token: event.token);
      final cats = _toList(raw);
      final roots = cats.where((c) => c['parent_id'] == null).toList();
      _rootCategories = roots.isEmpty ? cats : roots;

      emit(ProductCategoriesLoaded(
        rootCategories: _rootCategories,
        cart: state.cart,
        paymentMethod: state.paymentMethod,
        interestRate: state.interestRate,
        selectedFarmer: state.selectedFarmer,
        navStack: [const NavEntry(label: 'Catalogue')],
      ));
    } on Exception catch (e) {
      emit(ProductError(
        message: e.toString().replaceFirst('Exception: ', ''),
        cart: state.cart,
      ));
    }
  }

  // ── Drill-down dans une catégorie ─────────────────────────────
  Future<void> _onCategorySelected(
      ProductCategorySelected event,
      Emitter<ProductState> emit,
      ) async {
    final cat = event.category;
    final catId = cat['id'] as int;
    final catName = cat['name'] as String;
    final List<Map<String, dynamic>> children =
    _toList(cat['children_recursive'] ?? []);

    final newStack = [
      ...state.navStack,
      NavEntry(label: catName, category: cat),
    ];

    if (children.isNotEmpty) {
      emit(ProductSubcategoryView(
        parentCategory: cat,
        subcategories: children,
        products: const [],
        allProducts: const [],
        isLoadingProducts: false,
        cart: state.cart,
        paymentMethod: state.paymentMethod,
        interestRate: state.interestRate,
        selectedFarmer: state.selectedFarmer,
        navStack: newStack,
      ));
      return;
    }

    emit(ProductSubcategoryView(
      parentCategory: cat,
      subcategories: const [],
      products: const [],
      allProducts: const [],
      isLoadingProducts: true,
      cart: state.cart,
      paymentMethod: state.paymentMethod,
      interestRate: state.interestRate,
      selectedFarmer: state.selectedFarmer,
      navStack: newStack,
    ));

    try {
      final raw = await _apiClient.get(
        'products?category_id=$catId',
        token: event.token,
      );
      final products = _toList(raw);
      emit(ProductSubcategoryView(
        parentCategory: cat,
        subcategories: const [],
        products: products,
        allProducts: products,
        activeSubcategory: null,
        isLoadingProducts: false,
        cart: state.cart,
        paymentMethod: state.paymentMethod,
        interestRate: state.interestRate,
        selectedFarmer: state.selectedFarmer,
        navStack: newStack,
      ));
    } on Exception catch (e) {
      emit(ProductError(
        message: e.toString().replaceFirst('Exception: ', ''),
        cart: state.cart,
        navStack: newStack,
      ));
    }
  }

  // ── Filtrer par sous-catégorie ─────────────────────────────────
  Future<void> _onSubcategoryFilter(
      ProductSubcategoryFilterChanged event,
      Emitter<ProductState> emit,
      ) async {
    if (state is! ProductSubcategoryView) return;
    final current = state as ProductSubcategoryView;

    if (event.subcategory == null) {
      emit(current.copyWithProducts(
        products: current.allProducts,
        clearActive: true,
      ));
      return;
    }

    final subId = event.subcategory!['id'] as int;
    final filtered =
    current.allProducts.where((p) => p['category_id'] == subId).toList();

    if (filtered.isNotEmpty) {
      emit(current.copyWithProducts(
        products: filtered,
        activeSubcategory: event.subcategory,
      ));
      return;
    }

    emit(current.copyWithProducts(
      products: const [],
      activeSubcategory: event.subcategory,
      isLoadingProducts: true,
    ));

    try {
      final raw = await _apiClient.get(
        'products?category_id=$subId',
        token: event.token,
      );
      final products = _toList(raw);
      emit(current.copyWithProducts(
        products: products,
        activeSubcategory: event.subcategory,
        isLoadingProducts: false,
      ));
    } on Exception catch (e) {
      emit(ProductError(
        message: e.toString().replaceFirst('Exception: ', ''),
        cart: state.cart,
        navStack: state.navStack,
      ));
    }
  }

  // ── Retour navigation ──────────────────────────────────────────
  void _onNavigateBack(
      ProductNavigateBack event, Emitter<ProductState> emit) {
    final stack = List<NavEntry>.from(state.navStack);
    if (stack.length <= 1) return;
    stack.removeLast();

    if (stack.length == 1) {
      emit(ProductCategoriesLoaded(
        rootCategories: _rootCategories,
        cart: state.cart,
        paymentMethod: state.paymentMethod,
        interestRate: state.interestRate,
        selectedFarmer: state.selectedFarmer,
        navStack: stack,
      ));
      return;
    }

    final parentEntry = stack.last;
    if (parentEntry.category != null) {
      final parentCat = parentEntry.category!;
      final children = _toList(parentCat['children_recursive'] ?? []);
      emit(ProductSubcategoryView(
        parentCategory: parentCat,
        subcategories: children,
        products: const [],
        allProducts: const [],
        isLoadingProducts: false,
        cart: state.cart,
        paymentMethod: state.paymentMethod,
        interestRate: state.interestRate,
        selectedFarmer: state.selectedFarmer,
        navStack: stack,
      ));
    }
  }

  // ── Cart operations ────────────────────────────────────────────
  void _onAddToCart(ProductAddToCart event, Emitter<ProductState> emit) {
    final cart = List<CartItem>.from(state.cart);
    final productId = event.product['id'] as int;
    final idx =
    cart.indexWhere((c) => (c.product['id'] as int) == productId);

    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(quantity: cart[idx].quantity + 1);
    } else {
      cart.add(CartItem(product: event.product, quantity: 1));
    }
    emit(_rebuildWithCart(cart));
  }

  void _onRemoveFromCart(
      ProductRemoveFromCart event, Emitter<ProductState> emit) {
    final cart = state.cart
        .where((c) => (c.product['id'] as int) != event.productId)
        .toList();
    emit(_rebuildWithCart(cart));
  }

  void _onUpdateQty(
      ProductUpdateCartQty event, Emitter<ProductState> emit) {
    final cart = List<CartItem>.from(state.cart);
    final idx =
    cart.indexWhere((c) => (c.product['id'] as int) == event.productId);
    if (idx < 0) return;

    if (event.quantity <= 0) {
      cart.removeAt(idx);
    } else {
      cart[idx] = cart[idx].copyWith(quantity: event.quantity);
    }
    emit(_rebuildWithCart(cart));
  }

  void _onPaymentMethod(
      ProductPaymentMethodChanged event, Emitter<ProductState> emit) {
    emit(_rebuildWith(paymentMethod: event.method));
  }

  void _onInterestRate(
      ProductInterestRateChanged event, Emitter<ProductState> emit) {
    emit(_rebuildWith(interestRate: event.rate));
  }

  void _onFarmerSelected(
      ProductFarmerSelected event, Emitter<ProductState> emit) {
    emit(_rebuildWith(selectedFarmer: event.farmer));
  }

  // ── Checkout ───────────────────────────────────────────────────
  // Étapes :
  //  1. POST /transactions  → crée la transaction
  //  2. Si paiement = crédit → POST /debts  → crée la dette liée
  Future<void> _onCheckout(
      ProductCheckoutRequested event,
      Emitter<ProductState> emit,
      ) async {
    final farmer = state.selectedFarmer;
    if (state.cart.isEmpty || farmer == null || (farmer['id'] ?? 0) == 0) {
      return;
    }

    final isCredit = state.paymentMethod == 'credit';

    emit(ProductCheckoutLoading(
      cart: state.cart,
      paymentMethod: state.paymentMethod,
      interestRate: state.interestRate,
      selectedFarmer: farmer,
      navStack: state.navStack,
    ));

    try {
      // ── 1. Créer la transaction ────────────────────────────────
      final transactionBody = {
        'farmer_id': farmer['id'],
        'payment_method': state.paymentMethod,
        if (isCredit) 'interest_rate': state.interestRate,
        'items': state.cart
            .map((c) => {
          'product_id': c.product['id'],
          'quantity': c.quantity,
        })
            .toList(),
      };

      final transactionResult = await _apiClient.post(
        'transactions',
        token: event.token,
        body: transactionBody,
      );

      // Récupérer l'id de la transaction créée
      // L'API peut retourner { data: { id: ... } } ou { id: ... }
      final transactionData = transactionResult['data'] is Map
          ? transactionResult['data'] as Map<String, dynamic>
          : transactionResult;

      final transactionId = transactionData['id'] as int?;

      // ── 2. Si crédit → créer la dette dans /debts ─────────────
      if (isCredit && transactionId != null) {
        // amount_fcfa = total avec intérêts (credited_amount)
        final creditedAmount = state.cartTotal * (1 + state.interestRate);

        final debtBody = {
          'transaction_id': transactionId,
          'farmer_id': farmer['id'],
          'amount_fcfa': double.parse(creditedAmount.toStringAsFixed(2)),
          'amount_paid': 0.0,
          'status': 'open',
        };

        await _apiClient.post(
          'debts',
          token: event.token,
          body: debtBody,
        );
      }

      emit(ProductCheckoutSuccess(
        transaction: transactionData,
        isCredit: isCredit,
        navStack: state.navStack,
      ));
    } on Exception catch (e) {
      emit(ProductError(
        message: e.toString().replaceFirst('Exception: ', ''),
        cart: state.cart,
        paymentMethod: state.paymentMethod,
        interestRate: state.interestRate,
        selectedFarmer: farmer,
        navStack: state.navStack,
      ));
    }
  }

  void _onReset(ProductCheckoutReset event, Emitter<ProductState> emit) {
    // Vider panier + farmer, restaurer les catégories sans spinner
    emit(ProductCategoriesLoaded(
      rootCategories: _rootCategories,
      cart: const [],
      paymentMethod: 'cash',
      interestRate: 0.30,
      selectedFarmer: null,
      navStack: [const NavEntry(label: 'Catalogue')],
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _toList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  ProductState _rebuildWithCart(List<CartItem> cart) =>
      _rebuild(cart: cart);

  ProductState _rebuildWith({
    String? paymentMethod,
    double? interestRate,
    Map<String, dynamic>? selectedFarmer,
  }) =>
      _rebuild(
        paymentMethod: paymentMethod,
        interestRate: interestRate,
        selectedFarmer: selectedFarmer,
      );

  ProductState _rebuild({
    List<CartItem>? cart,
    String? paymentMethod,
    double? interestRate,
    Map<String, dynamic>? selectedFarmer,
  }) {
    final c = cart ?? state.cart;
    final pm = paymentMethod ?? state.paymentMethod;
    final ir = interestRate ?? state.interestRate;
    final sf = selectedFarmer ?? state.selectedFarmer;
    final ns = state.navStack;

    if (state is ProductCategoriesLoaded) {
      return ProductCategoriesLoaded(
        rootCategories: (state as ProductCategoriesLoaded).rootCategories,
        cart: c,
        paymentMethod: pm,
        interestRate: ir,
        selectedFarmer: sf,
        navStack: ns,
      );
    }
    if (state is ProductSubcategoryView) {
      final s = state as ProductSubcategoryView;
      return ProductSubcategoryView(
        parentCategory: s.parentCategory,
        subcategories: s.subcategories,
        products: s.products,
        allProducts: s.allProducts,
        activeSubcategory: s.activeSubcategory,
        isLoadingProducts: s.isLoadingProducts,
        cart: c,
        paymentMethod: pm,
        interestRate: ir,
        selectedFarmer: sf,
        navStack: ns,
      );
    }
    if (state is ProductCheckoutView) {
      return ProductCheckoutView(
        cart: c,
        paymentMethod: pm,
        interestRate: ir,
        selectedFarmer: sf,
        navStack: ns,
      );
    }
    return ProductInitial();
  }
}