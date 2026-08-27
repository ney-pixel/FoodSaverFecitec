import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';

class TelaRelatorios extends StatelessWidget {
  final Usuario usuario;
  const TelaRelatorios({super.key, required this.usuario});

  // Abre o bottom sheet com os planos
  void _mostrarPlanos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BottomSheetPlanos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        cabecalhoPagina(
          "Relatórios",
          acaoTopo: const Icon(Icons.lock_rounded, color: Colors.amber, size: 18),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              cartao(
                filho: const Row(children: [
                  Icon(Icons.bar_chart_rounded, color: Colors.white38, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Análise de desperdício, consumo e performance alimentar",
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cartaoEscuro,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Column(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(height: 12),
                  const Text("Conteúdo Premium",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text(
                    "Assine o FoodSaver Pro para acessar relatórios avançados de desperdício, economia e performance.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Gráficos  ·  Histórico  ·  Insights IA",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: verdePrimario, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _mostrarPlanos(context),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.amber, Color(0xFFFF8C00)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text("Mostrar Planos",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// planos
class _BottomSheetPlanos extends StatelessWidget {
  const _BottomSheetPlanos();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          const Text(
            "Escolha seu plano",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Sem compromisso. Cancele quando quiser.",
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 20),

          // Cards lado a lado
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Card Free ──
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Free",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 10),
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(text: "R\$ ", style: TextStyle(fontSize: 13, color: Colors.white54)),
                            TextSpan(text: "0", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                            TextSpan(text: " /mês", style: TextStyle(fontSize: 12, color: Colors.white38)),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        const Text("Ideal para começar.",
                            style: TextStyle(fontSize: 12, color: Colors.white38)),
                        const SizedBox(height: 16),
                        _itemRecurso("Número limitado de Receitas IA", ativo: true),
                        _itemRecurso("Aparecimento de Anúncios", ativo: true),
                        _itemRecurso("Relatório com Insights IA", ativo: false),
                        _itemRecurso("Receitas ilimitadas", ativo: false),
                        const Spacer(),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 42,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text("Plano Atual",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // premium
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: verdePrimario.withOpacity(0.5), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //badge mais popular
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: verdePrimario.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: verdePrimario.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  color: verdePrimario, size: 12),
                              SizedBox(width: 4),
                              Text("MAIS POPULAR",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: verdePrimario,
                                    letterSpacing: 0.6,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text("Premium",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: verdePrimario,
                            )),
                        const SizedBox(height: 10),
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(text: "R\$ ", style: TextStyle(fontSize: 13, color: Colors.white54)),
                            TextSpan(text: "29", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                            TextSpan(text: " /mês", style: TextStyle(fontSize: 12, color: Colors.white38)),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        const Text("Tudo que você precisa\npara um impacto real.",
                            style: TextStyle(fontSize: 12, color: Colors.white54)),
                        const SizedBox(height: 16),
                        _itemRecurso("Tudo do Free", ativo: true),
                        _itemRecurso("IA de receitas ilimitada", ativo: true),
                        _itemRecurso("Relatórios com Insights IA", ativo: true),
                        _itemRecurso("Suporte prioritário 24h", ativo: true),
                        _itemRecurso("Aparecimento de Anúncios", ativo: false),
                        const Spacer(),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 42,
                          decoration: BoxDecoration(
                            color: verdePrimario,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: verdePrimario.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text("Fazer Upgrade",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //ativo e inativo verde e cinza
  static Widget _itemRecurso(String texto, {required bool ativo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18, margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: ativo
                  ? verdePrimario.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ativo ? Icons.check_rounded : Icons.close_rounded,
              size: 11,
              color: ativo ? verdePrimario : Colors.white24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: ativo ? Colors.white : Colors.white24,
                decoration: ativo ? null : TextDecoration.lineThrough,
                decorationColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}