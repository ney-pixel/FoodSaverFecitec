

import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'banco_dados.dart';
import 'home.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin>
    with SingleTickerProviderStateMixin, AnimacaoEntradaMixin {
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();

  Map<String, String?> _erros = {};
  bool _carregando    = false;
  bool _lembrarDeMin  = false; 

  @override
  void initState() {
    super.initState();
    iniciarAnimacaoEntrada();
  }

  @override
  void dispose() {
    descartarAnimacaoEntrada();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    final erros = <String, String?>{};
    if (!RegExp(r'^[\w.-]+@[\w-]+\.\w+$')
        .hasMatch(_controladorEmail.text.trim())) {
      erros['email'] = 'Email inválido';
    }
    if (_controladorSenha.text.isEmpty) {
      erros['senha'] = 'Informe sua senha';
    }
    setState(() => _erros = erros);
    return erros.isEmpty;
  }

  Future<void> _entrar() async {
    if (!_validarFormulario()) return;

    setState(() => _carregando = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _carregando = false);

    //busca usuario
    final dadosUsuario = BancoDados.buscarUsuario(
      _controladorEmail.text.trim(),
      _controladorSenha.text,
    );

    if (dadosUsuario == null) {
      setState(() => _erros = {'senha': 'Email ou senha incorretos'});
      return;
    }

    //monta as inicias a partir do nome
    final nomeCompleto = dadosUsuario['nome']!;
    final partes       = nomeCompleto.trim().split(' ');
    final iniciais     = partes.length >= 2
        ? '${partes.first[0]}${partes.last[0]}'.toUpperCase()
        : nomeCompleto.substring(0, 2).toUpperCase();

    final usuarioLogado = Usuario(
      nome:     nomeCompleto,
      email:    dadosUsuario['email']!,
      iniciais: iniciais,
      nivel:    7,
      xpAtual:  1240,
      xpMaximo: 2000,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TelaHome(usuario: usuarioLogado)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoEscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: verdePrimario),
      ),
      body: SafeArea(
        child: comAnimacaoEntrada(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Center(child: LogoFoodSaver()),
                  const SizedBox(height: 40),

                  const Text("Bem-vindo de volta",
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text("Faça login para continuar",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

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
                  const SizedBox(height: 12),

                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                 
                      Row(children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _lembrarDeMin = !_lembrarDeMin),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 38,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _lembrarDeMin
                                  ? verdePrimario
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 220),
                              alignment: _lembrarDeMin
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("Lembrar de mim",
                            style: TextStyle(
                                fontSize: 12, color: Colors.white54)),
                      ]),

                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text("Esqueceu a senha?",
                            style: TextStyle(
                                color: verdePrimario,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  BotaoPrincipal(
                    rotulo: "Entrar",
                    carregando: _carregando,
                    aoClicar: _entrar,
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
                        const Text("Não tem uma conta? "),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cadastrar",
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