import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FriccionActivity extends StatefulWidget {
  const FriccionActivity({super.key});

  @override
  _FriccionActivityState createState() => _FriccionActivityState();
}

class _FriccionActivityState extends State<FriccionActivity> {
  final _formKey = GlobalKey<FormState>();
  final _chartKey = GlobalKey();
  final _potenciaController = TextEditingController();
  final _horasController = TextEditingController();
  final _costoKwhController = TextEditingController();
  final _clienteController = TextEditingController();
  final _equipoController = TextEditingController();

  Uint8List? _equipoImageBytes;

  // Variable para el Slider de Porcentaje de Pérdida/Fricción
  double _porcentajeFriccion = 0.0; // Rango de 0 a 90

  // Variables de resultados
  double? _costoActualAnual;
  double? _costoFuturoAnual;
  double? _ahorroAnual;
  // Eliminado: _eficienciaActualSimulada
  double? _paybackAnios;
  double? _inversion;
  List<Map<String, double>> _tcoTable = [];

  // Constantes de Eficiencia base
  static const double eficienciaBase = 0.50; // 0% de fricción -> 0.50
  static const double eficienciaOptima =
      0.75; // Eficiencia después de la corrección

  // El decremento de eficiencia es 0.01 por cada 10% del slider (0.10 de valor del slider)
  // Total de decremento en 90% es 0.09 (0.50 - 0.41)
  static const double factorDecrementoPorcentaje = 0.01; // 0.01 por cada 10%

  // Datos para cálculo de inversión
  final Map<String, double> preciosBombas = {
    "0-5 Hp": 6500000 * 2.5,
    "5-10 Hp": 8800000 * 2.5,
    "10-15 Hp": 10600000 * 2.5,
    "15-20 Hp": 12500000 * 2.5,
    "20-30 Hp": 15320000 * 2.5,
    "30-40 Hp": 22750000 * 2.5,
    "40-50 Hp": 25000000 * 2.5,
    "50-75 Hp": 32000000 * 2.5,
  };
  final _fmt = NumberFormat('#,##0', 'es_CO');

  double _getCostoInversion(double hp) {
    if (hp <= 5) return preciosBombas["0-5 Hp"]!;
    if (hp <= 10) return preciosBombas["5-10 Hp"]!;
    if (hp <= 15) return preciosBombas["10-15 Hp"]!;
    if (hp <= 20) return preciosBombas["15-20 Hp"]!;
    if (hp <= 30) return preciosBombas["20-30 Hp"]!;
    if (hp <= 40) return preciosBombas["30-40 Hp"]!;
    if (hp <= 50) return preciosBombas["40-50 Hp"]!;
    return preciosBombas["50-75 Hp"]!;
  }

  // Lógica para calcular la eficiencia actual basada en el Slider
  double _calculateActualEfficiency() {
    // efActual = eficienciaBase - (porcentajeFriccion / 10) * 0.01
    final decremento = (_porcentajeFriccion / 10) * factorDecrementoPorcentaje;
    return eficienciaBase - decremento;
  }

  void _calculateAll() {
    if (!_formKey.currentState!.validate()) return;

    final hp = double.parse(_potenciaController.text.replaceAll(',', '.'));
    final horas = double.parse(_horasController.text.replaceAll(',', '.'));
    final costoKwh = double.parse(
      _costoKwhController.text.replaceAll(',', '.'),
    );

    // 1. Obtener eficiencia actual del Slider
    final efActual = _calculateActualEfficiency();

    // 2. Eficiencia futura (constante, asumiendo corrección de fricción/reemplazo de equipo)
    const double efNueva = eficienciaOptima; // 0.75

    final inversion = _getCostoInversion(hp);

    final potenciaMotorKw = hp * 0.746;
    final potenciaHidraulica = potenciaMotorKw * 0.9;

    final potenciaEntradaActual = potenciaHidraulica / efActual;
    final potenciaEntradaFuturo = potenciaHidraulica / efNueva;

    final costoActualAnual = potenciaEntradaActual * horas * costoKwh;
    final costoFuturoAnual = potenciaEntradaFuturo * horas * costoKwh;

    final ahorroAnual = costoActualAnual - costoFuturoAnual;
    final payback = ahorroAnual > 0 ? inversion / ahorroAnual : double.infinity;

    List<Map<String, double>> tabla = [];
    for (int year = 0; year <= 5; year++) {
      final tcoActual = costoActualAnual * year;
      final tcoNuevo = (costoFuturoAnual * year) + inversion;
      tabla.add({
        "anio": year.toDouble(),
        "tco_actual": tcoActual,
        "tco_nuevo": tcoNuevo,
      });
    }

    setState(() {
      _costoActualAnual = costoActualAnual;
      _costoFuturoAnual = costoFuturoAnual;
      _ahorroAnual = ahorroAnual;
      // Eliminado: _eficienciaActualSimulada = efActual;
      _paybackAnios = payback;
      _inversion = inversion;
      _tcoTable = tabla;
    });
  }

  Future<void> _pickImage() async {
    // Simulación de carga de imagen (mantenida del archivo original)
    try {
      final ByteData mockData = await rootBundle.load(
        'assets/images/logobyr.png',
      );
      setState(() {
        _equipoImageBytes = mockData.buffer.asUint8List();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen de equipo simulada/cargada correctamente.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al cargar la imagen simulada. Asegúrese de que "assets/images/logobyr.png" existe.',
            ),
          ),
        );
      }
      debugPrint("Error al simular la carga de imagen: $e");
    }
  }

  Future<void> _generatePdf() async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      if (_chartKey.currentContext == null) {
        debugPrint(
          "Error: Chart context is null. Make sure the chart is visible.",
        );
        return;
      }

      final ByteData logoData = await rootBundle.load(
        'assets/images/logobyr.png',
      );
      final Uint8List logoBytes = logoData.buffer.asUint8List();

      final boundary =
          _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image chartImage = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await chartImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List chartBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final now = DateFormat("dd/MM/yyyy").format(DateTime.now());

      final costoKwhTexto = _fmt.format(
        double.tryParse(_costoKwhController.text.replaceAll(',', '.')) ?? 0,
      );
      final horasOperacionTexto = _fmt.format(
        double.tryParse(_horasController.text.replaceAll(',', '.')) ?? 0,
      );
      final potenciaTexto = _fmt.format(
        double.tryParse(_potenciaController.text.replaceAll(',', '.')) ?? 0,
      );

      final dataTable = [
        {"label": "Cliente:", "value": _clienteController.text},
        {"label": "Equipo:", "value": _equipoController.text},
        {"label": "Potencia:", "value": "$potenciaTexto Hp"},
        {"label": "Costo Energía:", "value": "$costoKwhTexto COP/kWh"},
        {"label": "Horas de operación:", "value": "$horasOperacionTexto h/año"},
        {
          "label": "Porcentaje de cierre Valvula",
          "value": "${_porcentajeFriccion.toStringAsFixed(0)}%",
        },
        // Eliminado: "Eficiencia Actual:", "Eficiencia Futura:"
        {"label": "Fecha:", "value": now},
      ];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Propuesta de Ahorro de Bomba con Valvula Parcialmente cerrada",
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Image(pw.MemoryImage(logoBytes), width: 150, height: 50),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Tabla de datos del equipo y Foto del equipo
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Columna Izquierda: Datos del equipo y cliente
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: dataTable.map((data) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 1),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  data["label"]!,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                pw.SizedBox(width: 5),
                                pw.Expanded(
                                  child: pw.Text(
                                    data["value"]!,
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    pw.SizedBox(width: 20),

                    // Columna Derecha: Foto del Equipo
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            "Foto del equipo",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          if (_equipoImageBytes != null)
                            pw.Image(
                              pw.MemoryImage(_equipoImageBytes!),
                              height: 100,
                              fit: pw.BoxFit.contain,
                            )
                          else
                            pw.Container(
                              height: 100,
                              width: 150,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey300),
                                color: PdfColors.grey100,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  "Imagen no disponible",
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // FIN ENCABEZADO DE DATOS
                pw.Divider(),
                pw.SizedBox(height: 20),

                // Cuadros de Costo Actual y Costo Propuesto
                pw.Row(
                  children: [
                    _infoBox(
                      "Costo Actual",
                      "${_fmt.format(_costoActualAnual ?? 0)} COP/año",
                      PdfColors.red100,
                      PdfColors.red,
                    ),
                    pw.SizedBox(width: 10),
                    _infoBox(
                      "Costo Propuesto",
                      "${_fmt.format(_costoFuturoAnual ?? 0)} COP/año",
                      PdfColors.green100,
                      PdfColors.green,
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // TABLA DE RESULTADOS CLAVE
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Resultados Clave",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      // Solo resultados de la simulación
                      _kpiRow(
                        "Ahorro Anual",
                        "${_fmt.format(_ahorroAnual ?? 0)} COP",
                      ),
                      _kpiRow(
                        "Inversión Estimada",
                        "${_fmt.format(_inversion ?? 0)} COP",
                      ),
                      _kpiRow(
                        "Retorno de Inversión (Payback)",
                        _paybackAnios != null && _paybackAnios!.isFinite
                            ? "${_paybackAnios!.toStringAsFixed(2)} años"
                            : "N/A",
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 25),

                pw.Text(
                  "Gráfico retorno de inversión (5 años)",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                // Gráfico con tamaño reducido en un 25% (Antes 15%)
                pw.Center(
                  child: pw.SizedBox(
                    height: 150, // MODIFICADO: Altura ajustada
                    child: pw.Image(pw.MemoryImage(chartBytes)),
                  ),
                ),
                pw.SizedBox(height: 30),

                pw.Text(
                  "Nota:",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "Los resultados presentados corresponden a estimaciones basadas en el impacto de la fricción o restricciones en la eficiencia del bombeo. Se asume que la solución a este problema (p.ej., limpieza, cambio de tuberías) lleva a una eficiencia óptima. La inversión considerada es la del cambio de sistema de bombeo.",
                  style: pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      debugPrint("Error al generar PDF: $e");
    }
  }

  // --- Widgets Auxiliares del PDF (pw.Widget) ---

  pw.Widget _infoBox(
    String title,
    String value,
    PdfColor bg,
    PdfColor textColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _kpiRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- Widget de Gráfico (Flutter Widget) ---

  Widget _buildTcoChart() {
    if (_tcoTable.isEmpty) return const SizedBox.shrink();

    final spotsActual = _tcoTable
        .map((r) => FlSpot(r["anio"]!, r["tco_actual"]!))
        .toList();
    final spotsNuevo = _tcoTable
        .map((r) => FlSpot(r["anio"]!, r["tco_nuevo"]!))
        .toList();

    double maxVal = _tcoTable
        .map(
          (r) => r["tco_actual"]! > r["tco_nuevo"]!
              ? r["tco_actual"]!
              : r["tco_nuevo"]!,
        )
        .reduce((a, b) => a > b ? a : b);

    final maxY = (maxVal * 1.1);
    double interval = maxY / 5;

    String formatNumber(double value) {
      if (value >= 1e6) {
        return "${(value / 1e6).toStringAsFixed(0)} M";
      } else if (value >= 1e3) {
        return "${(value / 1e3).toStringAsFixed(0)} K";
      } else {
        return value.toStringAsFixed(0);
      }
    }

    return RepaintBoundary(
      key: _chartKey,
      child: SizedBox(
        height: 195, // MODIFICADO: Reducción total del 25% (260 * 0.75 = 195)
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 5,
            minY: 0,
            maxY: maxY,
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        formatNumber(value),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 38,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      "${value.toInt()}",
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            lineBarsData: [
              LineChartBarData(
                spots: spotsActual,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
              LineChartBarData(
                spots: spotsNuevo,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(y: 0, color: Colors.black54, strokeWidth: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Interfaz de Usuario (Flutter Widget) ---

  @override
  Widget build(BuildContext context) {
    // Calculamos la eficiencia actual para la lógica, pero no la mostramos directamente aquí.
    _calculateActualEfficiency();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Estudio perdidas por valvula parcialmente cerrada"),
        actions: [
          if (_costoActualAnual != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                _clienteController,
                "Nombre del cliente",
                isNumber: false,
              ),
              _buildTextField(
                _equipoController,
                "Nombre del equipo",
                isNumber: false,
              ),
              _buildTextField(_potenciaController, "Potencia bomba (HP)"),
              _buildTextField(_horasController, "Horas de operación al año"),
              _buildTextField(_costoKwhController, "Costo kWh (COP)"),

              const SizedBox(height: 12),

              // === SLIDER PARA SIMULAR LA PÉRDIDA POR FRICCIÓN ===
              _buildFriccionSlider(), // Ya no necesita pasar la eficiencia
              // ====================================================
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: Text(
                  _equipoImageBytes == null
                      ? "Cargar Foto del Equipo"
                      : "Cambiar Foto del Equipo",
                ),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _calculateAll,
                child: const Text("Calcular"),
              ),
              const SizedBox(height: 14),
              if (_costoActualAnual != null) ...[
                _buildResultsCard(), // Ya no necesita pasar la eficiencia
                const SizedBox(height: 14),
                _buildTcoChart(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET SLIDER
  Widget _buildFriccionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Porcentaje de valvula cerrada",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Porcentaje:", style: TextStyle(fontSize: 14)),
                  Text(
                    "${_porcentajeFriccion.toStringAsFixed(0)} %",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _porcentajeFriccion,
                min: 0,
                max: 90, // Límite máximo en 90%
                divisions: 9, // Para divisiones de 10% hasta 90%
                label: "${_porcentajeFriccion.toStringAsFixed(0)} %",
                onChanged: (double value) {
                  setState(() {
                    _porcentajeFriccion = value;
                  });
                },
              ),
              // Eliminado: Texto rojo de eficiencia actual simulada
            ],
          ),
        ),
      ],
    );
  }

  // TARJETA DE RESULTADOS DE LA UI DE FLUTTER
  Widget _buildResultsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resultados", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Eliminado: Eficiencia Actual Simulada y Eficiencia Futura
            const Divider(),
            _resultRow(
              "Costo anual actual",
              "${_fmt.format(_costoActualAnual ?? 0)} COP",
            ),
            _resultRow(
              "Costo anual optimizado",
              "${_fmt.format(_costoFuturoAnual ?? 0)} COP",
            ),
            _resultRow("Ahorro anual", "${_fmt.format(_ahorroAnual ?? 0)} COP"),
            const Divider(),
            _resultRow(
              "Inversión estimada",
              "${_fmt.format(_inversion ?? 0)} COP",
            ),
            _resultRow(
              "Payback",
              _paybackAnios != null && _paybackAnios!.isFinite
                  ? "${_paybackAnios!.toStringAsFixed(2)} años"
                  : "N/A",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool isNumber = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return "Ingrese un valor";
          if (isNumber) {
            if (double.tryParse(v.replaceAll(',', '.')) == null) {
              return "Número inválido";
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _resultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
