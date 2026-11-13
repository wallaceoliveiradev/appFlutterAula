import 'epi.dart';

class Emprestimo {
  final int id;
  final DateTime dataEmprestimo;
  final DateTime? dataDevolucao;
  final String status;
  final String observacao;
  final Epi epi;
  final String? funcionarioNome;

  Emprestimo({
    required this.id,
    required this.dataEmprestimo,
    required this.status,
    required this.observacao,
    required this.epi,
    this.dataDevolucao,
    this.funcionarioNome,
  });

  factory Emprestimo.fromJson(Map<String, dynamic> json) {
    return Emprestimo(
      id: json['id'],
      dataEmprestimo: DateTime.parse(json['dataEmprestimo']),
      dataDevolucao: json['dataDevolucao'] == null
          ? null
          : DateTime.parse(json['dataDevolucao']),
      status: json['status'],
      observacao: json['observacao'] ?? '',
      epi: Epi.fromJson(json['epi']),
      funcionarioNome:
          (json['funcionario'] as Map<String, dynamic>?)?['nome'] as String?,
    );
  }
}
