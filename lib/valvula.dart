import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ValvulaActivity extends StatefulWidget {
  const ValvulaActivity({super.key});

  @override
  _ValvulaActivityState createState() => _ValvulaActivityState();
}

class _ValvulaActivityState extends State<ValvulaActivity> {
  final _formKey = GlobalKey<FormState>();
  final _caudalController = TextEditingController();
  final _presionP1Controller = TextEditingController();
  final _presionP2Controller = TextEditingController();
  final _eficienciaBombaController = TextEditingController();
  final _horasOperacionController = TextEditingController();
  final _costoKwhController = TextEditingController();
  String _resultText = '';

  void _calculate() {
    // Oculta el teclado
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      try {
        // Obtener los valores del formulario
        double caudal = double.parse(_caudalController.text);
        double presionP1 = double.parse(_presionP1Controller.text);
        double presionP2 = double.parse(_presionP2Controller.text);
        double eficienciaBomba = double.parse(_eficienciaBombaController.text);
        double horasOperacion = double.parse(_horasOperacionController.text);
        double costoKwh = double.parse(_costoKwhController.text);

        // Imprimir valores para depuración
        print('Caudal: $caudal');
        print('Presión P1: $presionP1');
        print('Presión P2: $presionP2');
        print('Eficiencia Bomba: $eficienciaBomba');
        print('Horas Operación: $horasOperacion');
        print('Costo KWh: $costoKwh');

        // Realizar los cálculos
        double potenciaDisipacion = calcularPotenciaDisipacion(
          caudal,
          presionP1,
          presionP2,
          eficienciaBomba,
        );
        double resultadoFinal = calcularResultadoFinal(
          potenciaDisipacion,
          horasOperacion,
          costoKwh,
        );

        // Formatear el resultado
        String resultadoFinalFormateado = NumberFormat(
          '#,##0.00',
          'es_CO',
        ).format(resultadoFinal);

        // Actualizar el estado con el resultado
        setState(() {
          _resultText =
              "El ahorro anual estimado es: $resultadoFinalFormateado COP";
        });
      } catch (e) {
        print("Error: $e");
        setState(() {
          _resultText =
              "Hubo un error al calcular. Verifique los valores ingresados.";
        });
      }
    }
  }

  double calcularPotenciaDisipacion(
    double caudal,
    double presionP1,
    double presionP2,
    double eficienciaBomba,
  ) {
    return (caudal * (presionP1 - presionP2) * 0.7 * 3.28) /
        (3960 * (eficienciaBomba / 100));
  }

  double calcularResultadoFinal(
    double potenciaDisipacion,
    double horasOperacion,
    double costoKwh,
  ) {
    return potenciaDisipacion * horasOperacion * costoKwh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Válvula Parcialmente Cerrada'),
        backgroundColor: const Color.fromARGB(255, 113, 177, 230),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Imagen en el encabezado
              SizedBox(
                width: double.infinity,
                child: Image.asset('images/valvula.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 16.0),
              _buildTextField(
                _caudalController,
                'Caudal (USgpm)',
                TextInputType.number,
              ),
              _buildTextField(
                _presionP1Controller,
                'Presión antes de la válvula P1 (PSI)',
                TextInputType.number,
              ),
              _buildTextField(
                _presionP2Controller,
                'Presión después de la válvula P2 (PSI)',
                TextInputType.number,
              ),
              _buildTextField(
                _eficienciaBombaController,
                'Eficiencia de la bomba (%)',
                TextInputType.number,
              ),
              _buildTextField(
                _horasOperacionController,
                'Horas de operación',
                TextInputType.number,
              ),
              _buildTextField(
                _costoKwhController,
                'Costo Kw-h',
                TextInputType.number,
              ),
              const SizedBox(height: 20.0),
              Center(
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 54, 244, 139),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 32.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Calcular',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                _resultText,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType inputType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 12.0,
          ),
          labelStyle: const TextStyle(fontSize: 16.0),
        ),
        keyboardType: inputType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, complete este campo';
          }
          return null;
        },
      ),
    );
  }
}
