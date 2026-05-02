import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'debt_bloc.dart';

const Color kGreen = Color(0xFF2D6A4F);
const Color kGreenDark = Color(0xFF1B4332);
const Color kAmber = Color(0xFFC07C00);
const Color kBg = Color(0xFFF5F5F0);
const Color kRed = Color(0xFFD32F2F);

/// Taux de conversion 1 kg cacao → FCFA (configurable)
const double kKgToFcfa = 1000.0;

// ── Helper parsing robuste (Laravel renvoie parfois des String) ──
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class FarmerRemboursementView extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final String token;
  final int farmerId;
  final List<Map<String, dynamic>> debts;

  const FarmerRemboursementView({
    super.key,
    required this.farmer,
    required this.token,
    required this.farmerId,
    required this.debts,
  });

  @override
  Widget build(BuildContext context) {
    return _FarmerRemboursementView(
      farmer: farmer,
      token: token,
      farmerId: farmerId,
      debts: debts,
    );
  }
}

class _FarmerRemboursementView extends StatefulWidget {
  final Map<String, dynamic> farmer;
  final String token;
  final int farmerId;
  final List<Map<String, dynamic>> debts;

  const _FarmerRemboursementView({
    required this.farmer,
    required this.token,
    required this.farmerId,
    required this.debts,
  });

  @override
  State<_FarmerRemboursementView> createState() => _FarmerRemboursementViewState();
}

class _FarmerRemboursementViewState extends State<_FarmerRemboursementView> {
  final _kgController = TextEditingController();
  double _kg = 0;
  double _fcfa = 0;

  @override
  void initState() {
    super.initState();
    _kgController.addListener(_onKgChanged);
  }

  void _onKgChanged() {
    final val = double.tryParse(_kgController.text.trim().replaceAll(',', '.')) ?? 0;
    setState(() {
      _kg = val;
      _fcfa = val * kKgToFcfa;
    });
  }

  @override
  void dispose() {
    _kgController.dispose();
    super.dispose();
  }

  /// Calcul FIFO : applique le paiement sur les dettes dans l'ordre
  _FifoResult _computeFifo(double fcfa) {
    double remaining = fcfa;
    final debts = widget.debts;
    if (debts.isEmpty) return _FifoResult(firstDebt: 0, soldeRestant: 0, nextDebt: 0, nextLabel: '');

    // remaining_amount est le bon champ (original_amount - remboursé)
    final first = _toDouble(debts[0]['remaining_amount']);
    double soldeRestant = first - remaining;
    double nextDebt = 0;
    String nextLabel = '';

    if (soldeRestant < 0 && debts.length > 1) {
      nextDebt = _toDouble(debts[1]['remaining_amount']);
      final nextDate = _formatDate(debts[1]['created_at'] as String? ?? '');
      nextLabel = '${_fmt(nextDebt)} F (partiel)';
      nextLabel = 'Prochain crédit ${_fmt(nextDebt)} F (partiel) · $nextDate';
    }

    return _FifoResult(
      firstDebt: first,
      soldeRestant: soldeRestant < 0 ? 0 : soldeRestant,
      nextDebt: nextDebt,
      nextLabel: nextLabel,
    );
  }

  void _submit(BuildContext context) {
    if (_kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un montant en kg'), backgroundColor: Colors.orange),
      );
      return;
    }

    final firstDebtId = widget.debts.isNotEmpty ? widget.debts[0]['id'] : null;

    context.read<DebtBloc>().add(RepaymentSubmitted(
      token: widget.token,
      farmerId: widget.farmerId,
      data: {
        'farmer_id': widget.farmerId,
        'amount_kg': _kg,
        'amount_fcfa': _fcfa,
        'kg_rate': kKgToFcfa,
        if (firstDebtId != null) 'debt_id': firstDebtId,
      },
    ));

    // Retour vers la vue dettes après soumission
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final firstname = widget.farmer['firstname'] as String? ?? '';
    final lastname = widget.farmer['lastname'] as String? ?? '';
    final identifier = widget.farmer['identifier'] as String? ?? '';
    final fullname = '$firstname $lastname'.trim();

    final fifo = _computeFifo(_fcfa);
    final firstDebtDate = widget.debts.isNotEmpty
        ? _formatDate(widget.debts[0]['created_at'] as String? ?? '')
        : '';

    return BlocListener<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is RepaymentSuccess) {
          Navigator.of(context).pop();
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
                    const Text('Remboursement',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    const SizedBox(width: 60),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom farmer
                      Text('$fullname — $identifier',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),

                      // Saisie kg
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Saisie en kg (cacao)',
                                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _kgController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Color(0xFFDDDDD5)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Color(0xFFDDDDD5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: kGreenDark, width: 1.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                hintText: '0',
                                hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 28),
                                suffixText: 'kg',
                                suffixStyle: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Taux actuel',
                                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                                Text('1 kg = ${_fmt(kKgToFcfa)} FCFA',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Conversion & FIFO
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kGreen.withOpacity(0.3)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Conversion',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGreen)),
                            const SizedBox(height: 12),
                            _ConvRow(label: 'Kg reçus', value: '${_kg > 0 ? _kg.toStringAsFixed(_kg % 1 == 0 ? 0 : 1) : '0'} kg'),
                            const SizedBox(height: 6),
                            _ConvRow(label: 'Valeur FCFA', value: '${_fmt(_fcfa)} F', bold: true),

                            if (_fcfa > 0 && widget.debts.isNotEmpty) ...[
                              const Divider(height: 20, color: Color(0xFFEEEEE8)),
                              _ConvRow(
                                label: 'Crédit le plus ancien',
                                value: _fmt(fifo.firstDebt),
                                valueColor: kRed,
                              ),
                              const SizedBox(height: 6),
                              _ConvRow(
                                label: 'Solde restant',
                                value: '${_fmt(fifo.soldeRestant)} F',
                                valueColor: kRed,
                              ),
                              if (fifo.nextLabel.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Prochain crédit : ${_fmt(fifo.nextDebt)} F (partiel)',
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Alerte FIFO
                      if (_fcfa > 0 && widget.debts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kAmber.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: kAmber, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Logique FIFO : le crédit du $firstDebtDate\nsera soldé en premier',
                                  style: const TextStyle(fontSize: 13, color: kAmber, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bouton confirmer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: BlocBuilder<DebtBloc, DebtState>(
                  builder: (context, state) {
                    final isLoading = state is RepaymentLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 54,
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
                            : const Text('Confirmer le remboursement',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
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

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _fmt(double v) {
    if (v <= 0) return '0';
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ConvRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _ConvRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A1A),
            )),
      ],
    );
  }
}

class _FifoResult {
  final double firstDebt;
  final double soldeRestant;
  final double nextDebt;
  final String nextLabel;

  _FifoResult({
    required this.firstDebt,
    required this.soldeRestant,
    required this.nextDebt,
    required this.nextLabel,
  });
}