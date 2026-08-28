import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'visual.dart';
import 'usuario.dart';
import 'api_cliente.dart';

// ─────────────────────────────────────────────
//  Tela principal de Relatórios
// ─────────────────────────────────────────────
class TelaRelatorios extends StatefulWidget {
  final Usuario usuario;
  const TelaRelatorios({super.key, required this.usuario});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  int _periodo = 30; // 7, 30 ou 90 dias
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _dados;

  @override
  void initState() {
    super.initState();
    _buscarDados();
  }

  Future<void> _buscarDados() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final body = await ApiCliente.get(
        '/relatorio/relatorios.php',
        query: {'periodo': '$_periodo'},
      );
      setState(() { _dados = body; _carregando = false; });
    } on ApiException catch (e) {
      setState(() { _erro = e.mensagem; _carregando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabeçalho com seletor de período
        _Cabecalho(
          periodo: _periodo,
          aoMudar: (p) { setState(() => _periodo = p); _buscarDados(); },
        ),

        // Corpo
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: verdePrimario))
              : _erro != null
                  ? _ErroView(mensagem: _erro!, aoTentar: _buscarDados)
                  : RefreshIndicator(
                      color: verdePrimario,
                      backgroundColor: cartaoEscuro,
                      onRefresh: _buscarDados,
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                        children: [
                          _ResumoEstoque(dados: _dados!['resumo_estoque']),
                          const SizedBox(height: 20),
                          _TaxaAproveitamento(
                            dados: _dados!['taxa_aproveitamento'],
                            comparacao: _dados!['comparacao'],
                          ),
                          const SizedBox(height: 20),
                          _GraficoDesperdicoPorDia(
                            pontos: _dados!['desperdicio_por_dia'] as List,
                            periodo: _periodo,
                            comparacao: _dados!['comparacao'],
                          ),
                          const SizedBox(height: 20),
                          _TopAlimentos(
                            titulo: 'Mais desperdiçados',
                            icone: Icons.delete_outline_rounded,
                            cor: const Color(0xFFFF4444),
                            lista: _dados!['top_desperdicados'] as List,
                          ),
                          const SizedBox(height: 20),
                          _TopAlimentos(
                            titulo: 'Mais consumidos',
                            icone: Icons.check_circle_outline_rounded,
                            cor: verdePrimario,
                            lista: _dados!['top_consumidos'] as List,
                          ),
                          const SizedBox(height: 20),
                          _SituacaoValidades(
                              dados: _dados!['situacao_validades']),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Cabeçalho com seletor de período
// ─────────────────────────────────────────────
class _Cabecalho extends StatelessWidget {
  final int periodo;
  final void Function(int) aoMudar;
  const _Cabecalho({required this.periodo, required this.aoMudar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: bordaCartao, width: 0.5))),
      child: Row(children: [
        const Text('Relatórios',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5)),
        const Spacer(),
        // Seletor de período
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: cartaoEscuro,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bordaCartao)),
          child: Row(
            children: [
              _chipPeriodo('7d',  7,  periodo, aoMudar),
              _chipPeriodo('30d', 30, periodo, aoMudar),
              _chipPeriodo('90d', 90, periodo, aoMudar),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chipPeriodo(String rotulo, int valor, int atual, void Function(int) cb) {
    final sel = atual == valor;
    return GestureDetector(
      onTap: () => cb(valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? verdePrimario : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(rotulo,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.black : Colors.white38)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  1. Resumo do estoque
// ─────────────────────────────────────────────
class _ResumoEstoque extends StatelessWidget {
  final Map<String, dynamic> dados;
  const _ResumoEstoque({required this.dados});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      rotuloSecao('Resumo do estoque'),
      const SizedBox(height: 10),
      Row(children: [
        _cardMetrica(
          '${dados['total_alimentos']}',
          'No estoque',
          Icons.inventory_2_outlined,
          Colors.white70,
        ),
        const SizedBox(width: 10),
        _cardMetrica(
          '${dados['proximos_vencimento']}',
          'Vencem em 7d',
          Icons.schedule_rounded,
          const Color(0xFFFFA726),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _cardMetrica(
          '${dados['vencidos']}',
          'Vencidos',
          Icons.warning_amber_rounded,
          const Color(0xFFFF4444),
        ),
        const SizedBox(width: 10),
        _cardMetrica(
          _formatarQtd(dados['total_desperdicado'] as num),
          'Desperdício total',
          Icons.delete_outline_rounded,
          const Color(0xFFFF6B6B),
        ),
      ]),
    ]);
  }

  Widget _cardMetrica(String valor, String rotulo, IconData icone, Color cor) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cartaoEscuro,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bordaCartao)),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icone, color: cor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(valor,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                Text(rotulo,
                    style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ]),
            ),
          ]),
        ),
      );

  String _formatarQtd(num v) =>
      v == v.truncate() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

// ─────────────────────────────────────────────
//  6. Taxa de aproveitamento + comparação (7)
// ─────────────────────────────────────────────
class _TaxaAproveitamento extends StatelessWidget {
  final Map<String, dynamic> dados;
  final Map<String, dynamic> comparacao;
  const _TaxaAproveitamento({required this.dados, required this.comparacao});

  @override
  Widget build(BuildContext context) {
    final taxa       = dados['taxa'] as num?;
    final consumido  = (dados['consumido']    as num).toDouble();
    final desperd    = (dados['desperdicado'] as num).toDouble();
    final taxaAnterior = comparacao['taxa_anterior'] as num?;
    final varTaxa      = comparacao['variacao_taxa'] as num?;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      rotuloSecao('Taxa de aproveitamento'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: taxa == null
                    ? bordaCartao
                    : taxa >= 80
                        ? verdePrimario.withOpacity(0.3)
                        : const Color(0xFFFFA726).withOpacity(0.3))),
        child: taxa == null
            ? const Center(
                child: Text('Sem movimentações no período.',
                    style: TextStyle(color: Colors.white38, fontSize: 13)))
            : Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  // Número grande
                  Text('${taxa.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: taxa >= 80
                              ? verdePrimario
                              : const Color(0xFFFFA726),
                          letterSpacing: -1.5)),
                  // Gauge circular
                  SizedBox(
                    width: 60, height: 60,
                    child: Stack(fit: StackFit.expand, children: [
                      CircularProgressIndicator(
                        value: taxa / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white10,
                        color: taxa >= 80
                            ? verdePrimario
                            : const Color(0xFFFFA726),
                      ),
                      Center(
                        child: Icon(
                          taxa >= 80
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_down_rounded,
                          color: taxa >= 80
                              ? verdePrimario
                              : const Color(0xFFFFA726),
                          size: 20,
                        ),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                // Barra consumido vs desperdiçado
                _BarraConsumo(consumido: consumido, desperdicio: desperd),
                const SizedBox(height: 12),
                // Comparação com período anterior
                if (taxaAnterior != null && varTaxa != null)
                  _chipComparacao(
                    'Período anterior: ${taxaAnterior.toStringAsFixed(1)}%  '
                    '${varTaxa >= 0 ? '↑' : '↓'} ${varTaxa.abs().toStringAsFixed(1)} pp',
                    varTaxa >= 0,
                  ),
              ]),
      ),
    ]);
  }

  Widget _chipComparacao(String texto, bool melhora) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: (melhora ? verdePrimario : const Color(0xFFFF4444))
                .withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: (melhora ? verdePrimario : const Color(0xFFFF4444))
                    .withOpacity(0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            melhora ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: melhora ? verdePrimario : const Color(0xFFFF4444),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 11,
                    color: melhora ? verdePrimario : const Color(0xFFFF4444),
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

// Barra visual consumido/desperdiçado
class _BarraConsumo extends StatelessWidget {
  final double consumido;
  final double desperdicio;
  const _BarraConsumo({required this.consumido, required this.desperdicio});

  @override
  Widget build(BuildContext context) {
    final total = consumido + desperdicio;
    final pctCons = total > 0 ? consumido / total : 0.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _legenda(verdePrimario, 'Consumido: ${_fmt(consumido)}'),
        const SizedBox(width: 16),
        _legenda(const Color(0xFFFF4444), 'Desperdiçado: ${_fmt(desperdicio)}'),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 8,
          child: total == 0
              ? Container(color: Colors.white10)
              : Row(children: [
                  Expanded(
                    flex: (pctCons * 100).round(),
                    child: Container(color: verdePrimario),
                  ),
                  Expanded(
                    flex: ((1 - pctCons) * 100).round(),
                    child: Container(color: const Color(0xFFFF4444)),
                  ),
                ]),
        ),
      ),
    ]);
  }

  Widget _legenda(Color cor, String texto) => Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ]);

  String _fmt(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

// ─────────────────────────────────────────────
//  2. Gráfico de desperdício por dia
// ─────────────────────────────────────────────
class _GraficoDesperdicoPorDia extends StatelessWidget {
  final List pontos;
  final int periodo;
  final Map<String, dynamic> comparacao;
  const _GraficoDesperdicoPorDia(
      {required this.pontos, required this.periodo, required this.comparacao});

  @override
  Widget build(BuildContext context) {
    final varDesp      = comparacao['variacao_desperdicio'] as num?;
    final despAtual    = (comparacao['desperdicio_atual']    as num).toDouble();
    final despAnterior = (comparacao['desperdicio_anterior'] as num).toDouble();

    // Converte pontos para FlSpot
    final spots = pontos.asMap().entries.map((e) {
      final total = (e.value['total'] as num).toDouble();
      return FlSpot(e.key.toDouble(), total);
    }).toList();

    final maxY = spots.isEmpty
        ? 1.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxYAjustado = maxY == 0 ? 1.0 : maxY * 1.2;

    // Intervalo de labels no eixo X
    final intervalo = periodo == 7 ? 1 : periodo == 30 ? 7 : 15;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      rotuloSecao('Desperdício no período'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bordaCartao)),
        child: Column(children: [
          // Comparação de valores
          if (varDesp != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Expanded(child: _miniCard('Atual', despAtual, true)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Anterior', despAnterior, false)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: varDesp <= 0
                            ? verdePrimario.withOpacity(0.1)
                            : const Color(0xFFFF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: varDesp <= 0
                                ? verdePrimario.withOpacity(0.3)
                                : const Color(0xFFFF4444).withOpacity(0.3))),
                    child: Column(children: [
                      Icon(
                        varDesp <= 0
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        color: varDesp <= 0
                            ? verdePrimario
                            : const Color(0xFFFF4444),
                        size: 18,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${varDesp.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: varDesp <= 0
                                ? verdePrimario
                                : const Color(0xFFFF4444)),
                      ),
                      Text(
                        varDesp <= 0 ? 'Redução' : 'Aumento',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white38),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),

          // Gráfico
          SizedBox(
            height: 160,
            child: pontos.every((p) => (p['total'] as num) == 0)
                ? const Center(
                    child: Text('Sem desperdício registrado neste período.',
                        style: TextStyle(color: Colors.white38, fontSize: 12)))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxYAjustado,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white10, strokeWidth: 0.5),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              v == 0 ? '' : _fmtY(v),
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white38),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: intervalo.toDouble(),
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= pontos.length) {
                                return const SizedBox.shrink();
                              }
                              final dia = (pontos[idx]['dia'] as String)
                                  .substring(5); // MM-DD
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(dia,
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.white38)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFFFF4444),
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, _, __, ___) =>
                                FlDotCirclePainter(
                              radius: s.y > 0 ? 3 : 0,
                              color: const Color(0xFFFF4444),
                              strokeWidth: 0,
                              strokeColor: Colors.transparent,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF4444).withOpacity(0.2),
                                const Color(0xFFFF4444).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    ]);
  }

  Widget _miniCard(String rotulo, double valor, bool atual) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bordaCartao)),
        child: Column(children: [
          Text(_fmtY(valor),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(rotulo,
              style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ]),
      );

  String _fmtY(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

// ─────────────────────────────────────────────
//  3 & 4. Top alimentos (desperdiçados / consumidos)
// ─────────────────────────────────────────────
class _TopAlimentos extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color cor;
  final List lista;
  const _TopAlimentos(
      {required this.titulo,
      required this.icone,
      required this.cor,
      required this.lista});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      rotuloSecao(titulo),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bordaCartao)),
        child: lista.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: Text('Nenhum registro neste período.',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ),
              )
            : Column(
                children: lista.asMap().entries.map((e) {
                  final item  = e.value as Map<String, dynamic>;
                  final total = (item['total'] as num).toDouble();
                  final max   = (lista.first['total'] as num).toDouble();
                  final pct   = max > 0 ? total / max : 0.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        14, e.key == 0 ? 12 : 8, 14,
                        e.key == lista.length - 1 ? 12 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          // Posição
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                                color: e.key == 0
                                    ? cor.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(6)),
                            child: Center(
                              child: Text('${e.key + 1}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: e.key == 0
                                          ? cor
                                          : Colors.white38)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item['nome'] as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                          Text(
                            '${_fmt(total)} ${item['unidade']}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cor),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        // Barra de progresso relativa ao 1º
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.white10,
                            color: cor,
                            minHeight: 4,
                          ),
                        ),
                        if (e.key < lista.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.05)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    ]);
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

// ─────────────────────────────────────────────
//  5. Situação das validades
// ─────────────────────────────────────────────
class _SituacaoValidades extends StatelessWidget {
  final Map<String, dynamic> dados;
  const _SituacaoValidades({required this.dados});

  @override
  Widget build(BuildContext context) {
    final grupos = [
      (
        'Vencidos',
        dados['vencidos'] as List,
        const Color(0xFFFF4444),
        Icons.error_outline_rounded,
      ),
      (
        'Vencem em até 3 dias',
        dados['ate3dias'] as List,
        const Color(0xFFFF7043),
        Icons.warning_amber_rounded,
      ),
      (
        'Vencem em até 7 dias',
        dados['ate7dias'] as List,
        const Color(0xFFFFA726),
        Icons.schedule_rounded,
      ),
      (
        'Validade OK',
        dados['ok'] as List,
        verdePrimario,
        Icons.check_circle_outline_rounded,
      ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      rotuloSecao('Situação das validades'),
      const SizedBox(height: 10),
      ...grupos.map((g) {
        final (titulo, lista, cor, icone) = g;
        return _GrupoValidade(
          titulo: titulo,
          lista: lista,
          cor: cor,
          icone: icone,
        );
      }),
    ]);
  }
}

class _GrupoValidade extends StatefulWidget {
  final String titulo;
  final List lista;
  final Color cor;
  final IconData icone;
  const _GrupoValidade(
      {required this.titulo,
      required this.lista,
      required this.cor,
      required this.icone});

  @override
  State<_GrupoValidade> createState() => _GrupoValidadeState();
}

class _GrupoValidadeState extends State<_GrupoValidade> {
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    // Expande automaticamente grupos de alerta
    _expandido = widget.lista.isNotEmpty &&
        widget.titulo != 'Validade OK';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: widget.lista.isEmpty
                    ? bordaCartao
                    : widget.cor.withOpacity(0.25))),
        child: Column(
          children: [
            // Cabeçalho clicável
            GestureDetector(
              onTap: () => setState(() => _expandido = !_expandido),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                        color: widget.cor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(widget.icone, color: widget.cor, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.titulo,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: widget.cor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${widget.lista.length}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: widget.cor)),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                ]),
              ),
            ),

            // Itens expandidos
            if (_expandido && widget.lista.isNotEmpty) ...[
              const Divider(color: bordaCartao, height: 1),
              ...widget.lista.map((item) {
                final i = item as Map<String, dynamic>;
                final dias = (i['dias'] as num).toInt();
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Text(i['nome'] as String,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70)),
                    ),
                    Text(
                      '${(i['quantidade'] as num).toStringAsFixed(1)} ${i['unidade']}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dias < 0
                          ? '${dias.abs()}d atrás'
                          : dias == 0
                              ? 'Hoje'
                              : 'em ${dias}d',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.cor),
                    ),
                  ]),
                );
              }),
            ],

            if (_expandido && widget.lista.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text('Nenhum alimento nesta categoria.',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Estado de erro
// ─────────────────────────────────────────────
class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback aoTentar;
  const _ErroView({required this.mensagem, required this.aoTentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Text(mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: aoTentar,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: verdePrimario,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Tentar novamente',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ]),
      ),
    );
  }
}