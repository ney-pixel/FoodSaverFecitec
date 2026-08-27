

import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'banco_dados.dart';
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

    if (_controladorNome.text.trim().isEmpty) {
      erros['nome'] = 'Informe seu nome completo';
    }
    if (!RegExp(r'^[\w.-]+@[\w-]+\.\w+$')
        .hasMatch(_controladorEmail.text.trim())) {
      erros['email'] = 'Email inválido';
    }
    if (BancoDados.emailJaCadastrado(_controladorEmail.text.trim())) {
      erros['email'] = 'Este email já está cadastrado';
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
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _carregando = false);

    //aq salva o novo usuario na lista
    BancoDados.cadastrarUsuario(
      _controladorNome.text.trim(),
      _controladorEmail.text.trim(),
      _controladorSenha.text,
    );

    final nomeCompleto = _controladorNome.text.trim();
    final partes       = nomeCompleto.split(' ');
    final iniciais     = partes.length >= 2
        ? '${partes.first[0]}${partes.last[0]}'.toUpperCase()
        : nomeCompleto.substring(0, 2).toUpperCase();

    final usuarioLogado = Usuario(
      nome:     nomeCompleto,
      email:    _controladorEmail.text.trim(),
      iniciais: iniciais,
      nivel:    1,
      xpAtual:  0,
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