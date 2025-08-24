import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'medical_staff_info_screen.dart'; // لاستخدامه في رابط "Sign Up"
import 'auth_screen.dart'; // لاستخدامه في رابط "Sign Up"
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. تم إضافة الاستيراد الناقص
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. تم تحويل الواجهة إلى StatefulWidget
class MedicalStaffLoginScreen extends StatefulWidget {
  const MedicalStaffLoginScreen({Key? key}) : super(key: key);

  @override
  State<MedicalStaffLoginScreen> createState() => _MedicalStaffLoginScreenState();
}

class _MedicalStaffLoginScreenState extends State<MedicalStaffLoginScreen> {

    // Controllers لقراءة البيانات
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 2. تم نقل متغير الحالة إلى هنا
  bool _isPasswordVisible = false;
  bool _isLoading = false;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

   // --- دالة تسجيل الدخول ---
  Future<void> login() async {
    // التأكد من أن الحقول ليست فارغة
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // استخدام دالة Firebase لتسجيل الدخول
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // إذا نجح تسجيل الدخول، يمكنك الانتقال إلى الصفحة الرئيسية
      // Navigator.of(context).pushReplacement(...);
      print("Login Successful!");

    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء تسجيل الدخول الشائعة
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      }
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unknown error occurred: $e")),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 3. تم تعديل الهيكل ليستخدم Stack كعنصر رئيسي
      body: Stack(
        children: [
          // الطبقة الأولى: الخلفية
          CustomPaint(
            size: Size.infinite,
            painter: SignUpBacgroundPainter(),
          ),

          // الطبقة الثانية: المحتوى القابل للتمرير
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // الجزء العلوي مع الصورة
                  SizedBox(
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -10,
                          child: Image.asset(
                            'assets/doctors.png', // تأكد أن اسم الصورة صحيح
                            height: 300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // الجزء السفلي مع حقول الإدخال
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Welcome back!",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3A3A3A)),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Log in to existing ARVA account",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 60),
                        _buildTextField(controller: _emailController,icon: Icons.person_outline, hintText: 'Username'),
                        const SizedBox(height: 15),
                        
                        // --- حقل كلمة المرور مع أيقونة العين ---
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              // 4. عند الضغط، نستخدم setState لتحديث الواجهة
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 0.1),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Color(0xFF5A7A9A), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            // عند الضغط، استدعاء دالة login
                          onPressed: _isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A7A9A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                           child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                        ),
                        const SizedBox(height: 25),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: "Sign Up",
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (context) => const MedicalStaffSignUpScreen()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // الطبقة الثالثة: زر الرجوع
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen(userRole: 'Medical Staff')),
                );
              },
              backgroundColor: const Color(0xFF5A7A9A),
              child: const Icon(Icons.arrow_back, color: Colors.white),
              mini: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller,required IconData icon, required String hintText}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}



class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

