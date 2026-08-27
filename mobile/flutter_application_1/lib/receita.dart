
class Receita {
  final String id;
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
}