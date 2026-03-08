import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditAssetScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> assetData;

  const EditAssetScreen({super.key, required this.docId, required this.assetData});

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  late String _selectedType;
  late String _selectedStatus;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // ตัวแปรสำหรับรูปภาพ
  Uint8List? _imageBytes;
  String _imageBase64 = '';

  final List<String> _types = ['อุปกรณ์คอมพิวเตอร์', 'อุปกรณ์สำนักงาน', 'เฟอร์นิเจอร์', 'อื่นๆ'];
  final List<String> _statuses = ['ปกติ', 'ชำรุดรอซ่อม', 'จำหน่ายออก'];

  @override
  void initState() {
    super.initState();
    _idController.text = widget.docId;
    _nameController.text = widget.assetData['name'] ?? '';
    _brandController.text = widget.assetData['brand'] ?? '';
    _locationController.text = widget.assetData['location'] ?? '';
    _priceController.text = (widget.assetData['price'] ?? 0).toString();
    
    _selectedType = _types.contains(widget.assetData['type']) ? widget.assetData['type'] : _types[0];
    _selectedStatus = _statuses.contains(widget.assetData['status']) ? widget.assetData['status'] : _statuses[0];

    if (widget.assetData['purchase_date'] != null && widget.assetData['purchase_date'] is Timestamp) {
      _selectedDate = (widget.assetData['purchase_date'] as Timestamp).toDate();
      _dateController.text = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year + 543}";
    }

    // ดึงรูปเก่ามาใส่ตัวแปร
    if (widget.assetData['image_base64'] != null && widget.assetData['image_base64'].toString().isNotEmpty) {
      _imageBase64 = widget.assetData['image_base64'];
    }
  }

  // ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now(),
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

  Future<void> _updateData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('assets').doc(widget.docId).update({
          'name': _nameController.text.trim(),
          'type': _selectedType,
          'brand': _brandController.text.trim(),
          'location': _locationController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'status': _selectedStatus,
          'image_base64': _imageBase64, // อัปเดตรูปภาพ
          'purchase_date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isRequired = false, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, readOnly: readOnly,
          validator: isRequired && !readOnly ? (value) => value!.isEmpty ? 'กรุณากรอกข้อมูล' : null : null,
          decoration: InputDecoration(
            filled: true, fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade100,
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
          value: value, items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: onChanged,
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
        title: const Text('แก้ไขข้อมูลครุภัณฑ์', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ส่วนแก้ไขรูปภาพ ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _imageBytes != null 
                              ? Image.memory(_imageBytes!, fit: BoxFit.cover) // โชว์รูปที่เพิ่งเลือกใหม่
                              : (_imageBase64.isNotEmpty 
                                  ? Image.memory(base64Decode(_imageBase64), fit: BoxFit.cover) // โชว์รูปเก่า
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                      ],
                                    )),
                        ),
                      ),
                      // ไอคอนกล้องเล็กๆ มุมขวาล่างบอกว่ากดเปลี่ยนได้
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField('รหัสครุภัณฑ์ (ไม่สามารถแก้ไขได้)', _idController, readOnly: true),
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
                  onPressed: _isLoading ? null : _updateData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('บันทึกการแก้ไข', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}