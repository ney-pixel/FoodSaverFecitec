
import 'package:flutter/material.dart';
import 'cadastro.dart';

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
        textTheme:
            ThemeData.dark().textTheme.apply(fontFamily: 'DMSans'),
      ),

      home: const TelaCadastro(),
    );
  }
}