import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emprestimo.dart';
import 'api_config.dart';

class EmprestimoService {
  Future<List<Emprestimo>> buscarTodos(int adminId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/emprestimos')
        .replace(queryParameters: {'adminId': '$adminId'});
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(utf8.decode(response.bodyBytes));
    }
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List)
        .map((item) => Emprestimo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> movimentar(int id, int adminId, {required bool devolver}) async {
    final acao = devolver ? 'devolver' : 'aprovar';
    final uri = Uri.parse('${ApiConfig.baseUrl}/emprestimos/$id/$acao')
        .replace(queryParameters: {'adminId': '$adminId'});
    final response = await http.put(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  Future<List<Emprestimo>> buscarPorFuncionario(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/emprestimos/funcionario/$id'),
    );

    if (response.statusCode == 200) {
      final lista =
          jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return lista
          .map((item) => Emprestimo.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Erro ao carregar seus empréstimos');
  }

  // Envia a solicitação de empréstimo para a API
  Future<void> solicitar({
    required int funcionarioId,
    required int epiId,
    required String observacao,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/emprestimos'),
      headers: {'Content-Type': 'application/json'},
      // Mesmo formato da entidade Emprestimo do Java:
      // funcionário e EPI vão "dentro" do pedido, só com o id
      body: jsonEncode({
        'funcionario': {'id': funcionarioId},
        'epi': {'id': epiId},
        'observacao': observacao,
      }),
    );

    // 201 = Created: o empréstimo foi gravado
    if (response.statusCode == 201) {
      return;
    }
    // 400: a API explica o motivo (CA vencido, sem estoque ... )
    throw Exception(utf8.decode(response.bodyBytes));
  }
}
