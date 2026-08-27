import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'banco_dados.dart';
import 'banco_receitas.dart';
import 'receita.dart';
import 'alimento.dart';

class TelaReceitas extends StatefulWidget {
  final Usuario usuario;
  const TelaReceitas({super.key, required this.usuario});
  @override
  State<TelaReceitas> createState() => _TelaReceitasState();
}

class _TelaReceitasState extends State<TelaReceitas>
    with SingleTickerProviderStateMixin {
  late TabController _controladorSubabas;

  final List<Receita> _favoritas = [];

  final List<_GrupoReceitas> _grupos = [];

  void _aoFavoritar(Receita receita) {
    setState(() {
      if (!_favoritas.any((r) => r.id == receita.id)) {
        receita.favorita = true;
        _favoritas.add(receita);
      }
    });
  }

  void _aoDesfavoritar(Receita receita) {
    setState(() {
      receita.favorita = false;
      _favoritas.removeWhere((r) => r.id == receita.id);
    });
  }

  @override
  void initState() {
    super.initState();
    _controladorSubabas = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controladorSubabas.dispose();
    super.dispose();
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
          child: TabBarView(
            controller: _controladorSubabas,
            children: [
              _SubabaCriar(aoFavoritar: _aoFavoritar, favoritas: _favoritas),
              _SubabaFavoritas(favoritas: _favoritas, aoDesfavoritar: _aoDesfavoritar),
              _SubabaGruposReceitas(grupos: _grupos, todasFavoritas: _favoritas),
              _SubabaBiblioteca(aoFavoritar: _aoFavoritar, favoritas: _favoritas),
            ],
          ),
        ),
      ],
    );
  }
}

//subaba criar receitas
class _SubabaCriar extends StatefulWidget {
  final void Function(Receita) aoFavoritar;
  final List<Receita> favoritas;
  const _SubabaCriar({required this.aoFavoritar, required this.favoritas});
  @override
  State<_SubabaCriar> createState() => _SubabaCriarState();
}

class _SubabaCriarState extends State<_SubabaCriar> {
  final _controladorBuscaIngrediente = TextEditingController();
  final _focoBuscaIngrediente = FocusNode();
  final List<String> _ingredientesSelecionados = [];
  int _numeroPessoas = 2;
  int _indiceFome    = 1;
  final _nivelFome   = ['Leve', 'Médio', 'Muita fome'];

  int get _totalSelecionados => _ingredientesSelecionados.length;
  List<String> get _nomesSelecionados => _ingredientesSelecionados;

  //alimentos do estoque disponiveis para sugestao em receitas (com IA ativada)
  List<String> get _alimentosDisponiveis =>
      BancoDados.estoque.where((a) => a.entrarNaIA).map((a) => a.nome).toList();

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
    _focoBuscaIngrediente.dispose();
    super.dispose();
  }

  void _gerarReceita() {
    final receitasEncontradas = BancoReceitas.buscarPorIngredientes(_nomesSelecionados);
    if (receitasEncontradas.isEmpty) {
      _mostrarSemResultado();
    } else {
      _mostrarReceita(receitasEncontradas.first);
    }
  }

  void _mostrarSemResultado() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cartaoEscuro,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: const Icon(Icons.restaurant_outlined, color: Colors.white38, size: 28)),
          const SizedBox(height: 16),
          const Text('Nenhuma receita encontrada', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Tente selecionar mais ingredientes ou uma combinação diferente.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
        ]),
      ),
    );
  }

  void _mostrarReceita(Receita receita) {
    final jaFavorita = widget.favoritas.any((r) => r.id == receita.id);
    bool _favoritado = jaFavorita;

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
              // Handle
              Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              // Cabeçalho fixo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _badgeCategoria(receita.categoria),
                      const SizedBox(height: 6),
                      Text(receita.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(receita.descricao, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setB(() => _favoritado = !_favoritado);
                      if (_favoritado) {
                        widget.aoFavoritar(receita);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: _favoritado ? Colors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: _favoritado ? Colors.amber.withOpacity(0.5) : Colors.white12),
                      ),
                      child: Icon(_favoritado ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _favoritado ? Colors.amber : Colors.white38, size: 22),
                    ),
                  ),
                ]),
              ),
              // Chips de info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  _chipInfo(Icons.timer_rounded, '${receita.tempoPreparo} min', Colors.white54),
                  const SizedBox(width: 8),
                  _chipInfo(Icons.bar_chart_rounded, receita.dificuldade, _corDificuldade(receita.dificuldade)),
                  const SizedBox(width: 8),
                  _chipInfo(Icons.people_outline_rounded, '${receita.porcoes} porções', Colors.white54),
                  const SizedBox(width: 8),
                  _chipInfo(Icons.local_fire_department_outlined, '${receita.calorias} kcal', const Color(0xFFFFA726)),
                ]),
              ),
              const Divider(color: bordaCartao, height: 1),
              // Conteúdo scrollável
              Expanded(
                child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
                  // Ingredientes
                  _tituloSecao('Ingredientes'),
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
                  // Modo de preparo
                  _tituloSecao('Modo de preparo'),
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
                    _tituloSecao('Dicas'),
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

  Color _corDificuldade(String d) {
    switch (d) {
      case 'Fácil': return verdePrimario;
      case 'Médio': return const Color(0xFFFFA726);
      default:      return const Color(0xFFFF4444);
    }
  }

  Widget _badgeCategoria(String cat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3))),
        child: Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9B8FFF))),
      );

  Widget _chipInfo(IconData icone, String rotulo, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 11, color: cor),
          const SizedBox(width: 4),
          Text(rotulo, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _tituloSecao(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3));

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
          child: const TextField(maxLines: null, expands: true, style: TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: 'Ex: sem glúten, rápido de fazer...', hintStyle: TextStyle(color: Colors.white30, fontSize: 12), border: InputBorder.none, contentPadding: EdgeInsets.all(14))),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _totalSelecionados > 0 ? _gerarReceita : null,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _totalSelecionados > 0 ? [const Color(0xFF6C63FF), const Color(0xFF9B59B6)] : [const Color(0xFF222222), const Color(0xFF222222)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _totalSelecionados > 0 ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 5))] : [],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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

//cartao de receita
class _CartaoReceitaSimples extends StatelessWidget {
  final Receita receita;
  final VoidCallback aoAbrir;
  const _CartaoReceitaSimples({required this.receita, required this.aoAbrir});

  @override
  Widget build(BuildContext context) {
    final cor = receita.dificuldade == 'Fácil' ? verdePrimario : const Color(0xFFFFA726);
    return GestureDetector(
      onTap: aoAbrir,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.18))),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2))), child: const Icon(Icons.restaurant_rounded, color: Color(0xFF9B8FFF), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)]), borderRadius: BorderRadius.circular(4)), child: const Text('IA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
              const SizedBox(width: 6),
              Flexible(child: Text(receita.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
            ]),
            const SizedBox(height: 3),
            Text(receita.ingredientesNecessarios.join(' · '), style: const TextStyle(fontSize: 10, color: Colors.white38), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(children: [
              _pildora(Icons.timer_rounded, '${receita.tempoPreparo} min', Colors.white38),
              const SizedBox(width: 6),
              _pildora(Icons.bar_chart_rounded, receita.dificuldade, cor),
            ]),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
        ]),
      ),
    );
  }

  Widget _pildora(IconData icone, String rotulo, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withOpacity(0.2))),
        child: Row(children: [Icon(icone, size: 10, color: cor), const SizedBox(width: 3), Text(rotulo, style: TextStyle(fontSize: 10, color: cor))]),
      );
}

//subaba favoritas
class _SubabaFavoritas extends StatelessWidget {
  final List<Receita> favoritas;
  final void Function(Receita) aoDesfavoritar;
  const _SubabaFavoritas({required this.favoritas, required this.aoDesfavoritar});

  @override
  Widget build(BuildContext context) {
    if (favoritas.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.favorite_border_rounded, color: Colors.amber, size: 32)),
        const SizedBox(height: 16),
        const Text('Nenhuma receita favoritada', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Gere uma receita e favorite\npara ela aparecer aqui', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]));
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      itemCount: favoritas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = favoritas[i];
        return _CartaoFavorita(receita: r, aoDesfavoritar: () => aoDesfavoritar(r));
      },
    );
  }
}

class _CartaoFavorita extends StatelessWidget {
  final Receita receita;
  final VoidCallback aoDesfavoritar;
  const _CartaoFavorita({required this.receita, required this.aoDesfavoritar});

  @override
  Widget build(BuildContext context) {
    final cor = receita.dificuldade == 'Fácil' ? verdePrimario : const Color(0xFFFFA726);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cartaoEscuro, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.amber.withOpacity(0.25))), child: const Icon(Icons.favorite_rounded, color: Colors.amber, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(receita.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 3),
            Text(receita.ingredientesNecessarios.join(' · '), style: const TextStyle(fontSize: 11, color: Colors.white38), overflow: TextOverflow.ellipsis),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _pildora(Icons.timer_rounded, '${receita.tempoPreparo} min', Colors.white38),
          const SizedBox(width: 6),
          _pildora(Icons.bar_chart_rounded, receita.dificuldade, cor),
          const SizedBox(width: 6),
          _pildora(Icons.people_outline_rounded, '${receita.porcoes} porções', Colors.white38),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: aoDesfavoritar,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFF4444).withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.favorite_border_rounded, color: Color(0xFFFF4444), size: 14),
              SizedBox(width: 6),
              Text('Desfavoritar', style: TextStyle(color: Color(0xFFFF4444), fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _pildora(IconData icone, String rotulo, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withOpacity(0.2))),
        child: Row(children: [Icon(icone, size: 10, color: cor), const SizedBox(width: 3), Text(rotulo, style: TextStyle(fontSize: 10, color: cor))]),
      );
}

//subaba grupos
class _SubabaGruposReceitas extends StatefulWidget {
  final List<_GrupoReceitas> grupos;
  final List<Receita> todasFavoritas;
  const _SubabaGruposReceitas({required this.grupos, required this.todasFavoritas});
  @override
  State<_SubabaGruposReceitas> createState() => _SubabaGruposReceitasState();
}

class _SubabaGruposReceitasState extends State<_SubabaGruposReceitas> {
  void _criarGrupo() {
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
            onPressed: () {
              final nome = ctrl.text.trim();
              if (nome.isNotEmpty) setState(() => widget.grupos.add(_GrupoReceitas(id: DateTime.now().millisecondsSinceEpoch.toString(), nome: nome)));
              Navigator.pop(ctx);
            },
            child: const Text('Criar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _adicionarReceitas(_GrupoReceitas grupo) {
    final todas = BancoReceitas.receitas;
    final sels = List<bool>.generate(todas.length, (i) => grupo.receitas.any((r) => r.id == todas[i].id));
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
              itemCount: todas.length,
              itemBuilder: (_, i) => CheckboxListTile(
                value: sels[i], onChanged: (v) => setD(() => sels[i] = v ?? false),
                activeColor: verdePrimario, checkColor: Colors.black,
                title: Text(todas[i].nome, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(todas[i].categoria, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final escolhidas = [for (int i = 0; i < todas.length; i++) if (sels[i]) todas[i]];
                setState(() {
                  final idx = widget.grupos.indexWhere((g) => g.id == grupo.id);
                  if (idx >= 0) widget.grupos[idx] = grupo.copiarCom(receitas: escolhidas);
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

  void _excluirGrupo(_GrupoReceitas grupo) {
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
            onPressed: () { setState(() => widget.grupos.removeWhere((g) => g.id == grupo.id)); Navigator.pop(ctx); },
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
          onTap: _criarGrupo,
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
        child: widget.grupos.isEmpty
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
                itemCount: widget.grupos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CartaoGrupoReceitas(grupo: widget.grupos[i], aoAdicionarReceitas: _adicionarReceitas, aoExcluir: _excluirGrupo),
              ),
      ),
    ]);
  }
}

class _CartaoGrupoReceitas extends StatelessWidget {
  final _GrupoReceitas grupo;
  final void Function(_GrupoReceitas) aoAdicionarReceitas;
  final void Function(_GrupoReceitas) aoExcluir;
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
              onSelected: (a) { if (a == 'add') aoAdicionarReceitas(grupo); if (a == 'del') aoExcluir(grupo); },
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
            onTap: () => aoAdicionarReceitas(grupo),
            child: Container(margin: const EdgeInsets.fromLTRB(14, 0, 14, 12), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: bordaCartao)), child: const Center(child: Text('+ Adicionar receitas', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)))),
          ),
      ]),
    );
  }
}

class _GrupoReceitas {
  final String id;
  final String nome;
  final List<Receita> receitas;
  _GrupoReceitas({required this.id, required this.nome, List<Receita>? receitas}) : receitas = receitas ?? [];
  _GrupoReceitas copiarCom({List<Receita>? receitas}) => _GrupoReceitas(id: id, nome: nome, receitas: receitas ?? this.receitas);
}

// ─────────────────────────────────────────────
//  Subaba: Biblioteca de Receitas
//  Todas as receitas pré-cadastradas, com filtro
//  por ingrediente/alimento e busca por nome
// ─────────────────────────────────────────────
class _SubabaBiblioteca extends StatefulWidget {
  final void Function(Receita) aoFavoritar;
  final List<Receita> favoritas;
  const _SubabaBiblioteca({required this.aoFavoritar, required this.favoritas});
  @override
  State<_SubabaBiblioteca> createState() => _SubabaBibliotecaState();
}

class _SubabaBibliotecaState extends State<_SubabaBiblioteca> {
  final _controladorBusca = TextEditingController();
  String _textoBusca = '';

  List<Receita> get _receitasFiltradas {
    var lista = BancoReceitas.receitas;

    // Filtro por texto de busca (nome ou categoria)
    if (_textoBusca.isNotEmpty) {
      final b = _textoBusca.toLowerCase();
      lista = lista.where((r) =>
          r.nome.toLowerCase().contains(b) ||
          r.categoria.toLowerCase().contains(b)).toList();
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

  // Abre o detalhe da receita (mesmo bottom sheet do Criar)
  void _verReceita(BuildContext context, Receita receita) {
    bool favoritado = widget.favoritas.any((r) => r.id == receita.id);

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
                      _badgeCategoria(receita.categoria),
                      const SizedBox(height: 6),
                      Text(receita.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(receita.descricao, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setB(() => favoritado = !favoritado);
                      if (favoritado) widget.aoFavoritar(receita);
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
                    _chipInfo(Icons.timer_rounded, '${receita.tempoPreparo} min', Colors.white54),
                    const SizedBox(width: 8),
                    _chipInfo(Icons.bar_chart_rounded, receita.dificuldade, _corDificuldade(receita.dificuldade)),
                    const SizedBox(width: 8),
                    _chipInfo(Icons.people_outline_rounded, '${receita.porcoes} porções', Colors.white54),
                    const SizedBox(width: 8),
                    _chipInfo(Icons.local_fire_department_outlined, '${receita.calorias} kcal', const Color(0xFFFFA726)),
                  ]),
                ),
              ),
              const Divider(color: bordaCartao, height: 1),
              Expanded(
                child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
                  _tituloSecao('Ingredientes'),
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
                  _tituloSecao('Modo de preparo'),
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
                    _tituloSecao('Dicas'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.2))),
                      child: Column(children: receita.dicas.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(d, style: const TextStyle(fontSize: 12, color: Colors.white60))),
                        ]),
                      )).toList()),
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

  Color _corDificuldade(String d) {
    switch (d) {
      case 'Fácil': return verdePrimario;
      case 'Médio': return const Color(0xFFFFA726);
      default:      return const Color(0xFFFF4444);
    }
  }

  Widget _badgeCategoria(String cat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3))),
        child: Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9B8FFF))),
      );

  Widget _chipInfo(IconData icone, String rotulo, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 11, color: cor),
          const SizedBox(width: 4),
          Text(rotulo, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _tituloSecao(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3));

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
                    final isFav = widget.favoritas.any((f) => f.id == r.id);
                    return _CartaoBiblioteca(
                      receita: r,
                      isFavorita: isFav,
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
          // Ícone da categoria
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