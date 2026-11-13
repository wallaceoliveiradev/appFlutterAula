import 'package:flutter/material.dart';

import '../models/emprestimo.dart';
import '../models/usuario.dart';
import '../services/emprestimo_service.dart';

class SolicitacoesScreen extends StatefulWidget {
  final Usuario usuario;
  final String statusInicial;
  const SolicitacoesScreen({
    super.key,
    required this.usuario,
    this.statusInicial = 'SOLICITADO',
  });
  @override
  State<SolicitacoesScreen> createState() => _SolicitacoesScreenState();
}

class _SolicitacoesScreenState extends State<SolicitacoesScreen> {
  late Future<List<Emprestimo>> dados;
  late String status;
  int? processando;
  @override
  void initState() {
    super.initState();
    status = widget.statusInicial;
    if (widget.usuario.perfil.trim().toUpperCase() == 'ADMIN') {
      dados = carregar();
    }
  }

  Future<List<Emprestimo>> carregar() =>
      EmprestimoService().buscarTodos(widget.usuario.id);
  Future<void> atualizar() async {
    final futuro = carregar();
    setState(() {
      dados = futuro;
    });
    try {
      await futuro;
    } catch (_) {
      /* O FutureBuilder mostra a falha. */
    }
  }

  Future<void> movimentar(Emprestimo e) async {
    final devolver = e.status == 'EMPRESTADO';
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(devolver ? 'Registrar devolução' : 'Aprovar solicitação'),
        content: Text(
          '${devolver ? 'Confirmar a devolução' : 'Confirmar a entrega'} de ${e.epi.nome} para ${e.funcionarioNome ?? 'o funcionário'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() {
      processando = e.id;
    });
    try {
      await EmprestimoService().movimentar(
        e.id,
        widget.usuario.id,
        devolver: devolver,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            devolver ? 'Devolução registrada.' : 'Solicitação aprovada.',
          ),
        ),
      );
      await atualizar();
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          processando = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usuario.perfil.trim().toUpperCase() != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso restrito')),
        body: const Center(
          child: Text('Apenas administradores podem gerenciar solicitações.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações e empréstimos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'SOLICITADO',
                  child: Text('Solicitações pendentes'),
                ),
                DropdownMenuItem(
                  value: 'EMPRESTADO',
                  child: Text('EPIs emprestados'),
                ),
                DropdownMenuItem(
                  value: 'DEVOLVIDO',
                  child: Text('EPIs devolvidos'),
                ),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() {
                    status = valor;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Emprestimo>>(
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
                final itens = snapshot.requireData
                    .where((e) => e.status == status)
                    .toList();
                return RefreshIndicator(
                  onRefresh: atualizar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: itens.isEmpty
                        ? [
                            const ListTile(
                              title: Text('Nenhum registro neste status.'),
                            ),
                          ]
                        : [
                            for (final e in itens)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.epi.nome,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        'Funcionário: ${e.funcionarioNome ?? 'Não informado'}',
                                      ),
                                      Text('Status: ${e.status}'),
                                      if (e.observacao.isNotEmpty)
                                        Text('Motivo: ${e.observacao}'),
                                      if (e.status != 'DEVOLVIDO')
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: FilledButton.icon(
                                            onPressed: processando == null
                                                ? () => movimentar(e)
                                                : null,
                                            icon: Icon(
                                              e.status == 'SOLICITADO'
                                                  ? Icons.check
                                                  : Icons.assignment_return,
                                            ),
                                            label: Text(
                                              e.status == 'SOLICITADO'
                                                  ? 'Aprovar'
                                                  : 'Registrar devolução',
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
