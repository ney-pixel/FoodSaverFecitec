
import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'api_cliente.dart';
import 'login.dart';
import 'sobre_foodsaver.dart';
import 'sobre_nos.dart';
import 'planos.dart';

class TelaConfig extends StatefulWidget {
  final Usuario usuario;
  const TelaConfig({super.key, required this.usuario});

  @override
  State<TelaConfig> createState() => _TelaConfigState();
}

class _TelaConfigState extends State<TelaConfig> {
  bool _carregando = true;
  String? _erro;
  String _username = '';
  String _email = '';
  String _plano = 'gratis';
  bool _alertasValidade = true;

  @override
  void initState() {
    super.initState();
    _username = widget.usuario.nome;
    _email = widget.usuario.email;
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final resp = await ApiCliente.get('/configuracoes/listar_configuracoes.php');
      final cfg = resp['configuracoes'] as Map<String, dynamic>;
      setState(() {
        _username = (cfg['username'] as String?) ?? _username;
        _email = (cfg['email'] as String?) ?? _email;
        _plano = (cfg['plano'] as String?) ?? 'gratis';
        _alertasValidade = cfg['alertas_validade'] == true;
        _carregando = false;
      });
    } on ApiException catch (e) {
      setState(() { _carregando = false; _erro = e.mensagem; });
    }
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

  Future<void> _salvarPreferencia(Map<String, dynamic> corpo) async {
    try {
      await ApiCliente.post('/configuracoes/atualizar_configuracoes.php', corpo: corpo);
    } on ApiException catch (e) {
      _mostrarErro(e.mensagem);
      await _carregarConfiguracoes(); // reverte visualmente em caso de erro
    }
  }

  void _editarCampoTexto({
    required String titulo,
    required String valorAtual,
    required String campo, // 'username' ou 'email'
    TextInputType? tipoTeclado,
  }) {
    final ctrl = TextEditingController(text: valorAtual);
    String? erro;
    bool enviando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            keyboardType: tipoTeclado,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              errorText: erro,
              filled: true, fillColor: const Color(0xFF1C1C1C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: verdePrimario, width: 1.2)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: enviando ? null : () async {
                final valor = ctrl.text.trim();
                if (valor.isEmpty) { setD(() => erro = 'Campo obrigatório'); return; }
                setD(() => enviando = true);
                try {
                  await ApiCliente.post('/configuracoes/atualizar_configuracoes.php', corpo: {campo: valor});
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _carregarConfiguracoes();
                  _mostrarSucesso('Atualizado com sucesso!');
                } on ApiException catch (e) {
                  setD(() { enviando = false; erro = e.mensagem; });
                }
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoAlterarSenha() {
    final ctrlAtual = TextEditingController();
    final ctrlNova = TextEditingController();
    final ctrlConf = TextEditingController();
    String? erro;
    bool enviando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cartaoEscuro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Alterar senha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ctrlAtual, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _decoracao('Senha atual')),
            const SizedBox(height: 10),
            TextField(controller: ctrlNova, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _decoracao('Nova senha (mín. 6 caracteres)')),
            const SizedBox(height: 10),
            TextField(controller: ctrlConf, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _decoracao('Confirmar nova senha')),
            if (erro != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(erro!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: verdePrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: enviando ? null : () async {
                if (ctrlNova.text.length < 6) { setD(() => erro = 'A nova senha deve ter ao menos 6 caracteres.'); return; }
                if (ctrlNova.text != ctrlConf.text) { setD(() => erro = 'As senhas não coincidem.'); return; }
                setD(() => enviando = true);
                try {
                  await ApiCliente.post('/configuracoes/atualizar_configuracoes.php', corpo: {
                    'senha_atual': ctrlAtual.text,
                    'senha_nova': ctrlNova.text,
                    'senha_conf': ctrlConf.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _mostrarSucesso('Senha alterada com sucesso!');
                } on ApiException catch (e) {
                  setD(() { enviando = false; erro = e.mensagem; });
                }
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracao(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true, fillColor: const Color(0xFF1C1C1C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: verdePrimario, width: 1.2)),
        isDense: true,
      );

  // FS_usuarios.plano é um ENUM('gratuito','premium') no banco.
  String get _rotuloPlano => switch (_plano.toLowerCase()) {
        'gratuito' || 'gratis' || '' => 'Plano Grátis',
        'premium' => 'Plano Premium',
        _ => 'Plano ${_plano[0].toUpperCase()}${_plano.substring(1)}',
      };

  @override
  Widget build(BuildContext context) {
    final iniciais = Usuario.iniciaisDe(_username);

    return Column(
      children: [
        cabecalhoPagina("Configurações"),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: verdePrimario))
              : _erro != null
                  ? _telaErro(_erro!, _carregarConfiguracoes)
                  : ListView(
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: verdePrimario.withOpacity(0.12),
                        border: Border.all(
                            color: verdePrimario.withOpacity(0.3))),
                    child: Center(
                      child: Text(iniciais,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: verdePrimario)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_username,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(_email,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white38)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: verdePrimario.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_rotuloPlano, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: verdePrimario)),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _editarCampoTexto(titulo: 'Nickname', valorAtual: _username, campo: 'username'),
                child: _itemNav(Icons.badge_outlined, "Nickname", valor: _username),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _abrirDialogoAlterarSenha,
                child: _itemNav(Icons.lock_outline_rounded, "Alterar senha"),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _editarCampoTexto(titulo: 'E-mail', valorAtual: _email, campo: 'email', tipoTeclado: TextInputType.emailAddress),
                child: _itemNav(Icons.email_outlined, "E-mail", valor: _email),
              ),

              const SizedBox(height: 20),

              //plano
              rotuloSecao("Plano"),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => TelaPlanos(planoAtual: _plano))),
                child: _itemNav(Icons.workspace_premium_outlined,
                    "Ver planos e benefícios", valor: _rotuloPlano),
              ),

              const SizedBox(height: 20),

              //notific.
              rotuloSecao("Notificações"),
              const SizedBox(height: 10),
              _itemToggle(
                "Alertas de validade",
                "Avisar quando alimentos vencerão",
                _alertasValidade,
                () {
                  setState(() => _alertasValidade = !_alertasValidade);
                  _salvarPreferencia({'alertas_validade': _alertasValidade});
                },
              ),

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
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => _confirmarDesativarConta(context),
                  child: const Text("Desativar minha conta",
                      style: TextStyle(color: Colors.white24, fontSize: 12, decoration: TextDecoration.underline)),
                ),
              ),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiCliente.post('/usuarios/logout.php');
              } on ApiException catch (_) {
                // Mesmo se der erro no servidor, ainda limpamos a sessão local.
              }
              await ApiCliente.encerrarSessaoLocal();
              if (!context.mounted) return;
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

  void _confirmarDesativarConta(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartaoEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Desativar conta?", style: TextStyle(color: Colors.white)),
        content: const Text(
            "Sua conta será desativada. Você pode reativá-la a qualquer momento fazendo login novamente.",
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiCliente.post('/usuarios/desativar_conta.php');
              } on ApiException catch (e) {
                _mostrarErro(e.mensagem);
                return;
              }
              await ApiCliente.encerrarSessaoLocal();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const TelaLogin()),
                (_) => false,
              );
            },
            child: const Text("Desativar", style: TextStyle(color: Colors.white)),
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
            Flexible(
              child: Text(valor,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white38)),
            ),
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
