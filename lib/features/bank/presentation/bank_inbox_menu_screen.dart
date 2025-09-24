import 'package:flutter/material.dart';

class BankInboxMenuScreen extends StatelessWidget {
  const BankInboxMenuScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
// Header
                  Container(
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                          'Buzón de Solicitudes',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

// Banda blanca
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const SizedBox.shrink(),
                  ),

// Cuerpo
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BigPillButton(
                                  icon: Icons.badge_outlined,
                                  label: 'Afiliados',
                                  onPressed: () => Navigator.pushNamed(context, '/bank/inbox/afiliados'),
                                ),
                                const SizedBox(height: 20),
                                _BigPillButton(
                                  icon: Icons.credit_card_outlined,
                                  label: 'Autorización de terminal',
                                  onPressed: () => Navigator.pushNamed(context, '/bank/inbox/terminal'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BigPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _BigPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 18)),
      onPressed: onPressed,
    );
  }
}
