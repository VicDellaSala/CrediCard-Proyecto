import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VentasEquiposScreen extends StatelessWidget {
  const VentasEquiposScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);
  static const _collection = 'almacen_pdv';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Encabezado
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.inventory_2, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modelos de equipos disponibles a la venta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

// Lista de modelos
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(_collection)
                    .orderBy('modelo', descending: false)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snap.error}'),
                    );
                  }

                  final docs = snap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay modelos cargados en el almacén.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      int cross = 1;
                      if (w >= 1200) {
                        cross = 3;
                      } else if (w >= 800) {
                        cross = 2;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final d = docs[i];
                          final id = d.id;
                          final data = d.data();

                          final nombre =
                          (data['modelo'] ?? '').toString().trim();
                          final descripcion =
                          (data['descripcion'] ?? '').toString().trim();
                          final caracteristicas =
                          (data['caracteristicas'] ?? '').toString().trim();
                          final precioAny = data['precio'];
                          final double? precio = switch (precioAny) {
                            int v => v.toDouble(),
                            double v => v,
                            String v => double.tryParse(v),
                            _ => null,
                          };

                          return _ModeloCard(
                            modeloId: id,
                            nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
                            descripcion: descripcion,
                            caracteristicas: caracteristicas,
                            precio: precio,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeloCard extends StatelessWidget {
  final String modeloId;
  final String nombre;
  final String descripcion;
  final String caracteristicas;
  final double? precio;

  const _ModeloCard({
    required this.modeloId,
    required this.nombre,
    required this.descripcion,
    required this.caracteristicas,
    required this.precio,
  });

  void _mostrarDialogo(BuildContext context, String titulo, String texto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: Text(texto),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD0E6E6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

// Descripción
          if (descripcion.isNotEmpty) ...[
            const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _mostrarDialogo(context, 'Descripción', descripcion),
                child: const Text('Ver más'),
              ),
            ),
          ],

// Características
          if (caracteristicas.isNotEmpty) ...[
            const Text('Características', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              caracteristicas,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _mostrarDialogo(context, 'Características', caracteristicas),
                child: const Text('Ver más'),
              ),
            ),
          ],

// Precio
          Row(
            children: [
              const Icon(Icons.sell_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                precio == null ? 'Precio: —' : 'Precio: \$${precio!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const Spacer(),
          const SizedBox(height: 12),

// Botón Seleccionar
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ElegirOperadoraPlaceholder(
                      modeloId: modeloId,
                      nombre: nombre,
                      precio: precio,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Seleccionar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElegirOperadoraPlaceholder extends StatelessWidget {
  final String modeloId;
  final String nombre;
  final double? precio;

  const _ElegirOperadoraPlaceholder({
    required this.modeloId,
    required this.nombre,
    required this.precio,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir operadora (placeholder)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aquí continuarás con la selección de operadora para:\n\n'
                'Modelo: $nombre\n'
                'ID: $modeloId\n'
                'Precio: ${precio == null ? '—' : '\$${precio!.toStringAsFixed(2)}'}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

