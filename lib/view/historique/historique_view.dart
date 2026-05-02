import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'historique_bloc.dart';
import 'historique_detail_view.dart';
import '../../data/services/api_client.dart';

class HistoriqueView extends StatelessWidget {
  final String token;
  final ApiClient apiClient;

  const HistoriqueView({
    super.key,
    required this.token,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoriqueBloc(apiClient: apiClient)
        ..add(HistoriqueLoaded(token: token)),
      child: _HistoriqueView(token: token),
    );
  }
}

class _HistoriqueView extends StatelessWidget {
  final String token;
  const _HistoriqueView({required this.token});

  // clés alignées sur payment_method de l'API
  static const _filtres = <Map<String, String>>[
    {'label': 'Tout',    'key': 'Tout'},
    {'label': 'Espèces', 'key': 'cash'},
    {'label': 'Crédit',  'key': 'credit'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: BlocConsumer<HistoriqueBloc, HistoriqueState>(
        listener: (context, state) {
          if (state is HistoriqueDetailSuccess) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<HistoriqueBloc>(),
                  child: HistoriqueDetailView(token: token),
                ),
              ),
            );
          }
          if (state is HistoriqueDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HistoriqueLoading || state is HistoriqueInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            );
          }

          if (state is HistoriqueError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<HistoriqueBloc>()
                  .add(HistoriqueLoaded(token: token)),
            );
          }

          if (state is HistoriqueDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            );
          }

          final listeState = state is HistoriqueSuccess
              ? state
              : state is HistoriqueDetailSuccess
              ? state.listeState
              : null;

          if (listeState != null) {
            return _buildListe(context, listeState);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildListe(BuildContext context, HistoriqueSuccess state) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Historique',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    _PeriodeSelector(periodeActive: state.periodeActive),
                  ],
                ),
                const SizedBox(height: 14),
                // Résumé rapide dans le header
                Row(
                  children: [
                    _StatBadge(
                      icon: Icons.receipt_long_rounded,
                      label: '${state.transactionsFiltrees.length} ventes',
                    ),
                    const SizedBox(width: 10),
                    _StatBadge(
                      icon: Icons.payments_outlined,
                      label: '${_fmt(state.totalMontant)} F',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Filtres ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _filtres.map((f) {
                final isActive = state.filtreActif == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FiltreChip(
                    label: f['label']!,
                    isActive: isActive,
                    onTap: () => context
                        .read<HistoriqueBloc>()
                        .add(HistoriqueFiltreChanged(f['key']!)),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Liste ────────────────────────────────────────────
          Expanded(
            child: state.transactionsFiltrees.isEmpty
                ? const _EmptyView()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: state.transactionsFiltrees.length,
              itemBuilder: (context, index) {
                final tx = state.transactionsFiltrees[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionCard(
                    transaction: tx,
                    onTap: () => context.read<HistoriqueBloc>().add(
                      HistoriqueDetailRequested(
                        transactionId: tx.id,
                        token: token,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double montant) =>
      NumberFormat('#,###', 'fr_FR').format(montant).replaceAll('\u00a0', ' ');
}

// ── Widgets locaux ────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PeriodeSelector extends StatelessWidget {
  final String periodeActive;
  const _PeriodeSelector({required this.periodeActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPeriodeSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Text(periodeActive,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPeriodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["Ce mois", "Semaine", "Aujourd'hui"].map((p) {
            return ListTile(
              leading: const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF2D6A4F), size: 20),
              title: Text(p),
              onTap: () {
                context
                    .read<HistoriqueBloc>()
                    .add(HistoriquePeriodeChanged(p));
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FiltreChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2D6A4F) : Colors.white,
          border: Border.all(
            color:
            isActive ? const Color(0xFF2D6A4F) : const Color(0xFFDDDDDD),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF666666),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionCard({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final dateStr = DateFormat('dd MMM', 'fr_FR').format(transaction.date);
    final heureStr = DateFormat('HH:mm').format(transaction.date);
    final montantStr = NumberFormat('#,###', 'fr_FR')
        .format(transaction.montant)
        .replaceAll('\u00a0', ' ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isCredit
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCredit
                      ? Icons.credit_score_rounded
                      : Icons.payments_rounded,
                  color: isCredit
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2D6A4F),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.clientNom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.code} · '
                          '${transaction.nbArticles} art. · '
                          '$dateStr $heureStr',
                      style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Montant + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$montantStr F',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      transaction.modeLabel,
                      style: TextStyle(
                        color: isCredit
                            ? const Color(0xFFE65100)
                            : const Color(0xFF2D6A4F),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFCCCCCC), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Aucune transaction',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}