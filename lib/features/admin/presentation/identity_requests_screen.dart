import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Lista de bancos disponible para el rol "banco"
const List<String> kBanks = [
  'Banco de Venezuela',
  'Bancamiga',
  'Bancaribe',
  'Banco del Tesoro',
  'Bancrecer',
  'Mi Banco',
  'Banfanb',
  'Banco Activo',
];

class IdentityRequestsScreen extends StatefulWidget {
  /// Si quieres abrir directamente la pestaña de Bancos, pasa initialTab: 1
  final int initialTab;
  const IdentityRequestsScreen({super.key, this.initialTab = 0});

  @override
  State<IdentityRequestsScreen> createState() => _IdentityRequestsScreenState();
}

class _IdentityRequestsScreenState extends State<IdentityRequestsScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    final tabIndex = (widget.initialTab < 0 || widget.initialTab > 1) ? 0 : widget.initialTab;

    return DefaultTabController(
      length: 2,
      initialIndex: tabIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
// Header azul
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
                          label: const Text('Volver', style: TextStyle(color: Colors.black87)),
                        ),
                        const Spacer(),
                        const Text(
                          'Panel: Administrador de Identidades',
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

// Tira blanca con pestañas
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: const TabBar(
                      indicatorColor: Colors.transparent,
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.black54,
                      tabs: [
                        Tab(text: 'Solicitudes de roles Credicard'),
                        Tab(text: 'Solicitudes de roles Bancos'),
                      ],
                    ),
                  ),

// Contenido pestañas
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const TabBarView(
                        children: [
                          _CredicardRequestsTab(),
                          _BankRequestsTab(),
                        ],
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

// ================== TAB CREDICARD ==================
class _CredicardRequestsTab extends StatelessWidget {
  const _CredicardRequestsTab();

  @override
  Widget build(BuildContext context) {
    final qs = FirebaseFirestore.instance
        .collection('role_requests')
        .where('request_type', isEqualTo: 'credicard')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: qs,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No hay solicitudes Credicard pendientes.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data();
            final id = doc.id;
            final email = (d['email'] as String?) ?? '';
            final uid = (d['uid'] as String?) ?? '';
            final name = (d['name'] as String?) ?? '';
            final createdAt = d['createdAt'];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.badge),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (name.isNotEmpty) Text(name),
                          if (createdAt != null)
                            Text('Solicitado: $createdAt', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    _CredicardRoleSetter(uid: uid, requestId: id),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CredicardRoleSetter extends StatefulWidget {
  final String uid;
  final String requestId;
  const _CredicardRoleSetter({required this.uid, required this.requestId});

  @override
  State<_CredicardRoleSetter> createState() => _CredicardRoleSetterState();
}

class _CredicardRoleSetterState extends State<_CredicardRoleSetter> {
  final List<String> _roles = const ['supervisor', 'operador', 'admin_identidades'];
  String? _role;
  bool _saving = false;

  Future<void> _approve() async {
    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un rol')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'role': _role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('role_requests').doc(widget.requestId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol asignado: $_role')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text('¿Seguro que deseas eliminar esta cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
// Enviar solicitud de eliminación (si usas Cloud Functions para borrar en Auth)
      await FirebaseFirestore.instance.collection('deletion_requests').add({
        'uid': widget.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });

// Eliminar la solicitud de rol
      await FirebaseFirestore.instance.collection('role_requests').doc(widget.requestId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta marcada para eliminación')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          hint: const Text('Seleccionar rol'),
          value: _role,
          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _role = v),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saving ? null : _approve,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Asignar'),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Eliminar cuenta',
          onPressed: _deleteUser,
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ],
    );
  }
}

// ================== TAB BANCOS ==================
class _BankRequestsTab extends StatelessWidget {
  const _BankRequestsTab();

  @override
  Widget build(BuildContext context) {
    final qs = FirebaseFirestore.instance
        .collection('role_requests')
        .where('request_type', isEqualTo: 'bank')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: qs,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No hay solicitudes de bancos pendientes.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data();
            final id = doc.id;
            final email = (d['email'] as String?) ?? '';
            final uid = (d['uid'] as String?) ?? '';
            final name = (d['name'] as String?) ?? '';
            final domain = (d['domain'] as String?) ?? '';
            final createdAt = d['createdAt'];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_balance),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (name.isNotEmpty) Text(name),
                          if (domain.isNotEmpty) Text('Dominio: $domain', style: const TextStyle(fontSize: 12)),
                          if (createdAt != null)
                            Text('Solicitado: $createdAt', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          _BankRoleSetter(uid: uid, requestId: id),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BankRoleSetter extends StatefulWidget {
  final String uid;
  final String requestId;
  const _BankRoleSetter({required this.uid, required this.requestId});

  @override
  State<_BankRoleSetter> createState() => _BankRoleSetterState();
}

class _BankRoleSetterState extends State<_BankRoleSetter> {
  String? _bankName;
  bool _saving = false;

  Future<void> _approve() async {
    if (_bankName == null || _bankName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el banco')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'role': 'banco',
        'bank': _bankName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('role_requests').doc(widget.requestId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asignado rol Banco: $_bankName')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text('¿Seguro que deseas eliminar esta cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection('deletion_requests').add({
        'uid': widget.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });

      await FirebaseFirestore.instance.collection('role_requests').doc(widget.requestId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta marcada para eliminación')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          hint: const Text('Seleccionar banco'),
          value: _bankName,
          items: kBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (v) => setState(() => _bankName = v),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saving ? null : _approve,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Asignar'),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Eliminar cuenta',
          onPressed: _deleteUser,
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ],
    );
  }
}
