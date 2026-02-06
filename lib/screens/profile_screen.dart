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

  
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    // Branch on a condition that affects logic flow.
    if (user != null) {
      try {
        // Await an asynchronous operation.
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        // Branch on a condition that affects logic flow.
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      } catch (e) {
        // Branch on a condition that affects logic flow.
        if (mounted) setState(() => _isLoading = false);
        debugPrint("Error fetching user data: $e");
      }
    } else {
      // Branch on a condition that affects logic flow.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  void _showEditNameDialog() {
    final controller =
        TextEditingController(text: _userData?['username'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Username"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();

              // Branch on a condition that affects logic flow.
              if (newName.isEmpty) {
                // Branch on a condition that affects logic flow.
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Username cannot be empty."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              
              final lettersOnly =
                  RegExp(r'^[A-Za-z\u0600-\u06FF\s]+$'); 
              // Branch on a condition that affects logic flow.
              if (!lettersOnly.hasMatch(newName)) {
                // Branch on a condition that affects logic flow.
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text("Username must contain letters only (no numbers or symbols)."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                // Branch on a condition that affects logic flow.
                if (user != null) {
                  // Await an asynchronous operation.
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'username': newName});

                  // Branch on a condition that affects logic flow.
                  if (mounted) {
                    setState(() {
                      _userData = {...?_userData, 'username': newName};
                    });
                  }
                }

                // Branch on a condition that affects logic flow.
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Username updated successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Branch on a condition that affects logic flow.
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to update username: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

 
  Future<void> _signOut() async {
    try {
      // Await an asynchronous operation.
      await FirebaseAuth.instance.signOut();
      // Branch on a condition that affects logic flow.
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
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      
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

                     
                      _buildProfileOption(
                        icon: Icons.edit_outlined,
                        title: "Edit Profile",
                        onTap: _showEditNameDialog,
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
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3E5B7A)),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? () {},
    );
  }
}
