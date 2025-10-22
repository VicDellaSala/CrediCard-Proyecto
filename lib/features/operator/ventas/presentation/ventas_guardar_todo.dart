import 'package:flutter/material.dart';

class GuardarTodoPage extends StatelessWidget {
  final Map<String, dynamic> datos;

  const GuardarTodoPage({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Datos del Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoTile('RIF', datos['rif']),
            _infoTile('Nombre', datos['nombre']),
            _infoTile('Correo Electrónico', datos['correo']),
            const SizedBox(height: 20),
            const Text('Equipo Seleccionado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoTile('Modelo', datos['equipo']['modelo']),
            _infoTile('Serial', datos['equipo']['serial']),
            const SizedBox(height: 20),
            const Text('Tarjeta Operativa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoTile('Tipo', datos['tarjeta']['tipo']),
            _infoTile('Serial', datos['tarjeta']['serial']),
            const SizedBox(height: 20),
            const Text('Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoTile('Monto Total Cancelado', 'Bs. ${datos['monto']}'),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      leading: const Icon(Icons.info_outline),
    );
  }
}