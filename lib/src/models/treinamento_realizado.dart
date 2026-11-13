import 'package:app_epi/src/models/treinamento.dart';

class TreinamentoRealizado {
  final int id;
  final Treinamento treinamento;
  final DateTime dataConclusao;

  TreinamentoRealizado({
    required this.id,
    required this.treinamento,
    required this.dataConclusao,
  });

  factory TreinamentoRealizado.fromJson(Map<String, dynamic> json) {
    return TreinamentoRealizado(
      id: json['id'] as int,
      treinamento: Treinamento.fromJson(
        json['treinamento'] as Map<String, dynamic>,
      ),
      dataConclusao: DateTime.parse(json['dataConclusao'] as String),
    );
  }

  DateTime? get dataVencimento {
    final validadeMeses = treinamento.validadeMeses;
    if (validadeMeses == null) return null;

    final mesFinal = dataConclusao.month + validadeMeses;
    final anoFinal = dataConclusao.year + (mesFinal - 1) ~/ 12;
    final mesNormalizado = (mesFinal - 1) % 12 + 1;
    final ultimoDiaDoMes = DateTime(anoFinal, mesNormalizado + 1, 0).day;
    final diaFinal = dataConclusao.day > ultimoDiaDoMes
        ? ultimoDiaDoMes
        : dataConclusao.day;

    return DateTime(
      anoFinal,
      mesNormalizado,
      diaFinal,
      dataConclusao.hour,
      dataConclusao.minute,
      dataConclusao.second,
      dataConclusao.millisecond,
      dataConclusao.microsecond,
    );
  }

  bool get estaVencido {
    final vencimento = dataVencimento;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return vencimento != null && vencimento.isBefore(hoje);
  }

  String get dataFormatada {
    final dia = dataConclusao.day.toString().padLeft(2, '0');
    final mes = dataConclusao.month.toString().padLeft(2, '0');
    return '$dia/$mes/${dataConclusao.year}';
  }

  String get dataVencimentoFormatada {
    final vencimento = dataVencimento;
    if (vencimento == null) return '';
    final dia = vencimento.day.toString().padLeft(2, '0');
    final mes = vencimento.month.toString().padLeft(2, '0');
    return '$dia/$mes/${vencimento.year}';
  }
}
