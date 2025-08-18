
// ---------------------------------------------------
// الملف 2: lib/screens/auth_screen.dart (تم تعديله ليصبح قابلاً لإعادة الاستخدام)
// ---------------------------------------------------
import 'package:flutter/material.dart';
import 'medical_staff_info_screen.dart';
import 'patient_info_screen.dart';
import 'OnboardingScreen.dart'; // لاستخدام الخلفية
import 'medical_staff_login_screen.dart';
import 'choose_role_screen.dart';
import 'patient_login_screen.dart';


class AuthScreen extends StatelessWidget {
  // 1. أضفنا هذا المعامل لنعرف من هو المستخدم الحالي
  final String userRole;

  const AuthScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: OnboardingBackgroundPainter()),
          Positioned(
            bottom: 30,
            left: 30,
            child: FloatingActionButton(
              onPressed: () {Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
            );
           },
              backgroundColor: const Color(0xFF5A7A9A),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo1.png', height: 150),
                    const SizedBox(height: 30),
                    const Text("Let's get started!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    // 2. يمكنك تغيير هذا النص بناءً على الدور إذا أردت
                    Text(
                      "Login or Sign Up  to enjoy the features we’ve provided, and stay healthy! \n continue as a $userRole.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 122, 122, 122)),
                    ),
                    const SizedBox(height: 100),
                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () { 
                          if (userRole == 'Medical Staff') {
                          Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const MedicalStaffLoginScreen()),
                        );
                          } else {
                          //  توجيه المريض إلى شاشة تسجيل دخول خاصة به هنا
                          Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const  PatientLoginScreen())

                        );
                          }
                         },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A7A9A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // زر إنشاء حساب
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          // 3. هنا هو المنطق الرئيسي
                          // إذا كان المستخدم طبيباً، اذهب إلى شاشة معلومات الطبيب
                          if (userRole == 'Medical Staff') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const MedicalStaffSignUpScreen()),
                            );
                          } 
                          // وإذا كان مريضاً، اذهب إلى شاشة معلومات المريض
                          else {
                            Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const PatientSignUpScreen()),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5A7A9A), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A7A9A))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

