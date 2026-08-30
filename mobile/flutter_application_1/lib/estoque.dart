import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'alimento.dart';
import 'grupo.dart';
import 'api_cliente.dart';

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

  bool _carregando = true;
  String? _erro;
  List<AlimentoEstoque> _estoque = [];
  List<GrupoAlimentos> _grupos = [];

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
    _carregarTudo();
  }

  @override
  void dispose() {
    _controladorSubabas.dispose();
    _controladorBusca.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      await Future.wait([_carregarEstoque(), _carregarGrupos()]);
      setState(() => _carregando = false);
    } on ApiException catch (e) {
      setState(() { _carregando = false; _erro = e.mensagem; });
    }
  }

  Future<void> _carregarEstoque() async {
    final resp = await ApiCliente.get('/estoque/listar_alimentos.php');
    final lista = (resp['alimentos'] as List)
        .map((j) => AlimentoEstoque.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _estoque = lista);
  }

  Future<void> _carregarGrupos() async {
    final resp = await ApiCliente.get('/grupos/gerenciar_grupo_alimentos.php');
    final lista = (resp['grupos'] as List)
        .map((j) => GrupoAlimentos.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _grupos = lista);
  }

  String _formatarIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

  //dialogue para adicionar
  void _abrirDialogoAdicionarAlimento({AlimentoEstoque? edicao}) {
    final ctrlNome       = TextEditingController(text: edicao?.nome ?? '');
    final ctrlQuantidade = TextEditingController(
        text: edicao != null
            ? (edicao.quantidade == edicao.quantidade.truncateToDouble()
                ? edicao.quantidade.toInt().toString()
                : edicao.quantidade.toString())
            : '');
    String unidadeSelecionada = edicao?.unidade ?? unidadesMedida.first;
    DateTime? dataValidade;
    if (edicao != null && edicao.validade.isNotEmpty) {
      dataValidade = DateTime.tryParse(edicao.validade);
    }
    String? erroNome, erroQtd, erroVal;
    bool salvando = false;

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
                  _rotuloDialog('Validade'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final agora = DateTime.now();
                      final escolhida = await showDatePicker(
                        context: ctx,
                        initialDate: dataValidade ?? agora,
                        firstDate: DateTime(agora.year - 1),
                        lastDate: DateTime(agora.year + 5),
                      );
                      if (escolhida != null) setD(() => dataValidade = escolhida);
                    },
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: erroVal != null ? Colors.redAccent : bordaCartao),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, color: verdePrimario, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          dataValidade == null
                              ? 'Selecione a data'
                              : '${dataValidade!.day.toString().padLeft(2, '0')}/${dataValidade!.month.toString().padLeft(2, '0')}/${dataValidade!.year}',
                          style: TextStyle(color: dataValidade == null ? Colors.white38 : Colors.white, fontSize: 13),
                        ),
                      ]),
                    ),
                  ),
                  if (erroVal != null) Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(erroVal!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: salvando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: salvando ? null : () async {
                String? en, eq, ev;
                if (ctrlNome.text.trim().isEmpty) en = 'Obrigatório';
                final qtd = double.tryParse(ctrlQuantidade.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) eq = 'Valor inválido';
                if (dataValidade == null) ev = 'Selecione a data de validade';
                if (en != null || eq != null || ev != null) {
                  setD(() { erroNome = en; erroQtd = eq; erroVal = ev; });
                  return;
                }

                final corpo = <String, dynamic>{
                  'nome': ctrlNome.text.trim(),
                  'quantidade': qtd,
                  'unidade': unidadeSelecionada,
                  'validade': _formatarIso(dataValidade!),
                };

                setD(() => salvando = true);
                try {
                  String mensagem;
                  if (edicao == null) {
                    final resp = await ApiCliente.post('/estoque/cadastrar_alimento.php', corpo: corpo);
                    mensagem = (resp['mensagem'] as String?) ?? 'Item adicionado!';
                  } else {
                    corpo['id'] = int.parse(edicao.id);
                    await ApiCliente.post('/estoque/editar_alimento.php', corpo: corpo);
                    mensagem = 'Item atualizado!';
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarEstoque();
                  _mostrarSucesso(mensagem);
                } on ApiException catch (e) {
                  setD(() { salvando = false; erroVal = e.mensagem; });
                }
              },
              child: salvando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(edicao == null ? 'Adicionar' : 'Salvar', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiCliente.post('/estoque/excluir_alimento.php', corpo: {'id': int.parse(item.id)});
                await _carregarEstoque();
                _mostrarSucesso('Alimento excluído com sucesso.');
              } on ApiException catch (e) {
                _mostrarErro(e.mensagem);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Registra consumo ou desperdício de parte (ou todo) do item — é o que
  // alimenta os relatórios de aproveitamento/desperdício.
  void _abrirDialogoMovimentar(AlimentoEstoque item) {
    final ctrlQtd = TextEditingController();
    String tipo = 'consumo';
    String? erro;
    bool enviando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Registrar uso — ${item.nome}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Disponível: ${item.quantidadeFormatada}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setD(() => tipo = 'consumo'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: tipo == 'consumo' ? verdePrimario.withOpacity(0.15) : const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tipo == 'consumo' ? verdePrimario : bordaCartao),
                    ),
                    child: Center(child: Text('Consumi', style: TextStyle(color: tipo == 'consumo' ? verdePrimario : Colors.white54, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(
                  onTap: () => setD(() => tipo = 'desperdicio'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: tipo == 'desperdicio' ? const Color(0xFFFF4444).withOpacity(0.15) : const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tipo == 'desperdicio' ? const Color(0xFFFF4444) : bordaCartao),
                    ),
                    child: Center(child: Text('Descartei', style: TextStyle(color: tipo == 'desperdicio' ? const Color(0xFFFF4444) : Colors.white54, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                )),
              ]),
              const SizedBox(height: 14),
              _campoDialog('Quantidade (${item.unidade})', Icons.numbers_rounded, ctrlQtd, tipo: TextInputType.number, erro: erro),
            ],
          ),
          actions: [
            TextButton(onPressed: enviando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: enviando ? null : () async {
                final qtd = double.tryParse(ctrlQtd.text.replaceAll(',', '.'));
                if (qtd == null || qtd <= 0) {
                  setD(() => erro = 'Valor inválido');
                  return;
                }
                if (qtd > item.quantidade) {
                  setD(() => erro = 'Maior que o estoque disponível');
                  return;
                }
                setD(() => enviando = true);
                try {
                  await ApiCliente.post('/estoque/movimentar_alimento.php', corpo: {
                    'alimento_id': int.parse(item.id),
                    'tipo': tipo,
                    'quantidade': qtd,
                    'unidade_medida': item.unidade,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarEstoque();
                  _mostrarSucesso(tipo == 'consumo' ? 'Consumo registrado.' : 'Desperdício registrado.');
                } on ApiException catch (e) {
                  setD(() { enviando = false; erro = e.mensagem; });
                }
              },
              child: enviando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Registrar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoCriarGrupo() {
    final ctrl = TextEditingController();
    bool enviando = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
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
              onPressed: enviando ? null : () async {
                final nome = ctrl.text.trim();
                if (nome.isEmpty) return;
                setD(() => enviando = true);
                try {
                  await ApiCliente.post('/grupos/criar_grupo_alimentos.php', corpo: {'nome': nome});
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarGrupos();
                } on ApiException catch (e) {
                  setD(() => enviando = false);
                  _mostrarErro(e.mensagem);
                }
              },
              child: const Text('Criar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
              onPressed: () async {
                final idsAntes = grupo.alimentos.map((a) => a.id).toSet();
                final idsDepois = {for (int i = 0; i < _estoque.length; i++) if (selecionados[i]) _estoque[i].id};
                final paraAdicionar = idsDepois.difference(idsAntes);
                final paraRemover   = idsAntes.difference(idsDepois);

                Navigator.pop(ctx);
                try {
                  for (final id in paraAdicionar) {
                    await ApiCliente.post('/grupos/gerenciar_grupo_alimentos.php', corpo: {
                      'grupo_id': int.parse(grupo.id), 'alimento_id': int.parse(id),
                    });
                  }
                  for (final id in paraRemover) {
                    await ApiCliente.delete('/grupos/gerenciar_grupo_alimentos.php', corpo: {
                      'grupo_id': int.parse(grupo.id), 'alimento_id': int.parse(id),
                    });
                  }
                  await _carregarGrupos();
                } on ApiException catch (e) {
                  _mostrarErro(e.mensagem);
                }
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiCliente.post('/grupos/excluir_grupo_alimentos.php', corpo: {'grupo_id': int.parse(grupo.id)});
                await _carregarGrupos();
              } on ApiException catch (e) {
                _mostrarErro(e.mensagem);
              }
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
                            aoMovimentar:       _abrirDialogoMovimentar,
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
  final void Function(AlimentoEstoque) aoMovimentar;

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
    required this.aoMovimentar,
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
              : Builder(builder: (context) {
                  // Agrupa por nome (ignorando maiúsculas/minúsculas) porque o
                  // mesmo alimento pode ter vários lotes com validades
                  // diferentes (ex.: comprou mais carne, mas venceu num dia
                  // distinto do que já tinha) — cada lote continua sendo uma
                  // linha própria no banco (necessário pros relatórios), só a
                  // exibição é que agrupa.
                  final grupos = _agruparPorNome(alimentos);
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: grupos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final grupo = grupos[i];
                      return grupo.lotes.length == 1
                          ? _CartaoAlimento(item: grupo.lotes.first, aoEditar: aoEditar, aoExcluir: aoExcluir, aoMovimentar: aoMovimentar)
                          : _CartaoGrupoAlimento(grupo: grupo, aoEditar: aoEditar, aoExcluir: aoExcluir, aoMovimentar: aoMovimentar);
                    },
                  );
                }),
        ),
      ],
    );
  }

  // Junta os lotes de mesmo nome (case-insensitive) em um só grupo, mantendo
  // a ordem de primeira aparição na lista original.
  List<_GrupoAlimento> _agruparPorNome(List<AlimentoEstoque> lista) {
    final mapa = <String, _GrupoAlimento>{};
    for (final item in lista) {
      final chave = item.nome.trim().toLowerCase();
      final existente = mapa[chave];
      if (existente == null) {
        mapa[chave] = _GrupoAlimento(nome: item.nome, lotes: [item]);
      } else {
        existente.lotes.add(item);
      }
    }
    return mapa.values.toList();
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
  final void Function(AlimentoEstoque) aoMovimentar;

  const _CartaoAlimento({required this.item, required this.aoEditar, required this.aoExcluir, required this.aoMovimentar});

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
              Expanded(child: Text(item.textoValidade.isNotEmpty ? item.textoValidade : 'Vence ${item.validadeFormatadaBr}',
                  style: TextStyle(fontSize: 10, color: item.corStatus.withOpacity(0.85), fontWeight: FontWeight.w500))),
            ]),
          ]),
        ),
        Column(children: [
          GestureDetector(
            onTap: () => aoMovimentar(item),
            child: _acao(Icons.remove_circle_outline_rounded, const Color(0xFF4FC3F7)),
          ),
          const SizedBox(height: 6),
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
        width: 26, height: 26,
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: cor.withOpacity(0.2))),
        child: Icon(icone, size: 12, color: cor));
}

// Vários lotes do mesmo alimento (mesmo nome, ignorando maiúsculas/minúsculas)
// com validades possivelmente diferentes — cada AlimentoEstoque aqui
// continua sendo a linha própria dele no banco; isso só existe pra exibição.
class _GrupoAlimento {
  final String nome; // nome de exibição (do primeiro lote encontrado)
  final List<AlimentoEstoque> lotes;
  _GrupoAlimento({required this.nome, required this.lotes});

  // pior status entre os lotes manda no destaque do card (Urgente > Atenção > OK)
  String get status {
    if (lotes.any((l) => l.status == 'Urgente')) return 'Urgente';
    if (lotes.any((l) => l.status == 'Atenção')) return 'Atenção';
    return 'OK';
  }

  Color get corStatus {
    switch (status) {
      case 'Urgente': return const Color(0xFFFF4444);
      case 'Atenção': return const Color(0xFFFFA726);
      default:        return const Color(0xFF16DB65);
    }
  }

  // o lote que vence primeiro — é o texto de validade mostrado no resumo
  AlimentoEstoque get loteMaisProximo =>
      lotes.reduce((a, b) => a.diasValidade <= b.diasValidade ? a : b);

  // Soma por unidade (não dá pra somar kg com unidade sem converter, então
  // se houver mistura de unidades entre os lotes, mostra cada uma separada).
  String get quantidadeFormatada {
    final porUnidade = <String, double>{};
    for (final l in lotes) {
      porUnidade[l.unidade] = (porUnidade[l.unidade] ?? 0) + l.quantidade;
    }
    return porUnidade.entries.map((e) {
      final v = e.value == e.value.truncateToDouble() ? e.value.toInt().toString() : e.value.toString();
      return '$v ${e.key}';
    }).join(' + ');
  }

  // lotes do mais próximo de vencer para o mais distante
  List<AlimentoEstoque> get lotesOrdenados =>
      [...lotes]..sort((a, b) => a.diasValidade.compareTo(b.diasValidade));
}

// Card de resumo para quando há mais de um lote do mesmo alimento — mostra o
// total e o vencimento mais próximo; tocar abre o detalhe com cada lote.
class _CartaoGrupoAlimento extends StatelessWidget {
  final _GrupoAlimento grupo;
  final void Function(AlimentoEstoque) aoEditar;
  final void Function(AlimentoEstoque) aoExcluir;
  final void Function(AlimentoEstoque) aoMovimentar;

  const _CartaoGrupoAlimento({required this.grupo, required this.aoEditar, required this.aoExcluir, required this.aoMovimentar});

  @override
  Widget build(BuildContext context) {
    final icone = AlimentoEstoque.iconePorNome(grupo.nome);
    final proximo = grupo.loteMaisProximo;
    return GestureDetector(
      onTap: () => _abrirDetalheLotes(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cartaoEscuro,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: grupo.status == 'Urgente' ? const Color(0xFFFF4444).withOpacity(0.2) : bordaCartao),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: grupo.corStatus.withOpacity(0.08), borderRadius: BorderRadius.circular(11)),
            child: Icon(icone, color: grupo.corStatus.withOpacity(0.7), size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(grupo.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: grupo.corStatus.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                  child: Text(grupo.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: grupo.corStatus)),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(5)),
                  child: Text('${grupo.lotes.length} lotes', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white54)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(grupo.quantidadeFormatada, style: const TextStyle(fontSize: 11, color: Colors.white38)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 10, color: grupo.corStatus.withOpacity(0.7)),
                const SizedBox(width: 3),
                Expanded(child: Text(
                    'Mais próximo: ${proximo.textoValidade.isNotEmpty ? proximo.textoValidade : 'vence ${proximo.validadeFormatadaBr}'}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: grupo.corStatus.withOpacity(0.85), fontWeight: FontWeight.w500))),
              ]),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
        ]),
      ),
    );
  }

  // Lista cada lote individualmente (mesmo card de sempre, com as mesmas
  // ações) — fecha este painel antes de abrir qualquer diálogo de
  // editar/mover/excluir pra não ficar com dado desatualizado na tela.
  void _abrirDetalheLotes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cartaoEscuro,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, ctrl) => Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(grupo.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                    const SizedBox(height: 4),
                    Text('${grupo.lotes.length} lotes · ${grupo.quantidadeFormatada} no total', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ]),
                ),
              ]),
            ),
            const Divider(color: bordaCartao, height: 1),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                itemCount: grupo.lotesOrdenados.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final lote = grupo.lotesOrdenados[i];
                  return _CartaoAlimento(
                    item: lote,
                    aoEditar: (a) { Navigator.pop(context); aoEditar(a); },
                    aoExcluir: (a) { Navigator.pop(context); aoExcluir(a); },
                    aoMovimentar: (a) { Navigator.pop(context); aoMovimentar(a); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 72, height: 72, decoration: BoxDecoration(color: verdePrimario.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.folder_outlined, color: verdePrimario, size: 32)),
                      const SizedBox(height: 16),
                      const Text('Nenhum grupo criado ainda', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      const Text('Crie grupos para organizar seus\nalimentos por ocasião ou refeição', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ]),
                  ),
                ])
              : ListView.separated(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
