import 'package:app_epi/main.dart';
import 'package:app_epi/src/services/dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Aplicativo inicia no login', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
  test(
    'Dashboard consulta indicadores da aula e exercícios em uma requisição',
    () async {
      var chamadas = 0;
      final client = MockClient((request) async {
        chamadas++;
        expect(request.url.path, '/dashboard');
        expect(request.url.queryParameters['adminId'], '1');
        return http.Response(
          '{"episCadastrados":8,"episEmprestados":2,"episDevolvidos":1,"caVencidos":1,"solicitacoesPendentes":1,"treinamentosPendentes":10,"funcionariosCadastrados":3,"estoqueBaixo":2}',
          200,
        );
      });
      await http.runWithClient(() async {
        final dados = await DashboardService().buscar(1);
        expect(dados.treinamentosPendentes, 10);
        expect(dados.episCadastrados, 8);
        expect(dados.episDevolvidos, 1);
        expect(dados.solicitacoesPendentes, 1);
        expect(dados.funcionariosCadastrados, 3);
        expect(dados.estoqueBaixo, 2);
      }, () => client);
      expect(chamadas, 1);
    },
  );
  test('Resposta incompleta não vira indicador zero', () async {
    await http.runWithClient(() async {
      await expectLater(DashboardService().buscar(1), throwsFormatException);
    }, () => MockClient((_) async => http.Response('{}', 200)));
  });
}
