import 'dart:convert';

import 'package:app_epi/src/models/usuario.dart';
import 'package:app_epi/src/screens/main_screen.dart';
import 'package:app_epi/src/screens/epi_screen.dart';
import 'package:app_epi/src/screens/historico_funcionario_screen.dart';
import 'package:app_epi/src/services/resumo_funcionario_service.dart';
import 'package:app_epi/src/widgets/indicador_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final usuario = Usuario(
  id: 7,
  matricula: '007',
  nome: 'Ana',
  setor: 'Produção',
  perfil: 'FUNCIONARIO',
);
Map<String, dynamic> epi(int id, String nome) => {
  'id': id,
  'nome': nome,
  'categoria': 'Proteção',
  'ca': '123',
  'imagemUrl': '/imagem.png',
  'quantidadeDisponivel': 987,
  'validadeCa': '2099-12-31',
  'caVencido': false,
};
Map<String, dynamic> emprestimo(
  int id,
  String status,
  int epiId,
  String nome,
) => {
  'id': id,
  'status': status,
  'dataEmprestimo': '2025-01-01',
  'dataDevolucao': status == 'DEVOLVIDO' ? '2025-02-01' : null,
  'epi': epi(epiId, nome),
};
final treinamentos = [
  {'id': 1, 'titulo': 'NR 06', 'validadeMeses': 12},
  {'id': 2, 'titulo': 'NR 35', 'validadeMeses': null},
  {'id': 3, 'titulo': 'Integração', 'validadeMeses': null},
];

MockClient cliente({void Function(Uri)? aoConsultar}) => MockClient((
  request,
) async {
  aoConsultar?.call(request.url);
  final caminho = request.url.path;
  Object corpo;
  if (caminho == '/emprestimos/funcionario/7') {
    corpo = [
      emprestimo(1, 'EMPRESTADO', 1, 'Capacete'),
      emprestimo(2, 'EMPRESTADO', 1, 'Capacete'),
      emprestimo(3, 'DEVOLVIDO', 2, 'Luva'),
      emprestimo(4, 'SOLICITADO', 2, 'Luva'),
      emprestimo(5, 'REJEITADO', 2, 'Luva'),
    ];
  } else if (caminho == '/treinamentos') {
    corpo = treinamentos;
  } else if (caminho == '/treinamentos/realizados/funcionario/7') {
    corpo = [
      {'id': 1, 'treinamento': treinamentos[0], 'dataConclusao': '2000-01-01'},
      {'id': 2, 'treinamento': treinamentos[1], 'dataConclusao': '2024-01-01'},
      {'id': 3, 'treinamento': treinamentos[1], 'dataConclusao': '2025-01-01'},
    ];
  } else if (caminho == '/epis') {
    corpo = [epi(1, 'Capacete'), epi(2, 'Luva')];
  } else if (caminho == '/dashboard') {
    corpo = {
      'caVencidos': 0,
      'episCadastrados': 0,
      'episDevolvidos': 0,
      'solicitacoesPendentes': 0,
      'funcionariosCadastrados': 0,
      'estoqueBaixo': 0,
      'episEmprestados': 0,
      'treinamentosPendentes': 0,
    };
  } else {
    throw StateError('Consulta inesperada: $caminho');
  }
  return http.Response(
    jsonEncode(corpo),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

void main() {
  test('Resumo separa posse, solicitações e recebimentos e usa conclusão mais recente', () async {
    await http.runWithClient(() async {
      final resumo = await ResumoFuncionarioService().buscar(7);
      expect(resumo.emPosse.length, 2);
      expect(resumo.quantidadesEmPosse, {1: 2});
      expect(resumo.solicitados.length, 1);
      expect(resumo.recebidos.length, 3);
      expect(resumo.pendentes.map((t) => t.id), [1, 3]);
      expect(resumo.realizados.length, 3);
      expect(resumo.ultimasConclusoes[2]!.id, 3);
    }, () => cliente());
  });

  testWidgets(
    'Funcionário vê dois cards da Aula 7 e não tem lista de funcionários no menu',
    (tester) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(home: MainScreen(usuario: usuario)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Meus EPIs em uso'), findsOneWidget);
        expect(find.text('Meus treinamentos pendentes'), findsOneWidget);
        expect(find.byType(IndicadorCard), findsNWidgets(2));
        expect(find.text('Histórico de EPIs recebidos'), findsOneWidget);
        expect(find.text('Histórico de treinamentos'), findsOneWidget);
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        await tester.drag(
          find.descendant(
            of: find.byType(Drawer),
            matching: find.byType(ListView),
          ),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(find.text('Lista de Funcionários'), findsNothing);
      }, () => cliente());
    },
  );

  testWidgets('Administrador mantém acesso à lista de funcionários', (
    tester,
  ) async {
    final admin = Usuario(
      id: 1,
      matricula: '001',
      nome: 'Admin',
      setor: 'Segurança',
      perfil: 'ADMIN',
    );
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: MainScreen(usuario: admin)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(ListView),
        ),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lista de Funcionários'), findsOneWidget);
    }, () => cliente());
  });

  testWidgets(
    'Catálogo oculta estoque da empresa e mostra quantidade em posse',
    (tester) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(home: EpiScreen(usuario: usuario)));
        await tester.pumpAndSettle();
        expect(find.text('Em sua posse: 2 un.'), findsWidgets);
        expect(find.textContaining('987'), findsNothing);
        expect(find.text('EPIs fornecidos pela empresa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => cliente());
    },
  );

  testWidgets(
    'Histórico de recebimentos exclui solicitações e permite buscar',
    (tester) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: HistoricoFuncionarioScreen(
              usuario: usuario,
              consulta: ConsultaFuncionario.historicoEpis,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Capacete'), findsNWidgets(2));
        expect(find.widgetWithText(ListTile, 'Luva'), findsOneWidget);
        expect(find.textContaining('SOLICITADO'), findsNothing);
        await tester.enterText(find.byType(TextFormField), 'Luva');
        await tester.pumpAndSettle();
        expect(find.text('Capacete'), findsNothing);
        expect(find.widgetWithText(ListTile, 'Luva'), findsOneWidget);
      }, () => cliente());
    },
  );

  testWidgets('Histórico de treinamentos preserva todas as conclusões', (
    tester,
  ) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: HistoricoFuncionarioScreen(
            usuario: usuario,
            consulta: ConsultaFuncionario.historicoTreinamentos,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NR 35'), findsNWidgets(2));
      expect(find.text('NR 06'), findsOneWidget);
      expect(find.textContaining('Vencido em'), findsOneWidget);
    }, () => cliente());
  });

  testWidgets('Card de treinamentos abre somente pendentes e vencidos', (
    tester,
  ) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: MainScreen(usuario: usuario)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meus treinamentos pendentes'));
      await tester.pumpAndSettle();
      expect(find.text('NR 06'), findsOneWidget);
      expect(find.text('Integração'), findsOneWidget);
      expect(find.text('NR 35'), findsNothing);
      expect(find.text('Vencido – refazer'), findsOneWidget);
    }, () => cliente());
  });

  testWidgets('Retorno dos detalhes atualiza os números do painel', (
    tester,
  ) async {
    var consultas = 0;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(home: MainScreen(usuario: usuario)),
        );
        await tester.pumpAndSettle();
        expect(consultas, 1);
        await tester.tap(find.text('Meus EPIs em uso'));
        await tester.pumpAndSettle();
        expect(find.text('2 un.'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(consultas, 3); // Painel, detalhes e atualização ao voltar.
      },
      () => cliente(
        aoConsultar: (uri) {
          if (uri.path == '/emprestimos/funcionario/7') consultas++;
        },
      ),
    );
  });
}
