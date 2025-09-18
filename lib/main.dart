import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // generado por `flutterfire configure`

// Importa pantallas
import 'features/landing/presentation/landing_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Credicard',
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

// 👇 Rutas necesarias para login según rol
        '/home': (context) => const UserHomeScreen(),
        '/admin': (context) => const AdminHomeScreen(),
      },
    );
  }
}

/// Pantalla temporal para usuarios (cliente, supervisor, operador)
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Usuario')),
      body: const Center(
        child: Text('Bienvenido al Home de Usuario'),
      ),
    );
  }
}

/// Pantalla temporal para admin de identidades
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Admin Identidades')),
      body: const Center(
        child: Text('Bienvenido al Panel del Administrador de Identidades'),
      ),
    );
  }
}

