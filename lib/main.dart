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
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


Map<String, dynamic> patientSimulationData = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeService();
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
          
          return const PatientHomeScreen();
        }
      },
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  final Map<String, Timer> activeSimulations = {};
  
  // --- دالة مساعدة لبدء المحاكاة لتجنب تكرار الكود ---
  void startSimulationLogic(String patientId, List<Map<String, dynamic>> dataset, int startIndex) {
    if (activeSimulations.containsKey(patientId)) return;
    
    int simulationIndex = startIndex;
    print("Starting simulation for $patientId at index $simulationIndex");

    Timer patientTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
      simulationIndex++;
    });

    activeSimulations[patientId] = patientTimer;
  }
  
  // --- استعادة الحالة عند بدء تشغيل الخدمة ---
  final prefs = await SharedPreferences.getInstance();
  final String? savedSimulationsJson = prefs.getString('active_simulations_state');

  if (savedSimulationsJson != null) {
    final Map<String, dynamic> savedState = jsonDecode(savedSimulationsJson);
    savedState.forEach((patientId, data) {
      // أعد تشغيل المحاكاة للمرضى الذين كانوا نشطين
      final dataset = List<Map<String, dynamic>>.from(data['dataset']);
      // ملاحظة: لم نقم بتخزين الـ index الحالي للتبسيط، ستبدأ من الصفر عند إعادة التشغيل
      // ولكنها لن تضاف مرة أخرى عند دخول الشاشة
      startSimulationLogic(patientId, dataset, 0); 
    });
  }

  // --- منطق الأوامر القادمة من الواجهة ---
  service.on('startPatientSimulation').listen((data) async {
    if (data == null) return;
    final patientId = data['patientId'] as String;

    if (activeSimulations.containsKey(patientId)) {
      print("Simulation for $patientId is already running.");
      return;
    }
    
    final dataset = List<Map<String, dynamic>>.from(data['dataset']);
    startSimulationLogic(patientId, dataset, data['startIndex'] ?? 0);

    // حفظ الحالة الجديدة في الذاكرة الدائمة
    final currentState = prefs.getString('active_simulations_state');
    Map<String, dynamic> stateMap = currentState != null ? jsonDecode(currentState) : {};
    stateMap[patientId] = {'dataset': dataset};
    await prefs.setString('active_simulations_state', jsonEncode(stateMap));
  });

  service.on('stopPatientSimulation').listen((data) async {
    if (data == null) return;
    final patientId = data['patientId'] as String;
    
    activeSimulations[patientId]?.cancel();
    activeSimulations.remove(patientId);
    
    // تحديث الحالة في الذاكرة الدائمة
    final currentState = prefs.getString('active_simulations_state');
    if (currentState == null) return;
    Map<String, dynamic> stateMap = jsonDecode(currentState);
    stateMap.remove(patientId);
    await prefs.setString('active_simulations_state', jsonEncode(stateMap));
    print("Stopped and removed simulation for $patientId from persistent storage.");
  });

  // ... يمكنك إضافة الإشعار هنا إذا أردت ...
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
