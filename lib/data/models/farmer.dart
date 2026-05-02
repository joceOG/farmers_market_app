class Farmer {
  final int id;
  final String identifier;
  final String firstName;
  final String lastName;
  final String phone;         // ✅ "phone" pas "phone_number"
  final double creditLimit;
  final int createdBy;        // ✅ FK → user.id
  final DateTime createdAt;

  // ✅ total_debt n'existe pas en BD
  // → à calculer depuis les debts ou retourné par Laravel en computed field
  final double? totalDebt;

  Farmer({
    required this.id,
    required this.identifier,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.creditLimit,
    required this.createdBy,
    required this.createdAt,
    this.totalDebt,
  });

  String get fullname => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  // Badge dashboard : dette active si totalDebt > 0
  bool get hasActiveDebt => (totalDebt ?? 0) > 0;

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'] as int,
      identifier: json['identifier'] as String,
      firstName: json['firstname'] as String,    // ✅ schéma : firstname
      lastName: json['lastname'] as String,       // ✅ schéma : lastname
      phone: json['phone'] as String? ?? '',      // ✅ schéma : phone
      creditLimit: (json['credit_limit'] as num).toDouble(),
      createdBy: json['created_by'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalDebt: json['total_debt'] != null      // champ computed optionnel
          ? (json['total_debt'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'identifier': identifier,
    'firstname': firstName,
    'lastname': lastName,
    'phone': phone,
    'credit_limit': creditLimit,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
  };
}