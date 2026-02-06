import 'package:flutter/material.dart';
import 'medical_staff_info_screen.dart';
import 'patient_info_screen.dart';
import 'OnboardingScreen.dart'; 
import 'medical_staff_login_screen.dart';
import 'choose_role_screen.dart';
import 'patient_login_screen.dart';


class AuthScreen extends StatelessWidget {
  final String userRole;
  const AuthScreen({super.key, required this.userRole});

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
                    
                    Text(
                      "Login or Sign Up  to enjoy the features we’ve provided, and stay healthy! \n continue as a $userRole.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 122, 122, 122)),
                    ),
                    const SizedBox(height: 100),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () { 
                          // Branch on a condition that affects logic flow.
                          if (userRole == 'Medical Staff') {
                          Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const MedicalStaffLoginScreen()),
                        );
                          } else {
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
                    
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          
                          
                          // Branch on a condition that affects logic flow.
                          if (userRole == 'Medical Staff') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const MedicalStaffSignUpScreen()),
                            );
                          } 
                          
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

