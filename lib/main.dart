import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // generado por `flutterfire configure`

// Landing & Auth
import 'features/landing/presentation/landing_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';

// Admin
import 'features/admin/presentation/admin_home_screen.dart';
import 'features/admin/presentation/identity_requests_screen.dart';

// Operator (panel + subpáginas)
import 'features/operator/presentation/operator_home_screen.dart';
import 'features/operator/ventas/presentation/ventas_screen.dart';
import 'features/operator/consultas/presentation/consultas_screen.dart';
import 'features/operator/reportes/presentation/reportes_screen.dart';
import 'features/operator/banco/presentation/banco_screen.dart';
import 'features/operator/almacen/presentation/almacen_screen.dart';
import 'features/operator/finanzas/presentation/finanzas_screen.dart';

// Supervisor & Usuario
import 'features/supervisor/presentation/supervisor_home_screen.dart';
import 'features/user/presentation/user_home_screen.dart';

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
// Base
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

// Rutas según rol
        '/home': (context) => const UserHomeScreen(), // usuarios/clientes (y fallback)
        '/user': (context) => const UserHomeScreen(), // alias opcional
        '/supervisor': (context) => const SupervisorHomeScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/admin/identity-requests': (context) => const IdentityRequestsScreen(),

// Operador
        '/operator': (context) => const OperatorHomeScreen(),
        '/operator/ventas': (context) => const VentasScreen(),
        '/operator/consultas': (context) => const ConsultasScreen(),
        '/operator/reportes': (context) => const ReportesScreen(),
        '/operator/banco': (context) => const BancoScreen(),
        '/operator/almacen': (context) => const AlmacenScreen(),
        '/operator/finanzas': (context) => const FinanzasScreen(),
      },
    );
  }
}
