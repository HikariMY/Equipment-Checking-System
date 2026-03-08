import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr_scan_screen.dart';
import 'edit_asset_screen.dart';
import 'asset_detail_screen.dart';

class AssetListScreen extends StatefulWidget {
  final bool isAdmin; 
  const AssetListScreen({super.key, required this.isAdmin});

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
        centerTitle: false,
      ),
      body: Column(
        children: [
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
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('assets').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text('ยังไม่มีข้อมูลครุภัณฑ์'));

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool matchFilter = _selectedFilter == 'ทั้งหมด' || data['status'] == _selectedFilter;
                  
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssetDetailScreen(
                                docId: doc.id,
                                assetData: data,
                                isAdmin: widget.isAdmin, // ส่งสิทธิ์แอดมินไปเช็คการลบ/แก้ไข
                              ),
                            ),
                          );
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