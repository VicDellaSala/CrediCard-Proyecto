import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BankHomeScreen extends StatefulWidget {
  const BankHomeScreen({super.key});

  @override
  State<BankHomeScreen> createState() => _BankHomeScreenState();
}

class _BankHomeScreenState extends State<BankHomeScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  String? _bankName;
  bool _loadingBank = true;
  String? _bankLoadError;

  @override
  void initState() {
    super.initState();
    _loadMyBank();
  }

  Future<void> _loadMyBank() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _bankLoadError = 'No hay sesión activa.';
          _loadingBank = false;
        });
        return;
      }
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data();
      final bank = (data?['bank'] as String?)?.trim();
      setState(() {
        _bankName = (bank?.isNotEmpty ?? false) ? bank : null;
        _loadingBank = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _bankLoadError = e.message ?? e.code;
        _loadingBank = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        label: const Text('Volver',
                            style: TextStyle(color: Colors.black87)),
                      ),
                      const Spacer(),
                      Text(
                        _bankName == null
                            ? 'Panel del Banco'
                            : 'Panel: $_bankName',
                        style: const TextStyle(
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

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingBank) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bankLoadError != null) {
      return Center(child: Text('Error: $_bankLoadError'));
    }
    if (_bankName == null) {
      return const Center(
        child: Text(
          'Tu usuario no tiene banco asignado. Pide al Admin de identidades que te asigne uno.',
          textAlign: TextAlign.center,
        ),
      );
    }

// Colección sugerida: "affiliation_requests"
// Campos mínimos: bank (String), status (String: "pendiente"/"aprobado"/"rechazado"),
// clientId, clientName, rif, createdAt (Timestamp), requestedBy (uid operador), etc.
    final query = FirebaseFirestore.instance
        .collection('affiliation_requests')
        .where('bank', isEqualTo: _bankName)
        .where('status', isEqualTo: 'pendiente')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No hay solicitudes pendientes para este banco.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final id = docs[i].id;
            final clientName = (d['clientName'] as String?) ?? '';
            final rif = (d['rif'] as String?) ?? '';
            final createdAt = d['createdAt'];
            final email = (d['email'] as String?) ?? ''; // opcional

            return Card(
              color: const Color(0xFFF6F0F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_add),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            clientName.isNotEmpty ? clientName : rif,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (rif.isNotEmpty)
                          Text('RIF: $rif',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        const Spacer(),
                        if (createdAt != null)
                          Text(
                            _fmtTS(createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(id, 'rechazado'),
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _updateStatus(id, 'aprobado'),
                          icon: const Icon(Icons.check),
                          label: const Text('Aprobar'),
                        ),
                      ],
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

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('affiliation_requests')
          .doc(docId)
          .update({
        'status': status,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud $status')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message ?? e.code}')),
      );
    }
  }
}

// ---- helpers ----
String _fmtTS(dynamic ts) {
  try {
    final t = (ts as Timestamp).toDate().toLocal();
    final dd = t.day.toString().padLeft(2, '0');
    final mm = t.month.toString().padLeft(2, '0');
    final yyyy = t.year.toString();
    final hh = t.hour.toString().padLeft(2, '0');
    final mi = t.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$mi';
  } catch (_) {
    return '';
  }
}
