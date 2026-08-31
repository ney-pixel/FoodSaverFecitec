

import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'api_cliente.dart';
import 'login.dart';
import 'home.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro>
    with SingleTickerProviderStateMixin, AnimacaoEntradaMixin {
  final _controladorNome     = TextEditingController();
  final _controladorEmail    = TextEditingController();
  final _controladorSenha    = TextEditingController();
  final _controladorConfirma = TextEditingController();

  Map<String, String?> _erros = {};
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    iniciarAnimacaoEntrada();
  }

  @override
  void dispose() {
    descartarAnimacaoEntrada();
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirma.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    final erros = <String, String?>{};

    if (_controladorNome.text.trim().length < 5) {
      erros['nome'] = 'Mínimo 5 caracteres';
    }
    if (!RegExp(r'^[\w.-]+@[\w-]+\.\w+$')
        .hasMatch(_controladorEmail.text.trim())) {
      erros['email'] = 'Email inválido';
    }
    if (_controladorSenha.text.length < 6) {
      erros['senha'] = 'Mínimo 6 caracteres';
    }
    if (_controladorConfirma.text != _controladorSenha.text) {
      erros['confirma'] = 'As senhas não coincidem';
    }

    setState(() => _erros = erros);
    return erros.isEmpty;
  }

  Future<void> _enviarCadastro() async {
    if (!_validarFormulario()) return;

    setState(() => _carregando = true);

    final nomeCompleto = _controladorNome.text.trim();
    final email        = _controladorEmail.text.trim();
    final senha        = _controladorSenha.text;

    try {
      // Cadastra e já loga em seguida com as mesmas credenciais
      await ApiCliente.post('/usuarios/cadastro.php', corpo: {
        'username': nomeCompleto,
        'email': email,
        'senha': senha,
      });

      final resp = await ApiCliente.post('/usuarios/login.php', corpo: {
        'email': email,
        'senha': senha,
      });

      final u = resp['usuario'] as Map<String, dynamic>;
      final usuarioLogado = Usuario(
        id: u['id'] as int?,
        nome: (u['username'] as String?) ?? nomeCompleto,
        email: email,
        iniciais: Usuario.iniciaisDe((u['username'] as String?) ?? nomeCompleto),
      );

      if (!mounted) return;
      setState(() => _carregando = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TelaHome(usuario: usuarioLogado)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erros = e.erros ?? {'email': e.mensagem};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoEscuro,
      body: SafeArea(
        child: comAnimacaoEntrada(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Center(child: LogoFoodSaver()),
                  const SizedBox(height: 40),

                  const Text("Criar conta",
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text("Comece a reduzir o desperdício hoje",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  CampoTextoApp(
                    dica: "Nome completo",
                    icone: Icons.person,
                    controlador: _controladorNome,
                    mensagemErro: _erros['nome'],
                  ),
                  const SizedBox(height: 14),
                  CampoTextoApp(
                    dica: "Email",
                    icone: Icons.email,
                    controlador: _controladorEmail,
                    mensagemErro: _erros['email'],
                    tipoTeclado: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  CampoTextoApp(
                    dica: "Senha",
                    icone: Icons.lock,
                    controlador: _controladorSenha,
                    ehSenha: true,
                    mensagemErro: _erros['senha'],
                  ),
                  const SizedBox(height: 14),
                  CampoTextoApp(
                    dica: "Confirmar senha",
                    icone: Icons.lock_outline,
                    controlador: _controladorConfirma,
                    ehSenha: true,
                    mensagemErro: _erros['confirma'],
                  ),
                  const SizedBox(height: 30),

                  BotaoPrincipal(
                    rotulo: "Cadastrar",
                    carregando: _carregando,
                    aoClicar: _enviarCadastro,
                  ),
                  const SizedBox(height: 20),
                  const DivisorOu(),
                  const SizedBox(height: 20),

                  BotaoSocial(
                    rotulo: "Continuar com Google",
                    iconeAsset: 'assets/images/google.png',
                    aoClicar: () {},
                  ),
                  const SizedBox(height: 18),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Já tem uma conta? "),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TelaLogin()),
                          ),
                          child: const Text("Entrar",
                              style: TextStyle(
                                  color: verdePrimario,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
