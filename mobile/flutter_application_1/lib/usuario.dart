
class Usuario {
  final String nome;
  final String email;
  final String iniciais;
  final int nivel;
  final int xpAtual;
  final int xpMaximo;

  const Usuario({
    required this.nome,
    required this.email,
    required this.iniciais,
    this.nivel = 1,
    this.xpAtual = 0,
    this.xpMaximo = 2000,
  });

  //aqui cria uma copia com os campos atulaizados
  Usuario copiarCom({
    String? nome,
    String? email,
    String? iniciais,
    int? nivel,
    int? xpAtual,
    int? xpMaximo,
  }) {
    return Usuario(
      nome: nome ?? this.nome,
      email: email ?? this.email,
      iniciais: iniciais ?? this.iniciais,
      nivel: nivel ?? this.nivel,
      xpAtual: xpAtual ?? this.xpAtual,
      xpMaximo: xpMaximo ?? this.xpMaximo,
    );
  }

  double get porcentagemXP => xpAtual / xpMaximo;
}