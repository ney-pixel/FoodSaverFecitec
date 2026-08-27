
import 'package:flutter/material.dart';
import '../visual.dart';
import '../usuario.dart';

class TelaPerfil extends StatelessWidget {
  final Usuario usuario;

  const TelaPerfil({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        cabecalhoPagina("Perfil"),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            physics: const BouncingScrollPhysics(),
            children: [

              //nome,xp,nivel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cartaoEscuro,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: verdePrimario.withOpacity(0.2))),
                child: Column(children: [
                  Row(children: [
                    //avatar
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: verdePrimario.withOpacity(0.12),
                          border: Border.all(
                              color: verdePrimario.withOpacity(0.4),
                              width: 1.5)),
                      child: Center(
                        child: Text(usuario.iniciais,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: verdePrimario,
                                letterSpacing: -1)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario.nome,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color:
                                      verdePrimario.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(5),
                                  border: Border.all(
                                      color: verdePrimario
                                          .withOpacity(0.25))),
                              child: Text("Nível ${usuario.nivel}",
                                  style: const TextStyle(
                                      color: verdePrimario,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                            const Text("Plano Grátis",
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11)),
                          ]),
                        ],
                      ),
                    ),
                    // Anel de progresso de XP
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(fit: StackFit.expand, children: [
                        CircularProgressIndicator(
                          value: usuario.porcentagemXP,
                          strokeWidth: 4,
                          backgroundColor: Colors.white10,
                          color: verdePrimario,
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                "${(usuario.porcentagemXP * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: verdePrimario),
                              ),
                              const Text("XP",
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white38)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  const Divider(color: bordaCartao, height: 1),
                  const SizedBox(height: 12),
                  // Estatísticas resumidas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _estatistica("${usuario.xpAtual}", "XP Total"),
                      _divisorVertical(),
                      _estatistica("32", "Al. Salvos"),
                      _divisorVertical(),
                      _estatistica("18", "Refeições"),
                      _divisorVertical(),
                      _estatistica("${usuario.nivel}", "Nível"),
                    ],
                  ),
                ]),
              ),

              const SizedBox(height: 12),

              //card destaque
              Row(children: [
                _cardDestaque("32", "Alimentos\nSalvos",
                    Icons.check_circle_outline_rounded,
                    verdePrimario, "+4 este mês"),
                const SizedBox(width: 8),
                _cardDestaque("18", "Refeições\nAproveitadas",
                    Icons.restaurant_outlined,
                    const Color(0xFF4FC3F7), "+2 este mês"),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _cardDestaque("3",  "Conquistas\nDesbloqueadas",
                    Icons.emoji_events_outlined,
                    Colors.amber, "Estável"),
                const SizedBox(width: 8),
                _cardDestaque("12", "Dias de\nSequência",
                    Icons.bolt_rounded,
                    const Color(0xFF9B59B6), "Recorde!"),
              ]),

              const SizedBox(height: 16),

              //conquistas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  rotuloSecao("Conquistas"),
                  const Text("3 / 12",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),

              ...[
                ("Anti-desperdício",      "Salvou 10+ alimentos",       true,  Icons.recycling_rounded),
                ("Iniciante sustentável", "Criou 5 receitas",            true,  Icons.restaurant_rounded),
                ("Eco User",              "7 dias seguidos ativos",      true,  Icons.public_rounded),
                ("Speed Saver",           "Adicione 5 itens em um dia",  false, Icons.bolt_rounded),
                ("Master Chef",           "Crie 20 receitas",            false, Icons.restaurant_menu_rounded),
              ].map((conquista) {
                final (titulo, descricao, desbloqueada, icone) = conquista;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: cartaoEscuro,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: desbloqueada
                              ? verdePrimario.withOpacity(0.2)
                              : bordaCartao)),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: desbloqueada
                              ? verdePrimario.withOpacity(0.12)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(icone,
                          color: desbloqueada
                              ? verdePrimario
                              : Colors.white24,
                          size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: desbloqueada
                                      ? Colors.white
                                      : Colors.white38)),
                          const SizedBox(height: 2),
                          Text(descricao,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white38)),
                        ],
                      ),
                    ),
                    Icon(
                        desbloqueada
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        color: desbloqueada
                            ? verdePrimario
                            : Colors.white24,
                        size: 18),
                  ]),
                );
              }),

              const SizedBox(height: 16),

      
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  rotuloSecao("Atividade Recente"),
                  const Text("Últimos 7 dias",
                      style: TextStyle(
                          fontSize: 11, color: Colors.white38)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: cartaoEscuro,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bordaCartao)),
                child: Column(children: [
                  _itemAtividade("Adicionou Frango ao inventário",
                      "Hoje, 14:32", verdePrimario),
                  _itemAtividade(
                      "Criou receita \"Sopa de Cenoura\"",
                      "Ontem, 19:10", const Color(0xFF6C63FF)),
                  _itemAtividade("Salvou 2kg de Cenoura",
                      "Ontem, 11:05", verdePrimario),
                  _itemAtividade(
                      "Conquista: Eco User desbloqueada",
                      "Há 2 dias", Colors.amber),
                  _itemAtividade(
                      "Criou receita \"Arroz com Frango\"",
                      "Há 3 dias", const Color(0xFF6C63FF)),
                  _itemAtividade(
                      "Adicionou Arroz 3kg ao estoque",
                      "Há 5 dias", verdePrimario,
                      ultimo: true),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _estatistica(String valor, String rotulo) => Column(children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(rotulo,
            style: const TextStyle(
                fontSize: 10, color: Colors.white38)),
      ]);

  Widget _divisorVertical() =>
      Container(width: 0.5, height: 28, color: bordaCartao);

  Widget _cardDestaque(String valor, String rotulo, IconData icone,
          Color cor, String subtitulo) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
              color: cartaoEscuro,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bordaCartao)),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: cor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icone, color: cor, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  Text(rotulo,
                      style: const TextStyle(
                          fontSize: 9, color: Colors.white38),
                      maxLines: 2),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: TextStyle(
                          fontSize: 9,
                          color: cor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _itemAtividade(String titulo, String horario, Color cor,
          {bool ultimo = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: ultimo ? 0 : 11),
        child: Row(children: [
          Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: cor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(horario,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
        ]),
      );
}