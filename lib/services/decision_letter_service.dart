import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/application_model.dart';
import '../utils/constants.dart';

class DecisionLetterService {
  DecisionLetterService._();
  static final instance = DecisionLetterService._();

  final _storage = FirebaseStorage.instance;
  final _db = FirebaseFirestore.instance;

  Future<String> createAndUpload({
    required ApplicationModel application,
    required String status,
  }) async {
    final document = pw.Document();
    final accepted = status == AppStatus.diterima;
    document.addPage(
      pw.Page(
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SURAT PEMBERITAHUAN HASIL LAMARAN',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 28),
              pw.Text('Dengan ini kami menyampaikan hasil lamaran berikut:'),
              pw.SizedBox(height: 18),
              pw.Text('Posisi       : ${application.jobTitle}'),
              pw.Text('Perusahaan   : ${application.company}'),
              pw.Text(
                  'Status       : ${accepted ? 'DITERIMA' : 'TIDAK DITERIMA'}'),
              if (application.note.trim().isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('Catatan BKK  : ${application.note.trim()}'),
              ],
              pw.SizedBox(height: 32),
              pw.Text(
                accepted
                    ? 'Selamat dan terima kasih atas partisipasi Anda.'
                    : 'Terima kasih atas partisipasi Anda dalam proses seleksi.',
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text('SAPA Alumni\nBKK Sekolah'),
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = Uint8List.fromList(await document.save());
    final ref = _storage.ref('decision_letters/${application.id}.pdf');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final url = await ref.getDownloadURL();
    await _db.collection(Col.applications).doc(application.id).set({
      'decisionLetterUrl': url,
      'decisionLetterCreatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }
}
