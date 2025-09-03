import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'medical_staff_login_screen.dart';
import 'auth_screen.dart';


class MedicalStaffSignUpScreen extends StatefulWidget {
  const MedicalStaffSignUpScreen({super.key});

  @override
  State<MedicalStaffSignUpScreen> createState() => _MedicalStaffSignUpScreenState();
}

class _MedicalStaffSignUpScreenState extends State<MedicalStaffSignUpScreen> {
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'Medical Staff',
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "An error occurred")),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Nice to have you here",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(controller: _usernameController, icon: Icons.person_outline, hintText: 'User Name'),
                        const SizedBox(height: 15),
                        _buildTextField(controller: _emailController, icon: Icons.email_outlined, hintText: 'Email'),
                        const SizedBox(height: 15),
                        _buildPasswordTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          isVisible: _passwordVisible,
                          onToggleVisibility: () {
                            setState(() { _passwordVisible = !_passwordVisible; });
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildPasswordTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          isVisible: _confirmPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A7A9A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Sign up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                            children: [
                              const TextSpan(text: "Already have an account? "),
                              TextSpan(
                                text: "Login",
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const MedicalStaffLoginScreen()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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
                  MaterialPageRoute(builder: (context) => const AuthScreen(userRole: 'Medical Staff')),
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

  Widget _buildTextField({required TextEditingController controller, required IconData icon, required String hintText}) {
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

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hintText,
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
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}



class SignUpBacgroundPainter extends CustomPainter {
 
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

@override
void paint(Canvas canvas, Size size) {

final width = size.width;

final height = size.height;



final tealPaint = Paint()..color = const Color(0xFFBFDDE0);

canvas.save();

canvas.translate(width * 0.6, height * 0.03);

canvas.rotate(pi / 10);

canvas.drawRRect(
RRect.fromRectAndRadius(

Rect.fromCenter(center: Offset.zero, width: width * 0.8, height: 150),

const Radius.circular(30),

),

  tealPaint,

  );

  canvas.restore();



  final purplePaint = Paint()..color = const Color(0xFFC6B4DE);

canvas.save();

canvas.translate(width * 0.2, height * 0.03);

canvas.rotate(pi / 10);
canvas.drawRRect(

RRect.fromRectAndRadius(

Rect.fromCenter(center: Offset.zero, width: width, height: 200),

 const Radius.circular(30),

),

purplePaint,

);

canvas.restore();



}}

