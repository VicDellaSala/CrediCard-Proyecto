import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  Future<void> _startFlow(BuildContext context, String canal) async {
// 1) pedir correo
    final email = await _askEmail(context, canal);
    if (email == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(email.toLowerCase())
        .get();

    if (doc.exists) {
// 2a) ya existe
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado')),
        );
      }
      return;
    }

// 2b) no existe → abrir formulario de datos
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CustomerForm(
        initialEmail: email,
        canal: canal,
      ),
    );
  }

  /// diálogo simple para pedir email o cancelar
  Future<String?> _askEmail(BuildContext context, String canal) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Canal: $canal'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Correo del cliente',
              hintText: 'cliente@correo.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa un correo';
              if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(BuildContext ctx, IconData icon, String label, String canal) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _startFlow(ctx, canal),
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
                          onPressed: () => Navigator.pushReplacementNamed(context, '/operator'),
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          label: const Text('Volver',
                              style: TextStyle(color: Colors.black87, fontSize: 16)),
                        ),
                        const Spacer(),
                        const Row(
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Ventas',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1)),
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
                  Container(width: double.infinity, color: Colors.white, height: 8),

// Menú con 4 opciones
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
                            _menuButton(context, Icons.apartment, 'Oficina Comercial', 'Oficina Comercial'),
                            const SizedBox(height: 14),
                            _menuButton(context, Icons.handshake, 'Agente Autorizado', 'Agente Autorizado'),
                            const SizedBox(height: 14),
                            _menuButton(context, Icons.event, 'Jornada', 'Jornada'),
                            const SizedBox(height: 14),
                            _menuButton(context, Icons.account_balance, 'Banco', 'Banco'),
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

class _CustomerForm extends StatefulWidget {
  final String initialEmail;
  final String canal;
  const _CustomerForm({required this.initialEmail, required this.canal});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();

// Campos “adicionales”
  final _addressCtrl = TextEditingController();
  final _phone1Ctrl = TextEditingController();
  final _phone2Ctrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _extraEmailCtrl = TextEditingController();

// Nuevo cliente (opcional)
  bool _isNew = false;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  late final TextEditingController _mainEmailCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mainEmailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phone1Ctrl.dispose();
    _phone2Ctrl.dispose();
    _rifCtrl.dispose();
    _extraEmailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _mainEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

// usamos el correo principal como ID de documento
      final docId = _mainEmailCtrl.text.trim().toLowerCase();

      final data = <String, dynamic>{
        'firstName': _isNew ? _firstNameCtrl.text.trim() : FieldValue.delete(),
        'lastName': _isNew ? _lastNameCtrl.text.trim() : FieldValue.delete(),
        'email': _mainEmailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone1': _phone1Ctrl.text.trim(),
        'phone2': _phone2Ctrl.text.trim(),
        'rif': _rifCtrl.text.trim(),
        'extraEmail': _extraEmailCtrl.text.trim(),
        'channel': widget.canal,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      };

// limpiar deletes (para evitar claves con FieldValue.delete si _isNew=false)
      data.removeWhere((k, v) => v is FieldValue && v == FieldValue.delete());

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(docId)
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context); // cerrar hoja
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado')),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: ${e.message ?? e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          top: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
// Título
                Row(
                  children: [
                    const Icon(Icons.person_add_alt_1),
                    const SizedBox(width: 8),
                    Text('Registrar cliente — ${widget.canal}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),

// Toggle “Es nuevo cliente”
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Es nuevo cliente (añadir nombre/apellido/correo)'),
                  value: _isNew,
                  onChanged: (v) => setState(() => _isNew = v),
                ),

                if (_isNew) ...[
                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _lastNameCtrl,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                ],

                TextFormField(
                  controller: _mainEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo principal'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

// Campos adicionales (siempre)
                TextFormField(
                  controller: _rifCtrl,
                  decoration: const InputDecoration(labelText: 'RIF'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone1Ctrl,
                  decoration: const InputDecoration(labelText: 'Teléfono 1'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone2Ctrl,
                  decoration: const InputDecoration(labelText: 'Teléfono 2'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _extraEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo adicional'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Guardando...' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
