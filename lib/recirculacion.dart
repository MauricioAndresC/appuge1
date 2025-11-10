import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecirculacionActivity extends StatefulWidget {
  const RecirculacionActivity({super.key});

  @override
  _RecirculacionActivityState createState() => _RecirculacionActivityState();
}

class _RecirculacionActivityState extends State<RecirculacionActivity> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _caudalController = TextEditingController();
  final TextEditingController _presionDescargaBombaController =
      TextEditingController();
  final TextEditingController _eficienciaBombaController =
      TextEditingController();
  final TextEditingController _horasOperacionController =
      TextEditingController();
  final TextEditingController _costoKwhController = TextEditingController();

  String _resultText = '';

  double parseDouble(TextEditingController controller) {
    try {
      return double.parse(controller.text);
    } catch (e) {
      print('Error al parsear el valor: $e');
      return 0.0;
    }
  }

  double calcularPotenciaDisipacion(
    double caudal,
    double presionDescargaBomba,
    double eficienciaBomba,
  ) {
    return (caudal * presionDescargaBomba * 0.7 * 3.28) /
        (3960 * (eficienciaBomba / 100));
  }

  double calcularResultadoFinal(
    double potenciaDisipacion,
    double horasOperacion,
    double costoKwh,
  ) {
    return potenciaDisipacion * horasOperacion * costoKwh;
  }

  String formatFinalText(double resultadoFinal) {
    final formatter = NumberFormat('#,##0.00', 'es_CO');
    return 'El ahorro anual estimado es: ${formatter.format(resultadoFinal)} COP';
  }

  void calculate() {
    // Oculta el teclado
    FocusScope.of(context).unfocus();

    print('Calculando...');
    if (_formKey.currentState!.validate()) {
      double caudal = parseDouble(_caudalController);
      double presionDescargaBomba = parseDouble(
        _presionDescargaBombaController,
      );
      double eficienciaBomba = parseDouble(_eficienciaBombaController);
      double horasOperacion = parseDouble(_horasOperacionController);
      double costoKwh = parseDouble(_costoKwhController);

      double potenciaDisipacion = calcularPotenciaDisipacion(
        caudal,
        presionDescargaBomba,
        eficienciaBomba,
      );
      double resultadoFinal = calcularResultadoFinal(
        potenciaDisipacion,
        horasOperacion,
        costoKwh,
      );

      setState(() {
        _resultText = formatFinalText(resultadoFinal);
      });
    } else {
      setState(() {
        _resultText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recirculación de agua'),
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
                child: Image.asset(
                  'images/recirculacion.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16.0),
              _buildTextField(
                _caudalController,
                'Caudal (USgpm)',
                TextInputType.number,
              ),
              _buildTextField(
                _presionDescargaBombaController,
                'Presión descarga bomba P1 (PSI)',
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
              ElevatedButton(
                onPressed: calculate,
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
