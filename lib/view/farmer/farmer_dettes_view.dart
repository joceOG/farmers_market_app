import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'debt_bloc.dart';
import 'farmer_remboursement_view.dart';

const Color kGreen = Color(0xFF2D6A4F);
const Color kGreenDark = Color(0xFF1B4332);
const Color kAmber = Color(0xFFC07C00);
const Color kBg = Color(0xFFF5F5F0);
const Color kRed = Color(0xFFD32F2F);

// ── Helper parsing robuste (Laravel renvoie parfois des String) ──
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class FarmerDettesView extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final String token;
  final int farmerId;

  const FarmerDettesView({
    super.key,
    required this.farmer,
    required this.token,
    required this.farmerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtBloc()..add(DebtLoadRequested(token: token, farmerId: farmerId)),
      child: _FarmerDettesView(farmer: farmer, token: token, farmerId: farmerId),
    );
  }
}

class _FarmerDettesView extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final String token;
  final int farmerId;

  const _FarmerDettesView({
    required this.farmer,
    required this.token,
    required this.farmerId,
  });

  @override
  Widget build(BuildContext context) {
    final firstname = farmer['firstname'] as String? ?? '';
    final lastname = farmer['lastname'] as String? ?? '';
    final identifier = farmer['identifier'] as String? ?? '';
    final fullname = '$firstname $lastname'.trim();

    return BlocListener<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is RepaymentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Remboursement enregistré'),
              ]),
              backgroundColor: kGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        if (state is RepaymentError) {
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
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: kGreenDark,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Row(children: [
                        Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                        Text('Retour', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    const Spacer(),
                    const Text('Dettes', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    const SizedBox(width: 60),
                  ],
                ),
              ),

              // Contenu
              Expanded(
                child: BlocBuilder<DebtBloc, DebtState>(
                  builder: (context, state) {
                    if (state is DebtLoading) {
                      return const Center(child: CircularProgressIndicator(color: kGreenDark));
                    }

                    if (state is DebtError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(state.message, textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red, fontSize: 14)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.read<DebtBloc>()
                                  .add(DebtLoadRequested(token: token, farmerId: farmerId)),
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

                    List<Map<String, dynamic>> debts = [];
                    if (state is DebtLoaded) debts = state.debts;
                    if (state is RepaymentLoading) debts = state.debts;
                    if (state is RepaymentSuccess) debts = state.debts;
                    if (state is RepaymentError) debts = state.debts;

                    final totalDu = debts.fold<double>(
                        0, (sum, d) => sum + _toDouble(d['remaining_amount']));

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre farmer
                                Text('$fullname — $identifier',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A))),
                                const SizedBox(height: 12),

                                // Total dû
                                if (debts.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0F0),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: kRed.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      'Total dû : ${_fmt(totalDu)} FCFA sur ${debts.length} crédit${debts.length > 1 ? 's' : ''}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kRed),
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                if (debts.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Text('Aucune dette en cours 🎉',
                                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                                    ),
                                  ),

                                // Liste dettes (FIFO : la première = la plus ancienne)
                                ...debts.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final debt = entry.value;
                                  final isFifo = i == 0;
                                  return _DebtCard(debt: debt, isFifo: isFifo);
                                }),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),

                        // Bouton remboursement
                        if (debts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: state is RepaymentLoading
                                    ? null
                                    : () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<DebtBloc>(),
                                      child: FarmerRemboursementView(
                                        farmer: farmer,
                                        token: token,
                                        farmerId: farmerId,
                                        debts: debts,
                                      ),
                                    ),
                                  ));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kGreenDark,
                                  disabledBackgroundColor: kGreenDark.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: state is RepaymentLoading
                                    ? const SizedBox(height: 22, width: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Enregistrer un remboursement',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ),
                        const Text('Dettes en cours', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Carte dette individuelle ─────────────────────────────────────
class _DebtCard extends StatelessWidget {
  final Map<String, dynamic> debt;
  final bool isFifo;

  const _DebtCard({required this.debt, required this.isFifo});

  @override
  Widget build(BuildContext context) {
    final createdAt = debt['created_at'] as String? ?? '';
    final date = _formatDate(createdAt);
    // interest_rate est dans debt.transaction
    final transaction = debt['transaction'] as Map<String, dynamic>? ?? {};
    final rate = _toDouble(transaction['interest_rate']) * 100; // 0.3000 → 30%
    final remaining = _toDouble(debt['remaining_amount']);
    final original = _toDouble(debt['original_amount']); // champ correct
    final paid = original - remaining;
    final progress = original > 0 ? (paid / original).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isFifo ? Border.all(color: const Color(0xFFFFCDD2), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Crédit du $date',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text('Taux ${rate.toStringAsFixed(0)}%${isFifo ? '' : ''}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (isFifo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('FIFO\nprioritaire',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFC07C00))),
                  ),
                const SizedBox(height: 4),
                Text('${_fmt(remaining)} F',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kRed)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          // Barre de progression remboursement
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEEEE8),
              valueColor: const AlwaysStoppedAnimation<Color>(kRed),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            paid > 0 ? '${_fmt(paid)} F remboursé sur ${_fmt(original)} F' : 'Non remboursé',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}