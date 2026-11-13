import 'package:flutter/material.dart';

import '../models/funcionario.dart';
import '../models/usuario.dart';
import '../models/treinamento_realizado.dart';
import '../services/funcionario_service.dart';
import '../services/treinamento_Service.dart';

class FuncionarioScreen extends StatelessWidget {
  final Usuario usuario;
  const FuncionarioScreen({super.key, required this.usuario});

  void _mostrarTreinamentos(BuildContext context, Funcionario funcionario) {
    final realizadosFuture = TreinamentoService().buscarRealizados(
      funcionario.id,
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Treinamentos de ${funcionario.nome}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: FutureBuilder<List<TreinamentoRealizado>>(
            future: realizadosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar treinamentos: ${snapshot.error}',
                  ),
                );
              }

              final realizados = snapshot.data ?? [];
              if (realizados.isEmpty) {
                return const Center(
                  child: Text('Nenhum treinamento concluído.'),
                );
              }

              return ListView.separated(
                itemCount: realizados.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final realizado = realizados[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(realizado.treinamento.titulo),
                    subtitle: Text('Concluído em ${realizado.dataFormatada}'),
                    trailing: realizado.estaVencido
                        ? const Tooltip(
                            message: 'Vencido – refazer',
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Exercício 2: devolve um ícone diferente para cada setor
  IconData iconePorSetor(String setor) {
    switch (setor) {
      case 'Manutenção':
        return Icons.build;
      case 'Produção':
        return Icons.factory;
      case 'Almoxarifado':
        return Icons.inventory;
      default:
        return Icons.person; // setor não previsto
    }
  }

  @override
  Widget build(BuildContext context) {
    if (usuario.perfil.trim().toUpperCase() != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso restrito')),
        body: const Center(
          child: Text(
            'Apenas administradores podem acessar a lista de funcionários.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Funcionários'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fechar',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Funcionario>>(
        // Busca os dados da API
        future: FuncionarioService().buscarFuncionarios(usuario.id),
        builder: (context, snapshot) {
          // Exibe indicador enquanto aguarda os dados
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Exibe erro caso ocorra
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          // Recebe a lista retornada pela API
          final funcionarios = snapshot.data ?? [];

          if (funcionarios.isEmpty) {
            return const Center(child: Text('Nenhum funcionário cadastrado'));
          }

          return ListView.builder(
            itemCount: funcionarios.length,
            itemBuilder: (context, index) {
              final funcionario = funcionarios[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

                child: ListTile(
                  onTap: () => _mostrarTreinamentos(context, funcionario),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      iconePorSetor(funcionario.setor),
                      color: Colors.blue,
                    ),
                  ),

                  title: Text(funcionario.nome),

                  // Exibe matrícula e setor (a senha NÃO é exibida)
                  subtitle: Text(
                    'Matrícula: ${funcionario.matricula}\n'
                    'Setor: ${funcionario.setor}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
