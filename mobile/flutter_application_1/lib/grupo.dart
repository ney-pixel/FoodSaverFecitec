
import 'alimento.dart';

class GrupoAlimentos {
  final String id;
  final String nome;
  final List<AlimentoEstoque> alimentos;

  GrupoAlimentos({
    required this.id,
    required this.nome,
    List<AlimentoEstoque>? alimentos,
  }) : alimentos = alimentos ?? [];

  int get totalItens => alimentos.length;

  //monta um grupo a partir do JSON de grupos/gerenciar_grupo_alimentos.php (GET)
  factory GrupoAlimentos.fromJson(Map<String, dynamic> json) {
    final itens = (json['alimentos'] as List? ?? [])
        .map((a) => AlimentoEstoque(
              id: '${a['id']}',
              nome: a['nome'] as String,
              quantidade: (a['quantidade'] as num).toDouble(),
              unidade: a['unidade'] as String,
              validade: '',
              status: 'OK',
            ))
        .toList();
    return GrupoAlimentos(
      id: '${json['id']}',
      nome: json['nome'] as String,
      alimentos: itens,
    );
  }

  GrupoAlimentos copiarCom({
    String? nome,
    List<AlimentoEstoque>? alimentos,
  }) {
    return GrupoAlimentos(
      id:        id,
      nome:      nome ?? this.nome,
      alimentos: alimentos ?? this.alimentos,
    );
  }
}
