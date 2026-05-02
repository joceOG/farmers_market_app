import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  // ── Headers de base (sans auth) ───────────────────────────────
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Headers avec token Sanctum ────────────────────────────────
  Map<String, String> _authHeaders(String token) => {
    ..._baseHeaders,
    'Authorization': 'Bearer $token',
  };

  // ── Auth : Login ──────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: _baseHeaders,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erreur de connexion');
    }
  }

  // ── GET brut — retourne le JSON complet sans normalisation ───
  Future<dynamic> getRaw(String endpoint, {required String token}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _authHeaders(token),
    );

    print('=== RAW RESPONSE ($endpoint) ===');
    print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Erreur serveur ($endpoint)');
    }
  }

  // ── GET générique authentifié ─────────────────────────────────
  Future<dynamic> get(String endpoint, {required String token}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _authHeaders(token),
    );

    // ✅ Ajoute ces 2 lignes
    print('=== RAW RESPONSE ($endpoint) ===');
    print(response.body);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Réponse paginée Laravel : { data: { data: [...] } }
      if (decoded is Map && decoded['data'] is Map && decoded['data']['data'] is List) {
        return decoded['data']['data'];
      }

      // Réponse simple : { data: [...] }
      if (decoded is Map && decoded['data'] is List) {
        return decoded['data'];
      }

      // Tableau direct : [...]
      return decoded;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Erreur serveur ($endpoint)');
    }
  }

  // ── POST générique authentifié ────────────────────────────────
  Future<Map<String, dynamic>> post(
      String endpoint, {
        required String token,
        required Map<String, dynamic> body,
      }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded;
    } else {
      throw Exception(decoded['message'] ?? 'Erreur serveur ($endpoint)');
    }
  }

  // ── PUT générique authentifié ─────────────────────────────────
  Future<Map<String, dynamic>> put(
      String endpoint, {
        required String token,
        required Map<String, dynamic> body,
      }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return decoded;
    } else {
      throw Exception(decoded['message'] ?? 'Erreur serveur ($endpoint)');
    }
  }

  // ── DELETE générique authentifié ──────────────────────────────
  Future<void> delete(String endpoint, {required String token}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Erreur serveur ($endpoint)');
    }
  }
}