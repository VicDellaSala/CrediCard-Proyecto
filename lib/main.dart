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

// Operator (panel)
import 'features/operator/presentation/operator_home_screen.dart';

// Operator > Ventas / Consultas / Reportes / Banco / Finanzas
import 'features/operator/ventas/presentation/ventas_screen.dart';
import 'features/operator/consultas/presentation/consultas_screen.dart';
import 'features/operator/reportes/presentation/reportes_screen.dart';
import 'features/operator/banco/presentation/banco_screen.dart';
import 'features/operator/finanzas/presentation/finanzas_screen.dart';

// Operator > Almacén (menú + subpantallas)
import 'features/operator/almacen/presentation/almacen_screen.dart';
import 'features/operator/almacen/presentation/solicitar_equipos_screen.dart';
import 'features/operator/almacen/presentation/gestion_almacen_screen.dart';
import 'features/operator/almacen/presentation/autorizacion_solicitudes_screen.dart';
import 'features/operator/almacen/presentation/entrega_equipo_simcard_screen.dart';
import 'features/operator/almacen/presentation/traslado_almacen_screen.dart';

// Supervisor & Usuario
import 'features/supervisor/presentation/supervisor_home_screen.dart';
import 'features/user/presentation/user_home_screen.dart';

// Ventas > equipos (destino común)
import 'features/operator/ventas/presentation/ventas_equipos.dart';

// Banco (nuevo rol)
import 'features/bank/presentation/bank_home_screen.dart';
import 'features/bank/presentation/bank_inbox_menu_screen.dart';
import 'features/bank/presentation/bank_inbox_afiliados_screen.dart';
import 'features/bank/presentation/bank_inbox_terminal_screen.dart';
// Si tienes una pantalla real para "procesadas", impórtala y
// reemplaza el placeholder más abajo.
// import 'features/bank/presentation/bank_processed_screen.dart';

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
        '/home': (context) => const UserHomeScreen(), // fallback
        '/user': (context) => const UserHomeScreen(),
        '/supervisor': (context) => const SupervisorHomeScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/admin/identity-requests': (context) => const IdentityRequestsScreen(),

// Operador (panel)
        '/operator': (context) => const OperatorHomeScreen(),

// Operador > Módulos
        '/operator/ventas': (context) => const VentasScreen(),
        '/operator/consultas': (context) => const ConsultasScreen(),
        '/operator/reportes': (context) => const ReportesScreen(),
        '/operator/banco': (context) => const BancoScreen(),
        '/operator/finanzas': (context) => const FinanzasScreen(),

// Operador > Almacén
        '/operator/almacen': (context) => const AlmacenScreen(),
        '/operator/almacen/solicitar': (context) => const SolicitarEquiposScreen(),
        '/operator/almacen/gestion': (context) => const GestionAlmacenScreen(),
        '/operator/almacen/autorizaciones': (context) => const AutorizacionSolicitudesScreen(),
        '/operator/almacen/entrega': (context) => const EntregaEquipoSimcardScreen(),
        '/operator/almacen/traslado': (context) => const TrasladoAlmacenScreen(),

// Ventas > Equipos
        '/ventas/equipos': (context) => const VentasEquiposScreen(),

// Banco
        '/bank': (context) => const BankHomeScreen(),
        '/bank/inbox-menu': (context) => const BankInboxMenuScreen(),
        '/bank/inbox/afiliados': (context) => const BankInboxAfiliadosScreen(),
        '/bank/inbox/terminal': (context) => const BankInboxTerminalScreen(),
// Reemplaza este placeholder cuando tengas la pantalla real:
        '/bank/processed': (context) => const _BankProcessedPlaceholder(),
      },
    );
  }
}

// Placeholder temporal para “Solicitudes procesadas”
class _BankProcessedPlaceholder extends StatelessWidget {
  const _BankProcessedPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes procesadas')),
      body: const Center(
        child: Text('Aquí irán las solicitudes procesadas del banco'),
      ),
    );
  }
}
