import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr_scan_screen.dart';

// เปลี่ยนจาก StatelessWidget เป็น StatefulWidget เพื่อให้จัดการค่าการค้นหาได้
class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'ทั้งหมด';
  
  final List<String> _filters = ['ทั้งหมด', 'ปกติ', 'ชำรุดรอซ่อม', 'จำหน่ายออก'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ครุภัณฑ์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: false, // ปรับให้อยู่ชิดซ้ายตาม Figma
      ),
      body: Column(
        children: [
          // 1. ส่วนช่องค้นหา และ ปุ่มสแกน QR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาครุภัณฑ์...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // เปลี่ยนคำสั่งในปุ่มนี้ ให้พาไปยังหน้า QrScanScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QrScanScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('สแกน QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // 2. ส่วนปุ่มตัวกรอง (Filter Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _filters.map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                    selectedColor: const Color(0xFF1D4ED8),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    showCheckmark: false, // ปิดเครื่องหมายติ๊กถูกเพื่อความมินิมอล
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 3. ส่วนแสดงรายการครุภัณฑ์
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('assets').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text('ยังไม่มีข้อมูลครุภัณฑ์'));

                // นำข้อมูลทั้งหมดมาคัดกรอง (Filter & Search) ก่อนแสดงผล
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  
                  // เช็คเงื่อนไขตัวกรองสถานะ
                  bool matchFilter = _selectedFilter == 'ทั้งหมด' || data['status'] == _selectedFilter;
                  
                  // เช็คเงื่อนไขการพิมพ์ค้นหา (หาจาก รหัส หรือ ชื่อ)
                  String idString = doc.id.toLowerCase();
                  String nameString = (data['name'] ?? '').toString().toLowerCase();
                  String searchString = _searchQuery.toLowerCase();
                  bool matchSearch = _searchQuery.isEmpty || idString.contains(searchString) || nameString.contains(searchString);
                  
                  return matchFilter && matchSearch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('ไม่พบข้อมูลที่ค้นหา', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    // จัดการรูปภาพ Base64
                    Widget imageWidget;
                    String? base64String = data['image_base64'];
                    if (base64String != null && base64String.isNotEmpty) {
                      try {
                        imageWidget = Image.memory(base64Decode(base64String), width: 60, height: 60, fit: BoxFit.cover);
                      } catch (e) {
                        imageWidget = const Icon(Icons.broken_image, color: Colors.grey);
                      }
                    } else {
                      imageWidget = const Icon(Icons.computer, color: Colors.grey);
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(width: 60, height: 60, color: Colors.grey[200], child: imageWidget),
                        ),
                        title: Text(data['name'] ?? 'ไม่ระบุชื่อ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('รหัส: ${doc.id}'),
                            const SizedBox(height: 4),
                            Text(
                              'สถานะ: ${data['status'] ?? '-'}',
                              style: TextStyle(
                                color: data['status'] == 'ปกติ' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          // TODO: ไปหน้ารายละเอียดเพื่อแก้ไข
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}