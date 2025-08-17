import 'package:flutter/material.dart';

class PatientInfoScreen extends StatelessWidget {
  const PatientInfoScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Information")),
      body: const Center(child: Text("Enter your personal details here.")),
    );
  }
}