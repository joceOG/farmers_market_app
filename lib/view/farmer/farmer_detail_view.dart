import 'package:flutter/material.dart';
import 'farmer_dettes_view.dart';

const Color kGreen = Color(0xFF2D6A4F);
const Color kGreenDark = Color(0xFF1B4332);
const Color kAmber = Color(0xFFC07C00);
const Color kBg = Color(0xFFF5F5F0);
const Color kRed = Color(0xFFD32F2F);

class FarmerDetailView extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final String token;

  const FarmerDetailView({
    super.key,
    required this.farmer,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final firstname = farmer['firstname'] as String? ?? '';
    final lastname = farmer['lastname'] as String? ?? '';
    final fullname = '$firstname $lastname'.trim();
    final identifier = farmer['identifier'] as String? ?? '';
    final phone = farmer['phone'] as String? ?? '';
    final village = farmer['village'] as String? ?? '—';
    final region = farmer['region'] as String? ?? '—';
    final creditLimit = _toDouble(farmer['credit_limit']);
    final totalDebt = _toDouble(farmer['total_debt']);
    final debtCount = _toInt(farmer['debt_count']);

    final hasDebt = totalDebt > 0;
    final usedPercent = creditLimit > 0 ? (totalDebt / creditLimit).clamp(0.0, 1.0) : 0.0;
    final remainingCredit = creditLimit - totalDebt;

    final f = firstname.isNotEmpty ? firstname[0].toUpperCase() : '';
    final l = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    final initials = '$f$l';

    final farmerId = _toInt(farmer['id']); // robuste String/int/double

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header vert avec avatar ─────────────────────────
            Container(
              color: kGreenDark,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                children: [
                  // Barre retour
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                            Text('Retour', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text('Fiche', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const SizedBox(width: 60), // équilibrage
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(initials,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Text(fullname,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  // Identifier + statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(identifier,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasDebt ? kAmber.withOpacity(0.25) : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: hasDebt ? kAmber : Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          hasDebt ? 'Crédit' : 'Actif',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: hasDebt ? kAmber : Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Corps ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Infos contact
                    _Card(
                      child: Column(
                        children: [
                          _InfoRow(label: 'Téléphone', value: phone),
                          const Divider(height: 20, color: Color(0xFFEEEEE8)),
                          _InfoRow(label: 'Village', value: village, bold: true),
                          const Divider(height: 20, color: Color(0xFFEEEEE8)),
                          _InfoRow(label: 'Région', value: region, bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Crédit
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Limite crédit',
                            value: '${_fmt(creditLimit)} F',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Utilisé',
                            value: '${_fmt(totalDebt)} F',
                          ),
                          const SizedBox(height: 10),
                          // Barre de progression
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: usedPercent,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFDDDDD5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  usedPercent > 0.8 ? kRed : kGreen),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              Text('${(usedPercent * 100).toStringAsFixed(0)}% utilisé',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              Text(_fmt(creditLimit),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dettes en cours
                    _Card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dettes en cours',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                          Text(
                            debtCount > 0 ? '$debtCount impayée${debtCount > 1 ? 's' : ''}' : 'Aucune',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: debtCount > 0 ? kRed : kGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton Nouvelle transaction
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: naviguer vers transaction
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nouvelle transaction — à connecter')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreenDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Nouvelle transaction',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bouton Voir les dettes
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FarmerDettesView(
                              farmer: farmer,
                              token: token,
                              farmerId: farmerId,
                            ),
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kGreenDark,
                          side: const BorderSide(color: kGreenDark, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Voir les dettes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Fiche agriculteur',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de parsing robuste (Laravel renvoie parfois des String) ──
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _fmt(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return v.toStringAsFixed(0);
  }
}

// ── Widgets réutilisables ────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF1A1A1A))),
      ],
    );
  }
}