import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'lista_compras.dart';
import 'alimento.dart';
import 'api_cliente.dart';

// A API já sincroniza a lista de compras sozinha: toda vez que
// listar_compras.php é chamado, ela compara a quantidade mínima de
// cada alimento (FS_minimos_alimento, por nome — ver aba Mínimos) com o
// estoque atual e cria/remove automaticamente os itens "automáticos" da
// lista. Por isso não existe mais uma etapa client-side separada de
// "itens faltantes" — os itens automáticos já vêm prontos na própria
// lista, só marcados com um selo "Automático".
class TelaListaCompras extends StatefulWidget {
  final Usuario usuario;
  const TelaListaCompras({super.key, required this.usuario});

  @override
  State<TelaListaCompras> createState() => _TelaListaComprasState();
}

class _TelaListaComprasState extends State<TelaListaCompras>
    with SingleTickerProviderStateMixin {
  late TabController _controladorSubabas;
  int _abaAnterior = 0;

  bool _carregando = true;
  String? _erro;
  List<ItemListaCompras> _listaCompras = [];
  List<AlimentoEstoque> _estoque = [];
  List<MinimoAlimento> _minimos = [];

  @override
  void initState() {
    super.initState();
    _controladorSubabas = TabController(length: 2, vsync: this);
    _controladorSubabas.addListener(_aoTrocarSubaba);
    _carregarTudo();
  }

  @override
  void dispose() {
    _controladorSubabas.removeListener(_aoTrocarSubaba);
    _controladorSubabas.dispose();
    super.dispose();
  }

  // Toda vez que sai da aba "Mínimos" de volta pra "Lista", recarrega a
  // lista — definir/editar um mínimo pode ter mudado (ou criado/removido)
  // um item automático nela.
  void _aoTrocarSubaba() {
    final atual = _controladorSubabas.index;
    if (atual != _abaAnterior) {
      if (atual == 0 && _abaAnterior == 1) {
        _carregarLista();
      }
      _abaAnterior = atual;
    }
  }

  Future<void> _carregarTudo() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      await Future.wait([_carregarLista(), _carregarEstoque(), _carregarMinimos()]);
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

  Future<void> _carregarMinimos() async {
    final resp = await ApiCliente.get('/estoque/listar_minimos.php');
    final lista = (resp['minimos'] as List)
        .map((j) => MinimoAlimento.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _minimos = lista);
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: const Color(0xFFFF4444)),
    );
  }

  void _mostrarSucesso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: verdeEscuro),
    );
  }

  String _formatarIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

  // Só alterna a marcação de comprado — não mexe no estoque ainda. O
  // alimento só entra de fato no inventário quando o usuário confirma em
  // "Concluir" (ver _abrirDialogoConcluir), informando a validade.
  Future<void> _alternarComprado(ItemListaCompras item) async {
    setState(() => item.comprado = !item.comprado); // otimista
    try {
      await ApiCliente.patch('/compras/editar_compra.php', corpo: {'id': int.parse(item.id)});
    } on ApiException catch (e) {
      setState(() => item.comprado = !item.comprado); // desfaz
      _mostrarErro(e.mensagem);
    }
  }

  // ── Diálogo: concluir compras marcadas ────────────

  void _abrirDialogoConcluir() {
    final pendentes = _listaCompras.where((i) => i.comprado).toList();
    if (pendentes.isEmpty) {
      _mostrarErro('Marque ao menos um item como comprado para concluir.');
      return;
    }

    final validades = <String, DateTime?>{for (final i in pendentes) i.id: null};
    bool enviando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final faltam = validades.values.where((v) => v == null).length;
          return AlertDialog(
            backgroundColor: cartaoEscuro,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Concluir compras', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Informe a validade de cada item para adicioná-los ao seu estoque.',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pendentes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = pendentes[i];
                      final data = validades[item.id];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.nome, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              Text(item.quantidadeFormatada, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final agora = DateTime.now();
                              final escolhida = await showDatePicker(
                                context: ctx,
                                initialDate: data ?? agora,
                                firstDate: DateTime(agora.year - 1),
                                lastDate: DateTime(agora.year + 5),
                              );
                              if (escolhida != null) setD(() => validades[item.id] = escolhida);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: data != null ? verdePrimario.withOpacity(0.12) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: data != null ? verdePrimario.withOpacity(0.4) : Colors.white12),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.calendar_today_rounded, size: 13, color: data != null ? verdePrimario : Colors.white38),
                                const SizedBox(width: 6),
                                Text(
                                  data == null
                                      ? 'Validade'
                                      : '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data != null ? verdePrimario : Colors.white38),
                                ),
                              ]),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: verdePrimario,
                  disabledBackgroundColor: verdePrimario.withOpacity(0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (enviando || faltam > 0) ? null : () async {
                  setD(() => enviando = true);
                  try {
                    await ApiCliente.post('/compras/concluir_compras.php', corpo: {
                      'itens': pendentes.map((item) => {
                            'id': int.parse(item.id),
                            'validade': _formatarIso(validades[item.id]!),
                          }).toList(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _carregarTudo();
                    _mostrarSucesso(pendentes.length == 1
                        ? 'Item adicionado ao estoque!'
                        : '${pendentes.length} itens adicionados ao estoque!');
                  } on ApiException catch (e) {
                    setD(() => enviando = false);
                    _mostrarErro(e.mensagem);
                  }
                },
                child: enviando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(faltam > 0 ? 'Faltam $faltam' : 'Concluir', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Diálogo: quantidade mínima por alimento (por nome, não por lote —
  // pode ser um alimento que nem está no estoque ainda) ─────────

  void _abrirDialogoMinimo({MinimoAlimento? edicao}) {
    final ctrlNome = TextEditingController(text: edicao?.nome ?? '');
    final ctrlQtd = TextEditingController(
        text: edicao != null
            ? (edicao.quantidadeMinima == edicao.quantidadeMinima.truncateToDouble()
                ? edicao.quantidadeMinima.toInt().toString()
                : edicao.quantidadeMinima.toString())
            : '');
    String unidade = edicao?.unidade ?? unidadesMedida.first;
    String? erroNome, erroQtd;
    bool enviando = false;

    // Sugestões: nomes já usados no estoque que ainda não têm mínimo —
    // um atalho, mas o campo aceita qualquer nome digitado.
    final vistos = <String>{};
    final sugestoes = <AlimentoEstoque>[];
    if (edicao == null) {
      for (final a in _estoque) {
        final chave = a.nome.trim().toLowerCase();
        if (vistos.add(chave) &&
            !_minimos.any((m) => m.nome.trim().toLowerCase() == chave)) {
          sugestoes.add(a);
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(edicao == null ? 'Definir mínimo' : 'Editar mínimo',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Escolha o alimento — não precisa já estar no seu estoque.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              _campo('Nome do alimento', Icons.fastfood_outlined, ctrlNome, erro: erroNome),
              if (sugestoes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: sugestoes.take(8).map((a) => GestureDetector(
                    onTap: () => setD(() {
                      ctrlNome.text = a.nome;
                      unidade = a.unidade;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(20), border: Border.all(color: bordaCartao)),
                      child: Text(a.nome, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(flex: 2, child: _campo('Qtd. mínima', Icons.numbers_rounded, ctrlQtd, tipo: TextInputType.number, erro: erroQtd)),
                const SizedBox(width: 8),
                Expanded(child: _dropdown(unidade, unidadesMedida, (v) => setD(() => unidade = v!))),
              ]),
            ]),
          ),
          actions: [
            if (edicao != null)
              TextButton(
                onPressed: enviando ? null : () async {
                  setD(() => enviando = true);
                  try {
                    await ApiCliente.delete('/estoque/definir_minimo.php', corpo: {'id': int.parse(edicao.id)});
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _carregarMinimos();
                    await _carregarLista();
                  } on ApiException catch (e) {
                    setD(() { enviando = false; erroNome = e.mensagem; });
                  }
                },
                child: const Text('Remover', style: TextStyle(color: Color(0xFFFF4444))),
              ),
            TextButton(onPressed: enviando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
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
                  final corpo = <String, dynamic>{
                    'nome': ctrlNome.text.trim(),
                    'unidade': unidade,
                    'quantidade_minima': qtd,
                  };
                  if (edicao != null) corpo['id'] = int.parse(edicao.id);
                  await ApiCliente.post('/estoque/definir_minimo.php', corpo: corpo);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarMinimos();
                  await _carregarLista();
                } on ApiException catch (e) {
                  setD(() { enviando = false; erroNome = e.mensagem; });
                }
              },
              child: enviando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
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
                            aoConcluir:         _abrirDialogoConcluir,
                          ),
                          _SubabaMinimos(
                            minimos: _minimos,
                            aoNovoMinimo: () => _abrirDialogoMinimo(),
                            aoEditarMinimo: (m) => _abrirDialogoMinimo(edicao: m),
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
  final VoidCallback aoConcluir;

  const _SubabaLista({
    required this.itens,
    required this.nComprados,
    required this.aoAdicionarItem,
    required this.aoEditarItem,
    required this.aoExcluirItem,
    required this.aoAlternarComprado,
    required this.aoConcluir,
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

        // Só aparece quando há algo marcado como comprado: é o que
        // efetivamente joga a quantidade comprada pro estoque (pedindo a
        // validade de cada item antes).
        if (nComprados > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: GestureDetector(
              onTap: aoConcluir,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: verdePrimario,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: brilhoPrimario,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text('Concluir ($nComprados)',
                      style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800)),
                ]),
              ),
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
//  Subaba: Mínimos (por NOME de alimento — não precisa estar no estoque)
// ─────────────────────────────────────────────
class _SubabaMinimos extends StatelessWidget {
  final List<MinimoAlimento> minimos;
  final VoidCallback aoNovoMinimo;
  final void Function(MinimoAlimento) aoEditarMinimo;

  const _SubabaMinimos({required this.minimos, required this.aoNovoMinimo, required this.aoEditarMinimo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GestureDetector(
            onTap: aoNovoMinimo,
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: verdePrimario, borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_rounded, color: Colors.black, size: 16),
                SizedBox(width: 5),
                Text('Definir mínimo', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: bordaCartao)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: Colors.white30, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text('Escolha qualquer alimento, mesmo que ainda não esteja no seu estoque. Quando a quantidade ficar abaixo do mínimo, ele entra automaticamente na Lista de Compras.', style: TextStyle(fontSize: 11, color: Colors.white38, height: 1.4))),
            ]),
          ),
        ),
        Expanded(
          child: minimos.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.tune_rounded, color: verdePrimario, size: 32)),
                    const SizedBox(height: 16),
                    const Text('Nenhum mínimo definido ainda', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Toque em "Definir mínimo" e escolha\num alimento — do estoque ou não.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: minimos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = minimos[i];
                    final icone = AlimentoEstoque.iconePorNome(m.nome);

                    return GestureDetector(
                      onTap: () => aoEditarMinimo(m),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: cartaoEscuro,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: m.abaixoDoMinimo
                                  ? const Color(0xFFFF4444).withOpacity(0.25)
                                  : verdePrimario.withOpacity(0.15)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: m.abaixoDoMinimo ? const Color(0xFFFF4444).withOpacity(0.1) : verdePrimario.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              m.abaixoDoMinimo ? Icons.warning_amber_rounded : icone,
                              color: m.abaixoDoMinimo ? const Color(0xFFFF4444) : verdePrimario,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('Mínimo: ${m.minimoFormatado}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                            const SizedBox(height: 1),
                            Text('Estoque atual: ${m.atualFormatado}',
                                style: TextStyle(fontSize: 10, color: m.abaixoDoMinimo ? const Color(0xFFFF4444) : Colors.white38)),
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
