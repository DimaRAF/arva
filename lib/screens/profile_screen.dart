import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // لاستخدامه عند تسجيل الخروج

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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

  // دالة لجلب بيانات المستخدم الحالي
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        print("Error fetching user data: $e");
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- دالة تسجيل الخروج ---
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // بعد تسجيل الخروج، أغلق كل الشاشات واذهب إلى MainPage
      // MainPage ستقوم تلقائياً بتوجيهك إلى مسار تسجيل الدخول
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error signing out: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF75B5B6),
      ),
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                
                // كرت معلومات المستخدم
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // 1. تم تغيير اللون إلى الأبيض
                    color: const Color(0xFF75B5B6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundImage: AssetImage('assets/doctor_avatar.png'),
                        backgroundColor: Color(0xFF75B5B6),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData?['username'] ?? 'User',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 255, 255, 255)),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _userData?['email'] ?? 'No email',
                            
                            style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 255, 253, 253)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // قائمة الخيارات
                _buildProfileOption(icon: Icons.edit_outlined, title: "Edit Profile"),
                _buildProfileOption(icon: Icons.settings_outlined, title: "Settings"),
                _buildProfileOption(icon: Icons.help_outline, title: "Help & Support"),
                
                const Divider(height: 40),

                // زر تسجيل الخروج
                ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Log Out", style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // دالة مساعدة لبناء خيارات الملف الشخصي
  Widget _buildProfileOption({required IconData icon, required String title}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3E5B7A)),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}