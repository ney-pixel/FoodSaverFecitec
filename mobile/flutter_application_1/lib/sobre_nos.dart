
import 'package:flutter/material.dart';
import 'visual.dart';

class TelaSobreNos extends StatelessWidget {
  const TelaSobreNos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoEscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: verdePrimario),
        title: const Text("Sobre nós",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        physics: const BouncingScrollPhysics(),
        children: [

          //headlho
          const SizedBox(height: 12),
          const Center(
            child: Text("Criadores do Projeto",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5)),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              "Conheça quem desenvolveu o FoodSaver",
              style: TextStyle(fontSize: 13, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 28),

          //criadores
          _cardCriador(
            fotoAsset:  'assets/images/gabriel.jpg',
            iniciais:   'GS',
            nome:       'Gabriel Siqueira',
            papel:      'Front-end · UI/UX',
            corPapel:   verdePrimario,
            descricao:  'Responsável pela interface, experiência do usuário e identidade visual do FoodSaver.',
          ),
          const SizedBox(height: 14),
          _cardCriador(
            fotoAsset:  'assets/images/pedro.jpg',
            iniciais:   'PC',
            nome:       'Pedro Coura',
            papel:      'Back-end',
            corPapel:   const Color(0xFF4FC3F7),
            descricao:  'Responsável pela lógica da aplicação e estrutura principal do sistema.',
          ),
          const SizedBox(height: 14),
          _cardCriador(
            fotoAsset:  'assets/images/heitor.jpg',
            iniciais:   'HA',
            nome:       'Heitor Aoki',
            papel:      'Banco de Dados',
            corPapel:   const Color(0xFF9B59B6),
            descricao:  'Responsável pela modelagem, organização e gerenciamento dos dados do app.',
          ),

          const SizedBox(height: 28),

          //missao nossa
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: verdePrimario.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: verdePrimario.withOpacity(0.2)),
            ),
            child: Column(children: [
              const Icon(Icons.eco_rounded,
                  color: verdePrimario, size: 28),
              const SizedBox(height: 10),
              const Text("Nossa missão",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 8),
              const Text(
                "Desenvolvemos o FoodSaver com o objetivo de unir tecnologia e sustentabilidade, criando uma ferramenta simples e poderosa que ajuda as pessoas a desperdiçar menos e viver de forma mais consciente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                    height: 1.5),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text("© 2026 FoodSaver",
                style: TextStyle(
                    fontSize: 11, color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _cardCriador({
    required String fotoAsset,
    required String iniciais,
    required String nome,
    required String papel,
    required Color corPapel,
    required String descricao,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bordaCartao)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto ou iniciais
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                fotoAsset,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: corPapel.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Text(iniciais,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: corPapel)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: corPapel.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: corPapel.withOpacity(0.25))),
                    child: Text(papel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: corPapel)),
                  ),
                  const SizedBox(height: 8),
                  Text(descricao,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}