import 'package:farmers_market_app/view/historique/historique_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../farmer/farmer_view.dart';
import '../historique/historique_view.dart';
import '../product/product_view.dart';
import 'dashboard_bloc.dart';
import '../product/product_bloc.dart';       // 🆕 Import de ProductBloc
import '../../data/services/api_client.dart'; // 🆕 Import de ApiClient (ajustez le chemin si

const Color kGreen = Color(0xFF2D6A4F);
const Color kGreenDark = Color(0xFF1B4332);
const Color kAmber = Color(0xFFC07C00);
const Color kBg = Color(0xFFF5F5F0);

class DashboardView extends StatefulWidget {
  final String token;
  final String username;

  const DashboardView({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    // ── MultiBlocProvider remplace le BlocProvider unique ──────────
    return MultiBlocProvider(
      providers: [
        // 1️⃣  DashboardBloc (déjà présent)
        BlocProvider(
          create: (_) => DashboardBloc()
            ..add(DashboardLoadRequested(token: widget.token)),
        ),

        // 2️⃣  ProductBloc (🆕 ajouté pour corriger l'erreur)
        BlocProvider(
          create: (_) => ProductBloc(apiClient: _apiClient),
        ),
      ],
      child: _DashboardScaffold(
        token: widget.token,
        username: widget.username,
        apiClient: _apiClient,
        currentIndex: _currentIndex,
        onTabChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Scaffold principal ─────────────────────────────────────────
class _DashboardScaffold extends StatelessWidget {
  final String token;
  final String username;
  final ApiClient apiClient;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const _DashboardScaffold({
    required this.token,
    required this.username,
    required this.apiClient,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(token: token, username: username),
      FarmersView(token: token),
      ProductsView(token: token),
      HistoriqueView(token: token, apiClient: apiClient),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kGreenDark,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTabChanged,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconSize: 28,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Farmers'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), label: 'History'),
          ],
        ),
      ),
    );
  }
}

// ── Onglet Accueil ──────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String token;
  final String username;

  const _HomeTab({required this.token, required this.username});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return SafeArea(
          child: RefreshIndicator(
            color: kGreenDark,
            onRefresh: () async {
              context.read<DashboardBloc>().add(DashboardRefreshRequested(token: token));
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color:
                      Color(0xFF1A1A1A)),
                      children: [
                        const TextSpan(text: 'Hello Operator, '),
                        TextSpan(text: username, style: const TextStyle(color: kGreenDark,
                            fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (state is DashboardLoading)
                    _buildStatsShimmer()
                  else if (state is DashboardLoaded)
                    _buildStatsGrid(state)
                  else if (state is DashboardError)
                      _buildErrorBanner(context, state.message, token)
                    else
                      _buildStatsShimmer(),

                  const SizedBox(height: 32),

                  const Text('Recent Farmers', style: TextStyle(fontSize: 20, fontWeight:
                  FontWeight.w800, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 14),

                  if (state is DashboardLoading)
                    _buildFarmersShimmer()
                  else if (state is DashboardLoaded)
                    _buildRecentFarmers(state.recentFarmers)
                  else if (state is DashboardError)
                      const SizedBox.shrink()
                    else
                      _buildFarmersShimmer(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Stats Grid ────────────────────────────────────────────────
  Widget _buildStatsGrid(DashboardLoaded state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _StatCard(label: 'Farmers', value: state.totalFarmers.toString()),
        _StatCard(label: 'Transactions', value: _formatNumber(state.totalTransactions)),
        _StatCard(label: 'Active Credits', value: state.activeCredits.toString()),
        _StatCard(label: 'Reimbursements', value:
        '${state.reimbursedPercent.toStringAsFixed(0)}%'),
      ],
    );
  }

  // ── Recent Farmers ────────────────────────────────────────────
  Widget _buildRecentFarmers(List<Map<String, dynamic>> farmers) {
    if (farmers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: Text('No recent farmers', style: TextStyle(color: Colors.grey,
            fontSize: 16))),
      );
    }
    return Column(
      children: farmers.map((f) {
        final firstname = f['firstname'] as String? ?? '';
        final lastname = f['lastname'] as String? ?? '';
        final fullname = '$firstname $lastname'.trim();
        final initials = _initials(firstname, lastname);
        final identifier = f['identifier'] as String? ?? '';
        final totalDebt = f['total_debt'];
        final hasDebt = totalDebt != null && (totalDebt as num).toDouble() > 0;
        final badgeLabel = hasDebt ? 'In Debt' : 'Active';
        final badgeColor = hasDebt ? kAmber : kGreen;

        return _FarmerRow(initials: initials, name: fullname, code: identifier, badgeLabel:
        badgeLabel, badgeColor: badgeColor);
      }).toList(),
    );
  }

  // ── Shimmer / Loading ─────────────────────────────────────────
  Widget _buildStatsShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: List.generate(4, (_) => Container(
        decoration: BoxDecoration(color: kGreenDark.withOpacity(0.08), borderRadius:
        BorderRadius.circular(16)),
        child: const _ShimmerBox(),
      )),
    );
  }

  Widget _buildFarmersShimmer() {
    return Column(
      children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: kBg, shape:
            BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 140, color: kBg),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 90, color: kBg),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  // ── Error banner ──────────────────────────────────────────────
  Widget _buildErrorBanner(BuildContext context, String msg, String token) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius:
      BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 13))),
          TextButton(
            onPressed: () => context.read<DashboardBloc>().add(DashboardLoadRequested(token:
            token)),
            child: const Text('Retry', style: TextStyle(color: kGreenDark)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _initials(String firstname, String lastname) {
    final f = firstname.isNotEmpty ? firstname[0].toUpperCase() : '';
    final l = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    return '$f$l';
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Stat Card ───────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kGreenDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: kGreenDark.withOpacity(0.35), blurRadius: 10, offset: const
        Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color:
          Colors.white70, letterSpacing: 0.3)),
          Center(
            child: Text(value, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1)),
          ),
        ],
      ),
    );
  }
}

// ── Farmer Row ──────────────────────────────────────────────────
class _FarmerRow extends StatelessWidget {
  final String initials, name, code, badgeLabel;
  final Color badgeColor;

  const _FarmerRow({required this.initials, required this.name, required this.code, required
  this.badgeLabel, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: badgeColor.withOpacity(0.15),
                child: Text(initials, style: TextStyle(fontSize: 15, fontWeight:
                FontWeight.w700, color: badgeColor)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 3),
                    Text(code, style: const TextStyle(fontSize: 14, color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius:
                BorderRadius.circular(20)),
                child: Text(badgeLabel, style: TextStyle(fontSize: 13, fontWeight:
                FontWeight.w700, color: badgeColor)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEE8)),
      ],
    );
  }
}

// ── Shimmer Box ─────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds:
    1000))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(decoration: BoxDecoration(color: kGreenDark.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16))),
    );
  }
}

// ── Placeholder tabs ────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)));
  }
}