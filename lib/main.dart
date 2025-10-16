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

// Operator > módulos
import 'features/operator/ventas/presentation/ventas_screen.dart';
import 'features/operator/consultas/presentation/consultas_screen.dart';
import 'features/operator/reportes/presentation/reportes_screen.dart';
import 'features/operator/banco/presentation/banco_screen.dart';
import 'features/operator/finanzas/presentation/finanzas_screen.dart';

// Operator > Almacén (menú + subpantallas)
import 'features/operator/almacen/presentation/almacen_screen.dart';
import 'features/operator/almacen/presentation/almacen_equipos_menu_screen.dart';
import 'features/operator/almacen/presentation/almacen_tarjetas_screen.dart';

// Equipos (ver / añadir)
import 'features/operator/almacen/presentation/almacen_ver_equipos.dart';
import 'features/operator/almacen/presentation/almacen_anadir_equipos.dart';

// Tarjetas (ver / añadir) — archivo en singular para “añadir”
import 'features/operator/almacen/presentation/almacen_ver_tarjetas.dart';
import 'features/operator/almacen/presentation/almacen_anadir_tarjeta.dart';

// Supervisor & Usuario
import 'features/supervisor/presentation/supervisor_home_screen.dart';
import 'features/user/presentation/user_home_screen.dart';

// Ventas > equipos (modelos disponibles)
import 'features/operator/ventas/presentation/ventas_equipos.dart';

// Ventas > Operadoras (selección de plan) + Registro de serial
import 'features/operator/ventas/presentation/ventas_operadoras_screen.dart';
import 'features/operator/ventas/presentation/ventas_registro_serial_screen.dart';

// ===== Plan de pago + flujos =====
import 'features/operator/ventas/presentation/ventas_plan_de_pago_screen.dart';
import 'features/operator/ventas/presentation/ventas_comodato.dart';
import 'features/operator/ventas/presentation/ventas_contado_financiado.dart';

// ===== NUEVO: pago por transferencia + chequeo =====
import 'features/operator/ventas/presentation/ventas_transferencia_bancaria.dart';

// ===== NUEVO: pago por PDV + datos finales =====
import 'features/operator/ventas/presentation/venta_pdv_pago.dart';
import 'features/operator/ventas/presentation/ventas_datos_finales.dart';

// ===== NUEVO: pago en EFECTIVO =====
import 'features/operator/ventas/presentation/ventas_pago_efectivo.dart';

// ===== NUEVO: Access / Comerce =====
import 'features/operator/ventas/presentation/ventas_access_comerce.dart';

// Banco (nuevo rol)
import 'features/bank/presentation/bank_home_screen.dart';
import 'features/bank/presentation/bank_inbox_menu_screen.dart';
import 'features/bank/presentation/bank_inbox_afiliados_screen.dart';
import 'features/bank/presentation/bank_inbox_terminal_screen.dart';
// import 'features/bank/presentation/bank_processed_screen.dart'; // si ya la tienes

// ===== NUEVO: Compras (usuario)
import 'features/user/compras/presentation/user_compra_comprobante.dart';
import 'features/user/compras/presentation/user_compra_equipos_screen.dart';

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

// Rutas por rol
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

// Operador > Almacén (menú y sub-rutas)
        '/operator/almacen': (context) => const AlmacenScreen(),
        '/operator/almacen/equipos': (context) => const AlmacenEquiposMenuScreen(),

// Equipos
        '/operator/almacen/ver': (context) => const AlmacenVerEquiposScreen(),
        '/operator/almacen/anadir': (context) => const AlmacenAnadirEquiposScreen(),

// Tarjetas de operadoras
        '/operator/almacen/tarjetas': (context) =>
        const AlmacenTarjetasOperadorasScreen(),
        '/operator/almacen/tarjetas/ver': (context) =>
        const AlmacenVerTarjetasOperadorasScreen(),
        '/operator/almacen/tarjetas/add': (context) =>
        const AlmacenAnadirTarjetasOperadorasScreen(),

// Ventas > Equipos (lista de modelos)
        '/ventas/equipos': (context) => const VentasEquiposScreen(),

// Ventas > Operadoras (selección de plan)
        '/ventas/operadoras': (context) => const VentasOperadorasScreen(),

// Plan de pago + flujos
        '/ventas/plan': (context) => const VentasPlanDePagoScreen(),
        '/ventas/plan/comodato': (context) => const VentasComodatoScreen(),
        '/ventas/plan/contado-financiado': (context) =>
        const VentasContadoFinanciadoScreen(),

// NUEVO: transferencia bancaria y chequeo
        '/ventas/pago/transferencia': (context) =>
        const VentasTransferenciaBancariaScreen(),
        '/ventas/chequeo': (context) =>
        const VentasDatosFinalesScreen(),

// NUEVO: PDV y datos finales
        '/ventas/pago/pdv': (context) =>
        const VentaPdvPagoScreen(),
        '/ventas/datos-finales': (context) =>
        const VentasDatosFinalesScreen(),

// NUEVO: EFECTIVO
        '/ventas/pago/efectivo': (context) =>
        const VentasPagoEfectivoScreen(),

// NUEVO: ACCESS / COMERCE
        '/ventas/pago/access-comerce': (context) =>
        const VentasAccessComerceScreen(),

// Banco
        '/bank': (context) => const BankHomeScreen(),
        '/bank/inbox-menu': (context) => const BankInboxMenuScreen(),
        '/bank/inbox/afiliados': (context) => const BankInboxAfiliadosScreen(),
        '/bank/inbox/terminal': (context) => const BankInboxTerminalScreen(),
        '/bank/processed': (context) => const _BankProcessedPlaceholder(),

// ===== NUEVO: Compras (usuario)
        '/user/compras/comprobante': (context) =>
        const UserCompraComprobanteScreen(),
        '/user/compras/equipos': (context) =>
        const UserCompraEquiposScreen(),
      },

// Construir Registro de Serial con argumentos (sin tocar)
      onGenerateRoute: (settings) {
        if (settings.name == '/ventas/operadoras/serial') {
          final a = (settings.arguments ?? {}) as Map<String, dynamic>;

          String _s(key) => (a[key] ?? '').toString();
          int _i(key) => int.tryParse('${a[key]}') ?? 0;

          return MaterialPageRoute(
            builder: (_) => VentasRegistroSerialScreen(
              rif: _s('rif'),
              lineaId: _s('lineaId'),
              lineaName: _s('lineaName'),
              planIndex: _i('planIndex'),
              planTitle: _s('planTitle'),
              planDesc: _s('planDesc'),
              planPrice: _s('planPrice'),
              modeloSeleccionado: a['modeloSeleccionado'] as String?,
            ),
          );
        }
        return null; // el resto lo gestiona `routes: {}`
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
