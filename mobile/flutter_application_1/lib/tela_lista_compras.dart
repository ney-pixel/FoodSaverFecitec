import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'lista_compras.dart';
import 'banco_dados.dart';
import 'alimento.dart';

class TelaListaCompras extends StatefulWidget {
  final Usuario usuario;
  const TelaListaCompras({super.key, required this.usuario});

  @override
  State<TelaListaCompras> createState() => _TelaListaComprasState();
}

class _TelaListaComprasState extends State<TelaListaCompras>
    with SingleTickerProviderStateMixin {
  late TabController _controladorSubabas;

  // Lista de compras
  final List<ItemListaCompras> _listaCompras = [];

  // Configurações de mínimos
  final List<ConfiguracaoMinimo> _minimos = [];

  // ── Lógica de itens faltantes ─────────────────
  // Percorre os mínimos e compara com o estoque atual
  List<ConfiguracaoMinimo> get _itensFaltantes {
    return _minimos.where((cfg) {
      // Busca o alimento no estoque pelo nome (sem distinção de maiúsculas)
      final alimentoNoEstoque = BancoDados.estoque.where((a) =>
          a.nome.toLowerCase() == cfg.nomeAlimento.toLowerCase()).toList();

      // Se não existe nenhum no estoque → faltante
      if (alimentoNoEstoque.isEmpty) return true;

      // Se a soma das quantidades é menor que o mínimo → faltante
      final totalEstoque = alimentoNoEstoque.fold<double>(
          0, (soma, a) => soma + a.quantidade);
      return totalEstoque < cfg.quantidadeMinima;
    }).toList();
  }

  // Adiciona todos os faltantes à lista de compras (evita duplicatas)
  void _adicionarTudoNaLista() {
    final faltantes = _itensFaltantes;
    if (faltantes.isEmpty) return;
    setState(() {
      for (final cfg in faltantes) {
        final jaExiste = _listaCompras.any(
            (i) => i.nome.toLowerCase() == cfg.nomeAlimento.toLowerCase());
        if (!jaExiste) {
          _listaCompras.add(ItemListaCompras(
            id:         DateTime.now().millisecondsSinceEpoch.toString(),
            nome:       cfg.nomeAlimento,
            quantidade: cfg.quantidadeMinima,
            unidade:    cfg.unidade,
          ));
        }
      }
    });
  }

  // Adiciona um único faltante à lista
  void _adicionarUmNaLista(ConfiguracaoMinimo cfg) {
    final jaExiste = _listaCompras.any(
        (i) => i.nome.toLowerCase() == cfg.nomeAlimento.toLowerCase());
    if (!jaExiste) {
      setState(() => _listaCompras.add(ItemListaCompras(
        id:         DateTime.now().millisecondsSinceEpoch.toString(),
        nome:       cfg.nomeAlimento,
        quantidade: cfg.quantidadeMinima,
        unidade:    cfg.unidade,
      )));
    }
  }

  @override
  void initState() {
    super.initState();
    _controladorSubabas = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controladorSubabas.dispose();
    super.dispose();
  }

  // ── Diálogos ─────────────────────────────────

  void _abrirDialogoAdicionarItem() {
    final ctrlNome = TextEditingController();
    final ctrlQtd  = TextEditingController();
    String unidade = unidadesMedida.first;
    String? erroNome, erroQtd;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Adicionar item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo('Nome do item', Icons.shopping_cart_outlined, ctrlNome, erro: erroNome),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 2, child: _campo('Quantidade', Icons.numbers_rounded, ctrlQtd, tipo: TextInputType.number, erro: erroQtd)),
              const SizedBox(width: 8),
              Expanded(child: _dropdown(unidade, unidadesMedida, (v) => setD(() => unidade = v!))),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                String? en, eq;
                if (ctrlNome.text.trim().isEmpty) en = 'Obrigatório';
                final qtd = double.tryParse(ctrlQtd.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) eq = 'Valor inválido';
                if (en != null || eq != null) {
                  setD(() { erroNome = en; erroQtd = eq; });
                  return;
                }
                setState(() => _listaCompras.add(ItemListaCompras(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nome: ctrlNome.text.trim(),
                  quantidade: qtd!,
                  unidade: unidade,
                )));
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoEditarItem(ItemListaCompras item) {
    final ctrlNome = TextEditingController(text: item.nome);
    final ctrlQtd  = TextEditingController(
        text: item.quantidade == item.quantidade.truncateToDouble()
            ? item.quantidade.toInt().toString()
            : item.quantidade.toString());
    String unidade = item.unidade;
    String? erroNome, erroQtd;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Editar item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo('Nome do item', Icons.shopping_cart_outlined, ctrlNome, erro: erroNome),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 2, child: _campo('Quantidade', Icons.numbers_rounded, ctrlQtd, tipo: TextInputType.number, erro: erroQtd)),
              const SizedBox(width: 8),
              Expanded(child: _dropdown(unidade, unidadesMedida, (v) => setD(() => unidade = v!))),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                String? en, eq;
                if (ctrlNome.text.trim().isEmpty) en = 'Obrigatório';
                final qtd = double.tryParse(ctrlQtd.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) eq = 'Valor inválido';
                if (en != null || eq != null) {
                  setD(() { erroNome = en; erroQtd = eq; });
                  return;
                }
                setState(() {
                  item.nome      = ctrlNome.text.trim();
                  item.quantidade = qtd!;
                  item.unidade   = unidade;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _excluirItem(ItemListaCompras item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover item?', style: TextStyle(color: Colors.white)),
        content: Text('"${item.nome}" será removido da lista.', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => _listaCompras.removeWhere((i) => i.id == item.id));
              Navigator.pop(ctx);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoAdicionarMinimo() {
    final ctrlNome = TextEditingController();
    final ctrlQtd  = TextEditingController();
    String unidade = unidadesMedida.first;
    String? erroNome, erroQtd;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Quantidade mínima', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Defina o mínimo que você sempre quer ter em estoque.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 14),
            _campo('Alimento (ex: Arroz)', Icons.fastfood_outlined, ctrlNome, erro: erroNome),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 2, child: _campo('Qtd. mínima', Icons.numbers_rounded, ctrlQtd, tipo: TextInputType.number, erro: erroQtd)),
              const SizedBox(width: 8),
              Expanded(child: _dropdown(unidade, unidadesMedida, (v) => setD(() => unidade = v!))),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                String? en, eq;
                if (ctrlNome.text.trim().isEmpty) en = 'Obrigatório';
                final qtd = double.tryParse(ctrlQtd.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) eq = 'Valor inválido';
                if (en != null || eq != null) {
                  setD(() { erroNome = en; erroQtd = eq; });
                  return;
                }
                setState(() => _minimos.add(ConfiguracaoMinimo(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nomeAlimento: ctrlNome.text.trim(),
                  quantidadeMinima: qtd!,
                  unidade: unidade,
                )));
                Navigator.pop(ctx);
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _excluirMinimo(ConfiguracaoMinimo cfg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover mínimo?', style: TextStyle(color: Colors.white)),
        content: Text('A configuração de "${cfg.nomeAlimento}" será removida.', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => _minimos.removeWhere((m) => m.id == cfg.id));
              Navigator.pop(ctx);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Bottom sheet: visualizar itens faltantes
  void _verItensFaltantes() {
    final faltantes = _itensFaltantes;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cartaoEscuro,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setB) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Itens faltantes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('${faltantes.length} item${faltantes.length != 1 ? 's' : ''} abaixo do mínimo',
                      style: const TextStyle(fontSize: 12, color: Colors.white38)),
                ]),
                if (faltantes.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _adicionarTudoNaLista();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: verdePrimario, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Adicionar tudo', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),

              if (faltantes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: verdePrimario.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: verdePrimario.withOpacity(0.2))),
                  child: const Row(children: [
                    Icon(Icons.check_circle_rounded, color: verdePrimario, size: 22),
                    SizedBox(width: 12),
                    Expanded(child: Text('Tudo em ordem! Nenhum alimento está abaixo do mínimo.', style: TextStyle(color: Colors.white70, fontSize: 13))),
                  ]),
                )
              else
                ...faltantes.map((cfg) {
                  // Quantidade real no estoque
                  final totalEstoque = BancoDados.estoque
                      .where((a) => a.nome.toLowerCase() == cfg.nomeAlimento.toLowerCase())
                      .fold<double>(0, (s, a) => s + a.quantidade);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFFF4444).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4444), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cfg.nomeAlimento, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          'Tem: ${totalEstoque == totalEstoque.truncateToDouble() ? totalEstoque.toInt() : totalEstoque} ${cfg.unidade}  ·  Mínimo: ${cfg.minimoFormatado}',
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ])),
                      GestureDetector(
                        onTap: () {
                          _adicionarUmNaLista(cfg);
                          setB(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: verdePrimario.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: verdePrimario.withOpacity(0.3)),
                          ),
                          child: const Text('+ Lista', style: TextStyle(color: verdePrimario, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets auxiliares de diálogo ─────────────

  Widget _campo(String hint, IconData icone, TextEditingController ctrl, {TextInputType tipo = TextInputType.text, String? erro}) =>
      TextField(
        controller: ctrl, keyboardType: tipo,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, errorText: erro,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(icone, color: verdePrimario, size: 18),
          filled: true, fillColor: const Color(0xFF1C1C1C),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: verdePrimario, width: 1.2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
          isDense: true,
        ),
      );

  Widget _dropdown(String valor, List<String> itens, void Function(String?) aoMudar) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(12), border: Border.all(color: bordaCartao)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: itens.contains(valor) ? valor : itens.first,
            dropdownColor: const Color(0xFF1C1C1C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: itens.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: aoMudar,
          ),
        ),
      );

  // ── Build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nComprados   = _listaCompras.where((i) => i.comprado).length;
    final nFaltantes   = _itensFaltantes.length;

    return Column(
      children: [
        cabecalhoPagina('Lista de Compras',
          acaoTopo: nFaltantes > 0
              ? GestureDetector(
                  onTap: _verItensFaltantes,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4444), size: 13),
                      const SizedBox(width: 5),
                      Text('$nFaltantes faltante${nFaltantes != 1 ? 's' : ''}',
                          style: const TextStyle(color: Color(0xFFFF4444), fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )
              : null,
        ),
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: bordaCartao, width: 0.5))),
          child: TabBar(
            controller: _controladorSubabas,
            indicatorColor: verdePrimario,
            labelColor: verdePrimario,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Lista'),
              Tab(text: 'Mínimos'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controladorSubabas,
            children: [
              // ── Subaba: Lista ──
              _SubabaLista(
                itens:             _listaCompras,
                nComprados:        nComprados,
                aoAdicionarItem:   _abrirDialogoAdicionarItem,
                aoEditarItem:      _abrirDialogoEditarItem,
                aoExcluirItem:     _excluirItem,
                aoVerFaltantes:    _verItensFaltantes,
                nFaltantes:        nFaltantes,
                aoAlternarComprado: (item) => setState(() => item.comprado = !item.comprado),
              ),
              // ── Subaba: Mínimos ──
              _SubabaMinimos(
                minimos:                _minimos,
                itensFaltantes:         _itensFaltantes,
                aoAdicionarMinimo:      _abrirDialogoAdicionarMinimo,
                aoExcluirMinimo:        _excluirMinimo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Subaba: Lista de Compras
// ─────────────────────────────────────────────
class _SubabaLista extends StatelessWidget {
  final List<ItemListaCompras> itens;
  final int nComprados;
  final int nFaltantes;
  final VoidCallback aoAdicionarItem;
  final VoidCallback aoVerFaltantes;
  final void Function(ItemListaCompras) aoEditarItem;
  final void Function(ItemListaCompras) aoExcluirItem;
  final void Function(ItemListaCompras) aoAlternarComprado;

  const _SubabaLista({
    required this.itens,
    required this.nComprados,
    required this.nFaltantes,
    required this.aoAdicionarItem,
    required this.aoVerFaltantes,
    required this.aoEditarItem,
    required this.aoExcluirItem,
    required this.aoAlternarComprado,
  });

  @override
  Widget build(BuildContext context) {
    final pendentes  = itens.where((i) => !i.comprado).toList();
    final comprados  = itens.where((i) => i.comprado).toList();

    return Column(
      children: [
        // Barra de ações
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            // Botão adicionar item manualmente
            Expanded(
              child: GestureDetector(
                onTap: aoAdicionarItem,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: verdePrimario, borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_rounded, color: Colors.black, size: 16),
                    SizedBox(width: 5),
                    Text('Adicionar item', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botão ver faltantes
            GestureDetector(
              onTap: aoVerFaltantes,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cartaoEscuro,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: nFaltantes > 0 ? const Color(0xFFFF4444).withOpacity(0.4) : bordaCartao),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded, color: nFaltantes > 0 ? const Color(0xFFFF4444) : Colors.white38, size: 15),
                  const SizedBox(width: 5),
                  Text('Ver faltantes', style: TextStyle(color: nFaltantes > 0 ? const Color(0xFFFF4444) : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),

        // Progresso
        if (itens.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(12), border: Border.all(color: bordaCartao)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$nComprados de ${itens.length} comprado${nComprados != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                  Text('${itens.isEmpty ? 0 : (nComprados / itens.length * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: verdePrimario)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: itens.isEmpty ? 0 : nComprados / itens.length,
                    backgroundColor: const Color(0xFF2A2A2A),
                    color: verdePrimario,
                    minHeight: 6,
                  ),
                ),
              ]),
            ),
          ),

        const SizedBox(height: 8),

        // Lista
        Expanded(
          child: itens.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.shopping_cart_outlined, color: verdePrimario, size: 32)),
                    const SizedBox(height: 16),
                    const Text('Lista vazia', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Adicione itens manualmente ou\nimporte os alimentos faltantes.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Pendentes
                    if (pendentes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('A comprar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38)),
                      ),
                      ...pendentes.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CartaoItemLista(item: item, aoEditar: aoEditarItem, aoExcluir: aoExcluirItem, aoAlternar: aoAlternarComprado),
                      )),
                    ],
                    // Comprados
                    if (comprados.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          const Text('Comprados', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: verdePrimario.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('${comprados.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: verdePrimario)),
                          ),
                        ]),
                      ),
                      ...comprados.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CartaoItemLista(item: item, aoEditar: aoEditarItem, aoExcluir: aoExcluirItem, aoAlternar: aoAlternarComprado),
                      )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// Cartão de item da lista
class _CartaoItemLista extends StatelessWidget {
  final ItemListaCompras item;
  final void Function(ItemListaCompras) aoEditar;
  final void Function(ItemListaCompras) aoExcluir;
  final void Function(ItemListaCompras) aoAlternar;

  const _CartaoItemLista({required this.item, required this.aoEditar, required this.aoExcluir, required this.aoAlternar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: item.comprado ? const Color(0xFF0F1A0F) : cartaoEscuro,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: item.comprado ? verdePrimario.withOpacity(0.15) : bordaCartao),
      ),
      child: Row(children: [
        // Checkbox
        GestureDetector(
          onTap: () => aoAlternar(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: item.comprado ? verdePrimario : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: item.comprado ? verdePrimario : Colors.white30, width: 1.5),
            ),
            child: item.comprado
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 15)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nome,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.comprado ? Colors.white38 : Colors.white,
                  decoration: item.comprado ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white38,
                )),
            const SizedBox(height: 2),
            Text(item.quantidadeFormatada, style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ]),
        ),
        // Editar
        GestureDetector(
          onTap: () => aoEditar(item),
          child: Container(
            width: 29, height: 29,
            decoration: BoxDecoration(color: verdePrimario.withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: verdePrimario.withOpacity(0.2))),
            child: const Icon(Icons.edit_outlined, size: 13, color: verdePrimario),
          ),
        ),
        const SizedBox(width: 6),
        // Excluir
        GestureDetector(
          onTap: () => aoExcluir(item),
          child: Container(
            width: 29, height: 29,
            decoration: BoxDecoration(color: const Color(0xFFFF4444).withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.2))),
            child: const Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFFF4444)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  Subaba: Mínimos
// ─────────────────────────────────────────────
class _SubabaMinimos extends StatelessWidget {
  final List<ConfiguracaoMinimo> minimos;
  final List<ConfiguracaoMinimo> itensFaltantes;
  final VoidCallback aoAdicionarMinimo;
  final void Function(ConfiguracaoMinimo) aoExcluirMinimo;

  const _SubabaMinimos({
    required this.minimos,
    required this.itensFaltantes,
    required this.aoAdicionarMinimo,
    required this.aoExcluirMinimo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botão adicionar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: GestureDetector(
            onTap: aoAdicionarMinimo,
            child: Container(
              width: double.infinity, height: 42,
              decoration: BoxDecoration(
                color: verdePrimario.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: verdePrimario.withOpacity(0.3)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_rounded, color: verdePrimario, size: 16),
                SizedBox(width: 6),
                Text('Definir quantidade mínima', style: TextStyle(color: verdePrimario, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),

        // Explicação
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: bordaCartao)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: Colors.white30, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text('Defina a quantidade mínima que você quer ter de cada alimento. O app vai comparar com seu estoque e avisar o que está faltando.', style: TextStyle(fontSize: 11, color: Colors.white38, height: 1.4))),
            ]),
          ),
        ),

        // Lista de mínimos
        Expanded(
          child: minimos.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.tune_rounded, color: verdePrimario, size: 32)),
                    const SizedBox(height: 16),
                    const Text('Nenhum mínimo configurado', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Adicione alimentos e quantidades mínimas\npara monitorar seu estoque.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: minimos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final cfg     = minimos[i];
                    final faltante = itensFaltantes.any((f) => f.id == cfg.id);

                    // Quantidade atual no estoque
                    final totalEstoque = BancoDados.estoque
                        .where((a) => a.nome.toLowerCase() == cfg.nomeAlimento.toLowerCase())
                        .fold<double>(0, (s, a) => s + a.quantidade);
                    final temNoEstoque = totalEstoque > 0;
                    final qtdTexto = temNoEstoque
                        ? '${totalEstoque == totalEstoque.truncateToDouble() ? totalEstoque.toInt() : totalEstoque} ${cfg.unidade} em estoque'
                        : 'Não encontrado no estoque';

                    return Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: cartaoEscuro,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: faltante
                                ? const Color(0xFFFF4444).withOpacity(0.25)
                                : verdePrimario.withOpacity(0.15)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: faltante ? const Color(0xFFFF4444).withOpacity(0.1) : verdePrimario.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            faltante ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            color: faltante ? const Color(0xFFFF4444) : verdePrimario,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cfg.nomeAlimento, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Mínimo: ${cfg.minimoFormatado}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                          const SizedBox(height: 1),
                          Text(qtdTexto, style: TextStyle(fontSize: 10, color: faltante ? const Color(0xFFFF4444) : verdePrimario)),
                        ])),
                        GestureDetector(
                          onTap: () => aoExcluirMinimo(cfg),
                          child: Container(
                            width: 29, height: 29,
                            decoration: BoxDecoration(color: const Color(0xFFFF4444).withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.2))),
                            child: const Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFFF4444)),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}