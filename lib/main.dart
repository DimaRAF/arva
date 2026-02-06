import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/splashscreen.dart';
import 'screens/pateint_home.dart';
import 'screens/medical_staff_home_screen.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/vital_signs_screen.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:arva/ml/scaler_lite.dart';





Map<String, dynamic> patientSimulationData = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeService();
  final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

const AndroidInitializationSettings initSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
const InitializationSettings initSettings =
    InitializationSettings(android: initSettingsAndroid);

await notifications.initialize(
  initSettings,
  onDidReceiveNotificationResponse: (NotificationResponse response) async {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      final patientId = data['patientId'];
      final patientName = data['patientName'];

      runApp(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: VitalSignsScreen(patientId: patientId),
      ));
    }
  },
);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      home: MainPage(),
    );
  }
}


class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
       
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
         
          else if (snapshot.hasData) {
           
            return const RoleChecker();
          }
         
          else {
            
            return SplashScreen();
          }
        },
      ),
    );
  }
}


class RoleChecker extends StatelessWidget {
  const RoleChecker({super.key});

  @override
  Widget build(BuildContext context) {
    
    final user = FirebaseAuth.instance.currentUser!;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
         
          return SplashScreen(); 
        }

        
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userRole = userData['role'];

        
        if (userRole == 'Medical Staff') {
          
          return const MedicalStaffHomeScreen();
        } else {
          
          return PatientHomeScreen(patientId: user.uid);
        }
      },
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final interpreter = await Interpreter.fromAsset('assets/vitals_predictor_gru.tflite');
  final scaler = await loadScalerFromAssets('assets/vitals_scaler_params.json');

  

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: initSettingsAndroid);
  await notifications.initialize(initSettings);



  final Map<String, Timer> activeSimulations = {};

 
  service.on('startPatientSimulation').listen((data) {
  if (data == null) return;
  final patientId = data['patientId'] as String;
  final patientName = data['patientName'] ?? 'Unknown Patient'; 


  
    if (activeSimulations.containsKey(patientId)) {
      print("Simulation for $patientName is already running.");
      return;
    }
    
    final dataset = List<Map<String, dynamic>>.from(data['dataset']);
    int simulationIndex = data['startIndex'] ?? 0;
    
    print("✅ Starting simulation for $patientName at index $simulationIndex");

  
    Timer patientTimer = Timer.periodic(const Duration(seconds: 5), (timer)   async {
      if (dataset.isEmpty) {
        timer.cancel();
        return;
      }
      
      final nextIndex = simulationIndex % dataset.length;
      final newVitals = dataset[nextIndex];

     
      final encodableVitals = newVitals.map((key, value) {
        if (value is DateTime) return MapEntry(key, value.toIso8601String());
        return MapEntry(key, value);
      });

      
      service.invoke('update', {'patientId': patientId, 'vitals': encodableVitals});
      
      
      await saveVitals(patientId, encodableVitals);


final recentHistory = await loadRecentVitals(patientId, limit: 10);
if (recentHistory.length == 10) {
  final prediction = runPrediction(interpreter, scaler, recentHistory);

  await savePredictedVitals(patientId, prediction);

 
  checkAndNotify(prediction, patientId, patientName, isPredicted: true);
}

        
  final hr = (newVitals['HR'] as num?)?.toDouble() ?? 0;
  if (hr > 110 || hr < 50) {
    showBackgroundAlert(
      'Critical Heart Rate',
      'Abnormal HR detected for patient $patientName (HR: ${hr.toStringAsFixed(1)})',
      patientId,
      patientName,
    );
  }


  final temp = (newVitals['Temp'] as num?)?.toDouble() ?? 0;
  if (temp > 38 || temp < 35.5) {
    showBackgroundAlert(
      'Critical Temperature',
      'Abnormal temperature detected for patient $patientName (Temp: ${temp.toStringAsFixed(1)}°C)',
      patientId,
      patientName,
    );
  }

 
  final spo2 = (newVitals['SaO2'] as num?)?.toDouble() ?? 0;
  if (spo2 < 93) {
    showBackgroundAlert(
      'Low Oxygen Level',
      'Patient $patientName has low oxygen level (SaO₂: ${spo2.toStringAsFixed(1)}%)',
      patientId,
      patientName,
    );
  }

  
  final sys = (newVitals['NISysABP'] as num?)?.toDouble() ?? 0;
  final dia = (newVitals['NIDiasABP'] as num?)?.toDouble() ?? 0;
  if (sys > 140 || dia > 90 || sys < 90 || dia < 60) {
    showBackgroundAlert(
      'Abnormal Blood Pressure',
      'Patient $patientName has abnormal BP (Sys: ${sys.toStringAsFixed(0)}, Dia: ${dia.toStringAsFixed(0)})', 
      patientId,
      patientName,     

    );
  }

      simulationIndex++;
    });

    
    activeSimulations[patientId] = patientTimer;
  });

  
  service.on('stopPatientSimulation').listen((data) {
    if (data == null) return;
    final patientId = data['patientId'] as String;
    
    
    activeSimulations[patientId]?.cancel();
    activeSimulations.remove(patientId);
    print("🛑 Stopped simulation for $patientId.");
  });

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "ARVA Monitoring Service",
      content: "Patient simulations are active.",
    );
  }
}




Future<void> initializeService() async {
  final service = FlutterBackgroundService();

 

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );
}


Future<void> saveVitals(String patientId, Map<String, dynamic> vitals) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('vitals_$patientId', jsonEncode(vitals));
}

Future<List<Map<String, dynamic>>> loadRecentVitals(String id, {int limit = 10}) async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('vitals_history_$id');
  if (data == null) return [];
  final decoded = List<Map<String, dynamic>>.from(jsonDecode(data));
  return decoded.length > limit
      ? decoded.sublist(decoded.length - limit)
      : decoded;
}



Future<void> savePredictedVitals(String id, Map<String, dynamic> vitals) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('predicted_vitals_$id', jsonEncode(vitals));
}


Map<String, dynamic> runPrediction(Interpreter interpreter, MinMaxScalerLite scaler, List<Map<String, dynamic>> history) {
  final seqNorm = history.map((r) {
    final rawVec = [
      (r['HR'] as num).toDouble(),
      (r['Temp'] as num).toDouble(),
      (r['SaO2'] as num).toDouble(),
      (r['NISysABP'] as num).toDouble(),
      (r['NIDiasABP'] as num).toDouble(),
    ];
    return scaler.normalizeVector(rawVec);
  }).toList();

  final input = [seqNorm];
  final output = [List<double>.filled(5, 0)];
  interpreter.run(input, output);

  final denorm = scaler.denormalizeVector(output[0]);
  return {
    'HR': denorm[0],
    'Temp': denorm[1],
    'SaO2': denorm[2],
    'NISysABP': denorm[3],
    'NIDiasABP': denorm[4],
  };
}

void checkAndNotify(Map<String, dynamic> vitals, String patientId, String patientName, {bool isPredicted = false}) {
  final type = isPredicted ? "🧠 Predicted" : "📡 Real-Time";

  final hr = (vitals['HR'] as num?)?.toDouble() ?? 0;
  final temp = (vitals['Temp'] as num?)?.toDouble() ?? 0;
  final spo2 = (vitals['SaO2'] as num?)?.toDouble() ?? 0;

  if (hr > 110 || hr < 50) {
    showBackgroundAlert('$type - Heart Rate Alert', 'Abnormal HR for $patientName (${hr.toStringAsFixed(1)})', patientId, patientName);
  }
  if (temp > 38 || temp < 35.5) {
    showBackgroundAlert('$type - Temperature Alert', 'Abnormal Temp for $patientName (${temp.toStringAsFixed(1)}°C)', patientId, patientName);
  }
  if (spo2 < 93) {
    showBackgroundAlert('$type - Oxygen Alert', 'Low SaO₂ for $patientName (${spo2.toStringAsFixed(1)}%)', patientId, patientName);
  }
}
void showBackgroundAlert(String title, String body, String patientId, String patientName) {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  notifications.show(
    0,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'vital_alerts',
        'Vital Alerts',
        channelDescription: 'Critical alerts for patient vitals',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFD32F2F),
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: jsonEncode({
      'patientId': patientId,
      'patientName': patientName,
    }),
  );
}