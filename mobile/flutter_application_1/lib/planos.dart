import 'package:flutter/material.dart';
import 'visual.dart';

// Tela de planos — só visual por enquanto (sem cobrança real, sem endpoint
// próprio): mostra o que cada plano oferece, no mesmo espírito da aba
// "Planos" do site (web/html/perfil.html), pra o usuário saber o que ganha
// se fizer upgrade. O plano de verdade continua vindo de
// FS_usuarios.plano / listar_configuracoes.php.
class TelaPlanos extends StatelessWidget {
  final String planoAtual;
  const TelaPlanos({super.key, required this.planoAtual});

  bool get _ehPremium => planoAtual.toLowerCase() == 'premium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoEscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: verdePrimario),
        title: const Text("Planos",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text("Escolha o melhor para você",
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 22),

          _cartaoPlano(
            context,
            nome: "Free",
            preco: "0",
            descricao: "Ideal para começar.",
            atual: !_ehPremium,
            destaque: false,
            recursos: const [
              (true, "Acesso à Biblioteca de Receitas"),
              (true, "Aparecimento de Anúncios"),
              (false, "Relatório de Desperdícios"),
              (false, "Criação de Receitas com IA"),
            ],
          ),
          const SizedBox(height: 28),
          _cartaoPlano(
            context,
            nome: "Premium",
            preco: "29",
            descricao: "Tudo que você precisa para um impacto real.",
            atual: _ehPremium,
            destaque: true,
            recursos: const [
              (true, "Tudo do Free"),
              (true, "Criação de Receitas com IA"),
              (true, "Relatório de Desperdícios"),
              (true, "Suporte prioritário 24h"),
              (false, "Aparecimento de Anúncios"),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
                color: cartaoEscuro,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bordaCartao)),
            child: Row(children: [
              const Icon(Icons.shield_outlined,
                  color: verdePrimario, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                    "Garantia de 7 dias. Cancele quando quiser. Sem taxas ocultas.",
                    style: TextStyle(color: Colors.white38, fontSize: 11.5)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _cartaoPlano(
    BuildContext context, {
    required String nome,
    required String preco,
    required String descricao,
    required bool atual,
    required bool destaque,
    required List<(bool, String)> recursos,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: destaque ? verdePrimario.withOpacity(0.35) : bordaCartao,
                width: destaque ? 1.3 : 1),
            boxShadow: destaque ? brilhoPrimario : sombraCartao,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: destaque ? verdePrimario : Colors.white)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text("R\$",
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 3),
                Text(preco,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1)),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text("/mês",
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(descricao,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 18),
              ...recursos.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Icon(
                          r.$1
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 16,
                          color: r.$1 ? verdePrimario : Colors.white24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r.$2,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: r.$1 ? Colors.white70 : Colors.white24)),
                      ),
                    ]),
                  )),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: atual ? null : () => _aoTocarBotao(context, destaque),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: atual
                        ? Colors.transparent
                        : (destaque ? verdePrimario : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: atual
                            ? Colors.white24
                            : (destaque ? Colors.transparent : bordaCartao)),
                  ),
                  child: Text(
                    atual
                        ? "Plano Atual"
                        : (destaque ? "Fazer Upgrade" : "Voltar ao Free"),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: atual
                            ? Colors.white38
                            : (destaque ? Colors.black : Colors.white70)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (destaque)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: fundoEscuro,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: verdePrimario.withOpacity(0.4))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 12, color: verdePrimario),
                  SizedBox(width: 5),
                  Text("MAIS POPULAR",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: verdePrimario,
                          letterSpacing: 0.4)),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  // Só visual por enquanto: nenhuma cobrança real acontece, então avisamos
  // o usuário em vez de fingir que o upgrade/downgrade foi feito.
  void _aoTocarBotao(BuildContext context, bool destaque) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(destaque
            ? "Pagamentos ainda não estão disponíveis nesta versão."
            : "Alteração de plano ainda não está disponível nesta versão."),
        backgroundColor: cartaoEscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
