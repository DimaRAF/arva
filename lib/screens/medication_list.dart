import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'medication_detail_screen.dart';

class MedicationScreen extends StatefulWidget {
  final String? patientId;
  const MedicationScreen({super.key, this.patientId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  String? currentUid;
  String? userRole; // لتحديد الدور

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser?.uid;
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (currentUid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    if (doc.exists) {
      setState(() {
        userRole = doc.data()?['role']; // "Medical Staff" أو "Patient"
      });
    }
  }

  Stream<QuerySnapshot> getDrugsStream() {
    final uid = widget.patientId ?? currentUid;
    return FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(uid)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _addNewDrugDialog() async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final freqController = TextEditingController();
    final diseaseController = TextEditingController();
    final durationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Drug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Drug Name'),
              ),
              TextField(
                controller: diseaseController,
                decoration: const InputDecoration(labelText: 'Disease'),
              ),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(labelText: 'Dose (e.g. 500mg)'),
              ),
              TextField(
                controller: freqController,
                decoration: const InputDecoration(labelText: 'Frequency (e.g. Daily)'),
              ),
              TextField(
                controller: durationController,
                decoration:
                    const InputDecoration(labelText: 'Duration (e.g. 7 days)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  doseController.text.isEmpty ||
                  freqController.text.isEmpty ||
                  diseaseController.text.isEmpty ||
                  durationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠ Please fill all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final uid = widget.patientId ?? currentUid;
              if (uid == null) return;

              // 🟢 أسماء الحقول الجديدة + حقول الـ pending جاهزة للمودل
              final newDrug = {
                'drug_name': nameController.text.trim(),
                'disease': diseaseController.text.trim(),
                'dosage': doseController.text.trim(),
                'frequency': freqController.text.trim(),
                'duration': durationController.text.trim(),

                'test_name': null,
                'last_value': null,

                'pending_dosage': null,
                'pending_frequency': null,
                'pending_duration': null,
                'pending_test_name': null,
                'pending_test_value': null,
                'pending_status': null,

                'status': 'Pending', // تقدرِ تغيرينها لـ "Active" لو حابة
                'createdAt': Timestamp.now(),
              };

              await FirebaseFirestore.instance
                  .collection('patient_profiles')
                  .doc(uid)
                  .collection('medications')
                  .add(newDrug);

              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Drug added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double baseW = 393;
    final mq = MediaQuery.of(context);
    final double w = mq.size.width;
    final double s = w / baseW;
    final double safeTop = mq.padding.top;

    final bool isDoctor = userRole == "Medical Staff";

    return Scaffold(
      backgroundColor: const Color(0xFFCED5F7),
      floatingActionButton: isDoctor
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF5FAAB1),
              onPressed: _addNewDrugDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFCED5F7))),
            Positioned(
              top: -safeTop,
              left: 0,
              right: 0,
              height: (320 * s) + safeTop,
              child: const ColoredBox(color: Color(0xFF5FAAB1)),
            ),
            Positioned(
              right: 28 * s,
              top: safeTop + 50 * s,
              child: Image.asset(
                'assets/medicine_box.png',
                width: 172 * s,
                height: 172 * s,
              ),
            ),
            Positioned(
              left: 78 * s,
              top: safeTop + 115 * s,
              child: Image.asset(
                'assets/Thermometer.png',
                width: 80 * s,
                height: 58 * s,
              ),
            ),
            Positioned(
              right: 18 * s,
              top: safeTop + 30 * s,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44 * s,
                  height: 44 * s,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6B4DE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 30 * s,
                        offset: Offset(0, 4 * s),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_forward,
                      color: Colors.white, size: 20 * s),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: baseW * s,
                margin: EdgeInsets.only(top: 280 * s),
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8 * s,
                        offset: Offset(0, 4 * s),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(20 * s, 26 * s, 20 * s, 20 * s),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Medication & Drugs',
                              style: TextStyle(
                                color: const Color(0xFF0E1B3D),
                                fontSize: 22 * s,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          SizedBox(height: 18 * s),

                          // 🔹 قائمة الأدوية
                          StreamBuilder<QuerySnapshot>(
                            stream: getDrugsStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                    child: Text("No medications found."));
                              }

                              final docs = snapshot.data!.docs;
                              return Column(
                                children: docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final docId = doc.id;

                                  // 🟢 أسماء الحقول الجديدة + fallback لو فيه بيانات قديمة
                                  final String drugName =
                                      (data['drug_name'] ??
                                              data['drugName'] ??
                                              'Unknown Drug')
                                          .toString();
                                  final String disease =
                                      (data['disease'] ??
                                              data['Diseas'] ??
                                              'Unknown Disease')
                                          .toString();

                                  // جرعة/مدة/تكرار مع مراعاة pending
                                  String baseDosage =
                                      (data['dosage'] ?? data['dose'] ?? '-')
                                          .toString();
                                  String baseFreq =
                                      (data['frequency'] ?? '-').toString();
                                  String baseDuration =
                                      (data['duration'] ??
                                              data['Duration'] ??
                                              '-')
                                          .toString();

                                  final String pendingDosage =
                                      (data['pending_dosage'] ?? '')
                                          .toString();
                                  final String pendingFreq =
                                      (data['pending_frequency'] ?? '')
                                          .toString();
                                  final String pendingDuration =
                                      (data['pending_duration'] ?? '')
                                          .toString();

                                  // المريض يشوف فقط المعتمَد
                                  // الدكتور يشوف الـ pending لو موجودة
                                  final String shownDosage = isDoctor
                                      ? (pendingDosage.isNotEmpty
                                          ? pendingDosage
                                          : baseDosage)
                                      : baseDosage;
                                  final String shownFreq = isDoctor
                                      ? (pendingFreq.isNotEmpty
                                          ? pendingFreq
                                          : baseFreq)
                                      : baseFreq;
                                  final String shownDuration = isDoctor
                                      ? (pendingDuration.isNotEmpty
                                          ? pendingDuration
                                          : baseDuration)
                                      : baseDuration;

                                  final String subtitle =
                                      "$shownDosage • $shownFreq • $shownDuration";

                                  final String pendingStatus =
                                      (data['pending_status'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final String status =
                                      (data['status'] ?? '').toString();

                                  // 🟡 نحط علامة تحذير لو فيه pending، للطبيب فقط
                                  final bool warning = isDoctor &&
                                      (pendingStatus == 'pending' ||
                                          status == 'Pending');

                                  return Padding(
                                    padding:
                                        EdgeInsets.only(bottom: 16 * s),
                                    child: _PillCard(
                                      title: drugName,
                                      disease: disease,
                                      subtitle: subtitle,
                                      color: const Color(0xFF5FAAB1),
                                      height: 92 * s,
                                      radius: 26 * s,
                                      warning: warning,
                                      s: s,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                MedicationDetailScreen(
                                              patientId: (widget.patientId ??
                                                  currentUid)!,
                                              medId: docId,
                                              isDoctorView: isDoctor,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillCard extends StatelessWidget {
  final String title;
  final String disease;
  final String subtitle;
  final Color color;
  final bool warning;
  final double s;
  final double height;
  final double radius;
  final VoidCallback onTap;

  const _PillCard({
    required this.title,
    required this.disease,
    required this.subtitle,
    required this.color,
    required this.warning,
    required this.s,
    required this.height,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: height, maxHeight: 130 * s),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 10 * s),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4 * s),
                  Text(
                    disease,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (warning)
              Container(
                width: 26 * s,
                height: 26 * s,
                decoration: const BoxDecoration(
                  color: Color(0xFFFB6E6E),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline,
                    color: Colors.white, size: 15 * s),
              )
            else
              const SizedBox(width: 26),
            SizedBox(width: 12 * s),
            Icon(Icons.chevron_right, color: Colors.white, size: 24 * s),
          ],
        ),
      ),
    );
  }
}
