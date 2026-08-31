import 'package:flutter/material.dart';

//===== Identidade visual do FoodSaver =====
//paleta principal
const verdePrimario  = Color(0xFF16DB65);
const verdeEscuro    = Color(0xFF0F9D4F);
const verdeSuave     = Color(0xFF9CF5C4);
const roxoIA         = Color(0xFF6C63FF); // cor de destaque para tudo que envolve IA
const roxoIAClaro    = Color(0xFF9B59B6);

//neutros / fundo
const fundoEscuro    = Color(0xFF0A0A0A);
const cartaoEscuro   = Color(0xFF141414);
// Borda quase invisível (branco a ~6%)
const bordaCartao    = Color(0x0FFFFFFF);

//gradiente de marca, usado em destaques (logo, botões hero, etc)
const gradienteMarca = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [verdePrimario, verdeEscuro],
);

// Sombras suaves
const sombraCartao = [
  BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
];
const brilhoPrimario = [
  BoxShadow(color: Color(0x4016DB65), blurRadius: 24, offset: Offset(0, 10)),
];

//logo
class LogoFoodSaver extends StatelessWidget {
  const LogoFoodSaver({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: verdePrimario.withOpacity(0.05),
            border: Border.all(
                color: verdePrimario.withOpacity(0.35), width: 1),
            boxShadow: [
              BoxShadow(
                  color: verdePrimario.withOpacity(0.22),
                  blurRadius: 36,
                  spreadRadius: 2),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: verdePrimario.withOpacity(0.15),
                child:
                    const Icon(Icons.eco, color: verdePrimario, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "FoodSaver",
          style: TextStyle(
            fontFamily: 'logo',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: verdePrimario,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

//campo de texto default
class CampoTextoApp extends StatefulWidget {
  final String dica;
  final IconData icone;
  final bool ehSenha;
  final TextEditingController controlador;
  final String? mensagemErro;
  final TextInputType tipoTeclado;

  const CampoTextoApp({
    super.key,
    required this.dica,
    required this.icone,
    required this.controlador,
    this.ehSenha = false,
    this.mensagemErro,
    this.tipoTeclado = TextInputType.text,
  });

  @override
  State<CampoTextoApp> createState() => _CampoTextoAppState();
}

class _CampoTextoAppState extends State<CampoTextoApp> {
  bool _esconder = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controlador,
      obscureText: widget.ehSenha ? _esconder : false,
      keyboardType: widget.tipoTeclado,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: widget.dica,
        hintStyle: const TextStyle(color: Colors.grey),
        errorText: widget.mensagemErro,
        prefixIcon: Icon(widget.icone, color: verdePrimario),
        suffixIcon: widget.ehSenha
            ? IconButton(
                icon: Icon(
                  _esconder ? Icons.visibility : Icons.visibility_off,
                  color: verdePrimario,
                ),
                onPressed: () => setState(() => _esconder = !_esconder),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF141414),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: verdePrimario, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
    );
  }
}

//botao prota verde
class BotaoPrincipal extends StatelessWidget {
  final String rotulo;
  final bool carregando;
  final VoidCallback? aoClicar;

  const BotaoPrincipal({
    super.key,
    required this.rotulo,
    this.carregando = false,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: (carregando || aoClicar == null) ? null : brilhoPrimario,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: verdePrimario,
          disabledBackgroundColor: verdePrimario.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: carregando ? null : aoClicar,
        child: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : Text(
                rotulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}

//divisou ou entre os campos
class DivisorOu extends StatelessWidget {
  const DivisorOu({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF2A2A2A))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "ou",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF2A2A2A))),
      ],
    );
  }
}

//botao do google
class BotaoSocial extends StatelessWidget {
  final String rotulo;
  final String iconeAsset;
  final VoidCallback? aoClicar;

  const BotaoSocial({
    super.key,
    required this.rotulo,
    required this.iconeAsset,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2A2A2A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: aoClicar,
        icon: Image.asset(
          iconeAsset,
          width: 22,
          height: 22,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.g_mobiledata,
              color: Colors.white,
              size: 22),
        ),
        label: Text(
          rotulo,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }
}

//animaçao de entrada fade
mixin AnimacaoEntradaMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController controladorAnimacao;
  late Animation<double> animacaoFade;
  late Animation<Offset> animacaoDeslize;

  void iniciarAnimacaoEntrada() {
    controladorAnimacao = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    animacaoFade = CurvedAnimation(
      parent: controladorAnimacao,
      curve: Curves.easeOut,
    );
    animacaoDeslize =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: controladorAnimacao, curve: Curves.easeOut));
    controladorAnimacao.forward();
  }

  void descartarAnimacaoEntrada() => controladorAnimacao.dispose();

  Widget comAnimacaoEntrada(Widget filho) => FadeTransition(
        opacity: animacaoFade,
        child: SlideTransition(position: animacaoDeslize, child: filho),
      );
}

//healho default
Widget cabecalhoPagina(String titulo, {Widget? acaoTopo}) => Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: bordaCartao, width: 0.5))),
      child: Row(children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.6)),
        const Spacer(),
        if (acaoTopo != null) acaoTopo,
      ]));

//subtitulo
Widget rotuloSecao(String texto) => Text(texto,
    style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.1));

//cartao
Widget cartao({required Widget filho, Color? corBorda}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: cartaoEscuro,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corBorda ?? bordaCartao),
        boxShadow: sombraCartao),
    child: filho);