part of 'historique_bloc.dart';

// ── Modèles ───────────────────────────────────────────────────────────────────

class Transaction extends Equatable {
  final String id;
  final String code;
  final String clientNom;
  final int nbArticles;
  final double montant;
  final String mode;           // 'cash' | 'credit'
  final DateTime date;
  final String operatorUsername;
  final double interestRate;
  final double? creditedAmount;
  final List<ArticleCommande> items;

  const Transaction({
    required this.id,
    required this.code,
    required this.clientNom,
    required this.nbArticles,
    required this.montant,
    required this.mode,
    required this.date,
    required this.operatorUsername,
    required this.interestRate,
    this.creditedAmount,
    required this.items,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final farmer   = json['farmer']   as Map<String, dynamic>? ?? {};
    final operator = json['operator'] as Map<String, dynamic>? ?? {};
    final rawItems = json['items']    as List? ?? [];

    final articles = rawItems
        .map((i) => ArticleCommande.fromJson(i as Map<String, dynamic>))
        .toList();

    return Transaction(
      id:               json['id'].toString(),
      code:             farmer['identifier'] ?? '',
      clientNom:        '${farmer['firstname'] ?? ''} ${farmer['lastname'] ?? ''}'.trim(),
      nbArticles:       articles.length,
      montant:          double.tryParse(json['total_fcfa'].toString()) ?? 0,
      mode:             json['payment_method'] ?? 'cash',   // 'cash' | 'credit'
      date:             DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      operatorUsername: operator['username'] ?? '',
      interestRate:     double.tryParse(json['interest_rate'].toString()) ?? 0,
      creditedAmount:   json['credited_amount'] != null
          ? double.tryParse(json['credited_amount'].toString())
          : null,
      items: articles,
    );
  }

  // Helpers affichage
  bool get isCredit => mode.toLowerCase() == 'credit';
  String get modeLabel => isCredit ? 'Crédit' : 'Espèces';

  @override
  List<Object?> get props => [id];
}

class ArticleCommande extends Equatable {
  final String nom;
  final int quantite;
  final double prixUnitaire;
  final double subtotal;

  const ArticleCommande({
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    required this.subtotal,
  });

  factory ArticleCommande.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    return ArticleCommande(
      nom:          product['name'] ?? json['nom'] ?? '',
      quantite:     json['quantity'] ?? 1,
      prixUnitaire: double.tryParse(json['unit_price'].toString()) ?? 0,
      subtotal:     double.tryParse(json['subtotal'].toString()) ?? 0,
    );
  }

  double get total => subtotal;

  @override
  List<Object?> get props => [nom, quantite, prixUnitaire];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class HistoriqueState extends Equatable {
  const HistoriqueState();
  @override
  List<Object?> get props => [];
}

class HistoriqueInitial   extends HistoriqueState {}
class HistoriqueLoading   extends HistoriqueState {}

class HistoriqueSuccess extends HistoriqueState {
  final List<Transaction> transactions;
  final List<Transaction> transactionsFiltrees;
  final String filtreActif;
  final String periodeActive;
  final double totalMontant;

  const HistoriqueSuccess({
    required this.transactions,
    required this.transactionsFiltrees,
    required this.filtreActif,
    required this.periodeActive,
    required this.totalMontant,
  });

  @override
  List<Object?> get props => [transactionsFiltrees, filtreActif, periodeActive];
}

class HistoriqueError extends HistoriqueState {
  final String message;
  const HistoriqueError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Detail States ─────────────────────────────────────────────────────────────

class HistoriqueDetailLoading extends HistoriqueState {}

class HistoriqueDetailSuccess extends HistoriqueState {
  final Transaction detail;           // la transaction complète avec items
  final HistoriqueSuccess listeState;

  const HistoriqueDetailSuccess({
    required this.detail,
    required this.listeState,
  });

  @override
  List<Object?> get props => [detail];
}

class HistoriqueDetailError extends HistoriqueState {
  final String message;
  final HistoriqueSuccess listeState;

  const HistoriqueDetailError({required this.message, required this.listeState});
  @override
  List<Object?> get props => [message];
}