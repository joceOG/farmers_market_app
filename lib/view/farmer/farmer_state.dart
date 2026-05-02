part of 'farmer_bloc.dart';

abstract class FarmerState {}

class FarmerInitial extends FarmerState {}

class FarmerLoading extends FarmerState {}

class FarmerLoaded extends FarmerState {
  final List<Map<String, dynamic>> allFarmers;
  final List<Map<String, dynamic>> filteredFarmers;
  final String query;

  FarmerLoaded({
    required this.allFarmers,
    required this.filteredFarmers,
    this.query = '',
  });

  FarmerLoaded copyWith({
    List<Map<String, dynamic>>? allFarmers,
    List<Map<String, dynamic>>? filteredFarmers,
    String? query,
  }) {
    return FarmerLoaded(
      allFarmers: allFarmers ?? this.allFarmers,
      filteredFarmers: filteredFarmers ?? this.filteredFarmers,
      query: query ?? this.query,
    );
  }
}

class FarmerCreating extends FarmerState {
  final List<Map<String, dynamic>> allFarmers;
  final List<Map<String, dynamic>> filteredFarmers;
  FarmerCreating({required this.allFarmers, required this.filteredFarmers});
}

class FarmerCreateSuccess extends FarmerState {
  final List<Map<String, dynamic>> allFarmers;
  final List<Map<String, dynamic>> filteredFarmers;
  FarmerCreateSuccess({required this.allFarmers, required this.filteredFarmers});
}

class FarmerError extends FarmerState {
  final String message;
  FarmerError({required this.message});
}

class FarmerCreateError extends FarmerState {
  final String message;
  final List<Map<String, dynamic>> allFarmers;
  final List<Map<String, dynamic>> filteredFarmers;
  FarmerCreateError({
    required this.message,
    required this.allFarmers,
    required this.filteredFarmers,
  });
}