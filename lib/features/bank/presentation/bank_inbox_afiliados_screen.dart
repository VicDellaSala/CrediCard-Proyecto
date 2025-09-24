import 'package:flutter/material.dart';

class BankInboxAfiliadosScreen extends StatelessWidget {
  const BankInboxAfiliadosScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    tooltip: 'Volver',
                  ),
                  const Spacer(),
                  const Text(
                    'Buzón · Afiliados',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: Center(
                child: Text('Aquí listaremos solicitudes de AFILIADOS (pendientes) del banco'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
