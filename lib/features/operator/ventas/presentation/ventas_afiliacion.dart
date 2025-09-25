import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla de selección de banco para nueva afiliación
class VentasAfiliacionSelectBankScreen extends StatefulWidget {
  const VentasAfiliacionSelectBankScreen({super.key});

  @override
  State<VentasAfiliacionSelectBankScreen> createState() =>
      _VentasAfiliacionSelectBankScreenState();
}

class _VentasAfiliacionSelectBankScreenState
    extends State<VentasAfiliacionSelectBankScreen> {
  final List<String> bancos = const [
    "Banco de Venezuela",
    "Bancamiga",
    "Bancaribe",
    "Banco del Tesoro",
    "Bancrecer",
    "Mi Banco",
    "Banfanb",
    "Banco Activo",
  ];

  String? _selectedBank;
  bool _loading = false;

  Future<void> _enviarSolicitud(String rif, String clientId) async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un banco")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection("bank_requests").add({
        "clientId": clientId,
        "rif": rif,
        "bank": _selectedBank,
        "status": "pending",
        "created_at": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/ventas/afiliar/pending',
        arguments: {
          "bank": _selectedBank,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar solicitud: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final rif = args?["rif"] ?? "";
    final clientId = args?["clientId"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Banco"),
        backgroundColor: const Color(0xFFAED6D8),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Selecciona el banco para la nueva afiliación:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: bancos.length,
              itemBuilder: (context, index) {
                final banco = bancos[index];
                return RadioListTile<String>(
                  title: Text(banco),
                  value: banco,
                  groupValue: _selectedBank,
                  onChanged: (val) {
                    setState(() {
                      _selectedBank = val;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : () => _enviarSolicitud(rif, clientId),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Enviar Solicitud"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Pantalla de espera de aprobación
class VentasAfiliacionPendingScreen extends StatelessWidget {
  const VentasAfiliacionPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bank = args?["bank"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Afiliación Pendiente"),
        backgroundColor: const Color(0xFFAED6D8),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_bottom,
                  size: 100, color: Colors.blue.shade700),
              const SizedBox(height: 20),
              Text(
                "Tu solicitud de afiliación ha sido enviada a $bank.\n\n"
                    "Un administrador del banco debe aprobar tu solicitud. "
                    "Recibirás la actualización en este sistema.",
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/operator/ventas'));
                },
                child: const Text("Volver al menú de Ventas"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
