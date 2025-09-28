import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'pateint_home.dart'; // استيراد شاشة الملف الذكي


class VitalSignsScreen extends StatefulWidget {
  final String patientId;
  const VitalSignsScreen({super.key, required this.patientId});

  @override
  State<VitalSignsScreen> createState() => _VitalSignsScreenState();
}

class _VitalSignsScreenState extends State<VitalSignsScreen> {
  String _patientName = "Unknown Patient";
  String _roomNumber = '--';
   
  
  Interpreter? _interpreter;
  
  bool _isLoading = true;

  final List<Map<String, dynamic>> _patientSpecificDataset = [];
  final List<Map<String, dynamic>> _historyForChart = [];
  Map<String, dynamic> _currentVitals = {};
  Map<String, dynamic>? _predictedVitals;
  
  
  int _bottomNavIndex = 1;
@override
void initState() {
  super.initState();
  // 1. تحميل البيانات وإرسالها للخدمة
  _loadDataAndConfigureService();
  
  // 2. الاستماع للتحديثات القادمة من الخدمة
  FlutterBackgroundService().on('update').listen((data) {
    // تأكد أن التحديث خاص بهذا المريض وأن الشاشة ما زالت موجودة
    if (mounted && data != null && data['patientId'] == widget.patientId) {
      setState(() {
        // --- هذا هو الجزء الأهم الذي يجب التأكد منه ---

        // أ) استلم البيانات القادمة في متغير جديد
        final receivedVitals = Map<String, dynamic>.from(data['vitals']);

        // ب) حوّل الوقت من نص إلى كائن تاريخ
        if (receivedVitals['time'] is String) {
          receivedVitals['time'] = DateTime.parse(receivedVitals['time'] as String);
        }

        // ج) استخدم البيانات بعد تحويلها
        _currentVitals = receivedVitals;
        _historyForChart.add(_currentVitals);
        
        // --- نهاية الجزء المهم ---

        if (_historyForChart.length > 288) {
          _historyForChart.removeAt(0);
        }
      });
      _runPrediction();
    }
  });
}

Future<void> _loadModel() async {
  try {
    var options = InterpreterOptions()
      ..addDelegate(GpuDelegateV2()) 
      ..threads = 4;
    _interpreter = await Interpreter.fromAsset('assets/vitals_predictor.tflite', options: options); 
    print('TensorFlow Lite model loaded successfully.');
  } catch (e) {
    print('Failed to load TensorFlow Lite model: $e');
  }
}
void _runPrediction() {
  // --- جمل طباعة تشخيصية ---
  if (_interpreter == null) {
    print("Prediction skipped: Interpreter is null.");
    return;
  }
  if (_historyForChart.length < 10) {
    print("Prediction skipped: Not enough history data (${_historyForChart.length}/10).");
    return;
  }
  // --- نهاية جمل الطباعة ---

  const int sequenceLength = 10;
  const int numFeatures = 5;

  final recentHistory = _historyForChart.sublist(_historyForChart.length - sequenceLength);

  var input = List.generate(sequenceLength, (i) {
    final record = recentHistory[i];
    return [
      record['HR']?.toDouble() ?? 0.0,
      record['Temp']?.toDouble() ?? 0.0,
      record['SaO2']?.toDouble() ?? 0.0,
      record['NISysABP']?.toDouble() ?? 0.0,
      record['NIDiasABP']?.toDouble() ?? 0.0,
    ];
  });

  var shapedInput = [input];
  var output = List.filled(1 * numFeatures, 0.0).reshape([1, numFeatures]);

  try {
    _interpreter!.run(shapedInput, output);
    final predictedValues = output[0];

    setState(() {
      _predictedVitals = {
        'HR': predictedValues[0],
        'Temp': predictedValues[1],
        'SaO2': predictedValues[2],
        'NISysABP': predictedValues[3],
        'NIDiasABP': predictedValues[4],
      };
      // --- جملة طباعة مهمة جداً ---
      print('>>> PREDICTION SET SUCCESSFULLY: $_predictedVitals');
    });

  } catch (e) {
    // --- جملة طباعة للخطأ ---
    print("!!! ERROR running model prediction: $e");
  }
}


// أضف هذه الدالة الجديدة في الكلاس الخاص بك
LineChartBarData _buildPredictionLine({
  required String vitalKey,
  required Color color,
}) {
  // --- جمل طباعة تشخيصية ---
  print('--- Checking prediction line for: $vitalKey');

  if (_historyForChart.isEmpty) {
    print('--- [$vitalKey] Skipped: History is empty.');
    return LineChartBarData(show: false);
  }
  if (_predictedVitals == null) {
    print('--- [$vitalKey] Skipped: _predictedVitals is null.');
    return LineChartBarData(show: false);
  }

  final lastHistoryIndex = _historyForChart.length - 1;
  final lastHistoryValue = _historyForChart.last[vitalKey];
  final predictedValue = _predictedVitals![vitalKey];

  print('--- [$vitalKey] Last History Value: $lastHistoryValue | Predicted Value: $predictedValue');

  if (lastHistoryValue is! num || predictedValue is! num) {
    print('--- [$vitalKey] Skipped: One of the values is not a valid number.');
    return LineChartBarData(show: false);
  }
  // --- نهاية جمل الطباعة ---

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
    // تحميل البيانات (نفس كود _loadDataForPatient السابق)
    await _loadModel();
    await _loadDataForPatient();

    // بعد تحميل البيانات بنجاح، أرسلها إلى الخدمة الخلفية
    if (_patientSpecificDataset.isNotEmpty) {
      //_currentVitals = _patientSpecificDataset[0];
      FlutterBackgroundService().invoke('startPatientSimulation', {
  'patientId': widget.patientId,
  'dataset': _patientSpecificDataset.map((record) {
    return {
      ...record,
      'time': (record['time'] as DateTime).toIso8601String(), // ← أو .millisecondsSinceEpoch
    };
  }).toList(),
  'startIndex': 0,
});
    }

    if (mounted) setState(() => _isLoading = false);
  }






  // --- دوال منطق العمل ---


Map<String, dynamic> getVitalStatus(String vitalKey, double? value) {
  if (value == null) return {'text': 'N/A', 'color': Colors.grey};

  switch (vitalKey) {
    case 'HR': // Heart Rate
      if (value > 100) return {'text': 'High', 'color': Colors.red};
      if (value < 60) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
      return {'text': 'Normal', 'color': Colors.green};
    case 'Temp': // Temperature
      if (value > 37.5) return {'text': 'High', 'color': Colors.red};
      if (value < 36.1) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
      return {'text': 'Normal', 'color': Colors.green};
    case 'SaO2': // Oxygen Level
      if (value < 95) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
      return {'text': 'Normal', 'color': Colors.green};
    default:
      return {'text': 'Normal', 'color': Colors.green};
  }
}

// دالة خاصة لضغط الدم لأنه يحتوي على قيمتين
Map<String, dynamic> getBloodPressureStatus(double? systolic, double? diastolic) {
  if (systolic == null || diastolic == null) {
    return {'text': 'N/A', 'color': Colors.grey};
  }
  // يعتبر مرتفعًا إذا كانت أي من القيمتين مرتفعة
  if (systolic > 130 || diastolic > 85) return {'text': 'High', 'color': Colors.red};
  // يعتبر منخفضًا إذا كانت أي من القيمتين منخفضة
  if (systolic < 90 || diastolic < 60) return {'text': 'Low', 'color': const Color(0xFFFF9800)};
  return {'text': 'Normal', 'color': Colors.green};
}
  
Future<void> _loadDataForPatient() async {
  try {
    final profileDoc = await FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(widget.patientId)
        .get();

    // 1. التحقق من وجود مستند المريض في قاعدة البيانات
    if (!profileDoc.exists || profileDoc.data() == null) {
      print("Error: Patient document not found for ID: ${widget.patientId}");
      _patientName = 'Patient Not Found';
      _roomNumber = '--';
      return; // الخروج من الدالة إذا لم يتم العثور على المريض
    }

    // 2. قراءة بيانات المريض (الاسم ورقم الغرفة)
    final data = profileDoc.data()!;
    // تأكد من أن أسماء الحقول في Firestore هي 'name' و 'room'
    _patientName = data['username'] as String? ?? 'Unnamed Patient';
    _roomNumber = data['roomNumber']?.toString() ?? '--';

    // 3. التحقق من وجود ملف البيانات
    if (data['dataFilename'] == null) {
      print("Error: This patient has no assigned data file (dataFilename).");
      _patientSpecificDataset.clear();
      return; // الخروج إذا لم يكن هناك ملف بيانات
    }
    final String filename = data['dataFilename'];

    // 4. تحميل ومعالجة ملف CSV
    final txtData = await rootBundle.loadString('assets/patient_vitals/$filename');
    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(eol: '\n').convert(txtData);

    final headers = rowsAsListOfValues[0].map((e) => e.toString().trim()).toList();
    rowsAsListOfValues.removeAt(0);

    // مسح البيانات القديمة قبل تحميل الجديدة (مهم عند التنقل بين المرضى)
    _patientSpecificDataset.clear(); 
    DateTime lastDate = DateTime.now().subtract(const Duration(days: 1));
    
    for (int i = 0; i < rowsAsListOfValues.length; i++) {
      final row = rowsAsListOfValues[i];
      Map<String, dynamic> rowData = {};
      for (int j = 0; j < headers.length; j++) {
        if (headers[j] == 'Time') {
          try {
            final timeParts = row[j].toString().split(':');
            final hours = int.parse(timeParts[0]);
            final minutes = int.parse(timeParts[1]);
            if (i > 0 && _patientSpecificDataset.isNotEmpty && hours < (_patientSpecificDataset.last['time'] as DateTime).hour) {
              lastDate = lastDate.add(const Duration(days: 1));
            }
            rowData['time'] = DateTime(lastDate.year, lastDate.month, lastDate.day, hours, minutes);
          } catch(e) {
            rowData['time'] = lastDate.add(Duration(minutes: i * 5));
          }
        } else {
          rowData[headers[j]] = double.tryParse(row[j].toString()) ?? 0.0;
        }
      }
      _patientSpecificDataset.add(rowData);
    }
    
    print("Successfully loaded ${_patientSpecificDataset.length} records for $_patientName.");
    //_currentVitals = _patientSpecificDataset.isNotEmpty ? _patientSpecificDataset[0] : {};

  } catch (e) {
    print("Error loading or processing patient data file: $e");
    _patientName = 'Error Loading Data';
    _roomNumber = 'X';
  }
}


  // --- دوال بناء الواجهة ---

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
       bottomNavigationBar: _buildBottomNavBar(),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Vital Signs - Last 24 Hours", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: _bottomTitles),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
               
                minX: max(0, _historyForChart.length - 50).toDouble() - 1, // نطرح 1 لإعطاء مسافة على اليسار
                maxX: (_historyForChart.length - 1).toDouble() + 4,
                 
                lineBarsData: [
                  _buildLine(vitalKey: 'HR', color: Colors.red),
                  _buildPredictionLine(vitalKey: 'HR', color: Colors.red),
                  _buildLine(vitalKey: 'Temp', color: Colors.orange),
                  _buildPredictionLine(vitalKey: 'Temp', color: Colors.orange),
                  _buildLine(vitalKey: 'SaO2', color: Colors.blue),
                  _buildPredictionLine(vitalKey: 'SaO2', color: Colors.blue),
                  _buildLine(vitalKey: 'NISysABP', color: Colors.purple),
                  _buildPredictionLine(vitalKey: 'NISysABP', color: Colors.purple),
                  _buildLine(vitalKey: 'NIDiasABP', color: Colors.teal),
                  _buildPredictionLine(vitalKey: 'NIDiasABP', color: Colors.teal),
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
          if (index >= 0 && index < _historyForChart.length) {
             final time = _historyForChart[index]['time'] as DateTime?;
             if (time != null) {
                final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  angle:-0.7,
                  child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                );
             }
          }
          return const Text('');
        },
      );

  LineChartBarData _buildLine(
      {required String vitalKey,
      required Color color}) {
    List<FlSpot> historySpots = [];
    for (int i = 0; i < _historyForChart.length; i++) {
      final value = _historyForChart[i][vitalKey];
      if (value is num) {
        historySpots.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }
    return LineChartBarData(
      spots: historySpots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }
Widget _buildHeader() {
  // تم حذف const لأن Row أصبح يحتوي على دالة onTap
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Vital signs',
        style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF22364B)),
      ),
      // 1. استخدمنا InkWell لجعل الزر قابلاً للنقر
      InkWell(
        // لجعل تأثير الضغطة دائريًا
        customBorder: const CircleBorder(), 
        // 2. الدالة التي سيتم تنفيذها عند الضغط
        onTap: () {
          // هذا السطر يقوم بالرجوع إلى الشاشة السابقة
          Navigator.of(context).pop();
        },
        child: const CircleAvatar(
          backgroundColor: Color(0xFF4C6EA0),
          // 3. قمنا بتغيير الأيقونة إلى سهم للخلف
          child: Icon(Icons.arrow_forward_outlined, color: Colors.white),
        ),
      ),
    ],
  );
}

Widget _buildHeartRateCard(int heartRate) {
  // تحديد حالة نبض القلب
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
                style: TextStyle(color: Color(0xFF22364B), fontSize: 22
                ,fontWeight: FontWeight.bold)),
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
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.bold),
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
  // استخراج القيم
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
              style: const TextStyle(fontSize: 12,fontWeight: FontWeight.bold)),
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
  return Container(
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
              _patientName,
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
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor),
            const Icon(Icons.more_horiz, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 15),
        
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 7),
        valueWidget, // استخدام الويدجت مباشرة هنا
        const Spacer(),
        // عرض شريحة الحالة الديناميكية (واحدة فقط)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            statusText,
            style: TextStyle(
                color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

// دالة بناء شريط التنقل السفلي بالتصميم الجديد
Widget _buildBottomNavBar() {
  return Container(
    height: 70,
    decoration: const BoxDecoration(
      color: Color(0xFF4C6EA0), // لون الخلفية الأزرق
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // هنا نضع أيقونات شاشة الكادر الطبي بالترتيب
        _buildNavItem(icon: Icons.home, index: 0, label: 'Home'),
        _buildNavItem(icon: Icons.favorite, index: 1, label: 'Vitals'), // أيقونة العلامات الحيوية
        _buildNavItem(icon: Icons.receipt_long, index: 2, label: 'File'), // أيقونة الملف الذكي
        _buildNavItem(icon: Icons.person, index: 3, label: 'Profile'),
      ],
    ),
  );
}

// دالة بناء كل أيقونة في شريط التنقل (نفس تصميم شاشة المريض)
Widget _buildNavItem({required IconData icon, required int index, required String label}) {
  // تأكد من أن اسم المتغير هنا يطابق اسم متغير الحالة في شاشتك
  // في شاشتك اسمه _bottomNavIndex
  final isSelected = _bottomNavIndex == index;

  return GestureDetector(
    // onTap: () {
    //   // --- هنا المنطق الخاص بكل زر ---

    //   // الزر رقم 2 (File) سينتقل إلى شاشة الملف الذكي
    //   if (index == 2) {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => PatientHomeScreen(),
    //       ),
    //     );
    //   } else {
    //     // باقي الأزرار ستغير الصفحة المعروضة فقط
    //     setState(() {
    //       _bottomNavIndex = index;
    //     });
    //   }
    // },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isSelected
            ? Transform.translate(
                offset: const Offset(0, -15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6A8EAF), // لون الدائرة المرتفعة
                     boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
              )
            : Icon(icon, color: Colors.white.withOpacity(0.7), size: 28),
        
        // إضافة النص تحت الأيقونة
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

