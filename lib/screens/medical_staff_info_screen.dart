import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medical_staff_login_screen.dart';
import 'auth_screen.dart';
import 'medical_staff_home_screen.dart';


class MedicalStaffSignUpScreen extends StatefulWidget {
  const MedicalStaffSignUpScreen({super.key});

  @override
  State<MedicalStaffSignUpScreen> createState() =>
      _MedicalStaffSignUpScreenState();
}

class _MedicalStaffSignUpScreenState extends State<MedicalStaffSignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _jobTitleController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;


  String? _usernameError;
  String? _jobTitleError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;

    final username = _usernameController.text.trim();
    final jobTitle = _jobTitleController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
     
      // Branch on a condition that affects logic flow.
      if (username.isEmpty) {
        _usernameError = 'Name is required';
        isValid = false;
      } else {
        _usernameError = null;
      }

     
      // Branch on a condition that affects logic flow.
      if (jobTitle.isEmpty) {
        _jobTitleError = 'Job title is required';
        isValid = false;
      } else {
        _jobTitleError = null;
      }

      // Branch on a condition that affects logic flow.
      if (email.isEmpty) {
        _emailError = 'Email is required';
        isValid = false;
      } else {
        
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        // Branch on a condition that affects logic flow.
        if (!emailRegex.hasMatch(email)) {
          _emailError = 'Enter a valid email address';
          isValid = false;
        } else {
          _emailError = null;
        }
      }

      
      // Branch on a condition that affects logic flow.
      if (password.isEmpty) {
        _passwordError = 'Password is required';
        isValid = false;
      } else if (password.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        isValid = false;
      } else {
        _passwordError = null;
      }

      
      // Branch on a condition that affects logic flow.
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Confirm your password';
        isValid = false;
      } else if (password != confirmPassword) {
        _confirmPasswordError = 'Passwords do not match';
        isValid = false;
      } else {
        _confirmPasswordError = null;
      }
    });

    return isValid;
  }

  Future<void> signUp() async {
   
    // Branch on a condition that affects logic flow.
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          // Await an asynchronous operation.
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Branch on a condition that affects logic flow.
      if (userCredential.user != null) {
        // Await an asynchronous operation.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'Medical Staff',
          'jobTitle': _jobTitleController.text.trim(),
          'createdAt': Timestamp.now(),
        });
        // Branch on a condition that affects logic flow.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const MedicalStaffHomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Branch on a condition that affects logic flow.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "An error occurred")),
      );
    } catch (e) {
      // Branch on a condition that affects logic flow.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unknown error occurred: $e")),
      );
    }

    // Branch on a condition that affects logic flow.
    if (mounted && _isLoading) {
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
            painter: SignUpBackgroundPainter(),
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
                        const Text(
                          "Nice to have you here",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _usernameController,
                          icon: Icons.person_outline,
                          hintText: 'User Name',
                          errorText: _usernameError,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _jobTitleController,
                          icon: Icons.work_outline,
                          hintText: 'Job Title',
                          errorText: _jobTitleError,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hintText: 'Email',
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          isVisible: _passwordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                          errorText: _passwordError,
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          isVisible: _confirmPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            });
                          },
                          errorText: _confirmPasswordError,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A7A9A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Sign up',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                            children: [
                              const TextSpan(
                                  text: "Already have an account? "),
                              TextSpan(
                                text: "Login",
                                style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const MedicalStaffLoginScreen()),
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
                  MaterialPageRoute(
                      builder: (context) =>
                          const AuthScreen(userRole: 'Medical Staff')),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
        ),
        // Branch on a condition that affects logic flow.
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
        ),
        // Branch on a condition that affects logic flow.
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class SignUpBackgroundPainter extends CustomPainter {
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
        Rect.fromCenter(
            center: Offset.zero, width: width * 0.8, height: 150),
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
