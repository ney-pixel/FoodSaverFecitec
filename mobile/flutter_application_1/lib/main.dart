
import 'package:flutter/material.dart';
import 'api_cliente.dart';
import 'cadastro.dart';
import 'home.dart';
import 'usuario.dart';
import 'visual.dart';

void main() {
  runApp(const AplicativoFoodSaver());
}

class AplicativoFoodSaver extends StatelessWidget {
  const AplicativoFoodSaver({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FoodSaver',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: fundoEscuro,
        textTheme:
            ThemeData.dark().textTheme.apply(fontFamily: 'DMSans'),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: verdePrimario,
              secondary: verdePrimario,
              surface: cartaoEscuro,
            ),
        // Ripple/realce na cor da marca
        splashColor: verdePrimario.withOpacity(0.08),
        highlightColor: verdePrimario.withOpacity(0.04),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: verdePrimario),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? verdePrimario : Colors.transparent),
          checkColor: const WidgetStatePropertyAll(Colors.black),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cartaoEscuro,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.all(16),
        ),
      ),

      home: const TelaInicial(),
    );
  }
}

// Decide, ao abrir o app, se já existe sessão válida — pula pra Home ou cai no login.
class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    final temCookie = await ApiCliente.temSessaoSalva();
    if (!temCookie) {
      _irParaCadastro();
      return;
    }

    try {
      final resp = await ApiCliente.get('/usuarios/check_login.php');
      final u = resp['usuario'] as Map<String, dynamic>;
      final usuario = Usuario(
        id: u['id'] as int?,
        nome: (u['username'] as String?) ?? '',
        email: (u['email'] as String?) ?? '',
        iniciais: Usuario.iniciaisDe((u['username'] as String?) ?? '?'),
        plano: (u['plano'] as String?) ?? 'gratis',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TelaHome(usuario: usuario)),
      );
    } catch (_) {
      // Sessão expirada/inválida
      await ApiCliente.encerrarSessaoLocal();
      _irParaCadastro();
    }
  }

  void _irParaCadastro() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaCadastro()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: fundoEscuro,
      body: Center(
        child: CircularProgressIndicator(color: verdePrimario),
      ),
    );
  }
}
