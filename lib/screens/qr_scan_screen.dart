import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  String? _scannedId;
  Map<String, dynamic>? _assetData;
  bool _isLoading = false;
  final TextEditingController _manualInputController = TextEditingController();

  // ฟังก์ชันค้นหาข้อมูลจากรหัสที่สแกนหรือพิมพ์
  Future<void> _searchAsset(String id) async {
    setState(() {
      _isLoading = true;
      _scannedId = id;
      _assetData = null; // เคลียร์ข้อมูลเก่าก่อนค้นหาใหม่
    });

    try {
      // ไปค้นหา Document ใน Firestore ที่มี ID ตรงกับที่สแกนมา
      var doc = await FirebaseFirestore.instance.collection('assets').doc(id).get();
      
      if (doc.exists) {
        setState(() {
          _assetData = doc.data();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลครุภัณฑ์รหัสนี้ในระบบ'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. กล่องแสดงกล้องสแกน QR
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null && barcode.rawValue != _scannedId) {
                          // เมื่อสแกนเจอ ให้เรียกฟังก์ชันค้นหาทันที
                          _searchAsset(barcode.rawValue!);
                        }
                      }
                    },
                  ),
                  // กรอบสี่เหลี่ยมหลอกๆ ให้ดูเหมือนจุดโฟกัสสแกน
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('นำกล้องจ่อตรงรหัส QR ของครุภัณฑ์', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // 2. กล่องสำหรับกรอกรหัสด้วยตัวเอง (เหมาะสำหรับทดสอบบน Emulator)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('หรือกรอกรหัส', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualInputController,
                            decoration: InputDecoration(
                              hintText: 'เช่น 123ACC',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_manualInputController.text.isNotEmpty) {
                              // เอามือถือลงคีย์บอร์ด
                              FocusScope.of(context).unfocus(); 
                              _searchAsset(_manualInputController.text.trim());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('ค้นหา', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. ส่วนแสดงผลลัพธ์ข้อมูลครุภัณฑ์ที่ค้นเจอ
            if (_isLoading) 
              const CircularProgressIndicator()
            else if (_assetData != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _assetData!['name'] ?? 'ไม่ระบุชื่อ',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                      ),
                      const Divider(),
                      _buildDetailRow(Icons.qr_code, 'รหัส', _scannedId ?? '-'),
                      _buildDetailRow(Icons.category, 'ประเภท', _assetData!['type'] ?? '-'),
                      _buildDetailRow(Icons.branding_watermark, 'ยี่ห้อ', _assetData!['brand'] ?? '-'),
                      _buildDetailRow(Icons.location_on, 'ที่ตั้ง', _assetData!['location'] ?? '-'),
                      _buildDetailRow(Icons.attach_money, 'ราคา', '${_assetData!['price']} บาท'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          const Text('สถานะ: ', style: TextStyle(color: Colors.grey)),
                          Text(
                            _assetData!['status'] ?? '-',
                            style: TextStyle(
                              color: _assetData!['status'] == 'ปกติ' ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget ช่วยสร้างบรรทัดแสดงรายละเอียด (เพื่อให้โค้ดไม่ยาวเกินไป)
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}