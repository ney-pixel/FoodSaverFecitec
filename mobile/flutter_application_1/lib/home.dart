import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'estoque.dart';
import 'receitas.dart';
import 'relatorios.dart';
import 'tela_lista_compras.dart';
import 'config.dart';

class TelaHome extends StatefulWidget {
  final Usuario usuario;
  const TelaHome({super.key, required this.usuario});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome>
    with SingleTickerProviderStateMixin {
  int _abaAtual = 0;

  late final AnimationController _controladorFade;
  late final Animation<double>   _animacaoFade;

  @override
  void initState() {
    super.initState();
    _controladorFade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
    _animacaoFade =
        CurvedAnimation(parent: _controladorFade, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controladorFade.dispose();
    super.dispose();
  }

  void _trocarAba(int indice) {
    if (indice == _abaAtual) return;
    setState(() => _abaAtual = indice);
    _controladorFade.forward(from: 0);
  }

  // Abas: ícone ativo, ícone inativo, rótulo
  static const _itensNavegacao = [
    (Icons.inventory_2_rounded,          Icons.inventory_2_outlined,          'Estoque'),
    (Icons.restaurant_menu_rounded,      Icons.restaurant_menu_outlined,      'Receitas'),
    (Icons.shopping_cart_rounded,        Icons.shopping_cart_outlined,        'Compras'),
    (Icons.bar_chart_rounded,            Icons.bar_chart_outlined,            'Relatórios'),
    (Icons.settings_rounded,             Icons.settings_outlined,             'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    final paginas = [
      TelaEstoque(usuario: widget.usuario),
      TelaReceitas(usuario: widget.usuario),
      TelaListaCompras(usuario: widget.usuario),
      TelaRelatorios(usuario: widget.usuario),
      TelaConfig(usuario: widget.usuario),
    ];

    return Scaffold(
      backgroundColor: fundoEscuro,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animacaoFade,
          child: paginas[_abaAtual],
        ),
      ),
      bottomNavigationBar: Container(
        height: 62,
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          border: Border(top: BorderSide(color: bordaCartao, width: 0.5)),
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _itensNavegacao.asMap().entries.map((entrada) {
            final indice = entrada.key;
            final (iconeAtivo, iconeInativo, rotulo) = entrada.value;
            final sel = _abaAtual == indice;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _trocarAba(indice),
                borderRadius: BorderRadius.circular(10),
                splashColor: verdePrimario.withOpacity(0.12),
                highlightColor: verdePrimario.withOpacity(0.06),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? verdePrimario.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sel ? iconeAtivo : iconeInativo,
                          color: sel ? verdePrimario : Colors.white30, size: 20),
                      const SizedBox(height: 2),
                      Text(rotulo,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: sel ? verdePrimario : Colors.white30,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}