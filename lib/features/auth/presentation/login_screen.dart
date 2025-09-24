import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
// Mismo color que en RegisterScreen
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
// 1) Iniciar sesión en Firebase Auth
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

// 2) Leer datos del usuario en Firestore (colección 'users')
      final uid = cred.user!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

// Si no existe el doc, asumimos 'usuario'
      final data = snap.data() ?? {};
      final role = (data['role'] as String?)?.toLowerCase() ?? 'usuario';

      if (!mounted) return;

// 3) Redirigir según rol (AÑADIDO: 'banco' -> '/bank')
      switch (role) {
        case 'admin_identidades':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'operador':
          Navigator.pushReplacementNamed(context, '/operator');
          break;
        case 'supervisor':
          Navigator.pushReplacementNamed(context, '/supervisor');
          break;
        case 'banco': // 👈 NUEVO
          Navigator.pushReplacementNamed(context, '/bank');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      final map = {
        'invalid-email': 'Correo inválido.',
        'user-disabled': 'Usuario deshabilitado.',
        'user-not-found': 'Usuario no encontrado.',
        'wrong-password': 'Contraseña incorrecta.',
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
          SnackBar(content: Text('Error con Firestore: ${e.message ?? e.code}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error inesperado al iniciar sesión')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu email para recuperar la contraseña')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te enviamos un correo para restablecer la contraseña')),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'No se pudo enviar el correo';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
      }
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
// Header celeste con flecha y título centrado (igual que en Registro)
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
                          'Iniciar sesión',
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

// Banda blanca fina para coherencia visual
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const SizedBox.shrink(),
                  ),

// Panel grande celeste con el formulario dentro de una tarjeta blanca
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
                          constraints: const BoxConstraints(maxWidth: 460),
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
                                      controller: _emailCtrl,
                                      decoration: const InputDecoration(labelText: 'Email'),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) =>
                                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Contraseña',
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                          icon: Icon(
                                            _obscure ? Icons.visibility : Icons.visibility_off,
                                          ),
                                        ),
                                      ),
                                      obscureText: _obscure,
                                      validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _login,
                                        child: _loading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text('Entrar'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _resetPassword,
                                        child: const Text('¿Olvidaste tu contraseña?'),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('¿No tienes cuenta?'),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushReplacementNamed(context, '/register');
                                          },
                                          child: const Text('Regístrate'),
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
