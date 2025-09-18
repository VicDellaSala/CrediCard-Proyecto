import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // generado por `flutterfire configure`

// Importa pantallas
import 'features/landing/presentation/landing_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/admin/presentation/identity_requests_screen.dart';
import 'features/admin/presentation/admin_home_screen.dart';
import 'features/operator/presentation/operator_home_screen.dart';

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

// Rutas según rol
        '/home': (context) => const UserHomeScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/admin/identity-requests': (context) => const IdentityRequestsScreen(),
        '/operator': (context) => const OperatorHomeScreen(),
      },
    );
  }
}

/// Pantalla temporal para usuarios (clientes, supervisores, etc.)
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


