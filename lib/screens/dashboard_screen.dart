import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:url_launcher/url_launcher.dart'; // นำเข้าเครื่องมือเปิดเว็บ
import 'qr_scan_screen.dart'; 
import 'login_screen.dart'; 
import 'import_csv_screen.dart'; 

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;
  final bool isAdmin; 

  const DashboardScreen({super.key, required this.onNavigate, required this.isAdmin});

  Widget _buildStatCard(String title, int count, Color color, Color bgColor, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบตรวจเช็คครุภัณฑ์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ออกจากระบบ'),
                  content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('assets').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          int total = snapshot.data?.docs.length ?? 0;
          int normal = 0, broken = 0, disposed = 0;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['status'] == 'ปกติ') normal++;
              else if (data['status'] == 'ชำรุดรอซ่อม') broken++;
              else if (data['status'] == 'จำหน่ายออก') disposed++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.inventory_2, size: 80, color: Color(0xFF1D4ED8)),
                const SizedBox(height: 8),
                const Text('รายการทั้งหมด', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('ทั้งหมด', total, const Color(0xFF1D4ED8), Colors.blue.shade50, Icons.inventory),
                    _buildStatCard('ปกติ', normal, Colors.green, Colors.green.shade50, Icons.check_circle_outline),
                    _buildStatCard('ชำรุดรอซ่อม', broken, Colors.orange, Colors.orange.shade50, Icons.error_outline),
                    _buildStatCard('จำหน่ายออก', disposed, Colors.grey.shade700, Colors.grey.shade200, Icons.auto_graph),
                  ],
                ),
                const SizedBox(height: 32),
                const Align(alignment: Alignment.centerLeft, child: Text('เมนูลัด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    if (isAdmin) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onNavigate(1), 
                          icon: const Icon(Icons.add, color: Color(0xFF1D4ED8)),
                          label: const Text('เพิ่มครุภัณฑ์', style: TextStyle(color: Colors.black87)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanScreen()));
                        },
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1D4ED8)),
                        label: const Text('สแกนรหัส QR', style: TextStyle(color: Colors.black87)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
                
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  
                  // ถ้าเปิดบน "เว็บ (PC)" ให้โชว์ปุ่มอัปโหลดไฟล์สีเขียว
                  if (kIsWeb) 
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportCsvScreen()));
                        },
                        icon: const Icon(Icons.cloud_upload, color: Colors.green),
                        label: const Text('นำเข้าข้อมูลจากไฟล์ CSV (Web Admin)', style: TextStyle(color: Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    )
                  // ถ้าเปิดบน "มือถือ (App)" ให้โชว์ปุ่มกดเปิดเบราว์เซอร์
                  else 
                    InkWell(
                      onTap: () async {
                        // URL เว็บ Backend ของคุณ
                        final Uri url = Uri.parse('https://equipment-checking-web-backend.web.app/');
                        
                        // สั่งให้เปิดในแอปเบราว์เซอร์ภายนอก (เช่น Chrome, Safari)
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ไม่สามารถเปิดเว็บได้')),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.open_in_browser, color: Color(0xFF1D4ED8), size: 32),
                            SizedBox(height: 8),
                            Text(
                              'การนำเข้าข้อมูลจำนวนมาก (Import CSV)\nแตะที่นี่เพื่อเข้าใช้งานระบบ Web Admin',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text('https://equipment-checking-web-backend.web.app', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}