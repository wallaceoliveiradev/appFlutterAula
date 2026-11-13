import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/resumo_funcionario.dart';
import '../services/resumo_funcionario_service.dart';
import '../widgets/indicador_card.dart';
import 'historico_funcionario_screen.dart';
import 'treinamentos_Screen.dart';

class DashboardFuncionarioScreen extends StatefulWidget {
  final Usuario usuario;
  const DashboardFuncionarioScreen({super.key, required this.usuario});
  @override
  State<DashboardFuncionarioScreen> createState() =>
      _DashboardFuncionarioScreenState();
}

class _DashboardFuncionarioScreenState
    extends State<DashboardFuncionarioScreen> {
  late Future<ResumoFuncionario> dados;
  @override
  void initState() {
    super.initState();
    dados = carregar();
  }

  Future<ResumoFuncionario> carregar() =>
      ResumoFuncionarioService().buscar(widget.usuario.id);
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

  Future<void> abrir(Widget tela) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => tela));
    if (mounted) await atualizar();
  }

  void consulta(ConsultaFuncionario tipo) => abrir(
    HistoricoFuncionarioScreen(usuario: widget.usuario, consulta: tipo),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<ResumoFuncionario>(
    future: dados,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: ElevatedButton(
            onPressed: atualizar,
            child: const Text('Falha ao carregar o painel. Tentar novamente'),
          ),
        );
      }
      final resumo = snapshot.requireData;
      return RefreshIndicator(
        onRefresh: atualizar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Olá, ${widget.usuario.nome}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Acompanhe seus equipamentos e treinamentos.'),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              mainAxisExtent: 200 * MediaQuery.textScalerOf(context).scale(1),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                IndicadorCard(
                  titulo: 'Meus EPIs em uso',
                  valor: resumo.emPosse.length,
                  icone: Icons.health_and_safety,
                  cor: Colors.blue,
                  onTap: () => consulta(ConsultaFuncionario.emPosse),
                ),
                IndicadorCard(
                  titulo: 'Meus treinamentos pendentes',
                  valor: resumo.pendentes.length,
                  icone: Icons.school,
                  cor: Colors.orange,
                  onTap: () => abrir(
                    TreinamentosScreen(
                      usuario: widget.usuario,
                      apenasPendentes: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Consultas e históricos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Empréstimos solicitados'),
              trailing: Text('${resumo.solicitados.length}'),
              onTap: () => consulta(ConsultaFuncionario.solicitados),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de EPIs recebidos'),
              trailing: Text('${resumo.recebidos.length}'),
              onTap: () => consulta(ConsultaFuncionario.historicoEpis),
            ),
            ListTile(
              leading: const Icon(Icons.fact_check),
              title: const Text('Histórico de treinamentos'),
              trailing: Text('${resumo.realizados.length}'),
              onTap: () => consulta(ConsultaFuncionario.historicoTreinamentos),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: atualizar,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
