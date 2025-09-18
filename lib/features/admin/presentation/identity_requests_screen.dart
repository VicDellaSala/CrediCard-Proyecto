import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IdentityRequestsScreen extends StatefulWidget {
  const IdentityRequestsScreen({super.key});

  @override
  State<IdentityRequestsScreen> createState() => _IdentityRequestsScreenState();
}

class _IdentityRequestsScreenState extends State<IdentityRequestsScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  /// requestId -> selectedRole
  final Map<String, String> _selections = {};
  bool _submitting = false;

// Stream sin orderBy (ordenamos localmente para evitar depender de índice)
  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingRequestsStream() {
    return FirebaseFirestore.instance
        .collection('role_requests')
        .where('status', isEqualTo: 'pendiente')
        .snapshots();
  }

  List<DropdownMenuItem<String>> get _roleItems => const [
    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
    DropdownMenuItem(value: 'operador', child: Text('Operador')),
    DropdownMenuItem(
      value: 'admin_identidades',
      child: Text('Administrador de gestión de identidades'),
    ),
  ];

  Future<void> _submit() async {
    if (_selections.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final requestsCol = db.collection('role_requests');
      final usersCol = db.collection('users');

      for (final entry in _selections.entries) {
        final requestId = entry.key;
        final selectedRole = entry.value;

        final reqRef = requestsCol.doc(requestId);
        final reqSnap = await reqRef.get();
        if (!reqSnap.exists) continue;

        final data = reqSnap.data() as Map<String, dynamic>;
        if ((data['status'] as String?)?.toLowerCase() != 'pendiente') continue;

        final uid = data['userId'] as String?;
        if (uid == null || uid.isEmpty) continue;

        final userRef = usersCol.doc(uid);

// Asignar rol y aprobar
        batch.update(userRef, {
          'role': selectedRole, // supervisor | operador | admin_identidades
          'status': 'aprobado',
          'disabled': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        batch.update(reqRef, {
          'status': 'aprobado',
          'decidedRole': selectedRole,
          'decidedAt': FieldValue.serverTimestamp(),
          'decidedBy': adminUid,
        });
      }

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roles asignados correctamente')),
      );
      setState(() => _selections.clear());
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar roles: ${e.message ?? e.code}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al asignar roles')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteRequest({
    required String requestId,
    required String uid,
    required String email,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          '¿Seguro que deseas eliminar la cuenta:\n$email?\n\n'
              'Se deshabilitará el acceso del usuario y se marcará la solicitud como eliminada.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final userRef = db.collection('users').doc(uid);
      final reqRef = db.collection('role_requests').doc(requestId);

// 1) Deshabilita el usuario y marca eliminado (no borra Auth aquí)
      batch.update(userRef, {
        'status': 'eliminado',
        'disabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

// 2) Marca la solicitud como eliminada
      batch.update(reqRef, {
        'status': 'eliminado',
        'decidedRole': 'eliminado',
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': adminUid,
      });

// 3) Crea orden opcional para borrar en Authentication con Cloud Functions/Admin SDK
      final delRef = db.collection('deletion_requests').doc();
      batch.set(delRef, {
        'userId': uid,
        'email': email,
        'requestedBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada (deshabilitada)')),
      );

// Si estaba seleccionada en el dropdown, la quitamos del mapa
      setState(() {
        _selections.remove(requestId);
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.message ?? e.code}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al eliminar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selections.isNotEmpty && !_submitting;

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
// HEADER con volver al panel
                  Container(
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          label: const Text('Volver al Panel',
                              style: TextStyle(color: Colors.black87, fontSize: 16)),
                        ),
                        const Spacer(),
                        const Text(
                          'Gestión de identidades — Solicitudes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
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

// LISTA
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _pendingRequestsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error cargando solicitudes: ${snapshot.error}'),
                              );
                            }
                            final docs = snapshot.data?.docs ?? [];

// Ordena local por fecha (desc)
                            docs.sort((a, b) {
                              final ta = (a.data()['requestedAt'] as Timestamp?);
                              final tb = (b.data()['requestedAt'] as Timestamp?);
                              final da = ta?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                              final db = tb?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                              return db.compareTo(da);
                            });

                            if (docs.isEmpty) {
                              return const Center(
                                child: Text('No hay solicitudes pendientes',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                              );
                            }

                            return Column(
                              children: [
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: docs.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, i) {
                                      final doc = docs[i];
                                      final d = doc.data();
                                      final requestId = doc.id;
                                      final fullName = (d['fullName'] as String?) ?? '—';
                                      final email = (d['email'] as String?) ?? '—';
                                      final uid = (d['userId'] as String?) ?? '';
                                      final requestedAt = (d['requestedAt'] as Timestamp?);
                                      final when = requestedAt != null
                                          ? requestedAt.toDate().toLocal().toString().substring(0, 19)
                                          : '—';
                                      final selected = _selections[requestId];

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    fullName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
// Dropdown de rol
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.black12),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      value: selected,
                                                      items: _roleItems,
                                                      hint: const Text('Seleccionar rol'),
                                                      onChanged: (val) {
                                                        setState(() {
                                                          if (val == null) {
                                                            _selections.remove(requestId);
                                                          } else {
                                                            _selections[requestId] = val;
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
// Icono de basura
                                                IconButton(
                                                  tooltip: 'Eliminar cuenta',
                                                  onPressed: uid.isEmpty
                                                      ? null
                                                      : () => _deleteRequest(
                                                    requestId: requestId,
                                                    uid: uid,
                                                    email: email,
                                                  ),
                                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.email_outlined, size: 16),
                                                const SizedBox(width: 6),
                                                Text(email),
                                                const Spacer(),
                                                const Icon(Icons.schedule, size: 16),
                                                const SizedBox(width: 6),
                                                Text('Solicitado: $when'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

// Botón inferior para aplicar roles seleccionados
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: canSubmit ? _submit : null,
                                    icon: _submitting
                                        ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                        : const Icon(Icons.check_circle_outline),
                                    label: Text(_submitting
                                        ? 'Aplicando cambios...'
                                        : 'Asignar roles seleccionados'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
