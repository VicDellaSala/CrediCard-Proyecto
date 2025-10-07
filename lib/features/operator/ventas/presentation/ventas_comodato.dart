import 'package:flutter/material.dart';

class VentasComodatoScreen extends StatelessWidget {
  const VentasComodatoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comodato'),
        backgroundColor: const Color(0xFF4CB7A5),
      ),
      body: const Center(
        child: Text(
          'Pantalla de Comodato\n(Aquí se llenará la información más adelante)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
