import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

// ======== FLOW PRINCIPAL ===================================================
  Future<void> _startFlow(BuildContext context, String canal) async {
// 1) pedir RIF
    final rif = await _askRif(context, canal);
    if (rif == null) return;

    final rifLower = rif.trim().toLowerCase();
    debugPrint('[Ventas] Buscar por RIF: $rifLower');

    try {
      final q = await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: rifLower)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final doc = q.docs.first;
        debugPrint('[Ventas] Cliente EXISTE: ${doc.id}');
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ClienteDetalleScreen(docId: doc.id),
          ),
        );
        return;
      }

// 2) no existe → abrir formulario para crearlo
      debugPrint('[Ventas] Cliente NO existe. Abriendo formulario…');
      final createdDocId = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _CustomerForm(
          initialRif: rifLower,
          canal: canal,
        ),
      );

// si se guardó, navegar al detalle vacío
      if (createdDocId != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ClienteDetalleScreen(docId: createdDocId),
          ),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('[Ventas] Firestore error: ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Firestore: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      debugPrint('[Ventas] Error inesperado: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado')),
        );
      }
    }
  }

// ======== UI: DIALOGO PARA RIF ============================================
  Future<String?> _askRif(BuildContext context, String canal) async {
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
              labelText: 'RIF del cliente',
              hintText: 'Ej: 123456789 (ultimo valor pegado)',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa un RIF';
// puedes reforzar validación si necesitas un patrón específico
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

// ======== UI: MENU ========================================================
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
// Header azul (volver al panel Operador)
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

// ======== BOTTOM SHEET: FORMULARIO DE NUEVO CLIENTE =========================
class _CustomerForm extends StatefulWidget {
  final String initialRif; // rif en lower
  final String canal;
  const _CustomerForm({required this.initialRif, required this.canal});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phone1Ctrl = TextEditingController();
  final _phone2Ctrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _extraEmailCtrl = TextEditingController();
  final _deudaCtrl = TextEditingController(text: '0');

  bool _afiliado = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rifCtrl.text = widget.initialRif; // ya viene en lower
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _phone1Ctrl.dispose();
    _phone2Ctrl.dispose();
    _rifCtrl.dispose();
    _emailCtrl.dispose();
    _extraEmailCtrl.dispose();
    _deudaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final first = _firstNameCtrl.text.trim();
      final last = _lastNameCtrl.text.trim();
      final full = '$first $last'.trim();
      final fullLower = full.toLowerCase();

      final rif = _rifCtrl.text.trim();
      final rifLower = rif.toLowerCase();

      final email = _emailCtrl.text.trim();
      final emailLower = email.toLowerCase();

      final deudaNum = num.tryParse(_deudaCtrl.text.trim()) ?? 0;

      final data = <String, dynamic>{
        'first_name': first,
        'last_name': last,
        'full_name': full,
        'full_name_lower': fullLower,
        'address': _addressCtrl.text.trim(),
        'phone_1': _phone1Ctrl.text.trim(),
        'phone_2': _phone2Ctrl.text.trim(),
        'rif': rif,
        'rif_lower': rifLower,
        'email': email,
        'email_lower': emailLower,
        'extra_email': _extraEmailCtrl.text.trim(),
        'deuda': deudaNum,
        'afiliado': _afiliado,
        'channel': widget.canal,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'created_by': uid,
      };

// DocID = email_lower
      await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .doc(emailLower)
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context, emailLower); // devolvemos docId para abrir detalle
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
                Row(
                  children: const [
                    Icon(Icons.person_add_alt_1),
                    SizedBox(width: 8),
                    Text('Registrar nuevo cliente',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),

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

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo propio'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final t = v.trim();
                    if (!t.contains('@') || !t.contains('.')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _extraEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo adicional'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _rifCtrl,
                  decoration: const InputDecoration(labelText: 'RIF'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
                  controller: _deudaCtrl,
                  decoration: const InputDecoration(labelText: 'Deuda (número)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _afiliado,
                  onChanged: (v) => setState(() => _afiliado = v),
                  title: const Text('Afiliado'),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
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

// ======== PANTALLA DE DETALLE VACIA (placeholder) ===========================
class _ClienteDetalleScreen extends StatelessWidget {
  final String docId;
  const _ClienteDetalleScreen({required this.docId});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    label: const Text('Volver',
                        style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ),
                  const Spacer(),
                  const Text(
                    'Detalle de cliente',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(height: 8, color: Colors.white),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _panelColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('Pantalla de detalle (vacía)\nDocId: $docId',
                      textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
