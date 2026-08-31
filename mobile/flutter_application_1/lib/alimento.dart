import 'package:flutter/material.dart';

//unidades de mdidas disponivveis
const List<String> unidadesMedida = [
  'g', 'kg', 'ml', 'L', 'unid.', 'cx.', 'pct.', 'porção',
];

class AlimentoEstoque {
  final String id;
  final String nome;
  final double quantidade;
  final String unidade;
  final String validade; // formato ISO (yyyy-MM-dd), como vem da API
  final int diasValidade;
  final String status; // 'Urgente' | 'Atenção' | 'OK' (derivado de classe_validade)
  final String textoValidade; // ex: "Vence em 3 dia(s)" / "Vencido há 2 dia(s)"

  const AlimentoEstoque({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.validade,
    this.diasValidade = 0,
    required this.status,
    this.textoValidade = '',
  });

  //monta um AlimentoEstoque a partir do JSON de estoque/listar_alimentos.php
  factory AlimentoEstoque.fromJson(Map<String, dynamic> json) {
    return AlimentoEstoque(
      id: '${json['id']}',
      nome: json['nome'] as String,
      quantidade: (json['quantidade'] as num).toDouble(),
      unidade: json['unidade'] as String,
      validade: json['validade'] as String,
      diasValidade: (json['dias_validade'] as num?)?.toInt() ?? 0,
      status: _statusDeClasse(json['classe_validade'] as String?),
      textoValidade: (json['texto_validade'] as String?) ?? '',
    );
  }

  static String _statusDeClasse(String? classe) {
    switch (classe) {
      case 'danger':
        return 'Urgente';
      case 'warning':
        return 'Atenção';
      default:
        return 'OK';
    }
  }

  //aqui defininfo a cor correspondente ao status
  Color get corStatus {
    switch (status) {
      case 'Urgente': return const Color(0xFFFF4444);
      case 'Atenção': return const Color(0xFFFFA726);
      default:        return const Color(0xFF16DB65);
    }
  }

  //aqui tira o .0 qunado é inteiro
  String get quantidadeFormatada {
    final v = quantidade == quantidade.truncateToDouble()
        ? quantidade.toInt().toString()
        : quantidade.toString();
    return '$v $unidade';
  }

  //converte a validade ISO (yyyy-MM-dd) pra dd/mm/yyyy, usado ao editar
  String get validadeFormatadaBr {
    final partes = validade.split('-');
    if (partes.length != 3) return validade;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  //escolhe um icone com base em palavras-chave no nome do alimento
  static IconData iconePorNome(String nome) {
    final n = nome.toLowerCase();
    const mapa = <List<String>, IconData>{
      ['frango', 'carne', 'peixe', 'peito', 'file', 'linguiça', 'bacon', 'presunto', 'ovo']: Icons.set_meal_rounded,
      ['leite', 'queijo', 'iogurte', 'manteiga', 'requeijão', 'nata']: Icons.water_drop_outlined,
      ['maçã', 'maca', 'banana', 'limão', 'limao', 'laranja', 'uva', 'morango', 'fruta', 'melancia', 'abacaxi', 'pera']: Icons.eco_outlined,
      ['cenoura', 'batata', 'cebola', 'alho', 'tomate', 'alface', 'verdura', 'legume', 'pimentão', 'brócolis', 'couve']: Icons.grass_rounded,
      ['pão', 'pao', 'macarrão', 'macarrao', 'massa', 'bolo', 'biscoito', 'torrada']: Icons.bakery_dining_rounded,
      ['congelado', 'sorvete', 'gelo']: Icons.ac_unit_rounded,
      ['lata', 'enlatado', 'conserva']: Icons.inventory_2_outlined,
      ['doce', 'chocolate', 'sobremesa', 'açúcar', 'acucar']: Icons.cake_outlined,
      ['suco', 'refrigerante', 'água', 'agua', 'bebida', 'cerveja', 'vinho', 'café', 'cafe']: Icons.local_drink_outlined,
      ['tempero', 'molho', 'sal', 'pimenta', 'condimento', 'azeite', 'óleo', 'oleo', 'vinagre']: Icons.spa_outlined,
      ['snack', 'salgadinho', 'petisco', 'pipoca']: Icons.cookie_outlined,
      ['arroz', 'feijão', 'feijao', 'grão', 'grao', 'cereal', 'aveia', 'farinha']: Icons.grain_rounded,
    };
    for (final entrada in mapa.entries) {
      if (entrada.key.any((palavra) => n.contains(palavra))) return entrada.value;
    }
    return Icons.fastfood_outlined;
  }
}

// Quantidade mínima definida por NOME de alimento (não por lote/id do estoque)
class MinimoAlimento {
  final String id;
  final String nome;
  final String unidade;
  final double quantidadeMinima;
  final double quantidadeAtual; // soma de todos os lotes desse nome no estoque
  final bool abaixoDoMinimo;

  const MinimoAlimento({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.quantidadeMinima,
    required this.quantidadeAtual,
    required this.abaixoDoMinimo,
  });

  factory MinimoAlimento.fromJson(Map<String, dynamic> json) {
    return MinimoAlimento(
      id: '${json['id']}',
      nome: json['nome_alimento'] as String,
      unidade: json['unidade_medida'] as String,
      quantidadeMinima: (json['quantidade_minima'] as num).toDouble(),
      quantidadeAtual: (json['quantidade_atual'] as num).toDouble(),
      abaixoDoMinimo: json['abaixo_do_minimo'] == true,
    );
  }

  String _fmt(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  String get minimoFormatado => '${_fmt(quantidadeMinima)} $unidade';
  String get atualFormatado => '${_fmt(quantidadeAtual)} $unidade';
}
