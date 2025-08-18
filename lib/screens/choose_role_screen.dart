import 'package:flutter/material.dart';
import 'OnboardingScreen.dart'; // تأكد من أن هذا الملف موجود
import 'auth_screen.dart';     // تأكد من أن هذا الملف موجود

// --- الواجهة الرئيسية لصفحة اختيار الدور ---
class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({Key? key}) : super(key: key);

  @override
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: OnboardingBackgroundPainter()),
          
          CustomPaint(
            size: Size.infinite,
            painter: OnboardingBackgroundPainter(),
          ),

          // 2. المحتوى الرئيسي
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose your role :',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E5B7A),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleCard(
                      icon: Icons.medical_services_outlined,
                      label: 'Medical staff',
                      onTap: () {
                        // تم تعديل هذا لينتقل إلى شاشة تسجيل الدخول الصحيحة
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const AuthScreen(userRole: 'Medical Staff')),
                        );
                      },
                    ),
                    _buildRoleCard(
                      icon: Icons.personal_injury_outlined,
                      label: '   Patient   ',
                      onTap: () {
                        // تم تعديل هذا لينتقل إلى شاشة تسجيل الدخول الصحيحة
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const AuthScreen(userRole: 'Patient')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. زر الرجوع (تم إصلاحه)
          Positioned(
            bottom: 30,
            left: 30,
            child: FloatingActionButton(
              onPressed: () {
                
                // الدالة الصحيحة للرجوع هي .pop() فقط
                Navigator.of(context).pop();
              },
              backgroundColor: const Color(0xFF5A7A9A),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء كرت اختيار الدور
  Widget _buildRoleCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF5A7A9A), width: 9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 70, color: const Color(0xFF5A7A9A)),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5A7A9A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

