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
  
  // الخريطة ستحتوي على المؤقتات النشطة فقط
  final Map<String, Timer> activeSimulations = {};

  // الاستماع لأمر بدء محاكاة جديدة
  service.on('startPatientSimulation').listen((data) {
    if (data == null) return;
    final patientId = data['patientId'] as String;

    // التأكد من عدم وجود محاكاة نشطة لنفس المريض
    if (activeSimulations.containsKey(patientId)) {
      print("Simulation for $patientId is already running.");
      return;
    }
    
    final dataset = List<Map<String, dynamic>>.from(data['dataset']);
    int simulationIndex = data['startIndex'] ?? 0;
    
    print("✅ Starting simulation for $patientId at index $simulationIndex");

    // إنشاء المؤقت الدوري
    Timer patientTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (dataset.isEmpty) {
        timer.cancel();
        return;
      }
      
      final nextIndex = simulationIndex % dataset.length;
      final newVitals = dataset[nextIndex];

      // تحويل التاريخ إلى نص قبل إرساله
      final encodableVitals = newVitals.map((key, value) {
        if (value is DateTime) return MapEntry(key, value.toIso8601String());
        return MapEntry(key, value);
      });

      // إرسال التحديث إلى الواجهة
      service.invoke('update', {'patientId': patientId, 'vitals': encodableVitals});
      simulationIndex++;
    });

    // إضافة المؤقت الجديد إلى الخريطة
    activeSimulations[patientId] = patientTimer;
  });

  // الاستماع لأمر إيقاف المحاكاة
  service.on('stopPatientSimulation').listen((data) {
    if (data == null) return;
    final patientId = data['patientId'] as String;
    
    // إيقاف المؤقت وإزالته من الخريطة
    activeSimulations[patientId]?.cancel();
    activeSimulations.remove(patientId);
    print("🛑 Stopped simulation for $patientId.");
  });

  // إعداد الإشعار
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "ARVA Monitoring Service",
      content: "Patient simulations are active.",
    );
  }
}
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // لا تقم باستعادة الحالة هنا، دع الشاشة تدير ذلك عند فتحها
  // هذا يبسط المنطق ويمنع الأخطاء

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