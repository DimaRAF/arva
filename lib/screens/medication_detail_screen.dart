import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationDetailScreen extends StatefulWidget {
  final String patientId;
  final String medId;
  final bool isDoctorView; 

  const MedicationDetailScreen({
    super.key,
    required this.patientId,
    required this.medId,
    required this.isDoctorView,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  Map<String, dynamic>? medData;
  bool isLoading = true;
  bool isEditing = false;

  final doseController = TextEditingController();
  final freqController = TextEditingController();
  final durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Await an asynchronous operation.
      final doc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(widget.patientId)
          .collection('medications')
          .doc(widget.medId)
          .get();

      // Branch on a condition that affects logic flow.
      if (doc.exists) {
        medData = doc.data();

        final approvedDosage = medData?['dosage'];
        final approvedFreq = medData?['frequency'];
        final approvedDuration = medData?['duration'];

        final pendingDosage = medData?['pending_dosage'];
        final pendingFreq = medData?['pending_frequency'];
        final pendingDuration = medData?['pending_duration'];

        
        // Branch on a condition that affects logic flow.
        if (widget.isDoctorView) {
          doseController.text =
              (pendingDosage ?? approvedDosage ?? '').toString();
          freqController.text =
              (pendingFreq ?? approvedFreq ?? '').toString();
          durationController.text =
              (pendingDuration ?? approvedDuration ?? '').toString();
        } else {
         
          doseController.text = (approvedDosage ?? '').toString();
          freqController.text = (approvedFreq ?? '').toString();
          durationController.text = (approvedDuration ?? '').toString();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
    }
    setState(() => isLoading = false);
  }

  
  double? _parseDoseNumber(String text) {
    final match = RegExp(r'([\d\.]+)').firstMatch(text);
    // Branch on a condition that affects logic flow.
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  Future<void> _approveAndSave() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(widget.patientId)
          .collection('medications')
          .doc(widget.medId);

      final newDosage = doseController.text.trim();
      final newFreq = freqController.text.trim();
      final newDuration = durationController.text.trim();

     
      final numericDose = _parseDoseNumber(newDosage);
      // Branch on a condition that affects logic flow.
      if (numericDose != null && numericDose > 60000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⚠️ the dose is too high ,please check again.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Await an asynchronous operation.
      await docRef.update({
        
        'dosage': newDosage,
        'frequency': newFreq,
        'duration': newDuration,

        
        'pending_dosage': null,
        'pending_frequency': null,
        'pending_duration': null,
        'pending_test_name': null,
        'pending_test_value': null,
        'status': 'Approved', 
        'pending_updated_at': FieldValue.serverTimestamp(),

        'last_updated': FieldValue.serverTimestamp(),
      });

      setState(() => isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Changes approved and saved."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error saving changes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const double baseW = 393;
    final mq = MediaQuery.of(context);
    final double w = mq.size.width;
    final double s = w / baseW;
    final double safeTop = mq.padding.top;

    // Branch on a condition that affects logic flow.
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFCED5F7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5FAAB1)),
        ),
      );
    }

    final drugName = medData?['drug_name'] ?? 'Unknown Drug';
    final disease = medData?['disease'] ?? 'No Disease Info';
    final status = (medData?['status'] ?? '').toString();

    final displayDose =
        doseController.text.isEmpty ? '-' : doseController.text;
    final displayFreq = freqController.text;
    final displayDuration = durationController.text;

    
    String mainText;
    // Branch on a condition that affects logic flow.
    if (widget.isDoctorView) {
      mainText =
          'Based on the patient’s new test results, please review and approve or change the dose to $displayDose $displayFreq $displayDuration.';
    } else {
      // Branch on a condition that affects logic flow.
      if (status == 'Pending') {
       
        mainText =
            'Your doctor is reviewing an updated dose. Your current prescribed dose is $displayDose $displayFreq $displayDuration.';
      } else {
        mainText =
            'Your current prescribed dose is $displayDose $displayFreq $displayDuration.';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFCED5F7),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 320,
              child: ColoredBox(color: Color(0xFF5FAAB1)),
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
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
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
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20 * s,
                  ),
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
                    padding: EdgeInsets.fromLTRB(20 * s, 26 * s, 20 * s, 30 * s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Medication and Drugs',
                                  style: TextStyle(
                                    color: const Color(0xFF0E1B3D),
                                    fontSize: 22 * s,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 20 * s),

                               
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16 * s,
                                    horizontal: 10 * s,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5FAAB1),
                                    borderRadius:
                                        BorderRadius.circular(26 * s),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        drugName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20 * s,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6 * s),
                                      Text(
                                        disease,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13 * s,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 28 * s),

                                // Branch on a condition that affects logic flow.
                                if (!isEditing)
                                  Text(
                                    mainText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF2B2B2B),
                                      fontSize: 14 * s,
                                      fontWeight: FontWeight.w600,
                                      height: 1.6,
                                    ),
                                  )
                                else ...[
                                  _editableField("Dose", doseController, s),
                                  SizedBox(height: 12 * s),
                                  _editableField(
                                      "Frequency", freqController, s),
                                  SizedBox(height: 12 * s),
                                  _editableField(
                                      "Duration", durationController, s),
                                ],
                              ],
                            ),
                          ),
                        ),

                        
                        // Branch on a condition that affects logic flow.
                        if (widget.isDoctorView)
                          Padding(
                            padding: EdgeInsets.only(top: 20 * s),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Branch on a condition that affects logic flow.
                                if (!isEditing) ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          setState(() => isEditing = true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(22 * s),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16 * s,
                                        ),
                                      ),
                                      child: const Text(
                                        'Change Dose',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12 * s),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _approveAndSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF6B7FB0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(22 * s),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16 * s,
                                        ),
                                      ),
                                      child: const Text(
                                        'Approve',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _approveAndSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF6B7FB0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(22 * s),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16 * s,
                                        ),
                                      ),
                                      child: const Text(
                                        'Approve & Save',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
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

  Widget _editableField(
      String label, TextEditingController controller, double s) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10 * s),
        ),
      ),
    );
  }
}
