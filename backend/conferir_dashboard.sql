-- Aula 7: executar no banco epi_db e comparar com GET /dashboard?adminId=1.
SELECT
    (SELECT COUNT(*) FROM epi) AS episCadastrados,
    (SELECT COUNT(*) FROM emprestimo WHERE status = 'EMPRESTADO') AS episEmprestados,
    (SELECT COUNT(*) FROM emprestimo WHERE status = 'DEVOLVIDO') AS episDevolvidos,
    (SELECT COUNT(*) FROM epi WHERE validade_ca < CURDATE()) AS caVencidos,
    (SELECT COUNT(*) FROM emprestimo WHERE status = 'SOLICITADO') AS solicitacoesPendentes,
    GREATEST(0,
        (SELECT COUNT(*) FROM funcionario) * (SELECT COUNT(*) FROM treinamento)
        - (SELECT COUNT(*) FROM treinamento_realizado)) AS treinamentosPendentes,
    (SELECT COUNT(*) FROM funcionario) AS funcionariosCadastrados,
    (SELECT COUNT(*) FROM epi WHERE quantidade_disponivel <= 2) AS estoqueBaixo;
