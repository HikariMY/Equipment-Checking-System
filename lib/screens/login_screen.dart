import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      String inputId = _idController.text.trim();
      String inputPassword = _passwordController.text.trim();

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(inputId).get();

        if (mounted) {
          if (userDoc.exists) {
            String dbPassword = userDoc.get('password');
            
            if (inputPassword == dbPassword) {
              // เช็คว่าเป็นแอดมินหรือไม่
              bool isAdmin = (inputId == 'admin'); 

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainScreen(isAdmin: isAdmin)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ยินดีต้อนรับคุณ ${userDoc.get('name') ?? inputId}'), backgroundColor: Colors.green),
              );
            } else {
              _showError('รหัสผ่านไม่ถูกต้อง!');
            }
          } else {
            _showError('ไม่พบ Number ID นี้ในระบบ!');
          }
        }
      } catch (e) {
        if (mounted) _showError('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.inventory_2, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'ระบบตรวจเช็คครุภัณฑ์',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(height: 40),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _idController,
                          decoration: InputDecoration(
                            hintText: 'Number_ID',
                            prefixIcon: const Icon(Icons.person, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'กรุณากรอก Number ID' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'กรุณากรอก Password' : null,
                        ),
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : const Text('ลงชื่อเข้าใช้', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'ยังไม่มีบัญชี? สมัครสมาชิกที่นี่',
                            style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}