import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:proyectocredicard/features/operator/almacen/presentation/almacen_anadir_tarjeta.dart';
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

// Operator > Almacén
import 'features/operator/almacen/presentation/almacen_screen.dart';
import 'features/operator/almacen/presentation/almacen_equipos_menu_screen.dart';
import 'features/operator/almacen/presentation/almacen_tarjetas_screen.dart';
import 'features/operator/almacen/presentation/almacen_ver_equipos.dart';
import 'features/operator/almacen/presentation/almacen_anadir_equipos.dart';
import 'features/operator/almacen/presentation/almacen_ver_tarjetas.dart';
import 'features/operator/almacen/presentation/almacen_anadir_tarjeta.dart';

// Ventas
import 'features/operator/ventas/presentation/ventas_equipos.dart';
import 'features/operator/ventas/presentation/ventas_operadoras_screen.dart';
import 'features/operator/ventas/presentation/ventas_registro_serial_screen.dart';
import 'features/operator/ventas/presentation/ventas_plan_de_pago_screen.dart';

// Supervisor & Usuario
import 'features/supervisor/presentation/supervisor_home_screen.dart';
import 'features/user/presentation/user_home_screen.dart';

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

// Operador > Almacén
        '/operator/almacen': (context) => const AlmacenScreen(),
        '/operator/almacen/equipos': (context) => const AlmacenEquiposMenuScreen(),
        '/operator/almacen/tarjetas': (context) => const AlmacenTarjetasOperadorasScreen(),
        '/operator/almacen/ver': (context) => const AlmacenVerEquiposScreen(),
        '/operator/almacen/anadir': (context) => const AlmacenAnadirEquiposScreen(),
        '/operator/almacen/ver-tarjetas': (context) => const AlmacenVerTarjetasOperadorasScreen(),
        '/operator/almacen/anadir-tarjetas': (context) => const AlmacenAnadirTarjetasOperadorasScreen(),

// Ventas
        '/ventas/equipos': (context) => const VentasEquiposScreen(),
        '/ventas/operadoras': (context) => const VentasOperadorasScreen(),
      },

// 🔹 AQUI ESTA EL onGenerateRoute actualizado
      onGenerateRoute: (settings) {
        if (settings.name == '/ventas/operadoras/serial') {
          final a = settings.arguments as Map<String, dynamic>?;

// Si no llegaron argumentos, mostramos aviso
          if (a == null || a.isEmpty) {
            return MaterialPageRoute(builder: (_) => const _ArgsMissingScreen());
          }

// Lectura segura de argumentos
          final String rif = a['rif']?.toString() ?? '';
          final String lineaId = a['lineaId']?.toString() ?? '';
          final String lineaName = a['lineaName']?.toString() ?? '';
          final String planTitle = a['planTitle']?.toString() ?? '';
          final String planDesc = a['planDesc']?.toString() ?? '';
          final String planPrice = a['planPrice']?.toString() ?? '';
          final String? modeloSel = a['modeloSeleccionado']?.toString();

// planIndex puede venir como int o String -> normalizamos
          final dynamic idx = a['planIndex'];
          final int planIndex = (idx is int)
              ? idx
              : int.tryParse(idx?.toString() ?? '') ?? 0;

          return MaterialPageRoute(
            builder: (_) => VentasRegistroSerialScreen(
              rif: rif,
              lineaId: lineaId,
              lineaName: lineaName,
              planIndex: planIndex,
              planTitle: planTitle,
              planDesc: planDesc,
              planPrice: planPrice,
              modeloSeleccionado: modeloSel,
            ),
          );
        }

// Otras rutas siguen su flujo normal
        return null;
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

// 🔹 Pantalla mostrada si no llegaron argumentos
class _ArgsMissingScreen extends StatelessWidget {
  const _ArgsMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faltan datos')),
      body: const Center(
        child: Text(
          'No llegaron argumentos para el registro de serial.\n'
              'Vuelve y selecciona un plan nuevamente.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
