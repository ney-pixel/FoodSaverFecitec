
import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'login.dart';
import 'sobre_foodsaver.dart';
import 'sobre_nos.dart';

class TelaConfig extends StatefulWidget {
  final Usuario usuario;
  const TelaConfig({super.key, required this.usuario});

  @override
  State<TelaConfig> createState() => _TelaConfigState();
}

class _TelaConfigState extends State<TelaConfig> {
  bool _notifValidade = true;
  bool _notifReceitas = false;
  bool _notifXP       = true;
  bool _modoEscuro    = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        cabecalhoPagina("Configurações"),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            physics: const BouncingScrollPhysics(),
            children: [

              //conta
              rotuloSecao("Conta"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                    color: cartaoEscuro,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bordaCartao)),
                child: Row(children: [
                  Stack(children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: verdePrimario.withOpacity(0.12),
                          border: Border.all(
                              color: verdePrimario.withOpacity(0.3))),
                      child: Center(
                        child: Text(widget.usuario.iniciais,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: verdePrimario)),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 17, height: 17,
                        decoration: BoxDecoration(
                            color: verdePrimario,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: cartaoEscuro, width: 2)),
                        child: const Icon(Icons.edit_rounded,
                            size: 8, color: Colors.black)),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.usuario.nome,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(widget.usuario.email,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white38)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white24, size: 18),
                ]),
              ),
              const SizedBox(height: 8),
              _itemNav(Icons.badge_outlined,       "Nickname",
                  valor: "Humberto"),
              const SizedBox(height: 8),
              _itemNav(Icons.lock_outline_rounded,  "Alterar senha"),
              const SizedBox(height: 8),
              _itemNav(Icons.email_outlined,        "E-mail",
                  valor: widget.usuario.email),

              const SizedBox(height: 20),

              //notific.
              rotuloSecao("Notificações"),
              const SizedBox(height: 10),
              _itemToggle(
                "Alertas de validade",
                "Avisar quando alimentos vencerão",
                _notifValidade,
                () => setState(() => _notifValidade = !_notifValidade),
              ),
              const SizedBox(height: 8),
              _itemToggle(
                "Novas receitas IA",
                "Sugestões diárias personalizadas",
                _notifReceitas,
                () => setState(() => _notifReceitas = !_notifReceitas),
              ),
              const SizedBox(height: 8),
              _itemToggle(
                "XP e conquistas",
                "Ao subir de nível ou ganhar conquista",
                _notifXP,
                () => setState(() => _notifXP = !_notifXP),
              ),

              const SizedBox(height: 20),

              //aparencia
              rotuloSecao("Aparência"),
              const SizedBox(height: 10),
              _itemToggle(
                "Modo escuro",
                "Interface com fundo escuro",
                _modoEscuro,
                () => setState(() => _modoEscuro = !_modoEscuro),
              ),

              const SizedBox(height: 20),

              //privacidade
              rotuloSecao("Privacidade"),
              const SizedBox(height: 10),
              _itemNav(Icons.security_outlined, "Permissões do app"),
              const SizedBox(height: 8),
              _itemNav(Icons.download_outlined,  "Exportar meus dados"),

              const SizedBox(height: 20),

              //sobre
              rotuloSecao("Sobre"),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const TelaSobreFoodSaver())),
                child: _itemNav(Icons.info_outline_rounded,
                    "Sobre o FoodSaver", valor: "v1.0.0"),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const TelaSobreNos())),
                child: _itemNav(Icons.people_outline_rounded,
                    "Sobre nós"),
              ),
              const SizedBox(height: 8),
              _itemNav(Icons.help_outline_rounded,   "Central de ajuda"),
              const SizedBox(height: 8),
              _itemNav(Icons.feedback_outlined,      "Enviar feedback"),

              const SizedBox(height: 20),

              //quitar
              GestureDetector(
                onTap: () => _confirmarSaida(context),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFFFF4444).withOpacity(0.25)),
                  ),
                  child: const Center(
                    child: Text("Sair da conta",
                        style: TextStyle(
                            color: Color(0xFFFF4444),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmarSaida(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Sair da conta?",
            style: TextStyle(color: Colors.white)),
        content: const Text("Você precisará fazer login novamente.",
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const TelaLogin()),
                (_) => false,
              );
            },
            child: const Text("Sair",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _itemNav(IconData icone, String rotulo, {String? valor}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bordaCartao)),
        child: Row(children: [
          Icon(icone, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(rotulo,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500)),
          ),
          if (valor != null) ...[
            Text(valor,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white38)),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white24, size: 16),
        ]),
      );

  Widget _itemToggle(
          String titulo, String sub, bool ativo, VoidCallback aoAlternar) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bordaCartao)),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white30)),
              ],
            ),
          ),
          GestureDetector(
            onTap: aoAlternar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 42, height: 24,
              decoration: BoxDecoration(
                  color:
                      ativo ? verdePrimario : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                alignment:
                    ativo ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18, height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ]),
      );
}