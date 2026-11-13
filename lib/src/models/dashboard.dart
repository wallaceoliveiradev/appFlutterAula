class Dashboard {
  final int episCadastrados;
  final int episEmprestados;
  final int episDevolvidos;
  final int caVencidos;
  final int solicitacoesPendentes;
  final int treinamentosPendentes;
  final int funcionariosCadastrados;
  final int estoqueBaixo;

  const Dashboard({
    required this.episCadastrados,
    required this.episEmprestados,
    required this.episDevolvidos,
    required this.caVencidos,
    required this.solicitacoesPendentes,
    required this.treinamentosPendentes,
    required this.funcionariosCadastrados,
    required this.estoqueBaixo,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    int ler(String chave) {
      final valor = json[chave];
      if (valor is! int || valor < 0) {
        throw FormatException('Indicador inválido: $chave');
      }
      return valor;
    }

    return Dashboard(
      episCadastrados: ler('episCadastrados'),
      episEmprestados: ler('episEmprestados'),
      episDevolvidos: ler('episDevolvidos'),
      caVencidos: ler('caVencidos'),
      solicitacoesPendentes: ler('solicitacoesPendentes'),
      treinamentosPendentes: ler('treinamentosPendentes'),
      funcionariosCadastrados: ler('funcionariosCadastrados'),
      estoqueBaixo: ler('estoqueBaixo'),
    );
  }
}
