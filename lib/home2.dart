import 'package:flutter/material.dart';
import 'ahorro.dart'; // Importa la pantalla de Estimación
import 'ahorro2.dart'; // Importa la pantalla de Datos Conocidos

class Home2 extends StatelessWidget {
  const Home2({super.key});

  final Color mainColor = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Motobombas Ineficientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botón para la opción de Estimación
              _buildOptionButton(
                context,
                title: "Motobombas Ineficientes (Estimación)",
                icon: Icons.lightbulb_outline,
                page: const AhorroScreen(),
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              // Botón para la opción de Datos Conocidos
              _buildOptionButton(
                context,
                title: "Motobombas Ineficientes (Datos Conocidos)",
                icon: Icons.fact_check_outlined,
                page: const Ahorro2Screen(),
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget page,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
    );
  }
}
