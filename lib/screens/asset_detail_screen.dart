import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'edit_asset_screen.dart'; // ดึงหน้าแก้ไขมาใช้

class AssetDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> assetData;
  final bool isAdmin; // รับค่าเพื่อเช็คว่าจะโชว์ปุ่ม แก้ไข/ลบ ไหม

  const AssetDetailScreen({
    super.key,
    required this.docId,
    required this.assetData,
    required this.isAdmin,
  });

  // ฟังก์ชันแปลงวันที่เป็นภาษาไทย
  String _formatThaiDate(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';
    final date = timestamp.toDate();
    const thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  // ฟังก์ชันแปลงตัวเลขราคาให้มีคอมม่า (เช่น 35000 -> 35,000)
  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String mathFunc(Match match) => '${match[1]},';
    return price.toString().replaceAllMapped(reg, mathFunc);
  }

  // ฟังก์ชันลบข้อมูล
  void _deleteAsset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบครุภัณฑ์?'),
        content: Text('คุณต้องการลบข้อมูล "$docId" ใช่หรือไม่? ข้อมูลจะถูกลบถาวร'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // ปิด Dialog
              await FirebaseFirestore.instance.collection('assets').doc(docId).delete();
              if (context.mounted) {
                Navigator.pop(context); // กลับไปหน้ารายการ
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบข้อมูลเรียบร้อย'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบข้อมูล', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดสีของสถานะ
    Color statusColor = Colors.green;
    if (assetData['status'] == 'ชำรุดรอซ่อม') statusColor = Colors.orange;
    if (assetData['status'] == 'จำหน่ายออก') statusColor = Colors.grey;

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // พื้นหลังสีเทาอ่อนตามรูป
      appBar: AppBar(
        title: const Text('รายละเอียดครุภัณฑ์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8), // สีน้ำเงินตามรูป
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // โชว์ปุ่ม แก้ไขและลบ เฉพาะแอดมิน
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_note, size: 28),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => EditAssetScreen(docId: docId, assetData: assetData),
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 26, color: Colors.redAccent),
              onPressed: () => _deleteAsset(context),
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. ส่วนรูปภาพ ---
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 200,
                color: Colors.white,
                child: (assetData['image_base64'] != null && assetData['image_base64'].toString().isNotEmpty)
                    ? Image.memory(base64Decode(assetData['image_base64']), fit: BoxFit.cover)
                    : const Icon(Icons.computer, size: 80, color: Colors.grey), // รูปจำลองถ้าไม่มีรูป
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. การ์ดสถานะ ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('สถานะ:', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      assetData['status'] ?? 'ไม่ระบุ',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 3. การ์ดรายละเอียด ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assetData['name'] ?? 'ไม่มีชื่อ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(docId, style: const TextStyle(color: Colors.grey)), // รหัสครุภัณฑ์
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  
                  _buildDetailRow(Icons.category_outlined, 'ประเภท', assetData['type']),
                  _buildDetailRow(Icons.branding_watermark_outlined, 'ยี่ห้อ', assetData['brand']),
                  _buildDetailRow(Icons.location_on_outlined, 'ที่ตั้ง', assetData['location']),
                  _buildDetailRow(Icons.calendar_month_outlined, 'วันที่จัดซื้อ', _formatThaiDate(assetData['purchase_date'])),
                  _buildDetailRow(Icons.attach_money_outlined, 'ราคา', '${_formatPrice(assetData['price'])} บาท'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 4. การ์ด QR Code ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Icon(Icons.qr_code, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          QrImageView(
                            data: docId, // ใช้รหัสครุภัณฑ์ในการเจน QR
                            version: QrVersions.auto,
                            size: 150.0,
                          ),
                          const SizedBox(height: 8),
                          Text(docId, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ตัวช่วยสร้างบรรทัดรายละเอียด (ไอคอน + หัวข้อ + ข้อมูล)
  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value ?? 'ไม่ระบุ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}