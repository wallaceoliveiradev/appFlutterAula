import 'package:flutter/material.dart';

import 'epi_screen.dart';
import 'dashboard_screen.dart';
import 'dashboard_funcionario_screen.dart';
import 'solicitacoes_screen.dart';
import 'funcionario_screen.dart';
import 'meus_emprestimos_screen.dart';
import 'cadastrar_treinamento_screen.dart';

import '../models/usuario.dart';
import 'login_screen.dart';
import 'treinamentos_Screen.dart'; // Aula 6

class MainScreen extends StatefulWidget {
  final Usuario usuario;
  const MainScreen({super.key, required this.usuario});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Usuario get usuario => widget.usuario;
  int revisao = 0;
  Future<void> abrir(BuildContext context, Route<void> rota) async {
    Navigator.pop(context);
    await Navigator.of(context).push(rota);
    if (mounted) setState(() => revisao++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          usuario.perfil.trim().toUpperCase() == 'ADMIN'
              ? 'Empréstimos de EPIs'
              : 'Meu painel',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(usuario.nome),
              accountEmail: Text(usuario.perfil),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  usuario.nome[0],
                  style: const TextStyle(fontSize: 40.0),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Menu Principal', style: TextStyle(fontSize: 22)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('EPIs'),
              onTap: () {
                abrir(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EpiScreen(usuario: usuario), // Aula 4
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Treinamentos'),
              onTap: () {
                abrir(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TreinamentosScreen(usuario: usuario), // Aula 6
                  ),
                );
              },
            ),
            if (usuario.perfil.trim().toUpperCase() == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Cadastrar Treinamento'),
                onTap: () {
                  abrir(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CadastrarTreinamentoScreen(usuario: usuario),
                    ),
                  );
                },
              ),

            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Meus Empréstimos'),
              onTap: () {
                abrir(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeusEmprestimosScreen(usuario: usuario),
                  ),
                );
              },
            ),

            if (usuario.perfil.trim().toUpperCase() == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.pending_actions),
                title: const Text('Solicitações e empréstimos'),
                onTap: () => abrir(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SolicitacoesScreen(usuario: usuario),
                  ),
                ),
              ),
            if (usuario.perfil.trim().toUpperCase() == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Lista de Funcionários'),
                onTap: () {
                  abrir(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FuncionarioScreen(usuario: usuario),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: usuario.perfil.trim().toUpperCase() == 'ADMIN'
          ? DashboardScreen(key: ValueKey(revisao), usuario: usuario)
          : DashboardFuncionarioScreen(
              key: ValueKey(revisao),
              usuario: usuario,
            ),
    );
  }
}
