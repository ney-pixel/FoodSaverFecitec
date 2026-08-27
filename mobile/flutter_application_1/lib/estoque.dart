import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'alimento.dart';
import 'grupo.dart';
import 'banco_dados.dart';

class TelaEstoque extends StatefulWidget {
  final Usuario usuario;
  const TelaEstoque({super.key, required this.usuario});
  @override
  State<TelaEstoque> createState() => _TelaEstoqueState();
}

class _TelaEstoqueState extends State<TelaEstoque>
    with SingleTickerProviderStateMixin {
  late TabController _controladorSubabas;
  final _controladorBusca = TextEditingController();
  String _textoBusca      = '';
  int _indiceFiltroStatus = 0;    

  List<AlimentoEstoque> get _estoque => BancoDados.estoque;
  final List<GrupoAlimentos> _grupos = [];

  static const _rotulosStatus = ['Todos', 'Urgente', 'Atenção', 'OK'];
  static const _coresStatus   = [
    Colors.white54,
    Color(0xFFFF4444),
    Color(0xFFFFA726),
    verdePrimario,
  ];

  List<AlimentoEstoque> get _alimentosFiltrados {
    var lista = _indiceFiltroStatus == 0
        ? _estoque
        : _estoque
            .where((a) => a.status == _rotulosStatus[_indiceFiltroStatus])
            .toList();
    if (_textoBusca.isNotEmpty) {
      final b = _textoBusca.toLowerCase();
      lista = lista
          .where((a) => a.nome.toLowerCase().contains(b))
          .toList();
    }
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _controladorSubabas = TabController(length: 2, vsync: this);
    _controladorBusca
        .addListener(() => setState(() => _textoBusca = _controladorBusca.text));
  }

  @override
  void dispose() {
    _controladorSubabas.dispose();
    _controladorBusca.dispose();
    super.dispose();
  }

  //dialogue para adicionar
  void _abrirDialogoAdicionarAlimento({AlimentoEstoque? edicao}) {
    final ctrlNome       = TextEditingController(text: edicao?.nome ?? '');
    final ctrlQuantidade = TextEditingController(
        text: edicao != null
            ? (edicao.quantidade == edicao.quantidade.truncateToDouble()
                ? edicao.quantidade.toInt().toString()
                : edicao.quantidade.toString())
            : '');
    final ctrlValidade = TextEditingController(text: edicao?.validade ?? '');

    String unidadeSelecionada   = edicao?.unidade   ?? unidadesMedida.first;
    bool entrarNaIA             = edicao?.entrarNaIA ?? true;
    String? erroNome, erroQtd, erroVal;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            edicao == null ? 'Novo alimento' : 'Editar alimento',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _campoDialog('Nome do alimento', Icons.fastfood_outlined, ctrlNome, erro: erroNome),
                  const SizedBox(height: 14),
                  _rotuloDialog('Quantidade'),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(flex: 2, child: _campoDialog('Ex: 500', Icons.numbers_rounded, ctrlQuantidade, tipo: TextInputType.number, erro: erroQtd)),
                    const SizedBox(width: 8),
                    Expanded(child: _dropdownDialog(valor: unidadeSelecionada, itens: unidadesMedida, aoMudar: (v) => setD(() => unidadeSelecionada = v!))),
                  ]),
                  const SizedBox(height: 14),
                  _campoDialog('Validade (dd/mm)', Icons.calendar_today_rounded, ctrlValidade, erro: erroVal),
                  const SizedBox(height: 14),
                  _switchIA(entrarNaIA, () => setD(() => entrarNaIA = !entrarNaIA)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                String? en, eq, ev;
                if (ctrlNome.text.trim().isEmpty) en = 'Obrigatório';
                final qtd = double.tryParse(ctrlQuantidade.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) eq = 'Valor inválido';
                if (ctrlValidade.text.trim().isEmpty) ev = 'Obrigatório';
                if (en != null || eq != null || ev != null) {
                  setD(() { erroNome = en; erroQtd = eq; erroVal = ev; });
                  return;
                }
                setState(() {
                  if (edicao == null) {
                    BancoDados.estoque.add(AlimentoEstoque(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nome: ctrlNome.text.trim(),
                      quantidade: qtd!,
                      unidade: unidadeSelecionada,
                      validade: ctrlValidade.text.trim(),
                      status: 'OK',
                      entrarNaIA: entrarNaIA,
                    ));
                  } else {
                    final idx = BancoDados.estoque.indexWhere((a) => a.id == edicao.id);
                    if (idx >= 0) {
                      BancoDados.estoque[idx] = AlimentoEstoque(
                        id: edicao.id,
                        nome: ctrlNome.text.trim(),
                        quantidade: qtd!,
                        unidade: unidadeSelecionada,
                        validade: ctrlValidade.text.trim(),
                        status: edicao.status,
                        entrarNaIA: entrarNaIA,
                      );
                    }
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(edicao == null ? 'Adicionar' : 'Salvar', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(AlimentoEstoque item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir alimento?', style: TextStyle(color: Colors.white)),
        content: Text('"${item.nome}" será removido do estoque.', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => BancoDados.estoque.removeWhere((a) => a.id == item.id));
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoCriarGrupo() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Novo Grupo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dê um nome ao grupo.\nEx: "Janta do dia 15/06"', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nome do grupo...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1C1C1C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: verdePrimario, width: 1.2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final nome = ctrl.text.trim();
              if (nome.isNotEmpty) setState(() => _grupos.add(GrupoAlimentos(id: DateTime.now().millisecondsSinceEpoch.toString(), nome: nome)));
              Navigator.pop(ctx);
            },
            child: const Text('Criar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoAdicionarAoGrupo(GrupoAlimentos grupo) {
    final selecionados = List<bool>.generate(_estoque.length, (i) => grupo.alimentos.any((g) => g.id == _estoque[i].id));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(grupo.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _estoque.length,
              itemBuilder: (_, i) => CheckboxListTile(
                value: selecionados[i],
                onChanged: (v) => setD(() => selecionados[i] = v ?? false),
                activeColor: verdePrimario,
                checkColor: Colors.black,
                title: Text(_estoque[i].nome, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(_estoque[i].quantidadeFormatada, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final escolhidos = [for (int i = 0; i < _estoque.length; i++) if (selecionados[i]) _estoque[i]];
                setState(() {
                  final idx = _grupos.indexWhere((g) => g.id == grupo.id);
                  if (idx >= 0) _grupos[idx] = grupo.copiarCom(alimentos: escolhidos);
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

  void _excluirGrupo(GrupoAlimentos grupo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir grupo?', style: TextStyle(color: Colors.white)),
        content: Text('O grupo "${grupo.nome}" será removido.', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => _grupos.removeWhere((g) => g.id == grupo.id));
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

 
  Widget _campoDialog(String hint, IconData icone, TextEditingController ctrl, {TextInputType tipo = TextInputType.text, String? erro}) =>
      TextField(
        controller: ctrl,
        keyboardType: tipo,
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

  Widget _rotuloDialog(String t) => Text(t, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600));

  Widget _dropdownDialog({required String valor, required List<String> itens, required void Function(String?) aoMudar}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(12), border: Border.all(color: bordaCartao)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: itens.contains(valor) ? valor : itens.first,
            dropdownColor: const Color(0xFF1C1C1C),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: itens.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: aoMudar,
          ),
        ),
      );

  Widget _switchIA(bool ativo, VoidCallback aoAlternar) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ativo ? verdePrimario.withOpacity(0.3) : bordaCartao),
        ),
        child: Row(children: [
          Icon(Icons.auto_awesome_rounded, color: ativo ? verdePrimario : Colors.white38, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sugerir em receitas IA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ativo ? Colors.white : Colors.white54)),
              const SizedBox(height: 1),
              const Text('Aparece nas sugestões automáticas', style: TextStyle(fontSize: 10, color: Colors.white30)),
            ]),
          ),
          GestureDetector(
            onTap: aoAlternar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 22,
              decoration: BoxDecoration(color: ativo ? verdePrimario : const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(11)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: ativo ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        cabecalhoPagina('Estoque',
          acaoTopo: GestureDetector(
            onTap: () => _abrirDialogoAdicionarAlimento(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: verdePrimario, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.add_rounded, color: Colors.black, size: 15),
                SizedBox(width: 4),
                Text('Adicionar', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: bordaCartao, width: 0.5))),
          child: TabBar(
            controller: _controladorSubabas,
            indicatorColor: verdePrimario,
            labelColor: verdePrimario,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Alimentos'), Tab(text: 'Grupos')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controladorSubabas,
            children: [
              _SubabaAlimentos(
                alimentos:          _alimentosFiltrados,
                totalEstoque:       _estoque,
                indiceFiltroStatus: _indiceFiltroStatus,
                rotulosStatus:      _rotulosStatus,
                coresStatus:        _coresStatus,
                controladorBusca:   _controladorBusca,
                aoMudarStatus:      (i) => setState(() => _indiceFiltroStatus = i),
                aoEditar:           (a) => _abrirDialogoAdicionarAlimento(edicao: a),
                aoExcluir:          _confirmarExclusao,
              ),
              _SubabaGrupos(
                grupos:                    _grupos,
                aoCriarGrupo:              _abrirDialogoCriarGrupo,
                aoAdicionarAlimentosGrupo: _abrirDialogoAdicionarAoGrupo,
                aoExcluirGrupo:            _excluirGrupo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//subaba de alimnetos
class _SubabaAlimentos extends StatelessWidget {
  final List<AlimentoEstoque> alimentos;
  final List<AlimentoEstoque> totalEstoque;
  final int indiceFiltroStatus;
  final List<String> rotulosStatus;
  final List<Color> coresStatus;
  final TextEditingController controladorBusca;
  final void Function(int) aoMudarStatus;
  final void Function(AlimentoEstoque) aoEditar;
  final void Function(AlimentoEstoque) aoExcluir;

  const _SubabaAlimentos({
    required this.alimentos,
    required this.totalEstoque,
    required this.indiceFiltroStatus,
    required this.rotulosStatus,
    required this.coresStatus,
    required this.controladorBusca,
    required this.aoMudarStatus,
    required this.aoEditar,
    required this.aoExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final nU = totalEstoque.where((a) => a.status == 'Urgente').length;
    final nA = totalEstoque.where((a) => a.status == 'Atenção').length;
    final nO = totalEstoque.where((a) => a.status == 'OK').length;

    return Column(
      children: [
        // Busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(10), border: Border.all(color: bordaCartao)),
            child: Row(children: [
              const SizedBox(width: 12),
              const Icon(Icons.search_rounded, color: Colors.white30, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controladorBusca,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Buscar alimento...', hintStyle: TextStyle(color: Colors.white30, fontSize: 13), border: InputBorder.none, isDense: true),
                ),
              ),
              if (controladorBusca.text.isNotEmpty)
                GestureDetector(
                  onTap: () => controladorBusca.clear(),
                  child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, color: Colors.white38, size: 16)),
                ),
            ]),
          ),
        ),

        // Estatísticas
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(12), border: Border.all(color: bordaCartao)),
          child: Row(children: [
            _estat('$nU', 'Urgente', const Color(0xFFFF4444)),
            _div(), _estat('$nA', 'Atenção', const Color(0xFFFFA726)),
            _div(), _estat('$nO', 'Em dia', verdePrimario),
            _div(), _estat('${totalEstoque.length}', 'Total', Colors.white54),
          ]),
        ),

        //filtarr por status
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: rotulosStatus.asMap().entries.map((e) {
              final sel = indiceFiltroStatus == e.key;
              final cor = coresStatus[e.key];
              return GestureDetector(
                onTap: () => aoMudarStatus(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: e.key < rotulosStatus.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? cor.withOpacity(0.15) : cartaoEscuro,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? cor.withOpacity(0.5) : bordaCartao),
                  ),
                  child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? cor : Colors.white38)),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: alimentos.isEmpty
              ? _vazio(controladorBusca.text)
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: alimentos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CartaoAlimento(item: alimentos[i], aoEditar: aoEditar, aoExcluir: aoExcluir),
                ),
        ),
      ],
    );
  }

  Widget _vazio(String busca) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(busca.isNotEmpty ? 'Nenhum resultado para\n"$busca"' : 'Nenhum alimento nesse filtro',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ]),
      );

  Widget _estat(String v, String l, Color c) => Expanded(
        child: Column(children: [
          Text(v, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 1),
          Text(l, style: const TextStyle(fontSize: 9, color: Colors.white38)),
        ]),
      );

  Widget _div() => Container(width: 0.5, height: 26, color: bordaCartao);
}

//cartao do aliimento
class _CartaoAlimento extends StatelessWidget {
  final AlimentoEstoque item;
  final void Function(AlimentoEstoque) aoEditar;
  final void Function(AlimentoEstoque) aoExcluir;

  const _CartaoAlimento({required this.item, required this.aoEditar, required this.aoExcluir});

  @override
  Widget build(BuildContext context) {
    final icone = AlimentoEstoque.iconePorNome(item.nome);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cartaoEscuro,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: item.status == 'Urgente' ? const Color(0xFFFF4444).withOpacity(0.2) : bordaCartao),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: item.corStatus.withOpacity(0.08), borderRadius: BorderRadius.circular(11)),
          child: Icon(icone, color: item.corStatus.withOpacity(0.7), size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(item.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: item.corStatus.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(item.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: item.corStatus)),
              ),
            ]),
            const SizedBox(height: 3),
            Text(item.quantidadeFormatada, style: const TextStyle(fontSize: 11, color: Colors.white38)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 10, color: item.corStatus.withOpacity(0.7)),
              const SizedBox(width: 3),
              Text('Vence ${item.validade}', style: TextStyle(fontSize: 10, color: item.corStatus.withOpacity(0.85), fontWeight: FontWeight.w500)),
              if (item.entrarNaIA) ...[
                const SizedBox(width: 8),
                const Icon(Icons.auto_awesome_rounded, size: 10, color: Colors.white24),
              ],
            ]),
          ]),
        ),
        Column(children: [
          GestureDetector(
            onTap: () => aoEditar(item),
            child: _acao(Icons.edit_outlined, verdePrimario),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => aoExcluir(item),
            child: _acao(Icons.delete_outline_rounded, const Color(0xFFFF4444)),
          ),
        ]),
      ]),
    );
  }

  Widget _acao(IconData icone, Color cor) => Container(
        width: 29, height: 29,
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: cor.withOpacity(0.2))),
        child: Icon(icone, size: 13, color: cor));
}

//subaba grupos
class _SubabaGrupos extends StatelessWidget {
  final List<GrupoAlimentos> grupos;
  final VoidCallback aoCriarGrupo;
  final void Function(GrupoAlimentos) aoAdicionarAlimentosGrupo;
  final void Function(GrupoAlimentos) aoExcluirGrupo;

  const _SubabaGrupos({required this.grupos, required this.aoCriarGrupo, required this.aoAdicionarAlimentosGrupo, required this.aoExcluirGrupo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: GestureDetector(
            onTap: aoCriarGrupo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: verdePrimario.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: verdePrimario.withOpacity(0.3))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.create_new_folder_outlined, color: verdePrimario, size: 18),
                SizedBox(width: 8),
                Text('Criar novo grupo', style: TextStyle(color: verdePrimario, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ),
        ),
        Expanded(
          child: grupos.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.folder_outlined, color: verdePrimario, size: 32)),
                    const SizedBox(height: 16),
                    const Text('Nenhum grupo criado ainda', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Crie grupos para organizar seus\nalimentos por ocasião ou refeição', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: grupos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CartaoGrupo(grupo: grupos[i], aoAdicionarAlimentos: aoAdicionarAlimentosGrupo, aoExcluir: aoExcluirGrupo),
                ),
        ),
      ],
    );
  }
}

class _CartaoGrupo extends StatelessWidget {
  final GrupoAlimentos grupo;
  final void Function(GrupoAlimentos) aoAdicionarAlimentos;
  final void Function(GrupoAlimentos) aoExcluir;

  const _CartaoGrupo({required this.grupo, required this.aoAdicionarAlimentos, required this.aoExcluir});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: verdePrimario.withOpacity(0.15))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.folder_rounded, color: verdePrimario, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(grupo.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Text(grupo.totalItens == 0 ? 'Nenhum alimento adicionado' : '${grupo.totalItens} alimento${grupo.totalItens > 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
            ])),
            PopupMenuButton<String>(
              color: const Color(0xFF1C1C1C),
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (a) { if (a == 'add') aoAdicionarAlimentos(grupo); if (a == 'del') aoExcluir(grupo); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'add', child: Row(children: [Icon(Icons.add_rounded, color: verdePrimario, size: 16), SizedBox(width: 8), Text('Adicionar alimentos', style: TextStyle(color: Colors.white, fontSize: 13))])),
                const PopupMenuItem(value: 'del', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4444), size: 16), SizedBox(width: 8), Text('Excluir grupo', style: TextStyle(color: Color(0xFFFF4444), fontSize: 13))])),
              ],
            ),
          ]),
        ),
        if (grupo.alimentos.isNotEmpty) ...[
          const Divider(color: bordaCartao, height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Wrap(spacing: 6, runSpacing: 6, children: grupo.alimentos.map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: verdePrimario.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: verdePrimario.withOpacity(0.2))),
              child: Text(a.nome, style: const TextStyle(fontSize: 11, color: verdePrimario, fontWeight: FontWeight.w600)),
            )).toList()),
          ),
        ],
        if (grupo.alimentos.isEmpty)
          GestureDetector(
            onTap: () => aoAdicionarAlimentos(grupo),
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: bordaCartao)),
              child: const Center(child: Text('+ Adicionar alimentos', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500))),
            ),
          ),
      ]),
    );
  }
}