import '../models/emprestimo.dart';
import '../models/resumo_funcionario.dart';
import '../models/treinamento.dart';
import '../models/treinamento_realizado.dart';
import 'emprestimo_service.dart';
import 'treinamento_Service.dart';

class ResumoFuncionarioService {
  Future<ResumoFuncionario> buscar(int funcionarioId) async {
    final resultados = await Future.wait<Object>([
      EmprestimoService().buscarPorFuncionario(funcionarioId),
      TreinamentoService().buscarTreinamentos(),
      TreinamentoService().buscarRealizados(funcionarioId),
    ]);
    return ResumoFuncionario(
      emprestimos: resultados[0] as List<Emprestimo>,
      treinamentos: resultados[1] as List<Treinamento>,
      realizados: resultados[2] as List<TreinamentoRealizado>,
    );
  }
}
