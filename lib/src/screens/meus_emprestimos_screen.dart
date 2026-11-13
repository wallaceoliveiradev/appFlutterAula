import 'package:flutter/material.dart';

import '../models/emprestimo.dart';
import '../models/usuario.dart';
import '../services/emprestimo_service.dart';

class MeusEmprestimosScreen extends StatefulWidget {
  final Usuario usuario;

  const MeusEmprestimosScreen({super.key, required this.usuario});

  @override
  State<MeusEmprestimosScreen> createState() => _MeusEmprestimosScreenState();
}

class _MeusEmprestimosScreenState extends State<MeusEmprestimosScreen> {
  late Future<List<Emprestimo>> emprestimosFuture;

  @override
  void initState() {
    super.initState();
    emprestimosFuture =
        EmprestimoService().buscarPorFuncionario(widget.usuario.id);
  }

  Future<void> atualizar() async {
    setState(() {
      emprestimosFuture =
          EmprestimoService().buscarPorFuncionario(widget.usuario.id);
    });
    await emprestimosFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Empréstimos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Emprestimo>>(
        future: emprestimosFuture,
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
                    const Text('Não foi possível carregar seus empréstimos.'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: atualizar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final emprestimos = snapshot.data ?? [];
          if (emprestimos.isEmpty) {
            return RefreshIndicator(
              onRefresh: atualizar,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Você ainda não possui empréstimos.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: atualizar,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: emprestimos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _EmprestimoCard(emprestimo: emprestimos[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmprestimoCard extends StatelessWidget {
  final Emprestimo emprestimo;

  const _EmprestimoCard({required this.emprestimo});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(emprestimo.status);
    final data = emprestimo.dataEmprestimo;
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    emprestimo.epi.nome,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    emprestimo.status,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Data da solicitação: $dataFormatada'),
            const SizedBox(height: 6),
            Text('Motivo: ${emprestimo.observacao}'),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SOLICITADO':
        return Colors.orange;
      case 'EMPRESTADO':
        return Colors.green;
      case 'DEVOLVIDO':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}