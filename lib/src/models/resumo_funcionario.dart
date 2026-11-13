import 'emprestimo.dart';
import 'treinamento.dart';
import 'treinamento_realizado.dart';

class ResumoFuncionario {
  final List<Emprestimo> emprestimos;
  final List<Treinamento> treinamentos;
  final List<TreinamentoRealizado> realizados;

  ResumoFuncionario({
    required this.emprestimos,
    required this.treinamentos,
    required this.realizados,
  });

  List<Emprestimo> get emPosse =>
      emprestimos.where((e) => e.status.toUpperCase() == 'EMPRESTADO').toList();
  List<Emprestimo> get solicitados =>
      emprestimos.where((e) => e.status.toUpperCase() == 'SOLICITADO').toList();
  List<Emprestimo> get recebidos => emprestimos
      .where(
        (e) => ['EMPRESTADO', 'DEVOLVIDO'].contains(e.status.toUpperCase()),
      )
      .toList();

  Map<int, int> get quantidadesEmPosse {
    final quantidades = <int, int>{};
    for (final e in emPosse) {
      quantidades.update(e.epi.id, (valor) => valor + 1, ifAbsent: () => 1);
    }
    return quantidades;
  }

  Map<int, TreinamentoRealizado> get ultimasConclusoes {
    final ultimas = <int, TreinamentoRealizado>{};
    for (final r in realizados) {
      final anterior = ultimas[r.treinamento.id];
      if (anterior == null ||
          r.dataConclusao.isAfter(anterior.dataConclusao) ||
          (r.dataConclusao == anterior.dataConclusao && r.id > anterior.id)) {
        ultimas[r.treinamento.id] = r;
      }
    }
    return ultimas;
  }

  List<Treinamento> get pendentes {
    final ultimas = ultimasConclusoes;
    return treinamentos
        .where((t) => ultimas[t.id] == null || ultimas[t.id]!.estaVencido)
        .toList();
  }
}
