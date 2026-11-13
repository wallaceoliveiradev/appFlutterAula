import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../models/usuario.dart';
import '../services/dashboard_service.dart';
import '../widgets/indicador_card.dart';
import 'epi_screen.dart';
import 'funcionario_screen.dart';
import 'solicitacoes_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Usuario usuario;
  const DashboardScreen({super.key, required this.usuario});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Dashboard> futuroDados;
  DateTime? atualizadoEm;
  @override
  void initState() {
    super.initState();
    futuroDados = buscar();
  }

  Future<Dashboard> buscar() async {
    final dados = await DashboardService().buscar(widget.usuario.id);
    atualizadoEm = DateTime.now();
    return dados;
  }

  Future<void> recarregar() async {
    final futuro = buscar();
    setState(() {
      futuroDados = futuro;
    });
    try {
      await futuro;
    } catch (_) {
      /* Falha exibida abaixo. */
    }
  }

  Future<void> abrir(Widget tela) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => tela));
    if (mounted) await recarregar();
  }

  String doisDigitos(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final colunas = MediaQuery.sizeOf(context).width >= 700 ? 3 : 2;
    return FutureBuilder<Dashboard>(
      future: futuroDados,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: recarregar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }
        final d = snapshot.requireData;
        return RefreshIndicator(
          onRefresh: recarregar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Painel de Segurança do Trabalho',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Olá, ${widget.usuario.nome} · ${doisDigitos(hoje.day)}/${doisDigitos(hoje.month)}/${hoje.year}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              if (d.caVencidos > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${d.caVencidos} EPI(s) com CA vencido. Retire de uso e providencie a substituição.',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final larguraCard =
                      (constraints.maxWidth - (colunas - 1) * 12) / colunas;
                  final alturaBase = larguraCard / (colunas == 2 ? 0.95 : 1.6);
                  // Mantém a proporção da aula, com altura mínima para telas estreitas e texto ampliado.
                  final alturaMinima =
                      175 * MediaQuery.textScalerOf(context).scale(1);
                  return GridView.count(
                    crossAxisCount: colunas,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: alturaBase < alturaMinima
                        ? alturaMinima
                        : alturaBase,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      IndicadorCard(
                        titulo: 'EPIs cadastrados',
                        valor: d.episCadastrados,
                        icone: Icons.inventory_2,
                        cor: Colors.indigo,
                        onTap: () => abrir(EpiScreen(usuario: widget.usuario)),
                      ),
                      IndicadorCard(
                        titulo: 'EPIs emprestados',
                        valor: d.episEmprestados,
                        icone: Icons.outbox,
                        cor: Colors.blue,
                        onTap: () => abrir(
                          SolicitacoesScreen(
                            usuario: widget.usuario,
                            statusInicial: 'EMPRESTADO',
                          ),
                        ),
                      ),
                      IndicadorCard(
                        titulo: 'EPIs devolvidos',
                        valor: d.episDevolvidos,
                        icone: Icons.assignment_return,
                        cor: Colors.green,
                        onTap: () => abrir(
                          SolicitacoesScreen(
                            usuario: widget.usuario,
                            statusInicial: 'DEVOLVIDO',
                          ),
                        ),
                      ),
                      IndicadorCard(
                        titulo: 'CA vencidos',
                        valor: d.caVencidos,
                        icone: Icons.gpp_bad,
                        cor: Colors.red,
                        onTap: () => abrir(
                          EpiScreen(
                            usuario: widget.usuario,
                            apenasCaVencidos: true,
                          ),
                        ),
                      ),
                      IndicadorCard(
                        titulo: 'Solicitações pendentes',
                        valor: d.solicitacoesPendentes,
                        icone: Icons.pending_actions,
                        cor: Colors.amber,
                        onTap: () =>
                            abrir(SolicitacoesScreen(usuario: widget.usuario)),
                      ),
                      IndicadorCard(
                        titulo: 'Treinamentos pendentes',
                        valor: d.treinamentosPendentes,
                        icone: Icons.school,
                        cor: Colors.orange,
                      ),
                      IndicadorCard(
                        titulo: 'Funcionários cadastrados',
                        valor: d.funcionariosCadastrados,
                        icone: Icons.people,
                        cor: Colors.teal,
                        onTap: () =>
                            abrir(FuncionarioScreen(usuario: widget.usuario)),
                      ),
                      IndicadorCard(
                        titulo: 'Estoque baixo',
                        valor: d.estoqueBaixo,
                        icone: Icons.inventory,
                        cor: Colors.deepOrange,
                        onTap: () => abrir(
                          EpiScreen(
                            usuario: widget.usuario,
                            apenasEstoqueBaixo: true,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  Text(
                    'Atualizado às ${doisDigitos(atualizadoEm!.hour)}:${doisDigitos(atualizadoEm!.minute)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton.icon(
                    onPressed: recarregar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
