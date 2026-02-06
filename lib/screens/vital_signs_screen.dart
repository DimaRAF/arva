import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:arva/ml/scaler_lite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pateint_home.dart';

class VitalSignsScreen extends StatefulWidget {
  final String patientId;
  const VitalSignsScreen({super.key, required this.patientId});

  @override
  State<VitalSignsScreen> createState() => _VitalSignsScreenState();
}

class _VitalSignsScreenState extends State<VitalSignsScreen> {
  String _patientName = "Unknown Patient";
  String _roomNumber = '--';
  final Map<String, int> _lastAlertReadingCount = {};
  final Map<String, int> _criticalCount = {
    'HR': 0,
    'Temp': 0,
    'SaO2': 0,
    'BP': 0,
  };

  final Map<String, DateTime> _lastAlertTime = {};

  final Map<String, List<Map<String, dynamic>>> _patientDataCache = {};

  Interpreter? _interpreter;

  bool _isLoading = true;

  MinMaxScalerLite? _scaler;
  final List<String> _featuresOrder = ['HR', 'Temp', 'SaO2', 'NISysABP', 'NIDiasABP'];

  final List<Map<String, dynamic>> _patientSpecificDataset = [];
  final List<Map<String, dynamic>> _historyForChart = [];
  Map<String, dynamic> _currentVitals = {};
  Map<String, dynamic>? _predictedVitals;

  final int _bottomNavIndex = 1;

 
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    // Await an asynchronous operation.
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Branch on a condition that affects logic flow.
        if (response.payload != null && context.mounted) {
          try {
            final data = jsonDecode(response.payload!);
            final patientId = data['patientId'];
            final patientName = data['patientName'];

            // Navigate to another screen based on user action.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => VitalSignsScreen(patientId: patientId),
              ),
              (route) => route.isFirst,
            );
          } catch (e) {
            print("❌ Failed to decode notification payload: $e");
          }
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadChartHistory();
    
    _loadDataAndConfigureService();

   
    FlutterBackgroundService().on('update').listen((data) {
     
      // Branch on a condition that affects logic flow.
      if (mounted && data != null && data['patientId'] == widget.patientId) {
        setState(() {
          final receivedVitals = Map<String, dynamic>.from(data['vitals']);
          // Branch on a condition that affects logic flow.
          if (receivedVitals['time'] is String) {
            receivedVitals['time'] = DateTime.parse(receivedVitals['time'] as String);
          }
          _currentVitals = receivedVitals;
          _historyForChart.add(_currentVitals);
          // Branch on a condition that affects logic flow.
          if (_historyForChart.length > 288) _historyForChart.removeAt(0);
        });

        _saveChartHistory();
        _checkVitalsAndNotify(_currentVitals, isPredicted: false);

        _runPrediction();
      }
    });
  }

  Future<void> _loadScaler() async {
    // Await an asynchronous operation.
    _scaler = await loadScalerFromAssets('assets/vitals_scaler_params.json');
    
    // Branch on a condition that affects logic flow.
    if (_scaler!.featuresOrder.join(',') != _featuresOrder.join(',')) {
      print('⚠️ features_order in JSON != _featuresOrder in app');
    }
    print('✅ Scaler loaded');
  }

  Future<void> _loadModel() async {
    try {
      print('🔄 Loading model from assets...');

      // Await an asynchronous operation.
      final interpreter = await Interpreter.fromAsset('assets/vitals_predictor_gru.tflite');
      // Branch on a condition that affects logic flow.
      if (mounted) {
        setState(() => _interpreter = interpreter);
      }
      print('✅ TensorFlow Lite model loaded successfully.');
    } catch (e) {
      print('❌ Failed to load TensorFlow Lite model: $e');
    }
  }

  void _runPrediction() {
    // Branch on a condition that affects logic flow.
    if (_interpreter == null) {
      print("Prediction skipped: Interpreter is null.");
      return;
    }
    // Branch on a condition that affects logic flow.
    if (_scaler == null) {
      print("Prediction skipped: Scaler is null.");
      return;
    }
    // Branch on a condition that affects logic flow.
    if (_historyForChart.length < 10) {
      print("Prediction skipped: Not enough history data (${_historyForChart.length}/10).");
      return;
    }

    const int sequenceLength = 10;
    final recentHistory = _historyForChart.sublist(_historyForChart.length - sequenceLength);

    final List<List<double>> seqNorm = [];
    // Loop over a collection to apply logic.
    for (int i = 0; i < sequenceLength; i++) {
      final r = recentHistory[i];

      final rawVec = [
        double.tryParse(r['HR']?.toString() ?? '0') ?? 0.0,
        double.tryParse(r['Temp']?.toString() ?? '0') ?? 0.0,
        double.tryParse(r['SaO2']?.toString() ?? '0') ?? 0.0,
        double.tryParse(r['NISysABP']?.toString() ?? '0') ?? 0.0,
        double.tryParse(r['NIDiasABP']?.toString() ?? '0') ?? 0.0,
      ];

      final normVec = _scaler!.normalizeVector(rawVec);
      seqNorm.add(normVec);
    }

    final input = [seqNorm];

    final List<List<double>> output = [
      List<double>.filled(5, 0.0),
    ];

    try {
      _interpreter!.run(input, output);

      final denorm = _scaler!.denormalizeVector(output[0]);

      setState(() {
        _predictedVitals = {
          'HR': denorm[0],
          'Temp': denorm[1],
          'SaO2': denorm[2],
          'NISysABP': denorm[3],
          'NIDiasABP': denorm[4],
        };
      });
      _saveChartHistory();

      print('>>> PREDICTION (denormalized): $_predictedVitals');
      _checkVitalsAndNotify(_predictedVitals!, isPredicted: true);
    } catch (e) {
      print("!!! ERROR running model prediction: $e");
    }
  }

  LineChartBarData _buildPredictionLine({
    required String vitalKey,
    required Color color,
  }) {
    print('--- Checking prediction line for: $vitalKey');

    // Branch on a condition that affects logic flow.
    if (_historyForChart.isEmpty) {
      print('--- [$vitalKey] Skipped: History is empty.');
      return LineChartBarData(show: false);
    }
    // Branch on a condition that affects logic flow.
    if (_predictedVitals == null) {
      print('--- [$vitalKey] Skipped: _predictedVitals is null.');
      return LineChartBarData(show: false);
    }

    final lastHistoryIndex = _historyForChart.length - 1;
    final lastHistoryValue = _historyForChart.last[vitalKey];
    final predictedValue = _predictedVitals![vitalKey];

    print('--- [$vitalKey] Last History Value: $lastHistoryValue | Predicted Value: $predictedValue');

    // Branch on a condition that affects logic flow.
    if (lastHistoryValue is! num || predictedValue is! num) {
      print('--- [$vitalKey] Skipped: One of the values is not a valid number.');
      return LineChartBarData(show: false);
    }

    return LineChartBarData(
      spots: [
        FlSpot(lastHistoryIndex.toDouble(), lastHistoryValue.toDouble()),
        FlSpot((lastHistoryIndex + 1).toDouble(), predictedValue.toDouble()),
      ],
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: true),
      dashArray: [5, 5],
    );
  }

  Future<void> _loadDataAndConfigureService() async {
    // Await an asynchronous operation.
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('vitals_${widget.patientId}');
    // Branch on a condition that affects logic flow.
    if (data != null) {
      _currentVitals = jsonDecode(data);
      print('♻️ Loaded cached vitals for ${widget.patientId}');
    }

    // Await an asynchronous operation.
    await _loadScaler();

    
    // Await an asynchronous operation.
    await _loadModel();

    
    // Branch on a condition that affects logic flow.
    if (_interpreter == null) {
      print('⚠️ Interpreter not ready, skipping simulation start.');
      return;
    }

    
    // Await an asynchronous operation.
    await _loadDataForPatient();

   
    // Branch on a condition that affects logic flow.
    if (_patientSpecificDataset.isNotEmpty) {
      FlutterBackgroundService().invoke('startPatientSimulation', {
        'patientId': widget.patientId,
        'patientName': _patientName,
        'dataset': _patientSpecificDataset.map((record) {
          return {
            ...record,
            'time': (record['time'] as DateTime).toIso8601String(),
          };
        }).toList(),
        'startIndex': 0,
      });
    }

    // Branch on a condition that affects logic flow.
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveChartHistory() async {
    // Await an asynchronous operation.
    final prefs = await SharedPreferences.getInstance();
    final encodedHistory = jsonEncode(_historyForChart.map((e) {
      final map = Map<String, dynamic>.from(e);
      // Branch on a condition that affects logic flow.
      if (map['time'] is DateTime) {
        map['time'] = (map['time'] as DateTime).toIso8601String();
      }
      return map;
    }).toList());

    prefs.setString('chart_history_${widget.patientId}', encodedHistory);
  }

  Future<void> _loadChartHistory() async {
    // Await an asynchronous operation.
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chart_history_${widget.patientId}');
    // Branch on a condition that affects logic flow.
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      _historyForChart.clear();
      _historyForChart.addAll(decoded.map((e) {
        final map = Map<String, dynamic>.from(e);
        // Branch on a condition that affects logic flow.
        if (map['time'] is String) {
          map['time'] = DateTime.parse(map['time']);
        }
        return map;
      }));
    }
  }

  void _checkVitalsAndNotify(Map<String, dynamic> vitals, {bool isPredicted = false}) {
    final hr = (vitals['HR'] as num?)?.toDouble() ?? 0;
    final temp = (vitals['Temp'] as num?)?.toDouble() ?? 0;
    final spo2 = (vitals['SaO2'] as num?)?.toDouble() ?? 0;
    final sys = (vitals['NISysABP'] as num?)?.toDouble() ?? 0;
    final dia = (vitals['NIDiasABP'] as num?)?.toDouble() ?? 0;

    // Branch on a condition that affects logic flow.
    if (hr > 110 || hr < 50) {
      _criticalCount['HR'] = (_criticalCount['HR'] ?? 0) + 1;
    } else {
      _criticalCount['HR'] = 0;
    }

    // Branch on a condition that affects logic flow.
    if (temp > 38 || temp < 35.5) {
      _criticalCount['Temp'] = (_criticalCount['Temp'] ?? 0) + 1;
    } else {
      _criticalCount['Temp'] = 0;
    }

    // Branch on a condition that affects logic flow.
    if (spo2 < 93) {
      _criticalCount['SaO2'] = (_criticalCount['SaO2'] ?? 0) + 1;
    } else {
      _criticalCount['SaO2'] = 0;
    }

    // Branch on a condition that affects logic flow.
    if (sys > 140 || dia > 90 || sys < 90 || dia < 60) {
      _criticalCount['BP'] = (_criticalCount['BP'] ?? 0) + 1;
    } else {
      _criticalCount['BP'] = 0;
    }

    
    _criticalCount.forEach((key, count) {
      // Branch on a condition that affects logic flow.
      if (count >= 5) {
        final lastAlert = _lastAlertTime[key];
        final lastAlertCount = _lastAlertReadingCount[key] ?? 0;
        final now = DateTime.now();

        
        // Branch on a condition that affects logic flow.
        if (lastAlert == null ||
            now.difference(lastAlert).inMinutes >= 5 ||
            (_criticalCount[key]! - lastAlertCount) >= 10) {
          _showAlertNotification("${_getVitalDisplayName(key)} for $_patientName");
          _lastAlertTime[key] = now;
          _lastAlertReadingCount[key] = _criticalCount[key]!;
        }

        _criticalCount[key] = 0; 
      }
    });

    
    // Branch on a condition that affects logic flow.
    if (!isPredicted && sys > 0) {
      _updateSystolicLastValue(sys);
    }
  }

  
  Future<void> _updateSystolicLastValue(double systolic) async {
    try {
      final medsRef = FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(widget.patientId)
          .collection('medications');

      // Await an asynchronous operation.
      final query = await medsRef.where('test_name', isEqualTo: 'Systolic BP').get();

      // Branch on a condition that affects logic flow.
      if (query.docs.isEmpty) {
        print('ℹ لا توجد أدوية مرتبطة بـ Systolic BP لهذا المريض');
        return;
      }

      // Loop over a collection to apply logic.
      for (final doc in query.docs) {
        // Await an asynchronous operation.
        await doc.reference.update({
          'last_value': systolic,
          'last_updated': FieldValue.serverTimestamp(),
        });
      }

      print('💾 تم تحديث last_value لـ Systolic BP = $systolic في ${query.docs.length} دواء/أدوية');
    } catch (e) {
      print('❌ فشل تحديث last_value لـ Systolic BP: $e');
    }
  }

  String _getVitalDisplayName(String key) {
    // Select logic based on a key value.
    switch (key) {
      case 'HR':
        return "Heart Rate";
      case 'Temp':
        return "Temperature";
      case 'SaO2':
        return "Oxygen Level (SaO2)";
      case 'BP':
        return "Blood Pressure";
      default:
        return key;
    }
  }

  Future<void> _showAlertNotification(String vitalName, {bool isPredicted = false}) async {
    final typeLabel = isPredicted ? "🧠 Predicted Data" : "📡 Real-Time Data";
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'vital_alerts',
      'Vital Alerts',
      channelDescription: 'Alerts for abnormal vital signs',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFD32F2F),
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Await an asynchronous operation.
    await _notificationsPlugin.show(
      0,
      '⚠️ Critical Alert - $_patientName',
      '$typeLabel → Abnormal $vitalName detected for $_patientName!',
      notificationDetails,
      payload: jsonEncode({
        'patientId': widget.patientId,
        'patientName': _patientName,
      }),
    );
  }



  Map<String, dynamic> getVitalStatus(String vitalKey, double? value) {
    // Branch on a condition that affects logic flow.
    if (value == null) return {'text': 'N/A', 'color': Colors.grey};

    // Select logic based on a key value.
    switch (vitalKey) {
      case 'HR': // Heart Rate
        // Branch on a condition that affects logic flow.
        if (value > 100) return {'text': 'High', 'color': Colors.red};
        // Branch on a condition that affects logic flow.
        if (value < 60) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
        return {'text': 'Normal', 'color': Colors.green};
      case 'Temp':
        // Branch on a condition that affects logic flow.
        if (value > 37.5) return {'text': 'High', 'color': Colors.red};
        // Branch on a condition that affects logic flow.
        if (value < 36.1) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
        return {'text': 'Normal', 'color': Colors.green};
      case 'SaO2': 
        // Branch on a condition that affects logic flow.
        if (value < 95) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
        return {'text': 'Normal', 'color': Colors.green};
      default:
        return {'text': 'Normal', 'color': Colors.green};
    }
  }

  
  Map<String, dynamic> getBloodPressureStatus(double? systolic, double? diastolic) {
    // Branch on a condition that affects logic flow.
    if (systolic == null || diastolic == null) {
      return {'text': 'N/A', 'color': Colors.grey};
    }
    
    // Branch on a condition that affects logic flow.
    if (systolic > 130 || diastolic > 85) return {'text': 'High', 'color': Colors.red};
   
    // Branch on a condition that affects logic flow.
    if (systolic < 90 || diastolic < 60) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
    return {'text': 'Normal', 'color': Colors.green};
  }

  Future<void> _loadDataForPatient() async {
    try {
      // Branch on a condition that affects logic flow.
      if (_patientDataCache.containsKey(widget.patientId)) {
        print("♻️ Loaded ${widget.patientId} data from cache");
        _patientSpecificDataset
          ..clear()
          ..addAll(_patientDataCache[widget.patientId]!);
        return;
      }

      // Await an asynchronous operation.
      final profileDoc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(widget.patientId)
          .get();

     
      // Branch on a condition that affects logic flow.
      if (!profileDoc.exists || profileDoc.data() == null) {
        print("Error: Patient document not found for ID: ${widget.patientId}");
        _patientName = 'Patient Not Found';
        _roomNumber = '--';
        return;
      }

      
      final data = profileDoc.data()!;
   
      _patientName = data['username'] as String? ?? 'Unnamed Patient';
      _roomNumber = data['roomNumber']?.toString() ?? '--';

     
      // Branch on a condition that affects logic flow.
      if (data['dataFilename'] == null) {
        print("Error: This patient has no assigned data file (dataFilename).");
        _patientSpecificDataset.clear();
        return;
      }
      final String filename = data['dataFilename'];

      
      // Await an asynchronous operation.
      final txtData = await rootBundle.loadString('assets/patient_vitals/$filename');
      List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter(eol: '\n').convert(txtData);

      final headers = rowsAsListOfValues[0].map((e) => e.toString().trim()).toList();
      rowsAsListOfValues.removeAt(0);

      
      _patientSpecificDataset.clear();
      DateTime lastDate = DateTime.now().subtract(const Duration(days: 1));

      // Loop over a collection to apply logic.
      for (int i = 0; i < rowsAsListOfValues.length; i++) {
        final row = rowsAsListOfValues[i];
        Map<String, dynamic> rowData = {};
        // Loop over a collection to apply logic.
        for (int j = 0; j < headers.length; j++) {
          // Branch on a condition that affects logic flow.
          if (headers[j] == 'Time') {
            try {
              final timeParts = row[j].toString().split(':');
              final hours = int.parse(timeParts[0]);
              final minutes = int.parse(timeParts[1]);
              // Branch on a condition that affects logic flow.
              if (i > 0 &&
                  _patientSpecificDataset.isNotEmpty &&
                  hours < (_patientSpecificDataset.last['time'] as DateTime).hour) {
                lastDate = lastDate.add(const Duration(days: 1));
              }
              rowData['time'] =
                  DateTime(lastDate.year, lastDate.month, lastDate.day, hours, minutes);
            } catch (e) {
              rowData['time'] = lastDate.add(Duration(minutes: i * 5));
            }
          } else {
            rowData[headers[j]] = double.tryParse(row[j].toString()) ?? 0.0;
          }
        }
        _patientSpecificDataset.add(rowData);
      }

      print("Successfully loaded ${_patientSpecificDataset.length} records for $_patientName.");

     
      _patientDataCache[widget.patientId] = List.from(_patientSpecificDataset);
    } catch (e) {
      print("Error loading or processing patient data file: $e");
      _patientName = 'Error Loading Data';
      _roomNumber = 'X';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLiveVitalsSection(),
                  const SizedBox(height: 24),
                  _buildUnifiedActivityChartCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildLiveVitalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildHeartRateCard(_currentVitals['HR']?.toInt() ?? 0),
        const SizedBox(height: 16),
        _buildVitalsGrid(_currentVitals),
        const SizedBox(height: 16),
        _buildPatientInfoCard(),
      ],
    );
  }

  Widget _buildUnifiedActivityChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 350,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Vital Signs - Last 24 Hours",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 1.0),
              child: LineChart(
                LineChartData(
                  clipData: FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        const FlLine(color: Colors.black12, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: _bottomTitles),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 50)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: (_historyForChart.length > 10
                          ? _historyForChart.length - 10
                          : 0)
                      .toDouble(),
                  maxX: (_historyForChart.length - 1).toDouble() + 2,
                  lineBarsData: [
                    _buildPredictionLine(
                        vitalKey: 'HR',
                        color: const Color.fromARGB(255, 240, 139, 132)),
                    _buildLine(
                        vitalKey: 'HR',
                        color: const Color.fromARGB(255, 250, 19, 2)),
                    _buildPredictionLine(
                        vitalKey: 'Temp',
                        color: const Color.fromARGB(255, 248, 202, 132)),
                    _buildLine(vitalKey: 'Temp', color: Colors.orange),
                    _buildPredictionLine(
                        vitalKey: 'SaO2',
                        color: const Color.fromARGB(255, 131, 193, 243)),
                    _buildLine(
                        vitalKey: 'SaO2',
                        color: const Color.fromARGB(255, 0, 137, 250)),
                    _buildPredictionLine(
                        vitalKey: 'NISysABP',
                        color: const Color.fromARGB(255, 201, 145, 211)),
                    _buildLine(
                        vitalKey: 'NISysABP',
                        color: const Color.fromARGB(255, 149, 2, 175)),
                    _buildPredictionLine(
                        vitalKey: 'NIDiasABP',
                        color: const Color.fromARGB(255, 115, 189, 181)),
                    _buildLine(vitalKey: 'NIDiasABP', color: Colors.teal),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(color: Colors.red, text: 'HR'),
              _LegendItem(color: Colors.orange, text: 'Temp'),
              _LegendItem(color: Colors.blue, text: 'SaO2'),
              _LegendItem(color: Colors.purple, text: 'SysBP'),
              _LegendItem(color: Colors.teal, text: 'DiasBP'),
            ],
          )
        ],
      ),
    );
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: 50,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          // Branch on a condition that affects logic flow.
          if (index >= 0 && index < _historyForChart.length) {
            final time = _historyForChart[index]['time'] as DateTime?;
            // Branch on a condition that affects logic flow.
            if (time != null) {
              final timeStr =
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                angle: -0.7,
                child: Text(timeStr,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black54)),
              );
            }
          }
          return const Text('');
        },
      );

  LineChartBarData _buildLine({required String vitalKey, required Color color}) {
    List<FlSpot> historySpots = [];
    // Loop over a collection to apply logic.
    for (int i = 0; i < _historyForChart.length; i++) {
      final value = _historyForChart[i][vitalKey];
      // Branch on a condition that affects logic flow.
      if (value is num) {
        historySpots.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }
    return LineChartBarData(
      spots: historySpots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, barData) {
          return spot == barData.spots.last;
        },
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 5, 
          color: barData.color ?? const Color(0xFF000000), 
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const double kBtnSize = 44;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
    
          SizedBox(
            width: kBtnSize,
            height: kBtnSize,
            child: Material(
              color: const Color(0xFF4C6EA0),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                // Navigate to another screen based on user action.
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

         
          Expanded(
            child: Center(
              child: Text(
                'Vital signs',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22364B),
                ),
              ),
            ),
          ),
          const SizedBox(width: kBtnSize, height: kBtnSize),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard(int heartRate) {
   
    final status = getVitalStatus('HR', heartRate.toDouble());
    final statusText = status['text'] as String;
    final statusColor = status['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC2E8E8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Heart Rate',
                  style: TextStyle(
                      color: Color(0xFF22364B),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(heartRate.toString(),
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22364B))),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0, left: 4),
                    child: Text('bpm',
                        style: TextStyle(
                            color: Color(0xFF22364B),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 120,
            height: 60,
            child: CustomPaint(
              painter: HeartbeatPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(Map<String, dynamic> data) {
  
    final systolic = (data['NISysABP'] as num?)?.toDouble();
    final diastolic = (data['NIDiasABP'] as num?)?.toDouble();
    final temp = (data['Temp'] as num?)?.toDouble();
    final oxygen = (data['SaO2'] as num?)?.toDouble();

    final bpStatus = getBloodPressureStatus(systolic, diastolic);
    final tempStatus = getVitalStatus('Temp', temp);
    final oxygenStatus = getVitalStatus('SaO2', oxygen);

    return Row(
      children: [
        Expanded(
          child: _buildVitalCard(
            icon: Icons.bloodtype,
            iconColor: Colors.red,
            title: 'Blood Pressure',
            valueWidget: Text(
                '${systolic?.toInt() ?? '--'}/${diastolic?.toInt() ?? '--'} mmHg',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            statusText: bpStatus['text'],
            statusColor: bpStatus['color'],
            color: const Color(0xFFFADADD),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildVitalCard(
            icon: Icons.thermostat,
            iconColor: Colors.green,
            title: 'Temperature',
            valueWidget: Text(
              '${temp?.toStringAsFixed(1) ?? '--'}°C',
              style: const TextStyle(fontSize: 16),
            ),
            statusText: tempStatus['text'],
            statusColor: tempStatus['color'],
            color: const Color(0xFFD4EFDF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildVitalCard(
            icon: Icons.air,
            iconColor: Colors.blue,
            title: 'Oxygen Level',
            valueWidget: Text('${oxygen?.toInt() ?? '--'}%',
                style: const TextStyle(fontSize: 16)),
            statusText: oxygenStatus['text'],
            statusColor: oxygenStatus['color'],
            color: const Color(0xFFD6EAF8),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoCard() {
    return GestureDetector(
      onTap: () {
        print("🩺 Navigating to patient profile with ID: ${widget.patientId}");
        // Navigate to another screen based on user action.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientHomeScreen(
              patientId: widget.patientId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF6A8EAF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 37,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: Image.asset(
                  'assets/patient_icon.png',
                  fit: BoxFit.cover,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$_patientName's smart file",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.bed,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Room $_roomNumber",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget valueWidget,
    required String statusText,
    required Color statusColor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 7),
          valueWidget, 
          const Spacer(),
         
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  
}

class HeartbeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22364B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width * 0.2, size.height / 2)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.6, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}