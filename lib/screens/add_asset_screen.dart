import 'dart:convert';
import 'dart:typed_data';
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
  final TextEditingController _dateController = TextEditingController();

  String _selectedType = 'อุปกรณ์สำนักงาน';
  String _selectedStatus = 'ปกติ';
  DateTime? _selectedDate;
  bool _isLoading = false;

  // ตัวแปรสำหรับรูปภาพ
  Uint8List? _imageBytes;
  String _imageBase64 = '';

  final List<String> _types = ['อุปกรณ์คอมพิวเตอร์', 'อุปกรณ์สำนักงาน', 'เฟอร์นิเจอร์', 'อื่นๆ'];
  final List<String> _statuses = ['ปกติ', 'ชำรุดรอซ่อม', 'จำหน่ายออก'];

  // ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // บีบอัดรูปนิดหน่อยเพื่อไม่ให้ Base64 ยาวเกินไปจน Database บวม
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageBase64 = base64Encode(bytes); // แปลงเป็น Base64
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1D4ED8), onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year + 543}";
      });
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('assets').doc(_idController.text.trim()).set({
          'name': _nameController.text.trim(),
          'type': _selectedType,
          'brand': _brandController.text.trim(),
          'location': _locationController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'status': _selectedStatus,
          'purchase_date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : FieldValue.serverTimestamp(),
          'image_base64': _imageBase64, // บันทึกรูป Base64 ลงฐานข้อมูล
          'created_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!'), backgroundColor: Colors.green));
          
          // ล้างข้อมูลทั้งหมด
          _idController.clear(); _nameController.clear(); _brandController.clear();
          _locationController.clear(); _priceController.clear(); _dateController.clear();
          setState(() {
            _selectedDate = null;
            _selectedType = _types[0];
            _selectedStatus = _statuses[0];
            _imageBytes = null; // ล้างรูปภาพ
            _imageBase64 = '';
          });
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: isRequired ? (value) => value!.isEmpty ? 'กรุณากรอกข้อมูล' : null : null,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1D4ED8))),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1D4ED8))),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลครุภัณฑ์', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black87), automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ส่วนอัปโหลดรูปภาพ ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField('รหัสครุภัณฑ์ *', _idController, isRequired: true),
              _buildTextField('ชื่อครุภัณฑ์ *', _nameController, isRequired: true),
              _buildDropdown('ประเภท *', _selectedType, _types, (value) => setState(() => _selectedType = value!)),
              _buildTextField('ยี่ห้อ *', _brandController, isRequired: true),
              _buildTextField('ที่ตั้ง *', _locationController, isRequired: true),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('วันที่จัดซื้อ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dateController, readOnly: true, onTap: () => _selectDate(context),
                          decoration: InputDecoration(
                            hintText: 'เลือกวันที่', filled: true, fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('ราคา(บาท)', _priceController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 0), 
              _buildDropdown('สถานะ *', _selectedStatus, _statuses, (value) => setState(() => _selectedStatus = value!)),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8), padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}