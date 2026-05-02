import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ Ajouter cet import
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null); // ✅ Initialiser la locale fr_FR
  runApp(const MyApp());
}