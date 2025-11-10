// ahorro2.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Ahorro2Screen extends StatefulWidget {
  const Ahorro2Screen({super.key});

  @override
  State<Ahorro2Screen> createState() => _Ahorro2ScreenState();
}

class _Ahorro2ScreenState extends State<Ahorro2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _chartKey = GlobalKey();

  // Datos generales
  final _clienteController = TextEditingController();
  final _equipoController = TextEditingController();

  // Entradas energéticas/económicas
  final _horasController = TextEditingController();
  final _costoKwhController = TextEditingController();

  // Entradas para eficiencia medida en campo
  final _caudalGpmController = TextEditingController(); // US gpm
  final _deltaPsiController = TextEditingController(); // PSI
  final _potElecKwController = TextEditingController(); // kW eléctricos medidos

  Uint8List? _equipoImageBytes;

  // Resultados
  double? _phidKw; // Potencia hidráulica (kW)
  double? _efActual; // Eficiencia actual (0-1)
  double? _hpSugerido; // Potencia de motor nuevo en HP
  String? _rangoHpSeleccionado; // Rango elegido para inversión
  double? _inversion; // COP
  double? _costoActualAnual; // COP/año
  double? _costoFuturoAnual; // COP/año
  double? _ahorroAnual; // COP/año
  double? _paybackAnios; // años

  List<Map<String, double>> _tcoTable = [];

  // Tabla de precios (HP -> costo COP por rango)
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

  // Eficiencia objetivo del nuevo sistema
  static const double _efNuevaObjetivo = 0.70; // 70%

  // Selecciona inversión según el HP requerido (elige el rango inmediato superior)
  double _getCostoInversionYGuardarRango(double hpNecesario) {
    String rango = "50-75 Hp"; // por defecto el mayor
    double costo = preciosBombas["50-75 Hp"]!;

    if (hpNecesario <= 5) {
      rango = "0-5 Hp";
      costo = preciosBombas[rango]!;
    } else if (hpNecesario <= 10) {
      rango = "5-10 Hp";
      costo = preciosBombas[rango]!;
    } else if (hpNecesario <= 15) {
      rango = "10-15 Hp";
      costo = preciosBombas[rango]!;
    } else if (hpNecesario <= 20) {
      rango = "15-20 Hp";
      costo = preciosBombas[rango]!;
    } else if (hpNecesario <= 30) {
      rango = "20-30 Hp";
      costo = preciosBombas[rango]!;
    } else if (hpNecesario <= 40) {
      rango = "30-40 Hp";
      costo = preciosBombas[rango]!;
    } else if (hpNecesario <= 50) {
      rango = "40-50 Hp";
      costo = preciosBombas[rango]!;
    } else {
      rango = "50-75 Hp";
      costo = preciosBombas[rango]!;
    }

    _rangoHpSeleccionado = rango;
    return costo;
  }

  // Cálculos principales
  void _calculateAll() {
    if (!_formKey.currentState!.validate()) return;

    // Lectura de entradas
    final double gpm = double.parse(
      _caudalGpmController.text.replaceAll(',', '.'),
    );
    final double dPsi = double.parse(
      _deltaPsiController.text.replaceAll(',', '.'),
    );
    final double pElecKw = double.parse(
      _potElecKwController.text.replaceAll(',', '.'),
    );
    final double horas = double.parse(
      _horasController.text.replaceAll(',', '.'),
    );
    final double costoKwh = double.parse(
      _costoKwhController.text.replaceAll(',', '.'),
    );

    // Potencia hidráulica:
    // HHP = Q(gpm) * ΔP(psi) / 1714
    // P_hid(kW) = HHP * 0.7457
    final double hhp = (gpm * dPsi) / 1714.0;
    final double pHidKw = hhp * 0.7457;

    // Eficiencia actual medida en campo
    // eta = P_hid / P_electrica
    final double efActual = (pElecKw > 0) ? (pHidKw / pElecKw) : 0.0;

    // Dimensionamiento del motor nuevo
    // P_motor_nuevo_kW = P_hid_kW / efNueva
    final double pMotorNuevoKw = pHidKw / _efNuevaObjetivo;

    // Conversión a HP
    final double hpSugerido = pMotorNuevoKw / 0.746;

    // Inversión por rango superior inmediato
    final double inversion = _getCostoInversionYGuardarRango(hpSugerido);

    // Costos anuales
    final double costoActualAnual = pElecKw * horas * costoKwh;
    final double costoFuturoAnual = pMotorNuevoKw * horas * costoKwh;

    final double ahorroAnual = (costoActualAnual - costoFuturoAnual).clamp(
      -double.infinity,
      double.infinity,
    );
    final double payback = (ahorroAnual > 0)
        ? inversion / ahorroAnual
        : double.infinity;

    // TCO 0..5 años
    final List<Map<String, double>> tabla = [];
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
      _phidKw = pHidKw;
      _efActual = efActual;
      _hpSugerido = hpSugerido;
      _inversion = inversion;
      _costoActualAnual = costoActualAnual;
      _costoFuturoAnual = costoFuturoAnual;
      _ahorroAnual = ahorroAnual;
      _paybackAnios = payback;
      _tcoTable = tabla;
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await showDialog<XFile?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: const Text(
            '¿Deseas tomar una foto o seleccionar de la galería?',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final photo = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (context.mounted) Navigator.pop(context, photo);
              },
              child: const Text('Cámara'),
            ),
            TextButton(
              onPressed: () async {
                final gallery = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (context.mounted) Navigator.pop(context, gallery);
              },
              child: const Text('Galería'),
            ),
          ],
        ),
      );

      if (pickedFile == null) {
        setState(() => _equipoImageBytes = null);
        return;
      }
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _equipoImageBytes = bytes;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen cargada correctamente.')),
        );
      }
    } catch (e) {
      debugPrint("Error al cargar imagen: $e");
      setState(() => _equipoImageBytes = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar la imagen. Se dejará en blanco.'),
          ),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      if (_chartKey.currentContext == null) {
        debugPrint("Error: Chart context is null.");
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

      // Textos de entrada formateados
      String _fmtNum(String s) {
        final v = double.tryParse(s.replaceAll(',', '.')) ?? 0;
        return _fmt.format(v);
      }

      final dataTable = [
        {"label": "Cliente:", "value": _clienteController.text},
        {"label": "Equipo:", "value": _equipoController.text},
        {
          "label": "Caudal:",
          "value": "${_fmtNum(_caudalGpmController.text)} USgpm",
        },
        {
          "label": "Presión:",
          "value": "${_fmtNum(_deltaPsiController.text)} PSI",
        },
        {
          "label": "Potencia eléctrica:",
          "value": "${_fmtNum(_potElecKwController.text)} kW",
        },
        {
          "label": "Costo Energía:",
          "value": "${_fmtNum(_costoKwhController.text)} COP/kWh",
        },
        {
          "label": "Horas de operación:",
          "value": "${_fmtNum(_horasController.text)} h/año",
        },
        {"label": "Fecha:", "value": now},
      ];

      final String eficienciaTxt = _efActual != null
          ? "${(_efActual!.clamp(0, 1) * 100).toStringAsFixed(1)} %"
          : "N/A";
      final String hpSugeridoTxt = _hpSugerido != null
          ? _hpSugerido!.toStringAsFixed(1)
          : "N/A";
      final String rangoTxt = _rangoHpSeleccionado ?? "N/A";

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
                      child: pw.Text(
                        "Propuesta de Ahorro Energético en Sistemas de Bombeo",
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                    pw.Image(pw.MemoryImage(logoBytes), width: 150, height: 50),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Tabla de datos + Imagen
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: dataTable.map((data) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 1),
                            child: pw.Row(
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

                pw.Divider(),
                pw.SizedBox(height: 12),

                // KPIs principales (Actual vs Propuesto)
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
                pw.SizedBox(height: 12),

                // Resultados clave
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
                      pw.SizedBox(height: 6),
                      _kpiRow("Eficiencia actual (medida)", eficienciaTxt),
                      _kpiRow(
                        "Potencia hidráulica",
                        _phidKw != null
                            ? "${_phidKw!.toStringAsFixed(2)} kW (hidráulicos)"
                            : "N/A",
                      ),
                      _kpiRow(
                        "Potencia sugerida (motor nuevo)",
                        _hpSugerido != null ? "$hpSugeridoTxt HP" : "N/A",
                      ),
                      _kpiRow("Rango de potencia sugerida", rangoTxt),
                      _kpiRow(
                        "Inversión estimada",
                        "${_fmt.format(_inversion ?? 0)} COP",
                      ),
                      _kpiRow(
                        "Ahorro Anual",
                        "${_fmt.format(_ahorroAnual ?? 0)} COP",
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

                pw.SizedBox(height: 16),

                // Texto explicativo antes del gráfico (según solicitud)
                pw.Text(
                  "Según los datos medidos se encontró una eficiencia de $eficienciaTxt. "
                  "Para el punto hidráulico analizado se proyecta alcanzar una eficiencia del 70% en el sistema propuesto.",
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.justify,
                ),

                pw.SizedBox(height: 18),

                pw.Text(
                  "Gráfico retorno de inversión (5 años)",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.Image(pw.MemoryImage(chartBytes), height: 200),

                pw.SizedBox(height: 18),
                pw.Divider(),

                // Nota final
                pw.Text(
                  "Los resultados presentados corresponden a estimaciones basadas en mediciones y valores típicos de eficiencia. "
                  "Se recomienda realizar un estudio detallado para determinar con exactitud los ahorros reales de los equipos. "
                  "La inversión considerada en este análisis corresponde únicamente al cambio del sistema de bombeo.",
                  textAlign: pw.TextAlign.justify,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
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

  // ==== Widgets auxiliares PDF ====

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

  // ==== UI ====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estudio ahorro energetico motobomba"),
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

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _caudalGpmController,
                      "Caudal (USgpm)",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(_deltaPsiController, "ΔP (PSI)"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextField(
                _potElecKwController,
                "Potencia eléctrica medida (kW)",
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _horasController,
                      "Horas de operación al año",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      _costoKwhController,
                      "Costo kWh (COP)",
                    ),
                  ),
                ],
              ),

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
                _buildResultsCard(),
                const SizedBox(height: 14),
                _buildTcoChart(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final String eficienciaTxt = _efActual != null
        ? "${(_efActual!.clamp(0, 1) * 100).toStringAsFixed(1)} %"
        : "N/A";

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resultados", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _resultRow(
              "Potencia hidráulica",
              _phidKw != null
                  ? "${_phidKw!.toStringAsFixed(2)} kW (hidráulicos)"
                  : "N/A",
            ),
            _resultRow("Eficiencia actual (medida)", eficienciaTxt),
            _resultRow(
              "Potencia sugerida (motor nuevo)",
              _hpSugerido != null
                  ? "${_hpSugerido!.toStringAsFixed(1)} HP"
                  : "N/A",
            ),
            _resultRow(
              "Rango de potencia sugerida",
              _rangoHpSeleccionado ?? "N/A",
            ),
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
      if (value >= 1e6) return "${(value / 1e6).toStringAsFixed(0)} M";
      if (value >= 1e3) return "${(value / 1e3).toStringAsFixed(0)} K";
      return value.toStringAsFixed(0);
    }

    return RepaintBoundary(
      key: _chartKey,
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 5,
            minY: 0,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      formatNumber(value),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  reservedSize: 38,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) => Text(
                    "${value.toInt()}",
                    style: const TextStyle(fontSize: 10),
                  ),
                  reservedSize: 30,
                ),
              ),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            lineBarsData: [
              LineChartBarData(
                spots: spotsActual,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
              ),
              LineChartBarData(
                spots: spotsNuevo,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
              ),
            ],
          ),
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
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null) return "Número inválido";
            if (label.contains("kW") ||
                label.contains("Horas") ||
                label.contains("COP") ||
                label.contains("USgpm") ||
                label.contains("PSI")) {
              if (val < 0) return "Ingrese un valor no negativo";
            }
            if (label.contains("Horas") && val == 0)
              return "Las horas deben ser > 0";
            if (label.contains("Potencia eléctrica") && val == 0)
              return "La potencia eléctrica debe ser > 0";
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
