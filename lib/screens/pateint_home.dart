import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'uploud_medical_report.dart';
import 'medication_list.dart';
import 'medication_approval_listener.dart'; 
import 'lab_files_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final String patientId;
  const PatientHomeScreen({super.key, required this.patientId});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  String? _currentUserRole;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _HomePageContent(
        patientId: widget.patientId,
        onRoleLoaded: (role) {
          setState(() {
            _currentUserRole = role; // ✅ هنا يتم تحديث الدور في الأب
          });
        },
      ),
      const Center(child: Text("Search Page", style: TextStyle(fontSize: 24))),
      const ProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // ⬇️ أخفي البار للميديكال ستاف كما هو
      bottomNavigationBar:
          _currentUserRole == 'Medical Staff' ? null : _buildBottomNavBar(),

      // ⬇️ زر دائري أزرق بأسفل اليسار للميديكال ستاف فقط
      floatingActionButton: _currentUserRole == 'Medical Staff'
          ? FloatingActionButton(
              heroTag: 'docBackFab',
              shape: const CircleBorder(),
              backgroundColor: const Color(0xFF4C6EA0),
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // دالة بناء شريط التنقل السفلي
  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF4C6EA0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home, index: 0),
          _buildNavItem(icon: Icons.search, index: 1),
          _buildNavItem(icon: Icons.person, index: 2),
        ],
      ),
    );
  }

  // دالة بناء كل أيقونة في شريط التنقل
  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        // عند الضغط، قم بتحديث الفهرس المحدد لإظهار الصفحة الصحيحة
        setState(() {
          _selectedIndex = index;
        });
      },
      child: isSelected
          ? Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4C6EA0), // لون الدائرة المرتفعة
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
            )
          : Icon(icon, color: Colors.white.withOpacity(0.7), size: 30),
    );
  }
}

// --- تم إنشاء هذا الويدجت الجديد ليحتوي على كل محتوى الصفحة الرئيسية ---
// هذا يجعل الكود منظماً وسهل القراءة
class _HomePageContent extends StatefulWidget {
  final String patientId;
  final Function(String)? onRoleLoaded;
  const _HomePageContent({required this.patientId, this.onRoleLoaded});

  @override
  State<_HomePageContent> createState() => __HomePageContentState();
}

class __HomePageContentState extends State<_HomePageContent> {
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    // ✅ تشغيل الليسنر لموافقة الأدوية للمريض الحالي
    MedicationApprovalListener.instance.startListening();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final patientId = widget.patientId;

      // ✅ جلب المستخدم الحالي لمعرفة إذا كان طبيب أو مريض
      final currentUser = FirebaseAuth.instance.currentUser;
      String? currentUserRole;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        currentUserRole = userDoc.data()?['role'];
      }

      // 1. جلب البيانات من كلا المجموعتين (users و patient_profiles)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(patientId)
          .get();

      // 2. دمج البيانات في خريطة واحدة
      Map<String, dynamic> combinedData = {};
      if (userDoc.exists && userDoc.data() != null) {
        combinedData.addAll(userDoc.data() as Map<String, dynamic>);
      }
      if (profileDoc.exists && profileDoc.data() != null) {
        combinedData.addAll(profileDoc.data() as Map<String, dynamic>);
      }

      // ✅ حفظ الدور الحالي للمستخدم (عشان نستخدمه في الواجهة)
      if (mounted) {
        setState(() {
          _patientData = combinedData;
          _currentUserRole = currentUserRole;
        });
        if (widget.onRoleLoaded != null && currentUserRole != null) {
          widget.onRoleLoaded!(currentUserRole);
        }
      }
    } catch (e) {
      print("❌ Error fetching patient data: $e");
    }

    // 4. إيقاف التحميل
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- vvv دالة جديدة لحفظ التعديلات في قاعدة البيانات vvv ---
  Future<void> _updatePatientProfile(String field, dynamic value) async {
    User? user = FirebaseAuth.instance.currentUser;
    final patientId = widget.patientId;
    if (user == null) return;

    // تحويل القيمة إلى رقم إذا كان الحقل يتطلب ذلك
    if (field == 'age' || field == 'height' || field == 'weight') {
      value = int.tryParse(value.toString()) ?? 0;
    }

    try {
      await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(patientId)
          .update({field: value});

      // إعادة جلب البيانات لتحديث الواجهة
      await _fetchPatientData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to update profile: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- vvv دالة جديدة لإظهار نافذة التعديل vvv ---
  void _showEditDialog(String fieldKey, String title,
      {bool isNumeric = false}) {
    final controller = TextEditingController(
        text: _patientData?[fieldKey]?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update $title"),
        content: TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _updatePatientProfile(fieldKey, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF3E5B7A))))
        : SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 155,
                      width: double.infinity,
                      color: const Color(0xFF5FAAB1),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 30.0,
                              left: 20.0,
                              right: 20.0), // 👈 نزّل البحث شوي
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'search',
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.grey),
                              suffixIcon: const Icon(Icons.close,
                                  color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 175,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.93,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C6EA0),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25)),
                              child: const Icon(Icons.person,
                                  size: 45, color: Color(0xFF3E5B7A)),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_currentUserRole == 'Medical Staff') ...[
                                  const Text(
                                    "Smart File",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _patientData?['username']
                                            ?.toUpperCase() ??
                                        'USER',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ] else ...[
                                  const Text("Hi,",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18)),
                                  Text(
                                    _patientData?['username']
                                            ?.toUpperCase() ??
                                        'USER',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.3,
                        children: [
                          _buildInfoCard(
                            title: 'Blood Group',
                            value: _patientData?['blood_group'] ?? '--',
                            icon: Icons.bloodtype,
                            color: const Color(0xFFFBE0E0),
                            iconColor: Colors.red,
                            onTap: () =>
                                _showEditDialog('blood_group', 'Blood Group'),
                          ),
                          _buildInfoCard(
                            title: 'Weight',
                            value:
                                '${_patientData?['weight'] ?? '--'} kg',
                            icon: Icons.fitness_center,
                            color: const Color(0xFFBFE0E2),
                            iconColor: Colors.green.shade700,
                            onTap: () => _showEditDialog(
                                'weight', 'Weight',
                                isNumeric: true),
                          ),
                          _buildInfoCard(
                            title: 'Height',
                            value:
                                '${_patientData?['height'] ?? '--'} cm',
                            icon: Icons.height,
                            color: const Color(0xFFBFE0E2),
                            iconColor: Colors.green.shade700,
                            onTap: () => _showEditDialog(
                                'height', 'Height',
                                isNumeric: true),
                          ),
                          _buildInfoCard(
                            title: 'Age',
                            value: '${_patientData?['age'] ?? '--'}',
                            icon: Icons.cake_outlined,
                            color: const Color(0xFFE0E6F8),
                            iconColor: Colors.blue.shade700,
                            onTap: () => _showEditDialog(
                                'age', 'Age',
                                isNumeric: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text("Services",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildServiceButton(
                            imagePath: 'assets/analysis.png',
                            label: 'analysis',
                            onTap: () {
                              // 2. عند الضغط، انتقل إلى الواجهة الجديدة
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MedicalReportHomeScreen(
                                          patientId: widget.patientId),
                                ),
                              );
                            },
                          ),
                          _buildServiceButton(
                            imagePath: 'assets/drugs.png',
                            label: 'Drugs',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationScreen(
                                      patientId: widget.patientId),
                                ),
                              );
                            },
                          ),
                          _buildServiceButton(
                            imagePath: 'assets/report.png',
                            label: 'Report',
                            onTap: () {
                              Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MedicalReportsPage(patientId: widget.patientId),
  ),
);

                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  
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
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(25)),
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
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap, // 3. تم إضافة هذا السطر
  }) {
    // 4. تم تغليف الكرت بـ InkWell لجعله قابلاً للضغط
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
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
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
