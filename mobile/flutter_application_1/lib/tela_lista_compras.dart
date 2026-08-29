import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'lista_compras.dart';
import 'alimento.dart';
import 'api_cliente.dart';

// A API já sincroniza a lista de compras sozinha: toda vez que
// listar_compras.php é chamado, ela compara a quantidade mínima de
// cada alimento (FS_alimentos_minimos) com o estoque atual e
// cria/remove automaticamente os itens "automáticos" da lista. Por
// isso não existe mais uma etapa client-side separada de "itens
// faltantes" — os itens automáticos já vêm prontos na própria lista,
// só marcados com um selo "Automático".
class TelaListaCompras extends StatefulWidget {
  final Usuario usuario;
  const TelaListaCompras({super.key, required this.usuario});

  @override
  State<TelaListaCompras> createState() => _TelaListaComprasState();
}

class _TelaListaComprasState extends State<TelaListaCompras>
    with SingleTickerProviderStateMixin {
  late TabController _controladorSubabas;

  bool _carregando = true;
  String? _erro;
  List<ItemListaCompras> _listaCompras = [];
  List<AlimentoEstoque> _estoque = [];

  @override
  void initState() {
    super.initState();
    _controladorSubabas = TabController(length: 2, vsync: this);
    _carregarTudo();
  }

  @override
  void dispose() {
    _controladorSubabas.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      await Future.wait([_carregarLista(), _carregarEstoque()]);
      setState(() => _carregando = false);
    } on ApiException catch (e) {
      setState(() { _carregando = false; _erro = e.mensagem; });
    }
  }

  Future<void> _carregarLista() async {
    final resp = await ApiCliente.get('/compras/listar_compras.php');
    final lista = (resp['lista_compras'] as List)
        .map((j) => ItemListaCompras.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _listaCompras = lista);
  }

  Future<void> _carregarEstoque() async {
    final resp = await ApiCliente.get('/estoque/listar_alimentos.php');
    final lista = (resp['alimentos'] as List)
        .map((j) => AlimentoEstoque.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _estoque = lista);
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: const Color(0xFFFF4444)),
    );
  }

  // ── Diálogos: item da lista ─────────────────────

  void _abrirDialogoAdicionarItem() {
    final ctrlNome = TextEditingController();
    final ctrlQtd  = TextEditingController();
    String unidade = unidadesMedida.first;
    String? erroNome, erroQtd;
    bool enviando = false;

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
              onPressed: enviando ? null : () async {
                String? en, eq;
                if (ctrlNome.text.trim().isEmpty) en = 'Obrigatório';
                final qtd = double.tryParse(ctrlQtd.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) eq = 'Valor inválido';
                if (en != null || eq != null) {
                  setD(() { erroNome = en; erroQtd = eq; });
                  return;
                }
                setD(() => enviando = true);
                try {
                  await ApiCliente.post('/compras/adicionar_compra.php', corpo: {
                    'nome_alimento': ctrlNome.text.trim(),
                    'quantidade': qtd,
                    'unidade': unidade,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarLista();
                } on ApiException catch (e) {
                  setD(() { enviando = false; erroNome = e.mensagem; });
                }
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
    bool enviando = false;

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
              onPressed: enviando ? null : () async {
                String? en, eq;
                if (ctrlNome.text.trim().isEmpty) en = 'Obrigatório';
                final qtd = double.tryParse(ctrlQtd.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) eq = 'Valor inválido';
                if (en != null || eq != null) {
                  setD(() { erroNome = en; erroQtd = eq; });
                  return;
                }
                setD(() => enviando = true);
                try {
                  await ApiCliente.post('/compras/editar_compra.php', corpo: {
                    'id': int.parse(item.id),
                    'nome_alimento': ctrlNome.text.trim(),
                    'quantidade': qtd,
                    'unidade': unidade,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarLista();
                } on ApiException catch (e) {
                  setD(() { enviando = false; erroNome = e.mensagem; });
                }
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiCliente.delete('/compras/editar_compra.php', corpo: {'id': int.parse(item.id)});
                await _carregarLista();
              } on ApiException catch (e) {
                _mostrarErro(e.mensagem);
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _alternarComprado(ItemListaCompras item) async {
    final ficouComprado = !item.comprado;
    setState(() => item.comprado = !item.comprado); // otimista
    try {
      await ApiCliente.patch('/compras/editar_compra.php', corpo: {'id': int.parse(item.id)});
      // Marcar como comprado soma a quantidade no estoque (ou cria o item lá);
      // recarrega o estoque para essa tela já refletir isso.
      if (ficouComprado) await _carregarEstoque();
    } on ApiException catch (e) {
      setState(() => item.comprado = !item.comprado); // desfaz
      _mostrarErro(e.mensagem);
    }
  }

  // ── Diálogo: quantidade mínima de um alimento do estoque ─────────

  void _abrirDialogoMinimo(AlimentoEstoque item) {
    final ctrl = TextEditingController(
        text: item.quantidadeMinima != null
            ? (item.quantidadeMinima! == item.quantidadeMinima!.truncateToDouble()
                ? item.quantidadeMinima!.toInt().toString()
                : item.quantidadeMinima.toString())
            : '');
    String? erro;
    bool enviando = false;

    Future<void> salvar(String? valorMinimo) async {
      final corpo = <String, dynamic>{
        'id': int.parse(item.id),
        'nome': item.nome,
        'quantidade': item.quantidade,
        'unidade': item.unidade,
        'validade': item.validade,
        'quantidade_minima': valorMinimo,
      };
      await ApiCliente.post('/estoque/editar_alimento.php', corpo: corpo);
      await _carregarEstoque();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Mínimo — ${item.nome}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Estoque atual: ${item.quantidadeFormatada}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),
            _campo('Qtd. mínima (${item.unidade})', Icons.warning_amber_rounded, ctrl, tipo: TextInputType.number, erro: erro),
          ]),
          actions: [
            if (item.quantidadeMinima != null)
              TextButton(
                onPressed: enviando ? null : () async {
                  setD(() => enviando = true);
                  try {
                    await salvar('');
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on ApiException catch (e) {
                    setD(() { enviando = false; erro = e.mensagem; });
                  }
                },
                child: const Text('Remover mínimo', style: TextStyle(color: Color(0xFFFF4444))),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: enviando ? null : () async {
                final valor = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
                if (valor == null || valor <= 0) {
                  setD(() => erro = 'Valor inválido');
                  return;
                }
                setD(() => enviando = true);
                try {
                  await salvar(valor.toString());
                  if (ctx.mounted) Navigator.pop(ctx);
                } on ApiException catch (e) {
                  setD(() { enviando = false; erro = e.mensagem; });
                }
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
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
    final nComprados = _listaCompras.where((i) => i.comprado).length;
    final nAutomaticos = _listaCompras.where((i) => i.automatico && !i.comprado).length;

    return Column(
      children: [
        cabecalhoPagina('Lista de Compras',
          acaoTopo: nAutomaticos > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4444), size: 13),
                    const SizedBox(width: 5),
                    Text('$nAutomaticos abaixo do mínimo',
                        style: const TextStyle(color: Color(0xFFFF4444), fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
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
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: verdePrimario))
              : _erro != null
                  ? _telaErro(_erro!, _carregarTudo)
                  : RefreshIndicator(
                      color: verdePrimario,
                      backgroundColor: cartaoEscuro,
                      onRefresh: _carregarTudo,
                      child: TabBarView(
                        controller: _controladorSubabas,
                        children: [
                          _SubabaLista(
                            itens:              _listaCompras,
                            nComprados:         nComprados,
                            aoAdicionarItem:    _abrirDialogoAdicionarItem,
                            aoEditarItem:       _abrirDialogoEditarItem,
                            aoExcluirItem:      _excluirItem,
                            aoAlternarComprado: _alternarComprado,
                          ),
                          _SubabaMinimos(
                            estoque: _estoque,
                            aoDefinirMinimo: _abrirDialogoMinimo,
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _telaErro(String mensagem, Future<void> Function() aoTentar) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: aoTentar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: verdePrimario, borderRadius: BorderRadius.circular(10)),
                child: const Text('Tentar novamente', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────
//  Subaba: Lista de Compras
// ─────────────────────────────────────────────
class _SubabaLista extends StatelessWidget {
  final List<ItemListaCompras> itens;
  final int nComprados;
  final VoidCallback aoAdicionarItem;
  final void Function(ItemListaCompras) aoEditarItem;
  final void Function(ItemListaCompras) aoExcluirItem;
  final void Function(ItemListaCompras) aoAlternarComprado;

  const _SubabaLista({
    required this.itens,
    required this.nComprados,
    required this.aoAdicionarItem,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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

        Expanded(
          child: itens.isEmpty
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 72, height: 72, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.shopping_cart_outlined, color: verdePrimario, size: 32)),
                      const SizedBox(height: 16),
                      const Text('Lista vazia', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      const Text('Adicione itens manualmente ou\nconfigure mínimos na aba "Mínimos".', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ]),
                  ),
                ])
              : ListView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
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
            Row(children: [
              Flexible(child: Text(item.nome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.comprado ? Colors.white38 : Colors.white,
                    decoration: item.comprado ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white38,
                  ))),
              if (item.automatico) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFFF4444).withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                  child: const Text('Automático', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFFFF4444))),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text(item.quantidadeFormatada, style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ]),
        ),
        GestureDetector(
          onTap: () => aoEditar(item),
          child: Container(
            width: 29, height: 29,
            decoration: BoxDecoration(color: verdePrimario.withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: verdePrimario.withOpacity(0.2))),
            child: const Icon(Icons.edit_outlined, size: 13, color: verdePrimario),
          ),
        ),
        const SizedBox(width: 6),
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
//  Subaba: Mínimos (por alimento do estoque)
// ─────────────────────────────────────────────
class _SubabaMinimos extends StatelessWidget {
  final List<AlimentoEstoque> estoque;
  final void Function(AlimentoEstoque) aoDefinirMinimo;

  const _SubabaMinimos({required this.estoque, required this.aoDefinirMinimo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: bordaCartao)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: Colors.white30, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text('Defina a quantidade mínima de cada alimento do seu estoque. Quando ficar abaixo do mínimo, ele entra automaticamente na Lista de Compras.', style: TextStyle(fontSize: 11, color: Colors.white38, height: 1.4))),
            ]),
          ),
        ),
        Expanded(
          child: estoque.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.tune_rounded, color: verdePrimario, size: 32)),
                    const SizedBox(height: 16),
                    const Text('Seu estoque está vazio', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Cadastre alimentos na aba Estoque\npara definir mínimos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: estoque.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = estoque[i];
                    final temMinimo = item.quantidadeMinima != null;
                    final faltante = temMinimo && item.quantidade < item.quantidadeMinima!;

                    return GestureDetector(
                      onTap: () => aoDefinirMinimo(item),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: cartaoEscuro,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: faltante
                                  ? const Color(0xFFFF4444).withOpacity(0.25)
                                  : (temMinimo ? verdePrimario.withOpacity(0.15) : bordaCartao)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: faltante ? const Color(0xFFFF4444).withOpacity(0.1) : verdePrimario.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              faltante ? Icons.warning_amber_rounded : (temMinimo ? Icons.check_circle_outline_rounded : Icons.tune_rounded),
                              color: faltante ? const Color(0xFFFF4444) : verdePrimario,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                              temMinimo ? 'Mínimo: ${item.quantidadeMinima} ${item.unidade}' : 'Sem mínimo definido',
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                            const SizedBox(height: 1),
                            Text('Estoque atual: ${item.quantidadeFormatada}', style: TextStyle(fontSize: 10, color: faltante ? const Color(0xFFFF4444) : Colors.white38)),
                          ])),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
