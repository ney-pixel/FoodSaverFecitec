

import 'package:flutter/material.dart';
import 'visual.dart';

class TelaSobreFoodSaver extends StatelessWidget {
  const TelaSobreFoodSaver({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoEscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: verdePrimario),
        title: const Text("Sobre o FoodSaver",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        physics: const BouncingScrollPhysics(),
        children: [

          //logo + o slogan
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: verdePrimario.withOpacity(0.4), width: 1.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: verdePrimario.withOpacity(0.15),
                      child: const Icon(Icons.eco,
                          color: verdePrimario, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("FoodSaver",
                  style: TextStyle(
                      fontFamily: 'logo',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: verdePrimario,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              const Text(
                "Menos desperdício. Mais futuro.",
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: verdePrimario.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: verdePrimario.withOpacity(0.3)),
                ),
                child: const Text("v1.0.0",
                    style: TextStyle(
                        color: verdePrimario,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          //imagem de destaque
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/hero1.png',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                decoration: BoxDecoration(
                  color: verdePrimario.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: verdePrimario.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: verdePrimario, size: 40),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          //o que é
          _secao(
            icone: Icons.info_outline_rounded,
            titulo: "O que é",
            conteudo:
                "O FoodSaver é um aplicativo móvel que ajuda você a gerenciar os alimentos da sua casa de forma inteligente, reduzindo desperdícios e aproveitando melhor o que você já tem.",
          ),

          const SizedBox(height: 16),

          //objetivos
          _secao(
            icone: Icons.flag_outlined,
            titulo: "Objetivo",
            conteudo:
                "Conectar tecnologia e sustentabilidade para que qualquer pessoa possa controlar seu estoque de alimentos, receber alertas de vencimento e descobrir receitas criadas por IA com os ingredientes disponíveis.",
          ),

          const SizedBox(height: 16),

          //funcionalidade
          _secao(
            icone: Icons.auto_awesome_outlined,
            titulo: "Como funciona",
            conteudo: null,
            filhos: [
              _itemFuncionalidade(
                  Icons.inventory_2_outlined,
                  "Estoque inteligente",
                  "Cadastre alimentos, acompanhe validades e organize por grupos."),
              _itemFuncionalidade(
                  Icons.restaurant_menu_outlined,
                  "Receitas com IA",
                  "Selecione ingredientes e deixe a IA sugerir receitas para você."),
              _itemFuncionalidade(
                  Icons.bar_chart_rounded,
                  "Relatórios",
                  "Acompanhe seu histórico de consumo e redução de desperdício."),
              _itemFuncionalidade(
                  Icons.emoji_events_outlined,
                  "Conquistas e XP",
                  "Ganhe pontos e desbloqueie conquistas por boas práticas alimentares."),
            ],
          ),

          const SizedBox(height: 16),

          //img
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/organiza.png',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 16),

          //img
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/criarIA.png',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 24),

          //rodafeet
          Center(
            child: Text(
              "© 2026 FoodSaver  ·  Tecnologia • Sustentabilidade • Consciência",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao({
    required IconData icone,
    required String titulo,
    String? conteudo,
    List<Widget>? filhos,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cartaoEscuro,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bordaCartao)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icone, color: verdePrimario, size: 18),
              const SizedBox(width: 8),
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ]),
            const SizedBox(height: 10),
            if (conteudo != null)
              Text(conteudo,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                      height: 1.5)),
            if (filhos != null) ...filhos,
          ],
        ),
      );

  Widget _itemFuncionalidade(
          IconData icone, String titulo, String descricao) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: verdePrimario.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icone, color: verdePrimario, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(descricao,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
        ]),
      );
}