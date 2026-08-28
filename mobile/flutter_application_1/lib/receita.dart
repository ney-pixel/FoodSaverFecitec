
class Receita {
  final int id;
  final String nome;
  final String descricao;
  final String categoria;
  final String dificuldade;
  final int tempoPreparo;
  final int porcoes;
  final int calorias;
  final String imagem;
  bool favorita;
  final List<String> ingredientes;
  final List<String> ingredientesNecessarios;
  final List<String> preparo;
  final List<String> dicas;

  Receita({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.dificuldade,
    required this.tempoPreparo,
    required this.porcoes,
    required this.calorias,
    required this.imagem,
    this.favorita = false,
    required this.ingredientes,
    required this.ingredientesNecessarios,
    required this.preparo,
    required this.dicas,
  });

  //monta uma receita a partir do JSON de biblioteca/listar_biblioteca.php
  factory Receita.fromJson(Map<String, dynamic> json) {
    List<String> lista(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? [];
    return Receita(
      id: json['id'] as int,
      nome: json['titulo'] as String,
      descricao: (json['descricao'] as String?) ?? '',
      categoria: (json['categoria'] as String?) ?? '',
      dificuldade: (json['dificuldade'] as String?) ?? 'Fácil',
      tempoPreparo: (json['tempo_preparo'] as num?)?.toInt() ?? 0,
      porcoes: (json['porcoes'] as num?)?.toInt() ?? 1,
      calorias: (json['calorias'] as num?)?.toInt() ?? 0,
      imagem: (json['imagem'] as String?) ?? '',
      favorita: json['favorito'] == true,
      ingredientes: lista(json['ingredientes']),
      ingredientesNecessarios: lista(json['ingredientes_necessarios']),
      preparo: lista(json['modo_preparo']),
      dicas: lista(json['dicas']),
    );
  }
}

// Grupo de receitas da biblioteca (biblioteca/criar_grupo_biblioteca.php +
// gerenciar_grupo_biblioteca.php).
class GrupoReceitas {
  final String id;
  final String nome;
  final List<Receita> receitas;

  GrupoReceitas({
    required this.id,
    required this.nome,
    List<Receita>? receitas,
  }) : receitas = receitas ?? [];

  GrupoReceitas copiarCom({List<Receita>? receitas}) =>
      GrupoReceitas(id: id, nome: nome, receitas: receitas ?? this.receitas);
}
