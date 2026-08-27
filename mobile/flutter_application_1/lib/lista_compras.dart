
class ItemListaCompras {
  final String id;
  String nome;
  double quantidade;
  String unidade;
  bool comprado;

  ItemListaCompras({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    this.comprado = false,
  });

  String get quantidadeFormatada {
    final v = quantidade == quantidade.truncateToDouble()
        ? quantidade.toInt().toString()
        : quantidade.toString();
    return '$v $unidade';
  }
}


class ConfiguracaoMinimo {
  final String id;
  final String nomeAlimento;  
  double quantidadeMinima;
  String unidade;

  ConfiguracaoMinimo({
    required this.id,
    required this.nomeAlimento,
    required this.quantidadeMinima,
    required this.unidade,
  });

  String get minimoFormatado {
    final v = quantidadeMinima == quantidadeMinima.truncateToDouble()
        ? quantidadeMinima.toInt().toString()
        : quantidadeMinima.toString();
    return '$v $unidade';
  }
}