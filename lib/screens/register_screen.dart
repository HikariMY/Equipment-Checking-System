import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      String inputId = _idController.text.trim();
      String inputName = _nameController.text.trim();
      String inputPassword = _passwordController.text.trim();

      try {
        // เช็คก่อนว่ามี ID นี้ในระบบหรือยัง
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(inputId).get();

        if (userDoc.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Number ID นี้มีในระบบแล้ว!'), backgroundColor: Colors.redAccent),
            );
          }
        } else {
          // ถ้ายังไม่มี ให้สร้าง User ใหม่ลง Database
          await FirebaseFirestore.instance.collection('users').doc(inputId).set({
            'name': inputName,
            'password': inputPassword,
            'created_at': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('สมัครสมาชิกสำเร็จ! กรุณาล็อกอิน'), backgroundColor: Colors.green),
            );
            Navigator.pop(context); // กลับไปหน้า Login
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('สมัครสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.person_add, size: 60, color: Color(0xFF1D4ED8)),
                    const SizedBox(height: 24),
                    
                    // ช่อง Number_ID
                    TextFormField(
                      controller: _idController,
                      decoration: InputDecoration(
                        hintText: 'ตั้ง Number_ID (ใช้สำหรับล็อกอิน)',
                        prefixIcon: const Icon(Icons.badge, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'กรุณากรอก Number ID' : null,
                    ),
                    const SizedBox(height: 16),

                    // ช่อง ชื่อ-นามสกุล
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'ชื่อ-นามสกุล',
                        prefixIcon: const Icon(Icons.person, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 16),

                    // ช่อง Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'ตั้ง Password',
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
                    ),
                    const SizedBox(height: 32),

                    // ปุ่มสมัครสมาชิก
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ยืนยันการสมัคร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}