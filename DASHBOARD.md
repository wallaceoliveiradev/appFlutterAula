# Dashboard — Aula 7

A implementação segue o PDF **Flutter API Java - App de Empréstimo de EPIs - Aula 7**. Em divergências com a versão anterior, prevalecem o contrato, a fórmula e a estrutura da aula.

## Correspondência com o PDF

| Etapa | Implementação |
| --- | --- |
| 1 — Contagens nos repositórios | `countByStatus`, `countByValidadeCaBefore` e `count()` na API |
| 2 — Service Java | [DashboardService.java](../api_epi/src/main/java/com/senac/api_epi/service/DashboardService.java), com autorização ADMIN e `LinkedHashMap<String, Long>` |
| 3 — Controller Java | [DashboardController.java](../api_epi/src/main/java/com/senac/api_epi/controllers/DashboardController.java), com resposta 200 ou 403 |
| 4 — Conferência dos números | Consultas SQL diretas comparadas com a API e [SQL de conferência](backend/conferir_dashboard.sql) |
| 5 — Model Flutter | [dashboard.dart](lib/src/models/dashboard.dart), com os nomes exatos das chaves Java |
| 6 — Service Flutter | [dashboard_service.dart](lib/src/services/dashboard_service.dart), método `buscar(adminId)` |
| 7 — Card reutilizável | [indicador_card.dart](lib/src/widgets/indicador_card.dart), com `valor`, `MaterialColor`, círculo colorido e `onTap` opcional |
| 8 — Dashboard | [dashboard_screen.dart](lib/src/screens/dashboard_screen.dart), sem Scaffold, alerta de CA, data e horário de atualização |
| 9 — Tela inicial | [main_screen.dart](lib/src/screens/main_screen.dart), com o painel gerencial no body do ADMIN |
| Exercícios 1 e 2 | Cards de funcionários cadastrados e estoque baixo, com navegação |
| Exercício 3 | [dashboard_funcionario_screen.dart](lib/src/screens/dashboard_funcionario_screen.dart), com os dois cards pessoais da aula |

## Contrato da API

`GET /dashboard?adminId=1` retorna os seis indicadores da aula e os dois dos exercícios, na ordem de inserção do `LinkedHashMap`. Sem DTO ou entidade nova para o dashboard:

```json
{
  "episCadastrados": 8,
  "episEmprestados": 0,
  "episDevolvidos": 0,
  "caVencidos": 1,
  "solicitacoesPendentes": 3,
  "treinamentosPendentes": 14,
  "funcionariosCadastrados": 3,
  "estoqueBaixo": 1
}
```

Esses números foram conferidos no banco local em 11/11/2026; variam conforme os dados. A chave antiga `pedidosPendentes` foi substituída por `solicitacoesPendentes`, conforme o PDF. O endpoint antigo de detalhes do dashboard foi substituído pela navegação para as telas de EPIs, solicitações e funcionários.

Todos os indicadores são calculados por contagens no banco. Não são carregadas listas completas para calcular os números do administrador.

### Regras da aula

- EPIs cadastrados: `epiRepository.count()`.
- EPIs emprestados/devolvidos: empréstimos com status `EMPRESTADO`/`DEVOLVIDO`.
- CA vencidos: validade anterior ao dia atual; CA que vence hoje permanece válido nesse dia.
- Solicitações pendentes: status `SOLICITADO`.
- Treinamentos pendentes: **todos os funcionários × treinamentos − registros de conclusão**, incluindo administradores no total de funcionários, como no PDF. Esse indicador não representa reciclagens vencidas por pessoa.
- Funcionários cadastrados: `funcionarioRepository.count()`.
- Estoque baixo: EPIs com quantidade disponível menor ou igual a 2, incluindo estoque zero.

Adaptação ao histórico de renovações já existente: o resultado da fórmula de treinamentos tem piso zero. A aula pressupõe uma conclusão por funcionário/treinamento, enquanto este projeto preserva várias conclusões por renovação. A fórmula da aula permanece; se houver muitas renovações, ela não representa a quantidade exata de pessoas ainda sem primeira conclusão.

## Interface e navegação

O administrador vê os seis cards da aula e os dois exercícios. A grade usa duas colunas abaixo de 700 pixels e três a partir de 700, com `shrinkWrap` e rolagem pela lista externa. A proporção segue 0,95 no celular e 1,6 no computador, com altura mínima adicional para evitar overflow em telas estreitas ou com texto ampliado.

O alerta vermelho com ícone e texto aparece apenas quando há CA vencido. O rodapé mostra o horário da última consulta bem-sucedida e o botão Atualizar. Puxar para atualizar e retornar de uma tela também consultam os números novamente.

- EPIs cadastrados: catálogo da empresa.
- CA vencidos: catálogo filtrado por CA vencido.
- Estoque baixo: catálogo filtrado por quantidade <= 2.
- Solicitações pendentes: gerenciamento no status SOLICITADO.
- EPIs emprestados/devolvidos: gerenciamento no status correspondente.
- Funcionários cadastrados: lista de funcionários, restrita ao ADMIN.
- Treinamentos pendentes: indicador informativo, sem ação de toque, como no PDF; por isso não mostra seta.

## Aprovação e devolução

A aula referencia uma tela de solicitações da Aula 5 que não existia neste projeto. Foi criada [solicitacoes_screen.dart](lib/src/screens/solicitacoes_screen.dart), acessível pelos cards e pelo menu ADMIN, com seleção de status e confirmação das ações.

- `GET /emprestimos?adminId=1`: listagem gerencial.
- `PUT /emprestimos/{id}/aprovar?adminId=1`: aceita apenas SOLICITADO, verifica CA e estoque, desconta uma unidade e altera para EMPRESTADO.
- `PUT /emprestimos/{id}/devolver?adminId=1`: aceita apenas EMPRESTADO, devolve uma unidade ao estoque, grava a data de devolução e altera para DEVOLVIDO.

As operações conferem ADMIN no banco e usam transação e bloqueios no empréstimo e no EPI. Repetir a mesma ação é rejeitado, evitando estoque duplicado ou negativo. As solicitações pessoais existentes continuam funcionando. Cada registro de empréstimo representa uma unidade.

## Funcionário e funcionalidades anteriores

Conforme o exercício 3, o funcionário vê dois cards: **Meus EPIs em uso** e **Meus treinamentos pendentes**. Os registros vencidos entram nas pendências pessoais, usando a conclusão mais recente. Ao abrir o card de treinamentos, permanecem disponíveis material e conclusão/renovação.

As solicitações pessoais e os dois históricos solicitados anteriormente permanecem como opções de consulta abaixo dos cards. [Os históricos](lib/src/screens/historico_funcionario_screen.dart) têm filtros por nome e intervalo de datas, inicialmente sem restrição de período. EPIs recebidos incluem EMPRESTADO e DEVOLVIDO, sem contar pedidos ainda não entregues. O período desse histórico usa a data da solicitação, pois o modelo não registra data efetiva de entrega. O histórico de treinamentos mantém todas as conclusões e renovações.

O catálogo do funcionário oculta o estoque da empresa na lista e nos detalhes, mantém a solicitação de EPIs e mostra as quantidades pessoais em posse. A lista de funcionários permanece exclusiva do ADMIN na interface e em `GET /funcionarios?adminId=...`.

`validadeMeses`, adicionado anteriormente, continua disponível: nulo indica ausência de vencimento; valores informados devem ser positivos. Renovar um treinamento vencido cria outra conclusão sem apagar registros antigos. Treinamentos que vencem hoje permanecem válidos durante o dia.

O desafio extra da aula é uma proposta de evolução: uma relação entre setor e treinamento obrigatório permitiria contar obrigações por setor. Ela não foi aplicada, para preservar a fórmula e a regra de todos os funcionários fazerem todos os treinamentos exigidas nesta aula.

## Executar e verificar

Reinicie a API na porta 8080 usando JDK 17 ou superior (a validação foi feita com JDK 24, compilando para Java 17). A URL do app permanece em [api_config.dart](lib/src/services/api_config.dart). A API já aberta na porta 8080 ainda estava executando a versão antiga durante a validação; a versão nova foi verificada temporariamente na porta 18080.

Os arquivos Java em [backend/](backend/) são cópias dos arquivos aplicados à API vizinha. O projeto já usa `spring.jpa.hibernate.ddl-auto=update`; o campo de validade de treinamento foi criado ao iniciar a versão atualizada.

Validações realizadas:

- Testes Flutter: contrato JSON, acesso por perfil, colunas em 320/699/700/1200 pixels, alerta condicional, card sem ação, fluxo de aprovação/devolução com atualização ao voltar e funcionalidades pessoais anteriores.
- API: 14 testes para contrato e fórmula da aula, autorização, estoque, transições de status e renovação de treinamentos.
- MySQL existente: os oito números do JSON coincidiram com consultas SQL diretas.
- HTTP real: ADMIN recebeu os indicadores; funcionário recebeu 403 no dashboard, listagem de funcionários e listagem gerencial de empréstimos.
- As transições de aprovação/devolução foram verificadas em testes automatizados, sem movimentar os pedidos reais do banco durante a conferência HTTP.

A identidade continua seguindo o padrão da documentação: `adminId` informado na requisição e perfil conferido no banco. O projeto não possui autenticação de API por token/sessão.
