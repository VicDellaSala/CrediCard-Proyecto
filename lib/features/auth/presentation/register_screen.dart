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

  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isCredicardEmail(String email) =>
      email.toLowerCase().trim().endsWith('@credicard.com.ve');

  bool _isFirstIdentityAdmin(String email) =>
      email.toLowerCase().trim() == 'identidad@credicard.com.ve';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final firstName = _nameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();

// 1) Crear cuenta en Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final uid = cred.user!.uid;

// 2) Determinar rol y estado inicial
      String role;
      String status;
      bool companyUser = _isCredicardEmail(email);

      if (_isFirstIdentityAdmin(email)) {
        role = 'admin_identidades';
        status = 'aprobado';
      } else if (companyUser) {
        role = 'pendiente';
        status = 'pendiente';
      } else {
        role = 'cliente';
        status = 'aprobado';
      }

// 3) Guardar perfil en Firestore
      final users = FirebaseFirestore.instance.collection('users');
      await users.doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'email': email,
        'role': role,
        'status': status,
        'companyUser': companyUser,
        'createdAt': FieldValue.serverTimestamp(),
      });

// 4) Crear solicitud si es corporativo (y no el primer admin)
      if (companyUser && !_isFirstIdentityAdmin(email)) {
        await FirebaseFirestore.instance.collection('role_requests').add({
          'userId': uid,
          'email': email,
          'fullName': '$firstName $lastName',
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pendiente',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            companyUser && !_isFirstIdentityAdmin(email)
                ? 'Registro enviado. Un administrador asignará tu rol.'
                : 'Registro exitoso.',
          ),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      final map = {
        'email-already-in-use': 'El correo ya está registrado.',
        'invalid-email': 'Correo inválido.',
        'weak-password': 'La contraseña es muy débil (mín. 6).',
        'operation-not-allowed': 'Método de inicio de sesión deshabilitado.',
        'network-request-failed': 'Fallo de red. Verifica tu conexión.',
      };
      final msg = map[e.code] ?? (e.message ?? 'Error de autenticación');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $msg')));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando datos: ${e.message ?? e.code}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error inesperado')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
    if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
    return null;
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
// Header
                  Container(
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
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

                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const SizedBox.shrink(),
                  ),

// Formulario
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
                          constraints: const BoxConstraints(maxWidth: 540),
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
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _nameCtrl,
                                            decoration: const InputDecoration(labelText: 'Nombre'),
                                            validator: (v) => (v == null || v.trim().isEmpty)
                                                ? 'Ingresa tu nombre'
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _lastNameCtrl,
                                            decoration: const InputDecoration(labelText: 'Apellidos'),
                                            validator: (v) => (v == null || v.trim().isEmpty)
                                                ? 'Ingresa tus apellidos'
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _emailCtrl,
                                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _emailValidator,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _passCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Contraseña',
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(() => _obscure = !_obscure),
                                                icon: Icon(_obscure
                                                    ? Icons.visibility
                                                    : Icons.visibility_off),
                                              ),
                                            ),
                                            obscureText: _obscure,
                                            validator: (v) => (v == null || v.length < 6)
                                                ? 'Mínimo 6 caracteres'
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _confirmCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Confirmar contraseña',
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                                icon: Icon(_obscureConfirm
                                                    ? Icons.visibility
                                                    : Icons.visibility_off),
                                              ),
                                            ),
                                            obscureText: _obscureConfirm,
                                            validator: (v) => (v != _passCtrl.text)
                                                ? 'Las contraseñas no coinciden'
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 48,
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _register,
                                        child: _loading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text('Crear cuenta'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('¿Ya tienes cuenta?'),
                                        TextButton(
                                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                          child: const Text('Inicia sesión'),
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

