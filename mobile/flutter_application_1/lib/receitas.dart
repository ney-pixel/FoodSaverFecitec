import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'receita.dart';
import 'alimento.dart';
import 'api_cliente.dart';

class TelaReceitas extends StatefulWidget {
  final Usuario usuario;
  const TelaReceitas({super.key, required this.usuario});
  @override
  State<TelaReceitas> createState() => _TelaReceitasState();
}

class _TelaReceitasState extends State<TelaReceitas>
    with SingleTickerProviderStateMixin {
  late TabController _controladorSubabas;

  bool _carregando = true;
  String? _erro;
  List<Receita> _biblioteca = [];
  List<Receita> _favoritasIA = [];
  List<GrupoReceitas> _grupos = [];
  List<AlimentoEstoque> _estoque = [];

  List<Receita> get _favoritas => [
        ..._biblioteca.where((r) => r.favorita),
        ..._favoritasIA,
      ];

  @override
  void initState() {
    super.initState();
    _controladorSubabas = TabController(length: 4, vsync: this);
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
      await Future.wait([_carregarBiblioteca(), _carregarGrupos(), _carregarEstoque(), _carregarFavoritasIA()]);
      setState(() => _carregando = false);
    } on ApiException catch (e) {
      setState(() { _carregando = false; _erro = e.mensagem; });
    }
  }

  Future<void> _carregarBiblioteca() async {
    final resp = await ApiCliente.get('/biblioteca/listar_biblioteca.php');
    final lista = (resp['receitas'] as List)
        .map((j) => Receita.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _biblioteca = lista);
  }

  Future<void> _carregarGrupos() async {
    final resp = await ApiCliente.get('/biblioteca/gerenciar_grupo_biblioteca.php');
    final lista = (resp['grupos'] as List).map((j) {
      final grupo = j as Map<String, dynamic>;
      final itens = (grupo['receitas'] as List).map((it) {
        final id = it['id'] as int;
        // Hidrata com o objeto completo da biblioteca
        return _biblioteca.firstWhere(
          (r) => r.id == id,
          orElse: () => Receita(
            id: id,
            nome: it['titulo'] as String,
            descricao: '', categoria: '', dificuldade: 'Fácil',
            tempoPreparo: 0, porcoes: (it['porcoes'] as num?)?.toInt() ?? 1, calorias: 0, imagem: '',
            ingredientes: [], ingredientesNecessarios: [], preparo: [], dicas: [],
          ),
        );
      }).toList();
      return GrupoReceitas(id: '${grupo['id']}', nome: grupo['nome'] as String, receitas: itens);
    }).toList();
    if (mounted) setState(() => _grupos = lista);
  }

  Future<void> _carregarEstoque() async {
    final resp = await ApiCliente.get('/estoque/listar_alimentos.php');
    final lista = (resp['alimentos'] as List)
        .map((j) => AlimentoEstoque.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _estoque = lista);
  }

  Future<void> _carregarFavoritasIA() async {
    final resp = await ApiCliente.get('/ia/listar_receitas_ia.php');
    final lista = (resp['receitas'] as List)
        .map((j) => Receita.fromJson(j as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _favoritasIA = lista);
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: const Color(0xFFFF4444)),
    );
  }

  // Favoritar funciona diferente: biblioteca (catálogo fixo) vs gerada por IA
  Future<void> _alternarFavorito(Receita receita) async {
    if (receita.geradaPorIA) {
      await _alternarFavoritoIA(receita);
    } else {
      try {
        await ApiCliente.post('/biblioteca/favoritar_biblioteca.php', corpo: {'id': receita.id});
        await _carregarBiblioteca();
      } on ApiException catch (e) {
        _mostrarErro(e.mensagem);
      }
    }
  }

  Future<void> _alternarFavoritoIA(Receita receita) async {
    try {
      final corpo = receita.id > 0
          ? {'id': receita.id}
          : {
              'titulo': receita.nome,
              'descricao': receita.descricao,
              'categoria': receita.categoria,
              'dificuldade': receita.dificuldade,
              'tempo_preparo': receita.tempoPreparo,
              'porcoes': receita.porcoes,
              'calorias': receita.calorias,
              'ingredientes': receita.ingredientes,
              'ingredientes_necessarios': receita.ingredientesNecessarios,
              'modo_preparo': receita.preparo,
              'dicas': receita.dicas,
            };
      final resp = await ApiCliente.post('/ia/favoritar_receita_ia.php', corpo: corpo);
      receita.id = resp['id'] as int;
      receita.favorita = resp['favorito'] == true;
      await _carregarFavoritasIA();
    } on ApiException catch (e) {
      _mostrarErro(e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        cabecalhoPagina('Receitas IA',
          acaoTopo: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text('IA Ativa', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: bordaCartao, width: 0.5))),
          child: TabBar(
            controller: _controladorSubabas,
            indicatorColor: verdePrimario,
            labelColor: verdePrimario,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Criar'),
              Tab(text: 'Favoritas'),
              Tab(text: 'Grupos'),
              Tab(text: 'Biblioteca'),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: verdePrimario))
              : _erro != null
                  ? _telaErro(_erro!, _carregarTudo)
                  : TabBarView(
                      controller: _controladorSubabas,
                      children: [
                        _SubabaCriar(estoque: _estoque, aoFavoritar: _alternarFavorito),
                        _SubabaFavoritas(favoritas: _favoritas, aoDesfavoritar: _alternarFavorito),
                        _SubabaGruposReceitas(
                          grupos: _grupos,
                          todasReceitas: _biblioteca,
                          aoCriarGrupo: (nome) async {
                            await ApiCliente.post('/biblioteca/criar_grupo_biblioteca.php', corpo: {'nome': nome});
                            await _carregarGrupos();
                          },
                          aoAtualizarGrupo: (grupo, idsAntes, idsDepois) async {
                            final paraAdicionar = idsDepois.difference(idsAntes);
                            final paraRemover   = idsAntes.difference(idsDepois);
                            for (final id in paraAdicionar) {
                              await ApiCliente.post('/biblioteca/gerenciar_grupo_biblioteca.php', corpo: {
                                'grupo_id': int.parse(grupo.id), 'receita_id': id,
                              });
                            }
                            for (final id in paraRemover) {
                              await ApiCliente.delete('/biblioteca/gerenciar_grupo_biblioteca.php', corpo: {
                                'grupo_id': int.parse(grupo.id), 'receita_id': id,
                              });
                            }
                            await _carregarGrupos();
                          },
                          aoExcluirGrupo: (grupo) async {
                            await ApiCliente.post('/biblioteca/excluir_grupo_biblioteca.php', corpo: {'grupo_id': int.parse(grupo.id)});
                            await _carregarGrupos();
                          },
                          aoErro: _mostrarErro,
                        ),
                        _SubabaBiblioteca(biblioteca: _biblioteca, aoFavoritar: _alternarFavorito),
                      ],
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

//subaba criar receitas
class _SubabaCriar extends StatefulWidget {
  final List<AlimentoEstoque> estoque;
  final Future<void> Function(Receita) aoFavoritar;
  const _SubabaCriar({required this.estoque, required this.aoFavoritar});
  @override
  State<_SubabaCriar> createState() => _SubabaCriarState();
}

class _SubabaCriarState extends State<_SubabaCriar> {
  final _controladorBuscaIngrediente = TextEditingController();
  final _controladorObservacoes = TextEditingController();
  final _focoBuscaIngrediente = FocusNode();
  final List<String> _ingredientesSelecionados = [];
  int _numeroPessoas = 2;
  int _indiceFome    = 1;
  final _nivelFome   = ['Leve', 'Médio', 'Muita fome'];
  bool _gerando      = false;

  int get _totalSelecionados => _ingredientesSelecionados.length;
  List<String> get _nomesSelecionados => _ingredientesSelecionados;

  //alimentos do estoque disponiveis para sugestao em receitas
  List<String> get _alimentosDisponiveis =>
      widget.estoque.map((a) => a.nome).toList();

  //sugestoes filtradas a partir do texto digitado (letras ou silabas), ja
  //verificando se o alimento existe no estoque e ainda nao foi selecionado
  List<String> get _sugestoes {
    final busca = _controladorBuscaIngrediente.text.trim().toLowerCase();
    if (busca.isEmpty) return [];
    return _alimentosDisponiveis
        .where((nome) =>
            nome.toLowerCase().contains(busca) &&
            !_ingredientesSelecionados.contains(nome))
        .toList();
  }

  void _selecionarIngrediente(String nome) {
    setState(() {
      if (!_ingredientesSelecionados.contains(nome)) {
        _ingredientesSelecionados.add(nome);
      }
      _controladorBuscaIngrediente.clear();
    });
  }

  void _removerIngrediente(String nome) {
    setState(() => _ingredientesSelecionados.remove(nome));
  }

  @override
  void initState() {
    super.initState();
    _controladorBuscaIngrediente.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controladorBuscaIngrediente.dispose();
    _controladorObservacoes.dispose();
    _focoBuscaIngrediente.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: const Color(0xFFFF4444)),
    );
  }

  //chama a IA (api/ia/gerar_receita.php) com os ingredientes selecionados
  Future<void> _gerarReceita() async {
    setState(() => _gerando = true);
    try {
      final resp = await ApiCliente.post('/ia/gerar_receita.php',
          corpo: {
            'ingredientes': _nomesSelecionados,
            'porcoes': _numeroPessoas,
            'nivel_fome': _nivelFome[_indiceFome],
            'observacoes': _controladorObservacoes.text.trim(),
          },
          timeout: const Duration(seconds: 45));
      if (!mounted) return;
      setState(() => _gerando = false);
      final receita = Receita.fromJson(resp['receita'] as Map<String, dynamic>);
      _mostrarReceita(receita);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _gerando = false);
      _mostrarErro(e.mensagem);
    }
  }

  // Mostra a receita num painel completo (ver _abrirDetalheReceita)
  void _mostrarReceita(Receita receita) =>
      _abrirDetalheReceita(context, receita, widget.aoFavoritar);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      physics: const BouncingScrollPhysics(),
      children: [
        rotuloSecao('1.  Busque os ingredientes'),
        const SizedBox(height: 6),
        const Text('Digite o nome do alimento — buscamos no seu estoque', style: TextStyle(fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 10),

        //barra de pesquisa de alimentos
        Container(
          height: 44,
          decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(12), border: Border.all(color: _focoBuscaIngrediente.hasFocus ? verdePrimario.withOpacity(0.5) : bordaCartao)),
          child: Row(children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: Colors.white30, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controladorBuscaIngrediente,
                focusNode: _focoBuscaIngrediente,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Ex: frango, cenoura, arroz...', hintStyle: TextStyle(color: Colors.white30, fontSize: 13), border: InputBorder.none, isDense: true),
              ),
            ),
            if (_controladorBuscaIngrediente.text.isNotEmpty)
              GestureDetector(
                onTap: () => _controladorBuscaIngrediente.clear(),
                child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, color: Colors.white38, size: 16)),
              ),
          ]),
        ),

        //sugestoes com base no que existe no estoque
        if (_controladorBuscaIngrediente.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(12), border: Border.all(color: bordaCartao)),
            child: _sugestoes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white30, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text('Nenhum alimento com esse nome no seu estoque.', style: TextStyle(color: Colors.white38, fontSize: 12))),
                    ]),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _sugestoes.length,
                    separatorBuilder: (_, __) => const Divider(color: bordaCartao, height: 1),
                    itemBuilder: (_, i) {
                      final nome = _sugestoes[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(AlimentoEstoque.iconePorNome(nome), color: verdePrimario, size: 18),
                        title: Text(nome, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.add_circle_outline_rounded, color: verdePrimario, size: 18),
                        onTap: () => _selecionarIngrediente(nome),
                      );
                    },
                  ),
          ),
        ],

        const SizedBox(height: 16),
        rotuloSecao('Ingredientes'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: bordaCartao)),
          child: _ingredientesSelecionados.isEmpty
              ? const Text('Nenhum ingrediente selecionado ainda.', style: TextStyle(color: Colors.white38, fontSize: 12))
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _ingredientesSelecionados.map((nome) => Container(
                    padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
                    decoration: BoxDecoration(color: verdePrimario, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removerIngrediente(nome),
                        child: const Icon(Icons.close_rounded, size: 15, color: Colors.black87),
                      ),
                    ]),
                  )).toList(),
                ),
        ),
        const SizedBox(height: 16),
        rotuloSecao('2.  Para quantas pessoas?'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: bordaCartao)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Porções', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
            Row(children: [
              _botaoControle(Icons.remove_rounded, () { if (_numeroPessoas > 1) setState(() => _numeroPessoas--); }),
              const SizedBox(width: 16),
              Text('$_numeroPessoas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 16),
              _botaoControle(Icons.add_rounded, () => setState(() => _numeroPessoas++)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        rotuloSecao('3.  Nível de fome'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: bordaCartao)),
          child: Row(children: _nivelFome.asMap().entries.map((e) {
            final sel = _indiceFome == e.key;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _indiceFome = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(color: sel ? verdePrimario : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.black : Colors.white54))),
              ),
            ));
          }).toList()),
        ),
        const SizedBox(height: 16),
        rotuloSecao('4.  Observações (opcional)'),
        const SizedBox(height: 8),
        Container(
          height: 76,
          decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: bordaCartao)),
          child: TextField(
            controller: _controladorObservacoes,
            maxLines: null, expands: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(hintText: 'Ex: sem glúten, rápido de fazer...', hintStyle: TextStyle(color: Colors.white30, fontSize: 12), border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: (_totalSelecionados > 0 && !_gerando) ? _gerarReceita : null,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _totalSelecionados > 0 ? [const Color(0xFF6C63FF), const Color(0xFF9B59B6)] : [const Color(0xFF222222), const Color(0xFF222222)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _totalSelecionados > 0 ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 5))] : [],
            ),
            child: _gerando
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 10),
                    Text('Gerando receita...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      _totalSelecionados == 0 ? 'Selecione ingredientes acima' : 'Gerar receita com $_totalSelecionados ingrediente${_totalSelecionados > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ]),
          ),
        ),
      ],
    );
  }

  Widget _botaoControle(IconData icone, VoidCallback cb) => GestureDetector(
        onTap: cb,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: verdePrimario.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: verdePrimario.withOpacity(0.3))),
          child: Icon(icone, color: verdePrimario, size: 16),
        ),
      );
}

//subaba favoritas
// Modal de detalhe de receita — compartilhado entre Criar, Biblioteca e Favoritas
void _abrirDetalheReceita(BuildContext context, Receita receita, Future<void> Function(Receita) aoFavoritar) {
  bool favoritado = receita.favorita;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cartaoEscuro,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => StatefulBuilder(
      builder: (ctx, setB) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      _badgeCategoriaReceita(receita.categoria),
                      if (receita.geradaPorIA) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [roxoIA, roxoIAClaro]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 9),
                            SizedBox(width: 3),
                            Text('Gerada por IA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Text(receita.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(receita.descricao, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ]),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    setB(() => favoritado = !favoritado);
                    await aoFavoritar(receita);
                    setB(() => favoritado = receita.favorita);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: favoritado ? Colors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: favoritado ? Colors.amber.withOpacity(0.5) : Colors.white12),
                    ),
                    child: Icon(favoritado ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: favoritado ? Colors.amber : Colors.white38, size: 22),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chipInfoReceita(Icons.timer_rounded, '${receita.tempoPreparo} min', Colors.white54),
                  const SizedBox(width: 8),
                  _chipInfoReceita(Icons.bar_chart_rounded, receita.dificuldade, _corDificuldadeReceita(receita.dificuldade)),
                  const SizedBox(width: 8),
                  _chipInfoReceita(Icons.people_outline_rounded, '${receita.porcoes} porções', Colors.white54),
                  const SizedBox(width: 8),
                  _chipInfoReceita(Icons.local_fire_department_outlined, '${receita.calorias} kcal', const Color(0xFFFFA726)),
                ]),
              ),
            ),
            const Divider(color: bordaCartao, height: 1),
            Expanded(
              child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
                _tituloSecaoReceita('Ingredientes'),
                const SizedBox(height: 10),
                ...receita.ingredientes.map((ing) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: verdePrimario, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ing, style: const TextStyle(fontSize: 13, color: Colors.white70))),
                  ]),
                )),
                const SizedBox(height: 16),
                _tituloSecaoReceita('Modo de preparo'),
                const SizedBox(height: 10),
                ...receita.preparo.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 24, height: 24, margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: BoxDecoration(color: verdePrimario.withOpacity(0.12), borderRadius: BorderRadius.circular(7), border: Border.all(color: verdePrimario.withOpacity(0.3))),
                      child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: verdePrimario))),
                    ),
                    Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4))),
                  ]),
                )),
                if (receita.dicas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _tituloSecaoReceita('Dicas'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.2))),
                    child: Column(
                      children: receita.dicas.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(d, style: const TextStyle(fontSize: 12, color: Colors.white60))),
                        ]),
                      )).toList(),
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _corDificuldadeReceita(String d) {
  switch (d) {
    case 'Fácil': return verdePrimario;
    case 'Médio': return const Color(0xFFFFA726);
    default:      return const Color(0xFFFF4444);
  }
}

Widget _badgeCategoriaReceita(String cat) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3))),
      child: Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9B8FFF))),
    );

Widget _chipInfoReceita(IconData icone, String rotulo, Color cor) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 11, color: cor),
        const SizedBox(width: 4),
        Text(rotulo, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600)),
      ]),
    );

Widget _tituloSecaoReceita(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3));

class _SubabaFavoritas extends StatelessWidget {
  final List<Receita> favoritas;
  final Future<void> Function(Receita) aoDesfavoritar;
  const _SubabaFavoritas({required this.favoritas, required this.aoDesfavoritar});

  @override
  Widget build(BuildContext context) {
    if (favoritas.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.favorite_border_rounded, color: Colors.amber, size: 32)),
        const SizedBox(height: 16),
        const Text('Nenhuma receita favoritada', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Favorite uma receita na Biblioteca\npara ela aparecer aqui', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]));
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      itemCount: favoritas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = favoritas[i];
        return _CartaoFavorita(
          receita: r,
          aoAbrir: () => _abrirDetalheReceita(ctx, r, aoDesfavoritar),
          aoDesfavoritar: () => aoDesfavoritar(r),
        );
      },
    );
  }
}

// Mesmo formato de linha da Biblioteca — coração à direita desfavorita direto da lista
class _CartaoFavorita extends StatelessWidget {
  final Receita receita;
  final VoidCallback aoAbrir;
  final VoidCallback aoDesfavoritar;
  const _CartaoFavorita({required this.receita, required this.aoAbrir, required this.aoDesfavoritar});

  Color _corDif(String d) {
    switch (d) {
      case 'Fácil': return verdePrimario;
      case 'Médio': return const Color(0xFFFFA726);
      default:      return const Color(0xFFFF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corDif(receita.dificuldade);
    return GestureDetector(
      onTap: aoAbrir,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cartaoEscuro,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bordaCartao),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.amber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(receita.nome, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                if (receita.geradaPorIA) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [roxoIA, roxoIAClaro]), borderRadius: BorderRadius.circular(5)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome_rounded, size: 8, color: Colors.white),
                      SizedBox(width: 2),
                      Text('IA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(
                receita.categoria.isNotEmpty ? receita.categoria : receita.ingredientesNecessarios.join(' · '),
                style: const TextStyle(fontSize: 11, color: Colors.white38),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(children: [
                _pildora(Icons.timer_rounded, '${receita.tempoPreparo} min', Colors.white38),
                const SizedBox(width: 6),
                _pildora(Icons.bar_chart_rounded, receita.dificuldade, cor),
                const SizedBox(width: 6),
                _pildora(Icons.local_fire_department_outlined, '${receita.calorias} kcal', const Color(0xFFFFA726)),
              ]),
            ]),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: aoDesfavoritar,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.favorite_rounded, color: Colors.amber, size: 20),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pildora(IconData icone, String rotulo, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withOpacity(0.2))),
        child: Row(children: [Icon(icone, size: 9, color: cor), const SizedBox(width: 3), Text(rotulo, style: TextStyle(fontSize: 9, color: cor))]),
      );
}

//subaba grupos
class _SubabaGruposReceitas extends StatelessWidget {
  final List<GrupoReceitas> grupos;
  final List<Receita> todasReceitas;
  final Future<void> Function(String nome) aoCriarGrupo;
  final Future<void> Function(GrupoReceitas grupo, Set<int> idsAntes, Set<int> idsDepois) aoAtualizarGrupo;
  final Future<void> Function(GrupoReceitas grupo) aoExcluirGrupo;
  final void Function(String) aoErro;

  const _SubabaGruposReceitas({
    required this.grupos,
    required this.todasReceitas,
    required this.aoCriarGrupo,
    required this.aoAtualizarGrupo,
    required this.aoExcluirGrupo,
    required this.aoErro,
  });

  void _criarGrupo(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Novo Grupo de Receitas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Dê uma descrição ao grupo.\nEx: "Receitas para junho"', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: 'Descrição do grupo...', hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), filled: true, fillColor: const Color(0xFF1C1C1C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: verdePrimario, width: 1.2)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final nome = ctrl.text.trim();
              if (nome.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await aoCriarGrupo(nome);
              } on ApiException catch (e) {
                aoErro(e.mensagem);
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _adicionarReceitas(BuildContext context, GrupoReceitas grupo) {
    final sels = List<bool>.generate(todasReceitas.length, (i) => grupo.receitas.any((r) => r.id == todasReceitas[i].id));
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
              itemCount: todasReceitas.length,
              itemBuilder: (_, i) => CheckboxListTile(
                value: sels[i], onChanged: (v) => setD(() => sels[i] = v ?? false),
                activeColor: verdePrimario, checkColor: Colors.black,
                title: Text(todasReceitas[i].nome, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(todasReceitas[i].categoria, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                final idsAntes = grupo.receitas.map((r) => r.id).toSet();
                final idsDepois = {for (int i = 0; i < todasReceitas.length; i++) if (sels[i]) todasReceitas[i].id};
                Navigator.pop(ctx);
                try {
                  await aoAtualizarGrupo(grupo, idsAntes, idsDepois);
                } on ApiException catch (e) {
                  aoErro(e.mensagem);
                }
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _excluirGrupo(BuildContext context, GrupoReceitas grupo) {
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
                await aoExcluirGrupo(grupo);
              } on ApiException catch (e) {
                aoErro(e.mensagem);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GestureDetector(
          onTap: () => _criarGrupo(context),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.create_new_folder_outlined, color: Color(0xFF9B8FFF), size: 18),
              SizedBox(width: 8),
              Text('Criar novo grupo', style: TextStyle(color: Color(0xFF9B8FFF), fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
      ),
      Expanded(
        child: grupos.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.folder_outlined, color: Color(0xFF9B8FFF), size: 32)),
                const SizedBox(height: 16),
                const Text('Nenhum grupo criado ainda', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Crie grupos para organizar suas\nreceitas por tema ou período', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
              ]))
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: grupos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CartaoGrupoReceitas(
                  grupo: grupos[i],
                  aoAdicionarReceitas: () => _adicionarReceitas(context, grupos[i]),
                  aoExcluir: () => _excluirGrupo(context, grupos[i]),
                ),
              ),
      ),
    ]);
  }
}

class _CartaoGrupoReceitas extends StatelessWidget {
  final GrupoReceitas grupo;
  final VoidCallback aoAdicionarReceitas;
  final VoidCallback aoExcluir;
  const _CartaoGrupoReceitas({required this.grupo, required this.aoAdicionarReceitas, required this.aoExcluir});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.folder_rounded, color: Color(0xFF9B8FFF), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(grupo.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Text(grupo.receitas.isEmpty ? 'Nenhuma receita adicionada' : '${grupo.receitas.length} receita${grupo.receitas.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
            ])),
            PopupMenuButton<String>(
              color: const Color(0xFF1C1C1C),
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (a) { if (a == 'add') aoAdicionarReceitas(); if (a == 'del') aoExcluir(); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'add', child: Row(children: [Icon(Icons.add_rounded, color: Color(0xFF9B8FFF), size: 16), SizedBox(width: 8), Text('Adicionar receitas', style: TextStyle(color: Colors.white, fontSize: 13))])),
                const PopupMenuItem(value: 'del', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4444), size: 16), SizedBox(width: 8), Text('Excluir grupo', style: TextStyle(color: Color(0xFFFF4444), fontSize: 13))])),
              ],
            ),
          ]),
        ),
        if (grupo.receitas.isNotEmpty) ...[
          const Divider(color: bordaCartao, height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Wrap(spacing: 6, runSpacing: 6, children: grupo.receitas.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2))),
              child: Text(r.nome, style: const TextStyle(fontSize: 11, color: Color(0xFF9B8FFF), fontWeight: FontWeight.w600)),
            )).toList()),
          ),
        ],
        if (grupo.receitas.isEmpty)
          GestureDetector(
            onTap: aoAdicionarReceitas,
            child: Container(margin: const EdgeInsets.fromLTRB(14, 0, 14, 12), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: bordaCartao)), child: const Center(child: Text('+ Adicionar receitas', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)))),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  Subaba: Biblioteca de Receitas (catálogo fixo)
// ─────────────────────────────────────────────
class _SubabaBiblioteca extends StatefulWidget {
  final List<Receita> biblioteca;
  final Future<void> Function(Receita) aoFavoritar;
  const _SubabaBiblioteca({required this.biblioteca, required this.aoFavoritar});
  @override
  State<_SubabaBiblioteca> createState() => _SubabaBibliotecaState();
}

class _SubabaBibliotecaState extends State<_SubabaBiblioteca> {
  final _controladorBusca = TextEditingController();
  String _textoBusca = '';

  List<Receita> get _receitasFiltradas {
    var lista = widget.biblioteca;
    if (_textoBusca.isNotEmpty) {
      final b = _textoBusca.toLowerCase();
      lista = lista.where((r) =>
          r.nome.toLowerCase().contains(b) ||
          r.categoria.toLowerCase().contains(b) ||
          r.ingredientesNecessarios.any((ing) => ing.toLowerCase().contains(b))).toList();
    }
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _controladorBusca.addListener(() => setState(() => _textoBusca = _controladorBusca.text));
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  // Mesmo modal completo usado em Criar e Favoritas — ver _abrirDetalheReceita.
  void _verReceita(BuildContext context, Receita receita) =>
      _abrirDetalheReceita(context, receita, widget.aoFavoritar);

  @override
  Widget build(BuildContext context) {
    final filtradas = _receitasFiltradas;

    return Column(
      children: [
        // Busca por nome
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            height: 42,
            decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(12), border: Border.all(color: bordaCartao)),
            child: Row(children: [
              const SizedBox(width: 12),
              const Icon(Icons.search_rounded, color: Colors.white30, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controladorBusca,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Buscar receita...', hintStyle: TextStyle(color: Colors.white30, fontSize: 13), border: InputBorder.none, isDense: true),
                ),
              ),
              if (_controladorBusca.text.isNotEmpty)
                GestureDetector(
                  onTap: () => _controladorBusca.clear(),
                  child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, color: Colors.white38, size: 16)),
                ),
            ]),
          ),
        ),

        // Contador de resultados
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Todas as receitas',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
              ),
              Text(
                '${filtradas.length} receita${filtradas.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),

        // Lista de receitas
        Expanded(
          child: filtradas.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.white24, size: 48),
                    const SizedBox(height: 12),
                    const Text('Nenhuma receita encontrada', style: TextStyle(color: Colors.white38, fontSize: 14)),
                  ]),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = filtradas[i];
                    return _CartaoBiblioteca(
                      receita: r,
                      isFavorita: r.favorita,
                      aoAbrir: () => _verReceita(context, r),
                    );
                  },
                ),
        ),
      ],
    );
  }

}

// Cartão visual da biblioteca
class _CartaoBiblioteca extends StatelessWidget {
  final Receita receita;
  final bool isFavorita;
  final VoidCallback aoAbrir;
  const _CartaoBiblioteca({required this.receita, required this.isFavorita, required this.aoAbrir});

  Color _corDif(String d) {
    switch (d) {
      case 'Fácil': return verdePrimario;
      case 'Médio': return const Color(0xFFFFA726);
      default:      return const Color(0xFFFF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corDif(receita.dificuldade);
    return GestureDetector(
      onTap: aoAbrir,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cartaoEscuro,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bordaCartao),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: verdePrimario.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: verdePrimario.withOpacity(0.15)),
            ),
            child: const Icon(Icons.menu_book_rounded, color: verdePrimario, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(receita.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                if (isFavorita) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.favorite_rounded, color: Colors.amber, size: 13),
                ],
              ]),
              const SizedBox(height: 3),
              Text(receita.categoria, style: const TextStyle(fontSize: 11, color: Colors.white38)),
              const SizedBox(height: 6),
              Row(children: [
                _pildora(Icons.timer_rounded, '${receita.tempoPreparo} min', Colors.white38),
                const SizedBox(width: 6),
                _pildora(Icons.bar_chart_rounded, receita.dificuldade, cor),
                const SizedBox(width: 6),
                _pildora(Icons.local_fire_department_outlined, '${receita.calorias} kcal', const Color(0xFFFFA726)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
        ]),
      ),
    );
  }

  Widget _pildora(IconData icone, String rotulo, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withOpacity(0.2))),
        child: Row(children: [Icon(icone, size: 9, color: cor), const SizedBox(width: 3), Text(rotulo, style: TextStyle(fontSize: 9, color: cor))]),
      );
}
