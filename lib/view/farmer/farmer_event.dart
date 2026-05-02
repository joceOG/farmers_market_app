part of 'farmer_bloc.dart';

abstract class FarmerEvent {}

/// Chargement initial de la liste
class FarmerLoadRequested extends FarmerEvent {
  final String token;
  FarmerLoadRequested({required this.token});
}

/// Recherche par nom / ID / téléphone
class FarmerSearchChanged extends FarmerEvent {
  final String query;
  FarmerSearchChanged({required this.query});
}

/// Ajout d'un nouveau farmer
class FarmerCreateRequested extends FarmerEvent {
  final String token;
  final Map<String, dynamic> data;
  FarmerCreateRequested({required this.token, required this.data});
}