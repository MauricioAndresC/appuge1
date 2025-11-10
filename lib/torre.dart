import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TorreActivity extends StatefulWidget {
  const TorreActivity({super.key});

  @override
  _TorreActivityState createState() => _TorreActivityState();
}

class _TorreActivityState extends State<TorreActivity> {
  final _formKey = GlobalKey<FormState>();
  final _capacidadController = TextEditingController();
  final _tempEntradaController = TextEditingController();
  final _tempSalidaController = TextEditingController();
  final _presionDescargaController = TextEditingController();
  final _eficienciaActualController = TextEditingController();
  final _nuevaEficienciaController = TextEditingController();
  final _horasOperacionController = TextEditingController();
  final _costoKwhController = TextEditingController();
  final _deltaTempController = TextEditingController();
  String _resultText = '';
  String _tipoCapacidad = 'TR';

  void _calculate() {
    // Oculta el teclado
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      try {
        double capacidad = parseDouble(_capacidadController);
        double tempEntrada = parseDouble(_tempEntradaController);
        double tempSalida = parseDouble(_tempSalidaController);
        double presionDescarga = parseDouble(_presionDescargaController);
        double eficienciaActual = parseDouble(_eficienciaActualController);
        double nuevaEficiencia = parseDouble(_nuevaEficienciaController);
        double horasOperacion = parseDouble(_horasOperacionController);
        double costoKwh = parseDouble(_costoKwhController);
        double deltaTemp = parseDouble(_deltaTempController);

        double caudalTorre;
        if (_tipoCapacidad == 'TR') {
          double tr = capacidad;
          caudalTorre = (tr * 12000) / (500 * deltaTemp);
        } else {
          caudalTorre = capacidad;
        }

        double potenciaActual =
            (((caudalTorre / 4.4) * (presionDescarga * 0.704)) / 367) /
            (eficienciaActual / 100);

        double delta2 =
            (((tempEntrada * 9 / 5) + 32) - ((tempSalida * 9 / 5) + 32));

        double trActuales = (caudalTorre * 500 * delta2) / 12000;

        double nuevoCaudal = (trActuales * 12000) / (500 * deltaTemp);

        double nuevaPotencia =
            (((nuevoCaudal / 4.4) * (presionDescarga * 0.704)) / 367) /
            (nuevaEficiencia / 100);

        double potenciaAhorro = potenciaActual - nuevaPotencia;

        double resultadoFinal = potenciaAhorro * horasOperacion * costoKwh;

        String resultadoFinalFormateado = NumberFormat(
          '#,##0.00',
          'es_CO',
        ).format(resultadoFinal);

        setState(() {
          _resultText =
              "El ahorro anual estimado es: $resultadoFinalFormateado COP";
        });
      } catch (e) {
        print('Error durante el cálculo: $e');
        setState(() {
          _resultText = 'Error en los datos proporcionados';
        });
      }
    }
  }

  double parseDouble(TextEditingController controller) {
    try {
      return double.parse(controller.text);
    } catch (e) {
      print('Error al parsear el valor: $e');
      return 0.0; // o manejar el error según corresponda
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torre de Enfriamiento'),
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
                child: Image.asset('images/torre.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                initialValue: _tipoCapacidad,
                items: const [
                  DropdownMenuItem(
                    value: 'TR',
                    child: Text('Capacidad de la torre (TR)'),
                  ),
                  DropdownMenuItem(value: 'GPM', child: Text('Caudal (gpm)')),
                ],
                onChanged: (value) {
                  print('Tipo de capacidad seleccionado: $value');
                  setState(() {
                    _tipoCapacidad = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo de Capacidad',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 12.0,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              _buildTextField(
                _capacidadController,
                _tipoCapacidad == 'TR'
                    ? 'Capacidad de la torre (TR)'
                    : 'Caudal (gpm)',
                TextInputType.number,
              ),
              _buildTextField(
                _tempEntradaController,
                'Temperatura de entrada (°C)',
                TextInputType.number,
              ),
              _buildTextField(
                _tempSalidaController,
                'Temperatura de salida (°C)',
                TextInputType.number,
              ),
              _buildTextField(
                _presionDescargaController,
                'Presión de descarga de la bomba (PSI)',
                TextInputType.number,
              ),
              _buildTextField(
                _eficienciaActualController,
                'Eficiencia actual de la bomba (%)',
                TextInputType.number,
              ),
              _buildTextField(
                _nuevaEficienciaController,
                'Nueva eficiencia de la bomba (%)',
                TextInputType.number,
              ),
              _buildTextField(
                _horasOperacionController,
                'Horas de operación al año',
                TextInputType.number,
              ),
              _buildTextField(
                _costoKwhController,
                'Costo Kw-h',
                TextInputType.number,
              ),
              _buildTextField(
                _deltaTempController,
                'Delta de placa de torre (°F)',
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
