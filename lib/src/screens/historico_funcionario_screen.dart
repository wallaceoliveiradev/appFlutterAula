import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/resumo_funcionario.dart';
import '../services/resumo_funcionario_service.dart';

enum ConsultaFuncionario {
  emPosse,
  solicitados,
  historicoEpis,
  historicoTreinamentos,
}

class HistoricoFuncionarioScreen extends StatefulWidget {
  final Usuario usuario;
  final ConsultaFuncionario consulta;
  const HistoricoFuncionarioScreen({
    super.key,
    required this.usuario,
    required this.consulta,
  });

  @override
  State<HistoricoFuncionarioScreen> createState() =>
      _HistoricoFuncionarioScreenState();
}

class _HistoricoFuncionarioScreenState
    extends State<HistoricoFuncionarioScreen> {
  late Future<ResumoFuncionario> dados;
  final busca = TextEditingController();
  DateTimeRange? periodo;
  bool get historico =>
      widget.consulta == ConsultaFuncionario.historicoEpis ||
      widget.consulta == ConsultaFuncionario.historicoTreinamentos;
  String get titulo => switch (widget.consulta) {
    ConsultaFuncionario.emPosse => 'Meus EPIs em posse',
    ConsultaFuncionario.solicitados => 'Empréstimos solicitados',
    ConsultaFuncionario.historicoEpis => 'Histórico de EPIs recebidos',
    ConsultaFuncionario.historicoTreinamentos => 'Histórico de treinamentos',
  };

  @override
  void initState() {
    super.initState();
    dados = carregar();
  }

  Future<ResumoFuncionario> carregar() =>
      ResumoFuncionarioService().buscar(widget.usuario.id);
  @override
  void dispose() {
    busca.dispose();
    super.dispose();
  }

  Future<void> atualizar() async {
    final futuro = carregar();
    setState(() {
      dados = futuro;
    });
    try {
      await futuro;
    } catch (_) {
      /* Exibido no FutureBuilder. */
    }
  }

  bool corresponde(String nome, DateTime data) {
    final dia = DateTime(data.year, data.month, data.day);
    return nome.toLowerCase().contains(busca.text.trim().toLowerCase()) &&
        (periodo == null ||
            (!dia.isBefore(periodo!.start) && !dia.isAfter(periodo!.end)));
  }

  String data(DateTime valor) =>
      '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}';

  Future<void> escolherPeriodo() async {
    final selecionado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDateRange: periodo,
    );
    if (selecionado != null && mounted) setState(() => periodo = selecionado);
  }

  List<Widget> registros(ResumoFuncionario resumo) {
    if (widget.consulta == ConsultaFuncionario.emPosse) {
      final porId = {for (final e in resumo.emPosse) e.epi.id: e.epi};
      return [
        for (final entrada in resumo.quantidadesEmPosse.entries)
          Card(
            child: ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: Text(porId[entrada.key]!.nome),
              subtitle: Text('CA: ${porId[entrada.key]!.ca}'),
              trailing: Text('${entrada.value} un.'),
            ),
          ),
      ];
    }
    if (widget.consulta == ConsultaFuncionario.historicoTreinamentos) {
      final lista =
          resumo.realizados
              .where((r) => corresponde(r.treinamento.titulo, r.dataConclusao))
              .toList()
            ..sort((a, b) => b.dataConclusao.compareTo(a.dataConclusao));
      return [
        for (final r in lista)
          Card(
            child: ListTile(
              leading: Icon(
                r.estaVencido ? Icons.warning_amber : Icons.school,
                color: r.estaVencido ? Colors.orange : Colors.green,
              ),
              title: Text(r.treinamento.titulo),
              subtitle: Text(
                'Conclusão: ${r.dataFormatada}\n${r.dataVencimento == null ? 'Sem prazo de validade' : '${r.estaVencido ? 'Vencido em' : 'Válido até'} ${r.dataVencimentoFormatada}'}',
              ),
            ),
          ),
      ];
    }
    final lista =
        (widget.consulta == ConsultaFuncionario.solicitados
                ? resumo.solicitados
                : resumo.recebidos)
            .where((e) => corresponde(e.epi.nome, e.dataEmprestimo))
            .toList()
          ..sort((a, b) => b.dataEmprestimo.compareTo(a.dataEmprestimo));
    return [
      for (final e in lista)
        Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(e.epi.nome),
            subtitle: Text(
              'Solicitado em: ${data(e.dataEmprestimo)} • 1 un.\nStatus: ${e.status}${e.dataDevolucao == null ? '' : '\nDevolvido em: ${data(e.dataDevolucao!)}'}${e.observacao.isEmpty ? '' : '\nMotivo: ${e.observacao}'}',
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(titulo)),
    body: FutureBuilder<ResumoFuncionario>(
      future: dados,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: ElevatedButton(
              onPressed: atualizar,
              child: const Text('Falha ao carregar. Tentar novamente'),
            ),
          );
        }
        final itens = registros(snapshot.requireData);
        return RefreshIndicator(
          onRefresh: atualizar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (historico)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: busca,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Buscar por nome',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: escolherPeriodo,
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                periodo == null
                                    ? 'Todo o período'
                                    : '${data(periodo!.start)} a ${data(periodo!.end)}',
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                busca.clear();
                                periodo = null;
                              }),
                              child: const Text('Limpar filtros'),
                            ),
                          ],
                        ),
                        Text(
                          widget.consulta == ConsultaFuncionario.historicoEpis
                              ? 'Inclui EPIs em posse e devolvidos. O período usa a data da solicitação registrada no sistema.'
                              : 'Todas as conclusões, incluindo renovações e registros vencidos.',
                        ),
                      ],
                    ),
                  ),
                ),
              if (itens.isEmpty)
                const ListTile(title: Text('Nenhum registro encontrado.')),
              ...itens,
            ],
          ),
        );
      },
    ),
  );
}
