import 'dart:convert';

import 'package:app_epi/src/models/treinamento.dart';
import 'package:http/http.dart' as http;

import '../models/treinamento_realizado.dart';
import 'api_config.dart';

class TreinamentoService {
  Future<void> cadastrar({
    required int adminId,
    required String titulo,
    String? descricao,
    String? arquivoUrl,
    int? validadeMeses,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/treinamentos')
        .replace(queryParameters: {'adminId': adminId.toString()});
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'arquivoUrl': arquivoUrl,
        'validadeMeses': validadeMeses,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    final mensagem = utf8.decode(response.bodyBytes);
    throw Exception(
      mensagem.isEmpty
          ? 'Erro ao cadastrar treinamento (${response.statusCode})'
          : mensagem,
    );
  }

  // GET /treinamentos
  Future<List<Treinamento>> buscarTreinamentos() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/treinamentos'),
    );

    if (response.statusCode == 200) {
      final lista = json.decode(utf8.decode(response.bodyBytes)) as List;
      return lista
          .map((item) => Treinamento.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao carregar treinamentos');
  }

  // GET /treinamentos/realizados/funcionario/3
  Future<List<TreinamentoRealizado>> buscarRealizados(int funcionarioId) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/treinamentos/realizados/funcionario/$funcionarioId',
      ),
    );

    if (response.statusCode == 200) {
      final lista = json.decode(utf8.decode(response.bodyBytes)) as List;
      return lista
          .map(
            (item) =>
                TreinamentoRealizado.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    throw Exception('Erro ao carregar treinamentos concluídos');
  }

  // POST /treinamentos/2/concluir?funcionarioId=3
  Future<void> concluir(int treinamentoId, int funcionarioId) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/treinamentos/$treinamentoId/concluir'
        '?funcionarioId=$funcionarioId',
      ),
    );

    // 201 = registro de conclusão criado
    if (response.statusCode == 201) {
      return;
    }
    throw Exception(utf8.decode(response.bodyBytes));
  }
}
