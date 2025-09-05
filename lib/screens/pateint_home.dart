import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  // متغير لحفظ بيانات المستخدم
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  // --- دالة لجلب بيانات المريض الحالي من Firestore ---
  Future<void> _fetchPatientData() async {
    // الحصول على المستخدم الحالي
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // قراءة الملف الذي يطابق userId الخاص بالمستخدم
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('patient_profiles')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _patientData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          // في حال لم يتم العثور على بيانات للمستخدم
          setState(() {
            _isLoading = false;
          });
          print("No data found for this patient.");
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print("Error fetching patient data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patientData == null
              ? const Center(child: Text("No patient data available."))
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    _buildBody(),
                  ],
                ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- الأجزاء المختلفة للواجهة ---

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      backgroundColor: const Color(0xFF5A9D9D),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // الشكل المنحني في الخلفية
            Positioned.fill(
              child: ClipPath(
                clipper: AppBarClipper(),
                child: Container(color: Colors.white),
              ),
            ),
            // محتوى الـ AppBar
            Padding(
              padding: const EdgeInsets.all(20.0).copyWith(top: 60),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF3E5B7A)),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Hi,", style: TextStyle(color: Colors.white, fontSize: 18)),
                      Text(
                        _patientData?['username'] ?? 'User',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildBody() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط البحث
            TextField(
              decoration: InputDecoration(
                hintText: 'search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.close),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // عنوان "here's your smartfile"
            const Text(
              "here's your smartfile ! ✨",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // الشبكة التي تحتوي على بيانات المريض
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                _buildInfoCard(
                  title: 'Blood Group',
                  value: _patientData?['blood_group'] ?? 'N/A',
                  icon: Icons.bloodtype,
                  color: const Color(0xFFFBE0E0),
                  iconColor: Colors.red,
                ),
                _buildInfoCard(
                  title: 'Weight',
                  value: '${_patientData?['weight'] ?? 0} kg',
                  icon: Icons.fitness_center,
                  color: const Color(0xFFD4EFDF),
                  iconColor: Colors.green,
                ),
                _buildInfoCard(
                  title: 'Height',
                  value: '${_patientData?['height'] ?? 0} cm',
                  icon: Icons.height,
                  color: const Color(0xFFD4EFDF),
                  iconColor: Colors.green,
                ),
                _buildInfoCard(
                  title: 'Age',
                  value: '${_patientData?['age'] ?? 0}',
                  icon: Icons.cake,
                  color: const Color(0xFFE0E6F8),
                  iconColor: Colors.blue.shade700,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // عنوان "Services"
            const Text(
              "Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // أزرار الخدمات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildServiceButton(icon: Icons.science_outlined, label: 'analysis'),
                _buildServiceButton(icon: Icons.medical_services_outlined, label: 'Drugs'),
                _buildServiceButton(icon: Icons.receipt_long_outlined, label: 'Report'),
              ],
            )
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0,
      selectedItemColor: const Color(0xFF3E5B7A),
      // onTap: _onItemTapped,
    );
  }

  // --- دوال مساعدة لبناء الويدجتس الصغيرة ---

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
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
    );
  }

  Widget _buildServiceButton({required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: 35, color: const Color(0xFF3E5B7A)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}


// كلاس لرسم الشكل المنحني في الـ AppBar
class AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 4, size.height - 40, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 / 4 * size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
