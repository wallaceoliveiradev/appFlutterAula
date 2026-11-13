class Treinamento {
  final int id;
  final String titulo;
  final String? descricao;
  final String? arquivoUrl;
  final int? validadeMeses;

  Treinamento({
    required this.id,
    required this.titulo,
    this.descricao,
    this.arquivoUrl,
    this.validadeMeses,
  });

  factory Treinamento.fromJson(Map<String, dynamic> json) {
    final validadeMeses = json['validadeMeses'];

    return Treinamento(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String?,
      arquivoUrl: json['arquivoUrl'] as String?,
      validadeMeses: validadeMeses == null
          ? null
          : (validadeMeses as num).toInt(),
    );
  }
}
