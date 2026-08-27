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
  final String validade;
  final String status;
  final bool entrarNaIA; // aparece nas sugestões da IA?

  const AlimentoEstoque({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.validade,
    required this.status,
    this.entrarNaIA = true,
  });

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

  //escolhe um icone com base em palavras-chave no nome do alimento
  //(nao depende mais de categoria, que foi removida do cadastro)
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