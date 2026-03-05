import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedType;
  String? _selectedStatus = 'ปกติ';
  bool _isLoading = false;

  final List<String> _assetTypes = ['อุปกรณ์คอมพิวเตอร์', 'อุปกรณ์สำนักงาน', 'เฟอร์นิเจอร์', 'อื่นๆ'];
  final List<String> _statusList = ['ปกติ', 'ชำรุดรอซ่อม', 'จำหน่ายออก'];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30, 
      maxWidth: 600,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        String base64String = '';

        if (_imageFile != null) {
          List<int> imageBytes = await _imageFile!.readAsBytes();
          base64String = base64Encode(imageBytes);
        }

        await FirebaseFirestore.instance.collection('assets').doc(_idController.text).set({
          'name': _nameController.text,
          'type': _selectedType ?? '',
          'brand': _brandController.text,
          'location': _locationController.text,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'status': _selectedStatus,
          'image_base64': base64String, 
          'purchase_date': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกข้อมูลและรูปภาพสำเร็จ!'), backgroundColor: Colors.green),
          );
        }

        // ก่อนจะ reset เราเอา focus ออกก่อนจะได้ไม่ error
        FocusScope.of(context).unfocus();
        _formKey.currentState!.reset();
        _idController.clear();
        _nameController.clear();
        _brandController.clear();
        _locationController.clear();
        _priceController.clear();
        setState(() {
          _selectedType = null;
          _selectedStatus = 'ปกติ';
          _imageFile = null;
        });

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มครุภัณฑ์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('แตะเพื่อเลือกรูปภาพ', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null, 
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(labelText: 'รหัสครุภัณฑ์ *', border: OutlineInputBorder()),
                    // --- จุดที่แก้ Error อยู่ตรงนี้ครับ ---
                    validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกรหัสครุภัณฑ์' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'ชื่อครุภัณฑ์ *', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกชื่อครุภัณฑ์' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'ประเภท *', border: OutlineInputBorder()),
                    value: _selectedType,
                    items: _assetTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (value) => value == null ? 'กรุณาเลือกประเภท' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'ยี่ห้อ', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'ที่ตั้ง *', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกที่ตั้ง' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'สถานะ *', border: OutlineInputBorder()),
                    value: _selectedStatus,
                    items: _statusList.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                    onChanged: (value) => setState(() => _selectedStatus = value),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveAsset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}