import 'package:flutter/material.dart';
import 'visual.dart';
import 'usuario.dart';
import 'planos.dart';

// FS_usuarios.plano é um ENUM('gratuito','premium') no banco.
bool ehPremium(Usuario usuario) => usuario.plano.toLowerCase() == 'premium';

// Tela mostrada no lugar de recursos exclusivos do Premium (Relatórios e
// Criar receitas com IA) quando o usuário está no plano gratuito. O bloqueio
// que vale de verdade é no backend (ex.: api/ia/gerar_receita.php).
class BloqueioPremium extends StatelessWidget {
  final Usuario usuario;
  final String titulo;
  final String descricao;
  final IconData icone;

  const BloqueioPremium({
    super.key,
    required this.usuario,
    required this.titulo,
    required this.descricao,
    this.icone = Icons.lock_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: verdePrimario.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: verdePrimario.withOpacity(0.35)),
            ),
            child: Icon(icone, color: verdePrimario, size: 32),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: fundoEscuro,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: verdePrimario.withOpacity(0.4)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_rounded, size: 11, color: verdePrimario),
              SizedBox(width: 4),
              Text('EXCLUSIVO PREMIUM',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: verdePrimario,
                      letterSpacing: 0.4)),
            ]),
          ),
          const SizedBox(height: 14),
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TelaPlanos(planoAtual: usuario.plano))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                  color: verdePrimario,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: brilhoPrimario),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Colors.black, size: 18),
                SizedBox(width: 8),
                Text('Ver planos',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
