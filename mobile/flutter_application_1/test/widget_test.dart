// Teste de smoke: garante que o app inicializa sem lançar exceções e que
// a tela de carregamento inicial (TelaInicial) aparece.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App inicializa e mostra a tela de carregamento', (WidgetTester tester) async {
    await tester.pumpWidget(const AplicativoFoodSaver());

    // Antes de checar a sessão salva, mostra um indicador de carregamento.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
