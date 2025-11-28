import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // جلب بيانات المستخدم الحالي
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        debugPrint("Error fetching user data: $e");
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // تسجيل الخروج
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // نحدد الدور عشان نختار الصورة
    final String role = (_userData?['role'] ?? '') as String;
    final bool isPatient = role == 'Patient';

    final String avatarAsset = isPatient
        ? 'assets/patient_icon.png'
        : 'assets/doctor_avatar.png';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF75B5B6),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
      ),
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // المحتوى القابل للسكرول
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      // كرت معلومات المستخدم
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF75B5B6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: const Color(0xFF75B5B6),
                              child: Padding(
                                padding: const EdgeInsets.all(1.0),
                                child: Image.asset(
                                  avatarAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userData?['username'] ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _userData?['email'] ?? 'No email',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // قائمة الخيارات
                      _buildProfileOption(
                        icon: Icons.edit_outlined,
                        title: "Edit Profile",
                      ),
                      _buildProfileOption(
                        icon: Icons.settings_outlined,
                        title: "Settings",
                      ),
                      _buildProfileOption(
                        icon: Icons.help_outline,
                        title: "Help & Support",
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // زر تسجيل الخروج ثابت في أسفل الصفحة
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3E5B7A)),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
