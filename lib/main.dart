import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// 1. استيراد جميع الشاشات التي سنحتاجها
import 'screens/splashscreen.dart';
import 'screens/pateint_home.dart';
import 'screens/medical_staff_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
        // 3. هذا السطر يستمع بشكل دائم لحالة تسجيل الدخول
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // إذا كان التطبيق لا يزال يتحقق من وجود مستخدم مسجل
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
          // إذا كان طبيباً، اذهب إلى شاشة الأطباء
          return const MedicalStaffHomeScreen();
        } else {
          // وإذا كان مريضاً، اذهب إلى شاشة المرضى
          return const PatientHomeScreen();
        }
      },
    );
  }
}