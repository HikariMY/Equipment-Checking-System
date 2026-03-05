import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

class ImportCsvScreen extends StatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  State<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends State<ImportCsvScreen> {
  bool _isLoading = false;
  String _statusMessage = 'รองรับไฟล์ .csv (เข้ารหัส UTF-8)';

  Future<void> _pickAndUploadCsv() async {
    try {
      // เปิดหน้าต่างให้เลือกไฟล์ (เฉพาะ .csv)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // จำเป็นมากสำหรับการทำงานบน Web
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
          _statusMessage = 'กำลังอ่านข้อมูลจากไฟล์...';
        });

        // ดึงข้อมูลไฟล์แบบ Byte
        final bytes = result.files.first.bytes;
        if (bytes == null) throw Exception("ไม่สามารถอ่านข้อมูลไฟล์ได้");

        // แปลงข้อมูลให้อ่านภาษาไทยออก (UTF-8)
        final csvString = utf8.decode(bytes);
        
        // แปลง Text ให้กลายเป็นตาราง (List ของแถวและคอลัมน์)
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

        if (csvTable.isEmpty || csvTable.length == 1) {
          throw Exception("ไฟล์ว่างเปล่า หรือไม่มีข้อมูลครุภัณฑ์");
        }

        setState(() {
          _statusMessage = 'กำลังนำเข้าข้อมูลจำนวน ${csvTable.length - 1} รายการ...';
        });

        int successCount = 0;

        // วนลูปอ่านข้อมูลทีละบรรทัด (ข้ามบรรทัดที่ 0 เพราะเป็นหัวข้อคอลัมน์)
        for (int i = 1; i < csvTable.length; i++) {
          var row = csvTable[i];
          
          // ป้องกัน Error ถ้าแถวนั้นว่าง หรือคอลัมน์ไม่ครบ
          if (row.length >= 6) {
            String id = row[0].toString().trim();
            String name = row[1].toString().trim();
            String type = row[2].toString().trim();
            String brand = row[3].toString().trim();
            String location = row[4].toString().trim();
            double price = double.tryParse(row[5].toString()) ?? 0.0;
            String status = row.length >= 7 ? row[6].toString().trim() : 'ปกติ';

            // ถ้ามีรหัสครุภัณฑ์ ให้บันทึกลง Firestore เลย
            if (id.isNotEmpty) {
              await FirebaseFirestore.instance.collection('assets').doc(id).set({
                'name': name,
                'type': type,
                'brand': brand,
                'location': location,
                'price': price,
                'status': status,
                'image_base64': '', // ข้อมูลนำเข้าจะยังไม่มีรูปภาพ
                'purchase_date': FieldValue.serverTimestamp(),
              });
              successCount++;
            }
          }
        }

        setState(() {
          _statusMessage = 'นำเข้าข้อมูลสำเร็จ $successCount รายการ!';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('นำเข้าข้อมูลสำเร็จ $successCount รายการ!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'เกิดข้อผิดพลาด: $e';
      });
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
        title: const Text('นำเข้าข้อมูล (Web Admin)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500, // กำหนดความกว้างกล่องให้เหมาะกับหน้าเว็บ
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file, size: 80, color: Color(0xFF1D4ED8)),
                  const SizedBox(height: 16),
                  const Text('อัปโหลดไฟล์ข้อมูลครุภัณฑ์', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_statusMessage, style: TextStyle(color: Colors.grey[600], fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickAndUploadCsv,
                      icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.folder_open, color: Colors.white),
                      label: Text(_isLoading ? 'กำลังประมวลผล...' : 'เลือกไฟล์ .CSV', style: const TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}