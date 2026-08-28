
class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String iniciais;
  final String plano;

  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.iniciais,
    this.plano = 'gratis',
  });

  //calcula as iniciais a partir de um nome/username qualquer
  static String iniciaisDe(String nomeCompleto) {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2 && partes.first.isNotEmpty && partes.last.isNotEmpty) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    if (nomeCompleto.trim().isEmpty) return '?';
    final semEspacos = nomeCompleto.trim();
    return semEspacos.length >= 2
        ? semEspacos.substring(0, 2).toUpperCase()
        : semEspacos.substring(0, 1).toUpperCase();
  }

  //aqui cria uma copia com os campos atulaizados
  Usuario copiarCom({
    int? id,
    String? nome,
    String? email,
    String? iniciais,
    String? plano,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      iniciais: iniciais ?? this.iniciais,
      plano: plano ?? this.plano,
    );
  }
}
