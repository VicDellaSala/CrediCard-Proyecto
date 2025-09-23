import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final first = _firstNameCtrl.text.trim();
      final last = _lastNameCtrl.text.trim();
      final fullName = '$first $last';

// 1) Crear usuario en Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passCtrl.text.trim(),
      );
      final uid = cred.user!.uid;

// 2) Guardar datos básicos en Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'first_name': first,
        'last_name': last,
        'name': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

// 3) Lógica de roles y solicitudes
      const bankDomains = [
        'bancodevenezuela.com',
        'bancodevenezuela.com.ve',
        'bancamiga.com',
        'bancaribe.com.ve',
        'bdt.gob.ve', // Banco del Tesoro
        'bancrecer.com',
        'mibanco.com.ve',
        'banfanb.fin.ve', // Ajustar dominio real
        'bancoactivo.com.ve',
      ];

      String roleToSet = 'cliente';
      String? domain;
      final at = email.indexOf('@');
      if (at != -1) domain = email.substring(at + 1);

      if (email == 'identidad@credicard.com.ve') {
// Semilla: primer admin de identidades
        roleToSet = 'admin_identidades';
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': roleToSet,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (domain != null && bankDomains.contains(domain)) {
// 👉 Rol Banco (solicitud)
        await FirebaseFirestore.instance.collection('role_requests').add({
          'uid': uid,
          'email': email,
          'name': fullName,
          'domain': domain,
          'request_type': 'bank',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': 'pending_bank',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (email.endsWith('@credicard.com.ve')) {
// 👉 Rol Credicard (supervisor, operador o admin de identidades)
        await FirebaseFirestore.instance.collection('role_requests').add({
          'uid': uid,
          'email': email,
          'name': fullName,
          'request_type': 'credicard',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
// 👉 Cliente normal
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': roleToSet,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      final map = {
        'email-already-in-use': 'El correo ya está registrado.',
        'invalid-email': 'Correo inválido.',
        'weak-password': 'La contraseña es muy débil (mín. 6).',
        'operation-not-allowed': 'Método deshabilitado en Auth.',
        'network-request-failed': 'Fallo de red. Verifica tu conexión.',
      };
      final msg = map[e.code] ?? (e.message ?? 'Error de autenticación');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $msg')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Firestore: ${e.message ?? e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                mainAxisSize: MainAxisSize.min,
                children: [
// HEADER azul con botón volver
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
                          'Registro',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1)),
                            ],
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

// Panel celeste con el formulario
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      controller: _firstNameCtrl,
                                      decoration: const InputDecoration(labelText: 'Nombre'),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _lastNameCtrl,
                                      decoration: const InputDecoration(labelText: 'Apellidos'),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tus apellidos' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _emailCtrl,
                                      decoration: const InputDecoration(labelText: 'Correo'),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                                        if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Contraseña',
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                        ),
                                      ),
                                      obscureText: _obscure,
                                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirmCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Confirmar contraseña',
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                                          icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                                        ),
                                      ),
                                      obscureText: _obscure2,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                                        if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _register,
                                        child: _loading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text('Crear cuenta'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

