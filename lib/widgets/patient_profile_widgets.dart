// lib/widgets/patient_profile_widgets.dart

import 'package:flutter/material.dart';

// --- الويدجت الأول: شبكة المعلومات ---
class PatientInfoGrid extends StatelessWidget {
  final Map<String, dynamic>? patientData;
  final Function(String, String, {bool isNumeric}) onCardTap;

  const PatientInfoGrid({
    super.key,
    required this.patientData,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _buildInfoCard(
          title: 'Blood Group',
          value: patientData?['blood_group'] ?? '--',
          icon: Icons.bloodtype,
          color: const Color(0xFFFBE0E0),
          iconColor: Colors.red,
          onTap: () => onCardTap('blood_group', 'Blood Group'),
        ),
        _buildInfoCard(
          title: 'Weight',
          value: '${patientData?['weight'] ?? '--'} kg',
          icon: Icons.fitness_center,
          color: const Color(0xFFBFE0E2),
          iconColor: Colors.green.shade700,
          onTap: () => onCardTap('weight', 'Weight', isNumeric: true),
        ),
        _buildInfoCard(
          title: 'Height',
          value: '${patientData?['height'] ?? '--'} cm',
          icon: Icons.height,
          color: const Color(0xFFBFE0E2),
          iconColor: Colors.green.shade700,
          onTap: () => onCardTap('height', 'Height', isNumeric: true),
        ),
        _buildInfoCard(
          title: 'Age',
          value: '${patientData?['age'] ?? '--'}',
          icon: Icons.cake_outlined,
          color: const Color(0xFFE0E6F8),
          iconColor: Colors.blue.shade700,
          onTap: () => onCardTap('age', 'Age', isNumeric: true),
        ),
      ],
    );
  }

  // دالة بناء كرت المعلومات
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor),
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- الويدجت الثاني: قائمة الخدمات ---
class PatientServicesRow extends StatelessWidget {
  final BuildContext parentContext;

  const PatientServicesRow({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildServiceButton(
              imagePath: 'assets/analysis.png',
              label: 'analysis',
              onTap: () {
    //                 final currentUser = FirebaseAuth.instance.currentUser;
    // if (currentUser != null) {
    //   Navigator.of(parentContext).push(
    //     MaterialPageRoute(builder: (context) => MedicalReportHomeScreen(
    //       role: UserRole.patient, // الدور: مريض
    //       patientId: currentUser.uid, // هويته: هوية المستخدم الحالي
    //     )),
    //   );
    // }
              },
            ),
            _buildServiceButton(imagePath: 'assets/drugs.png', label: 'Drugs', onTap: () {}),
            _buildServiceButton(imagePath: 'assets/report.png', label: 'Report', onTap: () {}),
          ],
        ),
      ],
    );
  }

  // دالة بناء زر الخدمات
  Widget _buildServiceButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Image.asset(imagePath),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}