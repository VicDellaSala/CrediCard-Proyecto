import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ventas_equipos.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  // ======== FLOW PRINCIPAL ===================================================
  Future<void> _startFlow(BuildContext context, String canal) async {
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
        final data = doc.data();
        final deuda = _toNum(data['deuda']) ?? 0;
        final nombre = (data['full_name'] as String?) ?? 'Cliente';

        debugPrint('[Ventas] Cliente EXISTE: ${doc.id} - deuda=$deuda');

        // --- RAMAS POR DEUDA ---
        if (deuda > 500) {
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _DebtBlockScreen(amount: deuda, clientName: nombre)),
          );
          return;
        } else if (deuda >= 1 && deuda <= 499) {
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _DebtWarnScreen(
                amount: deuda,
                clientName: nombre,
                onContinue: () {
                  _routeByAfiliacion(context, doc.id, data);
                },
              ),
            ),
          );
          return;
        } else {
          // deuda == 0
          if (!context.mounted) return;
          _routeByAfiliacion(context, doc.id, data);
          return;
        }
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

      if (createdDocId != null && context.mounted) {
        // leer el doc recién creado para decidir flujo de afiliado
        final snap = await FirebaseFirestore.instance
            .collection('Cliente_completo')
            .doc(createdDocId)
            .get();
        final data = snap.data() ?? {};
        _routeByAfiliacion(context, createdDocId, data);
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

  // Chequeo de afiliación y ruteo
  void _routeByAfiliacion(BuildContext context, String docId, Map<String, dynamic> data) {
    final afiliado = (data['afiliado'] == true);
    final bank = (data['bank'] as String?)?.trim();
    final preventaEstado = (data['preventa_estado'] as String?)?.toLowerCase();

    // Si ya tiene preventa pendiente pero no afiliado, mostrar rama pendiente
    if (preventaEstado == 'pendiente' && !afiliado) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _AfiliadoPendienteScreen(docId: docId),
        ),
      );
      return;
    }

    if (afiliado && bank != null && bank.isNotEmpty) {
      // Afiliado existente → pantalla con opciones (incluye "Solicitar nuevo afiliado")
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _AfiliadoExistenteScreen(
            docId: docId,
            bank: bank,
          ),
        ),
      );
    } else {
      // No afiliado → pendiente por creación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _AfiliadoPendienteScreen(
            docId: docId,
          ),
        ),
      );
    }
  }

  num? _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return 0;
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
              hintText: 'Ej: J-12345678-9',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa un RIF';
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

// ======== FORMULARIO DE NUEVO CLIENTE ======================================
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

  String? _selectedBank;
  final List<String> _banks = const [
    'Banco de Venezuela',
    'Bancamiga',
    'Bancaribe',
    'Banco del Tesoro',
    'Bancrecer',
    'Mi Banco',
    'Banfanb',
    'Banco Activo',
  ];

  @override
  void initState() {
    super.initState();
    _rifCtrl.text = widget.initialRif;
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
    if (_afiliado && (_selectedBank == null || _selectedBank!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el banco afiliado')),
      );
      return;
    }

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
        if (_afiliado) 'bank': _selectedBank,
      };

      await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .doc(emailLower) // ID por correo en minúsculas
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context, emailLower); // devolvemos docId
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

  Widget _bankChooser() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: _banks.map((b) {
          return RadioListTile<String>(
            title: Text(b),
            value: b,
            groupValue: _selectedBank,
            onChanged: (v) => setState(() => _selectedBank = v),
          );
        }).toList(),
      ),
    );
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
                  onChanged: (v) => setState(() {
                    _afiliado = v;
                    if (!v) _selectedBank = null;
                  }),
                  title: const Text('Afiliado'),
                ),
                const SizedBox(height: 8),
                if (_afiliado) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Seleccione banco afiliado:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  _bankChooser(),
                ],

                const SizedBox(height: 12),
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

// ======== PANTALLAS ESPECIALES POR DEUDA ====================================
class _DebtBlockScreen extends StatelessWidget {
  final num amount;
  final String clientName;
  const _DebtBlockScreen({required this.amount, required this.clientName});

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: const Row(
                children: [
                  Spacer(),
                  Text('Deuda alta',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  Spacer(),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Container(height: 8, color: Colors.white),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.report, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        '$clientName mantiene una deuda muy alta.\nMonto: $amount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamedAndRemoveUntil(context, '/operator/ventas', (_) => false),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver al menú de Ventas'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtWarnScreen extends StatelessWidget {
  final num amount;
  final String clientName;
  final VoidCallback onContinue;
  const _DebtWarnScreen({required this.amount, required this.clientName, required this.onContinue});

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: const Row(
                children: [
                  Spacer(),
                  Text('Deuda pendiente',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  Spacer(),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Container(height: 8, color: Colors.white),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        '$clientName tiene una deuda de $amount.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Puedes continuar de todos modos.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: onContinue,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Continuar de todos modos'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context, '/operator/ventas', (_) => false),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver al menú de Ventas'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======== FLUJO DE AFILIADO =================================================

class _AfiliadoExistenteScreen extends StatelessWidget {
  final String docId;
  final String bank;
  const _AfiliadoExistenteScreen({required this.docId, required this.bank});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        label: const Text('Volver', style: TextStyle(color: Colors.black87, fontSize: 16)),
                      ),
                      const Spacer(),
                      const Text(
                        'Afiliado existente',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 8, color: Colors.white),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'El cliente es afiliado y pertenece a:\n$bank',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => _GestionAfiliadoScreen(docId: docId)),
                              );
                            },
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Solicitar un afiliado nuevo'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => _ConfirmarAfiliadoExistenteScreen(docId: docId, bank: bank)),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Continuar con su afiliado existente'),
                          ),
                        ),
                      ],
                    ),
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
class _AfiliadoPendienteScreen extends StatelessWidget {
  final String docId;
  const _AfiliadoPendienteScreen({required this.docId});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: const Row(
                    children: [
                      Spacer(),
                      Text(
                        'Afiliación pendiente',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Spacer(),
                      SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 8, color: Colors.white),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending_actions, size: 64, color: Colors.blueGrey),
                        const SizedBox(height: 16),
                        const Text(
                          'El cliente no tiene afiliado existente.\nPendiente por creación de afiliado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _GestionAfiliadoScreen(docId: docId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.manage_accounts),
                            label: const Text('Gestión de afiliado'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _PreVentaScreen(docId: docId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Pre-Venta'),
                          ),
                        ),
                      ],
                    ),
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

// ======== GESTIÓN DE AFILIADO ==============================================
class _GestionAfiliadoScreen extends StatefulWidget {
  final String docId; // id del doc del cliente (email_lower)
  const _GestionAfiliadoScreen({required this.docId});

  @override
  State<_GestionAfiliadoScreen> createState() => _GestionAfiliadoScreenState();
}

// Pantalla de confirmación: Solicitud enviada (pendiente de aprobación bancaria)
class _SolicitudEnviadaScreen extends StatelessWidget {
  const _SolicitudEnviadaScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

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
// Header
                  Container(
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    child: const Row(
                      children: [
                        Spacer(),
                        Text(
                          'Solicitud enviada',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Container(width: double.infinity, color: Colors.white, height: 8),

// Cuerpo
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.hourglass_top, size: 72, color: Colors.orange),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tu solicitud de afiliación fue enviada al banco.\n'
                                      'Queda pendiente de aprobación.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/operator/ventas',
                                              (_) => false,
                                        ),
                                        child: const Text('Volver al módulo de Ventas'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Gestionar otra afiliación'),
                                      ),
                                    ),
                                  ],
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


class _GestionAfiliadoScreenState extends State<_GestionAfiliadoScreen> {
  static const _panelColor = Color(0xFFAED6D8);
  String? _selectedBank;
  bool _saving = false;

  final List<String> _banks = const [
    'Banco de Venezuela',
    'Bancamiga',
    'Bancaribe',
    'Banco del Tesoro',
    'Bancrecer',
    'Mi Banco',
    'Banfanb',
    'Banco Activo',
  ];

  Future<void> _aceptar() async {
    if (_selectedBank == null || _selectedBank!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un banco')));
      return;
    }
    setState(() => _saving = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('Cliente_completo').doc(widget.docId).get();
      final data = snap.data() ?? {};
      final currentBank = (data['bank'] as String?)?.trim();
      final rif = (data['rif'] as String?)?.trim() ?? '';
      final fullName = (data['full_name'] as String?)?.trim();
      final email = (data['email'] as String?)?.trim();

      // Evitar mismo banco
      if ((currentBank ?? '').toLowerCase() == _selectedBank!.toLowerCase()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya se encuentra afiliado a ese banco')));
        }
        if (mounted) setState(() => _saving = false);
        return;
      }

      // Crear solicitud al banco (pendiente)
      await FirebaseFirestore.instance.collection('bank_requests').add({
        'type': 'afiliacion',
        'status': 'pendiente',
        'bank': _selectedBank,
        'rif': rif,
        'rif_lower': rif.toLowerCase(),
        'clientId': widget.docId,
        'fullName': fullName,
        'email': email,
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _SolicitudEnviadaScreen()),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message ?? e.code}')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        label: const Text('Volver', style: TextStyle(color: Colors.black87, fontSize: 16)),
                      ),
                      const Spacer(),
                      const Text(
                        'Gestión de afiliado',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 8, color: Colors.white),

                // Contenido
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Seleccione el banco para la afiliación:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _banks.length,
                            itemBuilder: (_, i) {
                              final b = _banks[i];
                              return RadioListTile<String>(
                                title: Text(b),
                                value: b,
                                groupValue: _selectedBank,
                                onChanged: (v) => setState(() => _selectedBank = v),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _aceptar,
                            icon: _saving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.check),
                            label: Text(_saving ? 'Guardando...' : 'Aceptar'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Se enviará una notificación al banco para la creación del afiliado.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
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

// ======== CONFIRMACIÓN DE AFILIADO OK ======================================
class _AfiliadoOkScreen extends StatelessWidget {
  const _AfiliadoOkScreen();

  static const _panelColor = Color(0xFFAED6D8);

  Future<String?> _loadRifByDocId(BuildContext context) async {
// Esta pantalla no recibe docId, por lo que intentamos leer el último
// cliente trabajado desde una bandera simple en memoria, o puedes
// no usar esto si vienes desde _PreVentaOkScreen (que sí pasa el RIF).
    return null; // mantenemos sin uso aquí
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: const Row(
                children: [
                  Spacer(),
                  Text('Afiliación creada',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  Spacer(),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Container(height: 8, color: Colors.white),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 70, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        'Se ha afiliado correctamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, '/operator/ventas', (_) => false),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver al menú de Ventas'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
// Si en tu flujo real llegas aquí sin docId, no tenemos forma
// de recuperar el RIF con certeza. Se navega sin RIF.
                              Navigator.pushReplacementNamed(
                                context,
                                '/ventas/equipos',
                                arguments: {
// 'rif': '...opcional si lo tienes aquí...'
                                },
                              );
                            },
                            icon: const Icon(Icons.inventory_2),
                            label: const Text('Proceder a equipos disponibles'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ------------------ PREVENTA ----------------------
class _PreVentaScreen extends StatefulWidget {
  const _PreVentaScreen({
    super.key,
    this.docId, // ← nuevo parámetro opcional
  });

  final String? docId;

  @override
  State<_PreVentaScreen> createState() => _PreVentaScreenState();
}

class _PreVentaScreenState extends State<_PreVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rifController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _cliente;

  Future<void> _buscarCliente() async {
    final rif = _rifController.text.trim();
    if (rif.isEmpty) return;

    setState(() => _loading = true);
    try {
      final q = await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: rif.toLowerCase())
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        _cliente = q.docs.first.data();
        _estadoController.text = _cliente?['estado'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente encontrado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el cliente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _registrarPreventa() async {
    if (!_formKey.currentState!.validate()) return;
    final rif = _rifController.text.trim();
    final estado = _estadoController.text.trim();
    if (rif.isEmpty || estado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes llenar todos los campos')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('pre_ventas').add({
        'rif': rif,
        'estado': estado,
        'created_at': FieldValue.serverTimestamp(),
        if (widget.docId != null) 'doc_origen': widget.docId, // ← agregado
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pre-venta registrada con éxito')),
      );

// Pasamos el RIF al siguiente paso
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _PreVentaOkScreen(
            rif: (_cliente?['rif'] as String?)?.trim() ?? rif,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFAED6D8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.assignment_add, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registrar Pre-Venta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _rifController,
                        decoration: InputDecoration(
                          labelText: 'RIF del cliente',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _buscarCliente,
                          ),
                        ),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _estadoController,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _registrarPreventa,
                          icon: _loading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.save_alt),
                          label: Text(_loading ? 'Registrando...' : 'Registrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PreVentaOkScreen extends StatelessWidget {
  const _PreVentaOkScreen({super.key, this.rif});
  final String? rif;

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: const Row(
                children: [
                  Spacer(),
                  Text('Pre-venta aprobada',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  Spacer(),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Container(height: 8, color: Colors.white),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 70, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        'El cliente fue afiliado automáticamente por pre-venta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, '/operator/ventas', (_) => false),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver al menú de Ventas'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/ventas/equipos',
                                arguments: {
                                  if (rif != null && rif!.trim().isNotEmpty) 'rif': rif!.trim(),
                                },
                              );
                            },
                            icon: const Icon(Icons.inventory_2),
                            label: const Text('Proceder a equipos disponibles'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======== PANTALLA DETALLE PLACEHOLDER ======================================
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
                child: const Center(
                  child: Text('Pantalla de detalle (vacía)'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======== WIDGET AUX ========================================================
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}


class _ConfirmarAfiliadoExistenteScreen extends StatelessWidget {
  final String docId;
  final String bank;
  const _ConfirmarAfiliadoExistenteScreen({required this.docId, required this.bank});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        label: const Text('Regresar', style: TextStyle(color: Colors.black87, fontSize: 16)),
                      ),
                      const Spacer(),
                      const Text(
                        'Confirmar afiliado',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 8, color: Colors.white),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance, size: 64),
                        const SizedBox(height: 16),
                        Text('Banco afiliado actual:\n$bank',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Regresar'))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => _TerminalMenuScreen(docId: docId)));
                                },
                                child: const Text('Confirmar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _TerminalMenuScreen extends StatelessWidget {
  final String docId;
  const _TerminalMenuScreen({required this.docId});

  static const _panelColor = Color(0xFFAED6D8);

  Future<String?> _loadRif() async {
    final snap = await FirebaseFirestore.instance
        .collection('Cliente_completo')
        .doc(docId)
        .get();
    return (snap.data()?['rif'] as String?)?.trim();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadRif(),
      builder: (context, rifSnap) {
        final rif = rifSnap.data ?? '';
        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F2),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                      child: const Row(
                        children: [
                          Spacer(),
                          Text('Terminales', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                          Spacer(),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Container(height: 8, color: Colors.white),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/ventas/equipos',
                                  arguments: {'rif': rif},
                                ),
                                icon: const Icon(Icons.device_unknown),
                                label: const Text('Sin terminal disponible'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/ventas/equipos',
                                  arguments: {'rif': rif},
                                ),
                                icon: const Icon(Icons.point_of_sale),
                                label: const Text('Con terminal disponible'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Ya no necesitamos que las subpantallas carguen RIF; si las sigues usando,
// déjalas, pero no son necesarias para el paso del RIF.

class _TerminalNoDisponibleScreen extends StatelessWidget {
  final Map<String, dynamic>? clienteData;

  const _TerminalNoDisponibleScreen({this.clienteData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rifCliente = clienteData?['rif'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFAED6D8),
                borderRadius: BorderRadius.circular(16),
              ),
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
                    'Terminal no disponible',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Actualmente no hay terminales disponibles para este cliente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
// 🔹 Ir a registrar terminal adicional pasando el RIF
                        Navigator.pushNamed(
                          context,
                          '/ventas/equipos',
                          arguments: {
                            'rif': rifCliente,
                          },
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar terminal adicional'),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _TerminalDisponibleScreen extends StatelessWidget {
  final Map<String, dynamic>? clienteData;

  const _TerminalDisponibleScreen({this.clienteData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rifCliente = clienteData?['rif'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFAED6D8),
                borderRadius: BorderRadius.circular(16),
              ),
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
                    'Terminal disponible',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Este cliente tiene terminales disponibles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
// 🔹 Ir a equipos disponibles pasando el RIF
                        Navigator.pushNamed(
                          context,
                          '/ventas/equipos',
                          arguments: {
                            'rif': rifCliente,
                          },
                        );
                      },
                      icon: const Icon(Icons.devices),
                      label: const Text('Proceder a equipos disponibles'),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
