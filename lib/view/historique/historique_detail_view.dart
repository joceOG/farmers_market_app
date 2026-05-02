import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'historique_bloc.dart';

class HistoriqueDetailView extends StatelessWidget {
  final String token;
  const HistoriqueDetailView({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoriqueBloc, HistoriqueState>(
      listener: (context, state) {
        // Si on revient en arrière depuis le détail et que le state redevient
        // HistoriqueSuccess, on pop automatiquement
        if (state is HistoriqueSuccess) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: BlocBuilder<HistoriqueBloc, HistoriqueState>(
        builder: (context, state) {
          if (state is HistoriqueDetailLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
              ),
            );
          }

          if (state is HistoriqueDetailError) {
            return Scaffold(
              appBar: _appBar(context),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF666666))),
                  ],
                ),
              ),
            );
          }

          if (state is HistoriqueDetailSuccess) {
            return _DetailScaffold(tx: state.detail);
          }

          return const SizedBox();
        },
      ),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
    backgroundColor: const Color(0xFF1B4332),
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: const Text('Détail',
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18)),
    centerTitle: true,
  );
}

class _DetailScaffold extends StatelessWidget {
  final Transaction tx;
  const _DetailScaffold({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Détail de la vente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Contenu ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte client
                    _ClientCard(tx: tx),
                    const SizedBox(height: 16),

                    // Articles
                    _SectionCard(
                      title: 'Articles commandés',
                      icon: Icons.shopping_bag_outlined,
                      child: Column(
                        children: [
                          ...tx.items.map((a) => _ArticleLigne(article: a)),
                          const Divider(height: 20),
                          _TotalLigne(montant: tx.montant),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Infos paiement
                    _SectionCard(
                      title: 'Infos paiement',
                      icon: Icons.payments_outlined,
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Mode',
                            child: _ModeBadge(mode: tx.mode),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Opérateur',
                            child: Text(
                              tx.operatorUsername,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A)),
                            ),
                          ),
                          if (tx.isCredit) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Taux intérêt',
                              child: Text(
                                '${(tx.interestRate * 100).toStringAsFixed(0)} %',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFFE65100)),
                              ),
                            ),
                            if (tx.creditedAmount != null) ...[
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Montant crédité',
                                child: Text(
                                  '${_fmt(tx.creditedAmount!)} F',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFFE65100)),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      NumberFormat('#,###', 'fr_FR').format(v).replaceAll('\u00a0', ' ');
}

// ── Widgets locaux ────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final Transaction tx;
  const _ClientCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final dateStr =
    DateFormat("dd MMMM yyyy 'à' HH'h'mm", 'fr_FR').format(tx.date);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: tx.isCredit
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
            child: Text(
              tx.clientNom.isNotEmpty ? tx.clientNom[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tx.isCredit
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2D6A4F),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.clientNom,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(tx.code,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 13)),
                const SizedBox(height: 2),
                Text(dateStr,
                    style: const TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 11)),
              ],
            ),
          ),
          _ModeBadge(mode: tx.mode),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2D6A4F)),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ArticleLigne extends StatelessWidget {
  final ArticleCommande article;
  const _ArticleLigne({required this.article});

  @override
  Widget build(BuildContext context) {
    final prix = NumberFormat('#,###', 'fr_FR')
        .format(article.subtotal)
        .replaceAll('\u00a0', ' ');
    final pu = NumberFormat('#,###', 'fr_FR')
        .format(article.prixUnitaire)
        .replaceAll('\u00a0', ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.nom,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF333333))),
                Text('× ${article.quantite}  ·  $pu F / unité',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFAAAAAA))),
              ],
            ),
          ),
          Text('$prix F',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

class _TotalLigne extends StatelessWidget {
  final double montant;
  const _TotalLigne({required this.montant});

  @override
  Widget build(BuildContext context) {
    final s = NumberFormat('#,###', 'fr_FR')
        .format(montant)
        .replaceAll('\u00a0', ' ');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A1A1A))),
        Text('$s F',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D6A4F))),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
            const TextStyle(color: Color(0xFF888888), fontSize: 14)),
        child,
      ],
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isCredit = mode.toLowerCase() == 'credit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isCredit
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCredit ? 'Crédit' : 'Espèces',
        style: TextStyle(
          color: isCredit ? const Color(0xFFE65100) : const Color(0xFF2D6A4F),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}