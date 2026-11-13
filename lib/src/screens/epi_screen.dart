import 'package:flutter/material.dart';

import '../models/epi.dart';
import '../models/emprestimo.dart';
import '../models/usuario.dart';
import '../services/api_config.dart';
import '../services/epi_service.dart';
import '../services/emprestimo_service.dart';
import 'epi_detalhe_screen.dart';

class EpiScreen extends StatefulWidget {
  final Usuario usuario;
  final bool apenasCaVencidos;
  final bool apenasEstoqueBaixo;
  const EpiScreen({
    super.key,
    required this.usuario,
    this.apenasCaVencidos = false,
    this.apenasEstoqueBaixo = false,
  });
  @override
  State<EpiScreen> createState() => _EpiScreenState();
}

class _EpiScreenState extends State<EpiScreen> {
  late Future<void> dados;
  List<Epi> epis = [];
  Map<int, int> emPosse = {};
  bool get admin => widget.usuario.perfil.trim().toUpperCase() == 'ADMIN';
  @override
  void initState() {
    super.initState();
    dados = carregar();
  }

  Future<void> carregar() async {
    final resultados = await Future.wait<Object>([
      EpiService().buscarEpis(),
      if (!admin) EmprestimoService().buscarPorFuncionario(widget.usuario.id),
    ]);
    epis = resultados[0] as List<Epi>;
    emPosse = {};
    if (!admin) {
      // Um registro de empréstimo ativo representa uma unidade em posse.
      for (final emprestimo in resultados[1] as List<Emprestimo>) {
        if (emprestimo.status.toUpperCase() == 'EMPRESTADO') {
          final id = emprestimo.epi.id;
          emPosse.update(id, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  Future<void> atualizar() async {
    final futuro = carregar();
    setState(() {
      dados = futuro;
    });
    try {
      await futuro;
    } catch (_) {
      /* O FutureBuilder apresenta o erro. */
    }
  }

  Future<void> abrir(Epi epi) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EpiDetalheScreen(epi: epi, usuario: widget.usuario),
      ),
    );
    if (mounted) await atualizar();
  }

  Widget card(Epi epi, {bool posse = false}) => Card(
    color: epi.caVencido ? Colors.red.shade50 : null,
    child: ListTile(
      onTap: () => abrir(epi),
      leading: Image.network(
        '${ApiConfig.baseUrl}${epi.imagemUrl}',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.health_and_safety, size: 40, color: Colors.blue),
      ),
      title: Text(
        epi.nome,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(epi.categoria),
          Text(
            'CA: ${epi.ca} • ${epi.caVencido ? 'Vencido em' : 'Válido até'} ${epi.validadeFormatada}',
            style: TextStyle(color: epi.caVencido ? Colors.red : null),
          ),
          if (admin) Text('Disponível: ${epi.quantidadeDisponivel} un.'),
          if (!admin && (emPosse[epi.id] ?? 0) > 0)
            Text(
              'Em sua posse: ${emPosse[epi.id]} un.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (!posse) const Text('Toque para consultar e solicitar'),
        ],
      ),
      trailing: epi.caVencido
          ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(admin ? 'Lista de EPIs' : 'EPIs da empresa e meus EPIs'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: FutureBuilder<void>(
      future: dados,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: ElevatedButton(
              onPressed: atualizar,
              child: const Text('Falha ao carregar EPIs. Tentar novamente'),
            ),
          );
        }
        final filtrados = epis
            .where(
              (epi) =>
                  (!widget.apenasCaVencidos || epi.caVencido) &&
                  (!widget.apenasEstoqueBaixo || epi.quantidadeDisponivel <= 2),
            )
            .toList();
        final possuidos = epis
            .where((epi) => (emPosse[epi.id] ?? 0) > 0)
            .toList();
        return RefreshIndicator(
          onRefresh: atualizar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (!admin) ...[
                Text(
                  'Meus EPIs em posse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (possuidos.isEmpty)
                  const ListTile(title: Text('Você não possui EPIs em posse.')),
                for (final epi in possuidos) card(epi, posse: true),
                const SizedBox(height: 24),
                Text(
                  'EPIs fornecidos pela empresa',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
              ],
              if (filtrados.isEmpty)
                const ListTile(title: Text('Nenhum EPI cadastrado.')),
              for (final epi in filtrados) card(epi),
            ],
          ),
        );
      },
    ),
  );
}
