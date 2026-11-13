import 'dart:convert';

import 'package:app_epi/src/models/usuario.dart';
import 'package:app_epi/src/screens/dashboard_screen.dart';
import 'package:app_epi/src/services/dashboard_service.dart';
import 'package:app_epi/src/widgets/indicador_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final admin = Usuario(
  id: 1,
  matricula: '1001',
  nome: 'Ana Souza',
  setor: 'Segurança',
  perfil: 'ADMIN',
);
Map<String, int> indicadores({int vencidos = 1, int solicitados = 1}) => {
  'episCadastrados': 8,
  'episEmprestados': 2,
  'episDevolvidos': 1,
  'caVencidos': vencidos,
  'solicitacoesPendentes': solicitados,
  'treinamentosPendentes': 10,
  'funcionariosCadastrados': 3,
  'estoqueBaixo': 2,
};

void main() {
  for (final largura in [320.0, 699.0, 700.0, 1200.0]) {
    testWidgets('Aula 7: colunas e cards sem overflow em $largura pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(largura, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: DashboardScreen(usuario: admin)),
            ),
          );
          await tester.pumpAndSettle();
          final grid = tester.widget<GridView>(find.byType(GridView));
          expect(
            (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
                .crossAxisCount,
            largura >= 700 ? 3 : 2,
          );
          expect(find.textContaining('Retire de uso'), findsOneWidget);
          expect(find.text('EPIs cadastrados'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(ListView), const Offset(0, -2200));
          await tester.pumpAndSettle();
          expect(find.text('Funcionários cadastrados'), findsOneWidget);
          expect(find.text('Estoque baixo'), findsOneWidget);
          expect(find.textContaining('Atualizado às'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient(
          (_) async => http.Response(jsonEncode(indicadores()), 200),
        ),
      );
    });
  }

  testWidgets('Alerta de CA não aparece quando a contagem é zero', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DashboardScreen(usuario: admin)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Retire de uso'), findsNothing);
      },
      () => MockClient(
        (_) async => http.Response(jsonEncode(indicadores(vencidos: 0)), 200),
      ),
    );
  });

  testWidgets('Card sem ação não exibe seta', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 220,
            child: IndicadorCard(
              titulo: 'Treinamentos pendentes',
              valor: 10,
              icone: Icons.school,
              cor: Colors.orange,
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.text('10'), findsOneWidget);
  });

  test(
    'Funcionário recebe mensagem de acesso restrito no dashboard gerencial',
    () async {
      await http.runWithClient(
        () async {
          await expectLater(
            DashboardService().buscar(2),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'mensagem',
                contains('Apenas administradores'),
              ),
            ),
          );
        },
        () => MockClient(
          (_) async =>
              http.Response('Apenas administradores podem ver o painel', 403),
        ),
      );
    },
  );

  testWidgets('Aprovar, devolver e voltar atualiza os indicadores', (
    tester,
  ) async {
    var status = 'SOLICITADO';
    var consultas = 0;
    final client = MockClient((request) async {
      expect(request.url.queryParameters['adminId'], '1');
      if (request.url.path == '/dashboard') {
        consultas++;
        final dados = indicadores(
          vencidos: 0,
          solicitados: status == 'SOLICITADO' ? 1 : 0,
        );
        dados['episDevolvidos'] = status == 'DEVOLVIDO' ? 2 : 1;
        return http.Response(jsonEncode(dados), 200);
      }
      if (request.method == 'PUT') {
        status = request.url.path.endsWith('/aprovar')
            ? 'EMPRESTADO'
            : 'DEVOLVIDO';
        return http.Response('{}', 200);
      }
      return http.Response(
        jsonEncode([
          {
            'id': 9,
            'status': status,
            'dataEmprestimo': '2026-11-01',
            'funcionario': {'nome': 'Bruno'},
            'epi': {
              'id': 1,
              'nome': 'Capacete',
              'categoria': 'Proteção',
              'ca': '123',
              'imagemUrl': '',
              'quantidadeDisponivel': 3,
              'validadeCa': '2099-01-01',
              'caVencido': false,
            },
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DashboardScreen(usuario: admin)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Solicitações pendentes'));
      await tester.tap(find.text('Solicitações pendentes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprovar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(status, 'EMPRESTADO');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(consultas, 2);
      final pendentes = tester.widget<IndicadorCard>(
        find.ancestor(
          of: find.text('Solicitações pendentes'),
          matching: find.byType(IndicadorCard),
        ),
      );
      expect(pendentes.valor, 0);
      await tester.ensureVisible(find.text('EPIs emprestados'));
      await tester.tap(find.text('EPIs emprestados'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar devolução'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(status, 'DEVOLVIDO');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(consultas, 3);
    }, () => client);
  });
}
