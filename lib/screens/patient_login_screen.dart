import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'patient_info_screen.dart'; // لاستخدامه في رابط "Sign Up"
import 'medical_staff_info_screen.dart';
import 'auth_screen.dart'; // لاستخدامه في رابط "Sign Up"
import 'package:firebase_auth/firebase_auth.dart';
 // لاستيراد SignUpBackgroundPainter مؤقتاً

// تم تغيير اسم الكلاس ليناسب واجهة المريض
class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
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

            // إظهار رسالة نجاح عند تسجيل الدخول الصحيح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Successful!"),
            backgroundColor: Colors.green, // تلوين الرسالة باللون الأخضر
          ),
        );
      }

      // إذا نجح تسجيل الدخول، يمكنك الانتقال إلى الصفحة الرئيسية
      // Navigator.of(context).pushReplacement(...);
      
    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء تسجيل الدخول الشائعة
      String errorMessage = "An error occurred. Please try again.";
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'Incorrect email or password.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      }
      
      // Show the error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color.fromARGB(255, 150, 121, 119), // Color the message red
        ),
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
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: SignUpBacgroundPainter(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -10,
                          child: Image.asset(
                            
                            'assets/doctors.png',
                            height: 300,
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const Text(
                    "Welcome back!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3A3A3A)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Log in to existing ARVA account",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                      controller: _emailController, 
                      icon: Icons.email_outlined, // أيقونة البريد
                      hintText: 'Email' // النص المؤقت
                      ),
                  const SizedBox(height: 15),
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
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A7A9A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),),
                  ),
                  const SizedBox(height: 30),
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
                                MaterialPageRoute(builder: (context) => const PatientSignUpScreen()),
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
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen(userRole: 'Patient')),
                );
              },
              backgroundColor: const Color(0xFF5A7A9A),
              mini: true,
              child: const Icon(Icons.arrow_back, color: Colors.white),
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

