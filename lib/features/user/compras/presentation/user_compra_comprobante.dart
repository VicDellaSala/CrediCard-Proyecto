import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Compras > Paso 1: Comprobante del cliente por correo
/// - Lee el email del usuario autenticado
/// - Busca coincidencias en Cliente_completo (email, email_lower, extra_email, extra_emails[])
/// - Muestra el/los RIF encontrados para confirmar
/// - Aceptar -> navega a user_compra_equipos_screen.dart (pasando rif)
/// - Rechazar -> vuelve al menú principal (/home)
class UserCompraComprobanteScreen extends StatefulWidget {
  const UserCompraComprobanteScreen({super.key});

  @override
  State<UserCompraComprobanteScreen> createState() =>
      _UserCompraComprobanteScreenState();
}

class _UserCompraComprobanteScreenState extends State<UserCompraComprobanteScreen> {
  static const _panelColor = Color(0xFFAED6D8);
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;
  List<_ClienteItem> _result = [];
  _ClienteItem? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _result = [];
        _selected = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error =
          'No hay sesión iniciada. Inicia sesión para continuar con la compra.';
          _loading = false;
        });
        return;
      }

      final email = (user.email ?? '').trim();
      if (email.isEmpty) {
        setState(() {
          _error =
          'Tu cuenta no tiene un correo asociado. No es posible validar el RIF.';
          _loading = false;
        });
        return;
      }

      final emailLower = email.toLowerCase();

// Hacemos varias consultas y unimos resultados únicos por docId.
      final List<QuerySnapshot<Map<String, dynamic>>> snaps = await Future.wait([
        _fire
            .collection('Cliente_completo')
            .where('email_lower', isEqualTo: emailLower)
            .limit(10)
            .get(),
        _fire
            .collection('Cliente_completo')
            .where('email', isEqualTo: email)
            .limit(10)
            .get(),
// por si lo guardas como string
        _fire
            .collection('Cliente_completo')
            .where('extra_email', isEqualTo: email)
            .limit(10)
            .get(),
// por si lo guardas como arreglo
        _fire
            .collection('Cliente_completo')
            .where('extra_emails', arrayContains: email)
            .limit(10)
            .get(),
      ]);

      final Map<String, _ClienteItem> uniq = {};
      for (final s in snaps) {
        for (final d in s.docs) {
          uniq[d.id] = _ClienteItem.fromDoc(d);
        }
      }

      final items = uniq.values.toList()
        ..sort((a, b) => (a.fullNameLower ?? '').compareTo(b.fullNameLower ?? ''));

      setState(() {
        _result = items;
        _selected = items.isNotEmpty ? items.first : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al buscar el cliente: $e';
        _loading = false;
      });
    }
  }

  void _onReject() {
// Rechaza y vuelve al menú principal de usuario
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _onAccept() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente para continuar.')),
      );
      return;
    }
// Navegamos al siguiente paso (compra de equipos) pasando el RIF seleccionado.
    Navigator.pushNamed(
      context,
      '/user/compras/equipos',
      arguments: {
        'rif': _selected!.rif ?? '',
        'clienteDocId': _selected!.docId,
        'clienteEmail': _selected!.email,
        'clienteNombre': _selected!.fullName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Encabezado
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Validar cliente por correo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

// Contenido
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _ErrorBox(
                message: _error!,
                onBack: () => Navigator.pop(context),
              )
                  : _result.isEmpty
                  ? _EmptyBox(onBackHome: _onReject, onRetry: _load)
                  : SingleChildScrollView(
                padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Encontramos los siguientes registros asociados a tu correo.',
                            style: TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Selecciona el RIF correcto para continuar.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

// Lista de opciones
                    ..._result.map((c) {
                      final selected = _selected?.docId == c.docId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: RadioListTile<String>(
                          value: c.docId,
                          groupValue: _selected?.docId,
                          onChanged: (_) {
                            setState(() => _selected = c);
                          },
                          activeColor: Colors.black87,
                          title: Text(
                            c.fullName?.isNotEmpty == true
                                ? c.fullName!
                                : (c.email ?? '(sin nombre)'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text('RIF: ${c.rif ?? '—'}'),
                              if (c.email?.isNotEmpty == true)
                                Text('Email: ${c.email}'),
                            ],
                          ),
                          secondary: Icon(
                            selected
                                ? Icons.verified_user
                                : Icons.account_circle_outlined,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

// Botones Aceptar / Rechazar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _onReject,
                            icon: const Icon(Icons.close),
                            label: const Text('Rechazar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onAccept,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Aceptar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
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
    );
  }
}

class _ClienteItem {
  final String docId;
  final String? rif;
  final String? email;
  final String? fullName;
  final String? fullNameLower;

  _ClienteItem({
    required this.docId,
    this.rif,
    this.email,
    this.fullName,
    this.fullNameLower,
  });

  factory _ClienteItem.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> d,
      ) {
    final data = d.data();
    return _ClienteItem(
      docId: d.id,
      rif: (data['rif'] ?? '').toString(),
      email: (data['email'] ?? data['email_lower'] ?? '').toString(),
      fullName: (data['full_name'] ??
          '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}')
          .toString()
          .trim(),
      fullNameLower: (data['full_name_lower'] ?? '').toString(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E9EC)),
      ),
      child: child,
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final VoidCallback onBackHome;
  final VoidCallback onRetry;
  const _EmptyBox({required this.onBackHome, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 56, color: Colors.black45),
          const SizedBox(height: 8),
          const Text(
            'No conseguimos un cliente con tu correo.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
              'Verifica que tu cuenta tenga un email asociado a Cliente_completo.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBackHome,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorBox({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
          )
        ],
      ),
    );
  }
}
