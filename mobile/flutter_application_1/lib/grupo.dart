
import 'alimento.dart';

class GrupoAlimentos {
  final String id;
  final String nome;
  final List<AlimentoEstoque> alimentos;
  final DateTime dataCriacao;

  GrupoAlimentos({
    required this.id,
    required this.nome,
    List<AlimentoEstoque>? alimentos,
    DateTime? dataCriacao,
  })  : alimentos = alimentos ?? [],
        dataCriacao = dataCriacao ?? DateTime.now();

  int get totalItens => alimentos.length;

  GrupoAlimentos copiarCom({
    String? nome,
    List<AlimentoEstoque>? alimentos,
  }) {
    return GrupoAlimentos(
      id:          id,
      nome:        nome ?? this.nome,
      alimentos:   alimentos ?? this.alimentos,
      dataCriacao: dataCriacao,
    );
  }
}