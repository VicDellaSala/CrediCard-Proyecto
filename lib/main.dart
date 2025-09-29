import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Landing & Auth
import 'features/landing/presentation/landing_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';

// Admin
import 'features/admin/presentation/admin_home_screen.dart';
import 'features/admin/presentation/identity_requests_screen.dart';

// Operator (panel)
import 'features/operator/presentation/operator_home_screen.dart';

// Operator > Módulos principales
import 'features/operator/ventas/presentation/ventas_screen.dart';
import 'features/operator/consultas/presentation/consultas_screen.dart';
import 'features/operator/reportes/presentation/reportes_screen.dart';
import 'features/operator/banco/presentation/banco_screen.dart';
import 'features/operator/finanzas/presentation/finanzas_screen.dart';

// Operator > Almacén (menú y subpantallas)
import 'features/operator/almacen/presentation/almacen_screen.dart';
import 'features/operator/almacen/presentation/almacen_equipos_menu_screen.dart';
// Menú de tarjetas (botones Ver / Añadir)
import 'features/operator/almacen/presentation/almacen_tarjetas_screen.dart';

// Equipos: Ver / Añadir
import 'features/operator/almacen/presentation/almacen_ver_equipos.dart';
import 'features/operator/almacen/presentation/almacen_anadir_equipos.dart';

// Tarjetas: Ver / Añadir (ojo a los nombres de clase correctos)
import 'features/operator/almacen/presentation/almacen_ver_tarjetas.dart'
    show AlmacenVerTarjetasOperadorasScreen;
import 'features/operator/almacen/presentation/almacen_anadir_tarjeta.dart'
    show AlmacenAnadirTarjetasScreen;

// Supervisor & Usuario
import 'features/supervisor/presentation/supervisor_home_screen.dart';
import 'features/user/presentation/user_home_screen.dart';

// Ventas > Equipos (destino común)
import 'features/operator/ventas/presentation/ventas_equipos.dart';

// Banco (nuevo rol)
import 'features/bank/presentation/bank_home_screen.dart';
import 'features/bank/presentation/bank_inbox_menu_screen.dart';
import 'features/bank/presentation/bank_inbox_afiliados_screen.dart';
import 'features/bank/presentation/bank_inbox_terminal_screen.dart';

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

// Operador > Almacén (menú principal)
        '/operator/almacen': (context) => const AlmacenScreen(),

// Almacén > Equipos (menú + subrutas)
        '/operator/almacen/equipos': (context) => const AlmacenEquiposMenuScreen(),
        '/operator/almacen/ver': (context) => const AlmacenVerEquiposScreen(),
        '/operator/almacen/anadir': (context) => const AlmacenAnadirEquiposScreen(),

// Almacén > Tarjetas (menú + subrutas)
        '/operator/almacen/tarjetas': (context) => const AlmacenTarjetasScreen(),
        '/operator/almacen/tarjetas/ver': (context) => const AlmacenVerTarjetasOperadorasScreen(),
        '/operator/almacen/tarjetas/add': (context) => const AlmacenAnadirTarjetasScreen(),

// Ventas > Equipos
        '/ventas/equipos': (context) => const VentasEquiposScreen(),

// Banco
        '/bank': (context) => const BankHomeScreen(),
        '/bank/inbox-menu': (context) => const BankInboxMenuScreen(),
        '/bank/inbox/afiliados': (context) => const BankInboxAfiliadosScreen(),
        '/bank/inbox/terminal': (context) => const BankInboxTerminalScreen(),
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
