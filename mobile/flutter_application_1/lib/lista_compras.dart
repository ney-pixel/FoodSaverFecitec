
class ItemListaCompras {
  final String id;
  String nome;
  double quantidade;
  String unidade;
  bool comprado;
  final bool automatico;

  ItemListaCompras({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    this.comprado = false,
    this.automatico = false,
  });

  //monta um item a partir do JSON de compras/listar_compras.php
  factory ItemListaCompras.fromJson(Map<String, dynamic> json) {
    return ItemListaCompras(
      id: '${json['id']}',
      nome: json['nome_alimento'] as String,
      quantidade: (json['quantidade'] as num).toDouble(),
      unidade: json['unidade_medida'] as String,
      comprado: json['comprado'] == true,
      automatico: json['automatico'] == true,
    );
  }

  String get quantidadeFormatada {
    final v = quantidade == quantidade.truncateToDouble()
        ? quantidade.toInt().toString()
        : quantidade.toString();
    return '$v $unidade';
  }
}
