import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'farmer_bloc.dart';
import 'farmer_detail_view.dart';

const Color kGreen = Color(0xFF2D6A4F);
const Color kGreenDark = Color(0xFF1B4332);
const Color kAmber = Color(0xFFC07C00);
const Color kBg = Color(0xFFF5F5F0);

// ── Entry point ─────────────────────────────────────────────────
class FarmersView extends StatelessWidget {
  final String token;
  const FarmersView({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FarmerBloc()..add(FarmerLoadRequested(token: token)),
      child: _FarmersView(token: token),
    );
  }
}

class _FarmersView extends StatefulWidget {
  final String token;
  const _FarmersView({required this.token});

  @override
  State<_FarmersView> createState() => _FarmersViewState();
}

class _FarmersViewState extends State<_FarmersView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddFarmerDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<FarmerBloc>(),
        child: _AddFarmerDialog(token: widget.token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmerBloc, FarmerState>(
      listener: (context, state) {
        if (state is FarmerCreateSuccess) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Farmer ajouté avec succès'),
              ]),
              backgroundColor: kGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        if (state is FarmerCreateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              color: kGreenDark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Text('Farmers',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openAddFarmerDialog(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDDDD5), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) => context.read<FarmerBloc>().add(FarmerSearchChanged(query: q)),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                  decoration: InputDecoration(
                    hintText: 'ID, nom ou téléphone...',
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded, color: kGreenDark, size: 22),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (_, val, __) => val.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<FarmerBloc>().add(FarmerSearchChanged(query: ''));
                        },
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ),

            // Liste
            Expanded(
              child: BlocBuilder<FarmerBloc, FarmerState>(
                builder: (context, state) {
                  if (state is FarmerLoading) return _buildShimmer();
                  if (state is FarmerError) return _buildError(context, state.message);

                  List<Map<String, dynamic>> farmers = [];
                  if (state is FarmerLoaded) farmers = state.filteredFarmers;
                  if (state is FarmerCreating) farmers = state.filteredFarmers;
                  if (state is FarmerCreateSuccess) farmers = state.filteredFarmers;
                  if (state is FarmerCreateError) farmers = state.filteredFarmers;

                  if (farmers.isEmpty) return _buildEmpty();

                  return RefreshIndicator(
                    color: kGreenDark,
                    onRefresh: () async {
                      context.read<FarmerBloc>().add(FarmerLoadRequested(token: widget.token));
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: farmers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEE8)),
                      // ✅ FIX : on passe le token pour naviguer vers la fiche
                      itemBuilder: (context, i) => _FarmerTile(
                        farmer: farmers[i],
                        token: widget.token,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEE8)),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: const BoxDecoration(color: kBg, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 14, width: 150, color: kBg),
                const SizedBox(height: 8),
                Container(height: 12, width: 100, color: kBg),
              ]),
            ),
            Container(height: 28, width: 60, decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.person_search_rounded, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('Aucun farmer trouvé', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<FarmerBloc>().add(FarmerLoadRequested(token: widget.token)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreenDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

// ── Farmer Tile ─────────────────────────────────────────────────
class _FarmerTile extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final String token;
  const _FarmerTile({required this.farmer, required this.token});

  @override
  Widget build(BuildContext context) {
    final firstname = farmer['firstname'] as String? ?? '';
    final lastname = farmer['lastname'] as String? ?? '';
    final fullname = '$firstname $lastname'.trim();
    final identifier = farmer['identifier'] as String? ?? '';
    final phone = farmer['phone'] as String? ?? '';
    final totalDebt = farmer['total_debt'];
    final hasDebt = totalDebt != null && (totalDebt as num).toDouble() > 0;

    final String badgeLabel = hasDebt ? 'Crédit' : 'Actif';
    final Color badgeColor = hasDebt ? kAmber : kGreen;
    final Color avatarColor = hasDebt ? kAmber : kGreen;

    final f = firstname.isNotEmpty ? firstname[0].toUpperCase() : '';
    final l = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    final initials = '$f$l';

    return InkWell(
      // ✅ FIX : navigation vers la fiche farmer au tap
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FarmerDetailView(
              farmer: farmer,
              token: token,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: avatarColor.withOpacity(0.14),
              child: Text(initials,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: avatarColor)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fullname,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text('$identifier · $phone',
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badgeLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Farmer Dialog ───────────────────────────────────────────
class _AddFarmerDialog extends StatefulWidget {
  final String token;
  const _AddFarmerDialog({required this.token});

  @override
  State<_AddFarmerDialog> createState() => _AddFarmerDialogState();
}

class _AddFarmerDialogState extends State<_AddFarmerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _creditLimitCtrl = TextEditingController();

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _regionCtrl.dispose();
    _creditLimitCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF555555), fontSize: 14, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
      filled: true,
      fillColor: kBg,
      prefixIcon: icon != null ? Icon(icon, color: kGreenDark, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDD5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDD5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreenDark, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'identifier': _identifierCtrl.text.trim(),
      'firstname': _firstnameCtrl.text.trim(),
      'lastname': _lastnameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      if (_villageCtrl.text.trim().isNotEmpty) 'village': _villageCtrl.text.trim(),
      if (_regionCtrl.text.trim().isNotEmpty) 'region': _regionCtrl.text.trim(),
      'credit_limit': double.tryParse(_creditLimitCtrl.text.trim().replaceAll(' ', '')) ?? 0.0,
    };
    context.read<FarmerBloc>().add(FarmerCreateRequested(token: widget.token, data: data));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FarmerBloc, FarmerState>(
      builder: (context, state) {
        final isLoading = state is FarmerCreating;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  color: kGreenDark,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Text('Nouvel agriculteur',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: isLoading ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        TextFormField(
                          controller: _identifierCtrl,
                          decoration: _fieldDeco('Identifiant (carte)', hint: 'Ex: F005', icon: Icons.badge_outlined),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _firstnameCtrl,
                          decoration: _fieldDeco('Prénom', hint: 'Ex: Yves', icon: Icons.person_outline),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _lastnameCtrl,
                          decoration: _fieldDeco('Nom', hint: 'Ex: Kouadio', icon: Icons.person_outline),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: _fieldDeco('Téléphone', hint: 'Ex: 07 12 34 56', icon: Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _villageCtrl,
                          decoration: _fieldDeco('Village (optionnel)', hint: 'Ex: Divo', icon: Icons.location_city_outlined),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _regionCtrl,
                          decoration: _fieldDeco('Région (optionnel)', hint: 'Ex: Lôh-Djiboua', icon: Icons.map_outlined),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _creditLimitCtrl,
                          decoration: _fieldDeco('Limite de crédit (FCFA)', hint: 'Ex: 75000', icon: Icons.account_balance_wallet_outlined),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Champ requis';
                            if (double.tryParse(v.trim()) == null) return 'Montant invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreenDark,
                        disabledBackgroundColor: kGreenDark.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Enregistrer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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
}