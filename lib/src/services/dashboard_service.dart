import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard.dart';
import 'api_config.dart';

class DashboardService {
  Future<Dashboard> buscar(int adminId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard')
        .replace(queryParameters: {'adminId': '$adminId'});
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return Dashboard.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 403) {
      throw Exception('Apenas administradores podem ver o painel');
    }
    throw Exception(
      'Não foi possível carregar o painel (${response.statusCode}).',
    );
  }
}
