import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditAssetScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;
  final bool isAdmin; 

  const EditAssetScreen({super.key, required this.docId, required this.currentData, required this.isAdmin});

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;

  String? _selectedType;
  String? _selectedStatus;
  String? _existingImageBase64;
  bool _isLoading = false;

  final List<String> _assetTypes = ['อุปกรณ์คอมพิวเตอร์', 'อุปกรณ์สำนักงาน', 'เฟอร์นิเจอร์', 'อื่นๆ'];
  final List<String> _statusList = ['ปกติ', 'ชำรุดรอซ่อม', 'จำหน่ายออก'];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData['name'] ?? '');
    _brandController = TextEditingController(text: widget.currentData['brand'] ?? '');
    _locationController = TextEditingController(text: widget.currentData['location'] ?? '');
    _priceController = TextEditingController(text: (widget.currentData['price'] ?? 0).toString());
    
    _selectedType = widget.currentData['type'];
    if (!_assetTypes.contains(_selectedType)) _selectedType = null;
    
    _selectedStatus = widget.currentData['status'];
    if (!_statusList.contains(_selectedStatus)) _selectedStatus = 'ปกติ';

    _existingImageBase64 = widget.currentData['image_base64'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 30, maxWidth: 600);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _updateAsset() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        String base64String = _existingImageBase64 ?? '';
        if (_imageFile != null) {
          List<int> imageBytes = await _imageFile!.readAsBytes();
          base64String = base64Encode(imageBytes);
        }

        await FirebaseFirestore.instance.collection('assets').doc(widget.docId).update({
          'name': _nameController.text, 'type': _selectedType ?? '', 'brand': _brandController.text,
          'location': _locationController.text, 'price': double.tryParse(_priceController.text) ?? 0.0,
          'status': _selectedStatus, 'image_base64': base64String, 
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _confirmDelete() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'), content: Text('คุณต้องการลบครุภัณฑ์ "${_nameController.text}" ใช่หรือไม่?\n(ข้อมูลจะไม่สามารถกู้คืนได้)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() { _isLoading = true; });
              try {
                await FirebaseFirestore.instance.collection('assets').doc(widget.docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบข้อมูลสำเร็จ!'), backgroundColor: Colors.redAccent));
                  Navigator.pop(context);
                }
              } catch (e) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบข้อมูล', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) return Image.file(_imageFile!, fit: BoxFit.cover);
    else if (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty) {
      try { return Image.memory(base64Decode(_existingImageBase64!), fit: BoxFit.cover); } catch (e) { return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)); }
    } else {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.camera_alt, size: 40, color: Colors.grey),
        const SizedBox(height: 8),
        Text(widget.isAdmin ? 'แตะเพื่อเปลี่ยนรูปภาพ' : 'ไม่มีรูปภาพ', style: const TextStyle(color: Colors.grey)),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'แก้ไขข้อมูลครุภัณฑ์' : 'รายละเอียดครุภัณฑ์', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          if (widget.isAdmin)
            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: _confirmDelete)
        ],
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
                    onTap: widget.isAdmin ? _pickImage : null, 
                    child: Container(
                      height: 150, clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid)),
                      child: _buildImagePreview(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    initialValue: widget.docId,
                    decoration: const InputDecoration(labelText: 'รหัสครุภัณฑ์', border: OutlineInputBorder(), fillColor: Colors.black12, filled: true),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController, readOnly: !widget.isAdmin, 
                    decoration: InputDecoration(labelText: 'ชื่อครุภัณฑ์', border: const OutlineInputBorder(), filled: !widget.isAdmin, fillColor: widget.isAdmin ? null : Colors.grey[100]),
                    validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกชื่อครุภัณฑ์' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'ประเภท', border: const OutlineInputBorder(), filled: !widget.isAdmin, fillColor: widget.isAdmin ? null : Colors.grey[100]),
                    value: _selectedType,
                    items: _assetTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: widget.isAdmin ? (value) => setState(() => _selectedType = value) : null, 
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _brandController, readOnly: !widget.isAdmin,
                    decoration: InputDecoration(labelText: 'ยี่ห้อ', border: const OutlineInputBorder(), filled: !widget.isAdmin, fillColor: widget.isAdmin ? null : Colors.grey[100]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController, readOnly: !widget.isAdmin,
                    decoration: InputDecoration(labelText: 'ที่ตั้ง', border: const OutlineInputBorder(), filled: !widget.isAdmin, fillColor: widget.isAdmin ? null : Colors.grey[100]),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'สถานะ', border: const OutlineInputBorder(), filled: !widget.isAdmin, fillColor: widget.isAdmin ? null : Colors.grey[100]),
                    value: _selectedStatus,
                    items: _statusList.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                    onChanged: widget.isAdmin ? (value) => setState(() => _selectedStatus = value) : null,
                  ),
                  const SizedBox(height: 24),
                  
                  if (widget.isAdmin)
                    ElevatedButton(
                      onPressed: _updateAsset,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('อัปเดตข้อมูล', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
    );
  }
}