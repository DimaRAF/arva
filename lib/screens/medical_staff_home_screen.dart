import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';


class MedicalStaffHomeScreen extends StatefulWidget {
  const MedicalStaffHomeScreen({Key? key}) : super(key: key);

  @override
  State<MedicalStaffHomeScreen> createState() => _MedicalStaffHomeScreenState();
}

class _MedicalStaffHomeScreenState extends State<MedicalStaffHomeScreen> {
  Map<String, dynamic>? _staffData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaffData();
  }

  Future<void> _fetchStaffData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _staffData = doc.data() as Map<String, dynamic>?;
          });
        }
      } catch (e) {
        print("Error fetching staff data: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                
                Expanded(
                  child: Stack(
                    children: [
                     
                      CustomPaint(
                        size: Size.infinite,
                        painter: BodyBackgroundPainter(),
                      ),
                      
                      _buildPatientsList(),
                    ],
                  ),
                ),
                
              ],
            ),
    );
  }

  
  Widget _buildHeader() {
    return Container(
      height: 280,
      color: const Color(0xFF75B5B6),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white, size: 30),
                 
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 30),
                    onPressed: () {
                      // عند الضغط، انتقل إلى شاشة الملف الشخصي
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                  
                ],
              ),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF75B5B6),
                backgroundImage: AssetImage('assets/doctor_avatar.png'),
              ),
              Column(
                children: [
                  Text(
                    _staffData?['username'] ?? 'Doctor',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
   
                 _staffData?['jobTitle'] ?? 'Medical Staff', // اقرأ المسمى الوظيفي من قاعدة البيانات
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildPatientsList() {
    final String currentDoctorId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patient_profiles')
          .where('assignedDoctorId', isEqualTo: currentDoctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("You have no assigned patients."));
        }
        var patients = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            var patientData = patients[index].data() as Map<String, dynamic>;
            
            return _buildPatientCard(
              name: patientData['username'] ?? 'N/A',
              room: "Room ${patientData['roomNumber'] ?? '--'}",
              // تم تمرير اللون مباشرة هنا
              iconBackgroundColor: index % 2 == 0 
                  ? const Color(0xFFE0E6F8) // اللون الأول
                  : const Color(0xFFFBE0E0), // اللون الثاني
              iconColor: index % 2 == 0 
                  ? const Color(0xFF6A8EAF) // لون الأيقونة الأول
                  : Colors.red, // لون الأيقونة الثاني
            );
          },
        );
      },
    );
  }

Widget _buildPatientCard({
    required String name,
    required String room,
    required Color iconBackgroundColor, // يستقبل لون الخلفية
    required Color iconColor,          // يستقبل لون الأيقونة
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: iconBackgroundColor,
            child: Icon(Icons.person_outline, size: 30, color: iconColor),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.king_bed_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(room, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF75B5B6);
     canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldClipper) => false;
}


class BodyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    
    final paint1 = Paint()..color = const Color(0xFFDADADA).withOpacity(0.5);
    final path1 = Path()
      ..moveTo(width, height * 0.5)
      
      ..cubicTo(
        width * 0.3, height * 0.4, 
        width * 0.1, height * 0.9, 
        width * -0.1, height    
      )
     
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(path1, paint1);  

    
    final paint2 = Paint()..color = const Color(0xFFC3C9F9).withOpacity(0.6);
    final path2 = Path()
      ..moveTo(0,height * 0.1 )
      ..cubicTo(
        width * 0.4, height * 0.2, 
        width * 0.6, height * 0.7, 
        width * -0.3, height  *0.7  
      )
      ..lineTo(0,height * 0.9)
      ..close();
    canvas.drawPath(path2, paint2);

     
    final paint3 = Paint()..color = const Color(0x8B5FAAB1).withOpacity(0.5);
    final path3 = Path()
      ..moveTo(width , 0)
      ..lineTo(width*0.6, height*0)  
      ..cubicTo(
      width * 0.3, height * 0.2,  
      width * 0.3, height * 0.2,  
      width * 0.5, height * 0.3  
      )

  
      ..cubicTo(
      width * 0.7, height * 0.4,  
      width * 0.6, height * 0.5,  
      width , height * 0.4
      )

      
      ..lineTo(width, height*.3)
      ..close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldClipper) => false;
}
