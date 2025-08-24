
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. استيراد الحزمة
import 'firebase_options.dart'; 
import 'screens/splashscreen.dart';


// The main entry point of the application.
// 3. تم تحويل الدالة إلى async
void main() async {
  // 4. هذا السطر ضروري لضمان تهيئة كل شيء قبل runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // 5. تهيئة Firebase باستخدام الإعدادات الافتراضية للمنصة الحالية
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

// The root widget of your application.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Start the app with the SplashScreen.
      home: SplashScreen(),
    );
  }
}
