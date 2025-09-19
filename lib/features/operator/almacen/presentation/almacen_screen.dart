import 'package:flutter/material.dart';

class AlmacenScreen extends StatelessWidget {
const AlmacenScreen({super.key});

static const _panelColor = Color(0xFFAED6D8);

Widget _btn(BuildContext ctx, IconData icon, String label, String route) {
return SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton.icon(
onPressed: () => Navigator.pushNamed(ctx, route),
icon: Icon(icon, size: 26),
label: Text(label, style: const TextStyle(fontSize: 18)),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF2F2F2),
body: SafeArea(
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 900),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
// Header azul (flecha vuelve al panel Operador)
Container(
decoration: BoxDecoration(
color: _panelColor,
borderRadius: BorderRadius.circular(16),
),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
child: Row(
children: [
TextButton.icon(
onPressed: () =>
Navigator.pushReplacementNamed(context, '/operator'),
icon: const Icon(Icons.arrow_back, color: Colors.black87),
label: const Text(
'Volver',
style: TextStyle(color: Colors.black87, fontSize: 16),
),
),
const Spacer(),
const Row(
children: [
Icon(Icons.warehouse, color: Colors.white, size: 28),
SizedBox(width: 8),
Text(
'Almacén',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.w600,
color: Colors.white,
letterSpacing: 0.5,
shadows: [
Shadow(
blurRadius: 2,
color: Colors.black26,
offset: Offset(0, 1),
),
],
),
),
],
),
const Spacer(),
const SizedBox(width: 48),
],
),
),

// Banda blanca fina
Container(
width: double.infinity,
color: Colors.white,
height: 8,
),

// Panel con los 3 botones del menú de Almacén
Expanded(
child: Container(
margin: const EdgeInsets.only(top: 8),
width: double.infinity,
decoration: BoxDecoration(
color: _panelColor,
borderRadius: BorderRadius.circular(16),
),
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_btn(context, Icons.add_box, 'Solicitar equipos',
'/operator/almacen/solicitar'),
const SizedBox(height: 14),
_btn(context, Icons.settings, 'Gestión de almacén',
'/operator/almacen/gestion'),
const SizedBox(height: 14),
_btn(context, Icons.verified, 'Autorización de solicitudes',
'/operator/almacen/autorizaciones'),
],
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
