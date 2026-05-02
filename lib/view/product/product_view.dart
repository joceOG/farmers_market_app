import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_bloc.dart';

class ProductsView extends StatefulWidget {
  final String token;
  const ProductsView({super.key, required this.token});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  // ── Accordion state ───────────────────────────────────────────
  int? expandedCategoryId;
  int? selectedSubId;

  // ── Products state ────────────────────────────────────────────
  final Map<int, List<Map<String, dynamic>>> _cache = {};
  bool _isLoading = false;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _displayProducts = [];

  // ── Search ────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text;
        _applySearch();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductBloc>().add(ProductLoadCategories(token: widget.token));
      _loadInitialProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _isLoading = true);
    try {
      final bloc = context.read<ProductBloc>();
      final raw = await bloc.apiClient.get('products', token: widget.token);
      final all = List<Map<String, dynamic>>.from(raw);
      all.shuffle(Random());
      final initial = all.take(5).toList();
      setState(() {
        _allProducts = initial;
        _displayProducts = initial;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectSub(Map<String, dynamic> sub) async {
    final subId = sub['id'] as int;
    if (selectedSubId == subId) {
      setState(() {
        selectedSubId = null;
        _allProducts = _cache[-1] ?? [];
        _applySearch();
      });
      return;
    }
    setState(() {
      selectedSubId = subId;
      _isLoading = true;
    });
    if (_cache.containsKey(subId)) {
      setState(() {
        _allProducts = _cache[subId]!;
        _applySearch();
        _isLoading = false;
      });
      return;
    }
    try {
      final bloc = context.read<ProductBloc>();
      final raw = await bloc.apiClient.get(
        'products?category_id=$subId',
        token: widget.token,
      );
      final products = List<Map<String, dynamic>>.from(raw);
      _cache[subId] = products;
      setState(() {
        _allProducts = products;
        _applySearch();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _displayProducts = List.from(_allProducts);
    } else {
      _displayProducts = _allProducts
          .where((p) => (p['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  int _qtyInCart(ProductState state, dynamic productId) {
    try {
      return state.cart
          .firstWhere((c) => c.product['id'] == productId)
          .quantity;
    } catch (_) {
      return 0;
    }
  }

  void _openCheckout(BuildContext context, ProductState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ProductBloc>(),
        child: _CheckoutSheet(token: widget.token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductCheckoutSuccess) {
          Navigator.of(context).pop();
          final isCredit = state.isCredit;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCredit
                          ? '✅ Transaction effectuée avec succès !\n💳 Crédit enregistré pour cet agriculteur.'
                          : '✅ Transaction effectuée avec succès !',
                    ),
                  ),
                ],
              ),
              backgroundColor: isCredit ? Colors.orange.shade700 : Colors.green.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
          // Recharger les catégories pour revenir au menu produits
          context.read<ProductBloc>().add(
            ProductLoadCategories(token: widget.token),
          );
          _loadInitialProducts();
        }
        if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProductCategoriesLoading || state is ProductInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = _getCategories(state);
        final cartCount = state.cartCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            // ── AppBar vert sombre ──────────────────────────────
            title: const Text(
              'Catalogue',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1B5E20), // vert sombre
            foregroundColor: Colors.white,
            elevation: 2,
            actions: [
              // ── Icône panier : blanc, décalée de 40px vers la gauche ──
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      onPressed: () => _openCheckout(context, state),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                flex: 5,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    ...categories.map((cat) => _buildCategoryAccordion(cat, state)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit...',
                          hintStyle: const TextStyle(color: Colors.black38),
                          prefixIcon: const Icon(Icons.search, color: Colors.black54),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black38),
                            onPressed: () => _searchCtrl.clear(),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    )
                        : _displayProducts.isEmpty
                        ? const SizedBox(
                      height: 220,
                      child: Center(
                        child: Text('Aucun produit trouvé',
                            style: TextStyle(color: Colors.black45)),
                      ),
                    )
                        : SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _displayProducts.length,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemBuilder: (_, i) {
                          final p = _displayProducts[i];
                          return _buildProductCard(p, state, context);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryAccordion(Map<String, dynamic> cat, ProductState state) {
    final catId = cat['id'] as int;
    final subs = List<Map<String, dynamic>>.from(cat['children_recursive'] ?? []);
    final isOpen = expandedCategoryId == catId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: isOpen ? 10 : 3,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text(
                (cat['name'] as String).isNotEmpty
                    ? (cat['name'] as String)[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(cat['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.expand_more, color: Colors.black54),
            ),
            onTap: () => setState(() {
              expandedCategoryId = isOpen ? null : catId;
            }),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
            isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: subs.map<Widget>((sub) {
                    final subId = sub['id'] as int;
                    final isSelected = subId == selectedSubId;
                    return GestureDetector(
                      onTap: () => _selectSub(sub),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sub['name'] ?? '',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            secondChild: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> p,
      ProductState state,
      BuildContext context,
      ) {
    final productId = p['id'];
    final qty = _qtyInCart(state, productId);
    final price = _parsePrice(p['price_fcfa']);
    final imageUrl = p['image_url'] as String?;

    return Container(
      width: 170,
      height: 210,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _productPlaceholder(),
            )
                : _productPlaceholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatPrice(price)} F',
                        style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      qty == 0
                          ? GestureDetector(
                        onTap: () => context
                            .read<ProductBloc>()
                            .add(ProductAddToCart(product: p)),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B5E20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      )
                          : Row(
                        children: [
                          _qtyBtn(
                            icon: Icons.remove,
                            onTap: () => context.read<ProductBloc>().add(
                              ProductUpdateCartQty(
                                productId: productId as int,
                                quantity: qty - 1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('$qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          _qtyBtn(
                            icon: Icons.add,
                            onTap: () => context
                                .read<ProductBloc>()
                                .add(ProductAddToCart(product: p)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.eco, color: Color(0xFF1B5E20), size: 36),
    );
  }

  List<Map<String, dynamic>> _getCategories(ProductState state) {
    if (state is ProductCategoriesLoaded) return state.rootCategories;
    if (state is ProductSubcategoryView) return [state.parentCategory];
    return [];
  }

  double _parsePrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0.0;
  }

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) return price.toInt().toString();
    return price.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════════
// Checkout Bottom Sheet — avec liste des farmers
// ═══════════════════════════════════════════════════════════════
class _CheckoutSheet extends StatefulWidget {
  final String token;
  const _CheckoutSheet({required this.token});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _searchFarmerCtrl = TextEditingController();

  // ── Farmers ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _farmers = [];
  List<Map<String, dynamic>> _filteredFarmers = [];
  bool _loadingFarmers = false;
  bool _farmersLoaded = false;
  String _farmerSearch = '';

  @override
  void initState() {
    super.initState();
    _loadFarmers();
    _searchFarmerCtrl.addListener(() {
      setState(() {
        _farmerSearch = _searchFarmerCtrl.text.toLowerCase();
        _filteredFarmers = _farmers.where((f) {
          final name = '${f['firstname'] ?? ''} ${f['lastname'] ?? ''}'
              .toLowerCase();
          final id = (f['identifier'] ?? '').toString().toLowerCase();
          return name.contains(_farmerSearch) || id.contains(_farmerSearch);
        }).toList();
      });
    });
  }

  Future<void> _loadFarmers() async {
    if (_farmersLoaded) return;
    setState(() => _loadingFarmers = true);
    try {
      final bloc = context.read<ProductBloc>();
      final raw = await bloc.apiClient.get('farmers', token: widget.token);
      final list = List<Map<String, dynamic>>.from(raw);
      setState(() {
        _farmers = list;
        _filteredFarmers = list;
        _loadingFarmers = false;
        _farmersLoaded = true;
      });
    } catch (_) {
      setState(() => _loadingFarmers = false);
    }
  }

  @override
  void dispose() {
    _searchFarmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final cart = state.cart;
        final total = state.cartTotal;
        final credited = state.creditedAmount;
        final payMethod = state.paymentMethod;
        final interestRate = state.interestRate;
        final farmer = state.selectedFarmer;

        return Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.97,
            expand: false,
            builder: (_, scrollCtrl) => CustomScrollView(
              controller: scrollCtrl,
              slivers: [
                // ── En-tête ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                color: Color(0xFF1B5E20)),
                            SizedBox(width: 8),
                            Text('Mon Panier',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // ── Articles du panier ───────────────────────────
                if (cart.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Votre panier est vide',
                            style: TextStyle(color: Colors.black45)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) {
                        final item = cart[i];
                        final price =
                        _parsePrice(item.product['price_fcfa']);
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FFF9),
                            borderRadius: BorderRadius.circular(12),
                            border:
                            Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      '${_formatPrice(price)} FCFA / unité',
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _miniQtyBtn(
                                    icon: Icons.remove,
                                    onTap: () =>
                                        context.read<ProductBloc>().add(
                                          ProductUpdateCartQty(
                                            productId:
                                            item.product['id'] as int,
                                            quantity: item.quantity - 1,
                                          ),
                                        ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  _miniQtyBtn(
                                    icon: Icons.add,
                                    onTap: () =>
                                        context.read<ProductBloc>().add(
                                            ProductAddToCart(
                                                product: item.product)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_formatPrice(item.subtotal)} F',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: cart.length,
                    ),
                  ),

                // ── Totaux + options + farmer + bouton ───────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cart.isNotEmpty) ...[
                          const Divider(),
                          _totalRow('Sous-total',
                              '${_formatPrice(total)} FCFA'),
                          if (payMethod == 'credit')
                            _totalRow(
                              'Total crédit (+${(interestRate * 100).toStringAsFixed(0)}%)',
                              '${_formatPrice(credited)} FCFA',
                              bold: true,
                              color: Colors.orange,
                            )
                          else
                            _totalRow(
                              'Total',
                              '${_formatPrice(total)} FCFA',
                              bold: true,
                              color: const Color(0xFF1B5E20),
                            ),
                          const SizedBox(height: 16),
                        ],

                        // ── Mode de paiement ───────────────────
                        const Text('Mode de paiement',
                            style:
                            TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _payChip(
                              label: 'Espèces',
                              icon: Icons.payments_outlined,
                              selected: payMethod == 'cash',
                              onTap: () =>
                                  context.read<ProductBloc>().add(
                                    ProductPaymentMethodChanged(
                                        method: 'cash'),
                                  ),
                            ),
                            const SizedBox(width: 10),
                            _payChip(
                              label: 'Crédit',
                              icon: Icons.credit_card,
                              selected: payMethod == 'credit',
                              onTap: () =>
                                  context.read<ProductBloc>().add(
                                    ProductPaymentMethodChanged(
                                        method: 'credit'),
                                  ),
                            ),
                          ],
                        ),

                        if (payMethod == 'credit') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text(
                                'Un crédit sera enregistré pour cet agriculteur',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text("Taux d'intérêt",
                              style:
                              TextStyle(fontWeight: FontWeight.w600)),
                          Slider(
                            value: interestRate,
                            min: 0.05,
                            max: 0.50,
                            divisions: 9,
                            label:
                            '${(interestRate * 100).toStringAsFixed(0)}%',
                            activeColor: const Color(0xFF1B5E20),
                            onChanged: (v) =>
                                context.read<ProductBloc>().add(
                                    ProductInterestRateChanged(rate: v)),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ── Sélection de l'agriculteur ─────────
                        const Text('Agriculteur',
                            style:
                            TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),

                        if (farmer != null && (farmer['id'] ?? 0) != 0)
                        // Farmer sélectionné
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF1B5E20),
                                  width: 1.5),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                  const Color(0xFF1B5E20),
                                  radius: 18,
                                  child: Text(
                                    _initials(farmer),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${farmer['firstname'] ?? ''} ${farmer['lastname'] ?? ''}'
                                            .trim(),
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600),
                                      ),
                                      Text(
                                        farmer['identifier'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.read<ProductBloc>().add(
                                        ProductFarmerSelected(
                                            farmer: {}),
                                      ),
                                  child: const Icon(Icons.close,
                                      size: 20, color: Colors.black45),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          // Champ de recherche farmer
                          TextField(
                            controller: _searchFarmerCtrl,
                            decoration: InputDecoration(
                              hintText: 'Rechercher un agriculteur...',
                              prefixIcon: const Icon(
                                  Icons.person_search_outlined),
                              suffixIcon: _farmerSearch.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    _searchFarmerCtrl.clear(),
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Liste des farmers
                          if (_loadingFarmers)
                            const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ))
                          else
                            Container(
                              constraints:
                              const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _filteredFarmers.isEmpty
                                  ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                    'Aucun agriculteur trouvé',
                                    style: TextStyle(
                                        color: Colors.black45)),
                              )
                                  : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _filteredFarmers.length,
                                separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final f = _filteredFarmers[i];
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                      const Color(0xFFE8F5E9),
                                      radius: 16,
                                      child: Text(
                                        _initials(f),
                                        style: const TextStyle(
                                          color: Color(0xFF1B5E20),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${f['firstname'] ?? ''} ${f['lastname'] ?? ''}'
                                          .trim(),
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      f['identifier'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12),
                                    ),
                                    onTap: () {
                                      context
                                          .read<ProductBloc>()
                                          .add(ProductFarmerSelected(
                                          farmer: f));
                                      _searchFarmerCtrl.clear();
                                    },
                                  );
                                },
                              ),
                            ),
                        ],

                        const SizedBox(height: 20),

                        // ── Bouton Valider ─────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: payMethod == 'credit'
                                  ? Colors.orange.shade700
                                  : const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: (cart.isEmpty ||
                                state is ProductCheckoutLoading ||
                                farmer == null ||
                                (farmer['id'] ?? 0) == 0)
                                ? null
                                : () {
                              context.read<ProductBloc>().add(
                                ProductCheckoutRequested(
                                    token: widget.token),
                              );
                            },
                            child: state is ProductCheckoutLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2),
                            )
                                : Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  payMethod == 'credit'
                                      ? Icons.credit_card
                                      : Icons.check_circle_outline,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  payMethod == 'credit'
                                      ? 'Valider & Créer le crédit'
                                      : 'Valider la commande',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Message si pas de farmer sélectionné
                        if (farmer == null || (farmer['id'] ?? 0) == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Veuillez sélectionner un agriculteur',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(Map<String, dynamic> f) {
    final first =
    (f['firstname'] as String? ?? '').isNotEmpty ? f['firstname'][0] : '';
    final last =
    (f['lastname'] as String? ?? '').isNotEmpty ? f['lastname'][0] : '';
    return '${first}${last}'.toUpperCase();
  }

  Widget _miniQtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _payChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (label == 'Crédit'
              ? Colors.orange.shade700
              : const Color(0xFF1B5E20))
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.black54, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _parsePrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0.0;
  }

  static String _formatPrice(double price) {
    if (price == price.truncateToDouble()) return price.toInt().toString();
    return price.toStringAsFixed(0);
  }
}