import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/app_models.dart';

class PdfService {
  static final PdfColor _schoolBlue = PdfColor(0x1E, 0x3A, 0x8A);
  static final PdfColor _grey700 = PdfColor(0x64, 0x74, 0x8B);
  static final _titleStyle = pw.TextStyle(
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
    color: _schoolBlue,
  );
  static final _subStyle = pw.TextStyle(fontSize: 12, color: _grey700);
  static final _cell = pw.TextStyle(fontSize: 10);
  static final _cellBold =
      pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

  static Future<File> generateReportCard({
    required Student student,
    required List<Mark> midTermMarks,
    required List<Mark> finalMarks,
    required Map<String, int> attendance,
    required String teacherComment,
    required double feeBalance,
    required String feeLastDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: _schoolBlue),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('THE SCHOOL',
                      style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.Text('Report Card',
                      style:
                          pw.TextStyle(fontSize: 18, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Student Information', style: _titleStyle),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: const {
                0: pw.FractionColumnWidth(0.35),
                1: pw.FractionColumnWidth(0.65)
              },
              children: [
                _row('Name', student.name),
                _row('Roll No', student.rollNo),
                _row('Class',
                    '${student.className} ${student.section.isNotEmpty ? '- ${student.section}' : ''}'),
                _row('Parent Name', student.parentName),
                _row('Parent Phone', student.parentPhone),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Attendance Summary', style: _titleStyle),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: const {
                0: pw.FractionColumnWidth(0.4),
                1: pw.FractionColumnWidth(0.6)
              },
              children: [
                _row('Present', '${attendance['Present'] ?? 0}'),
                _row('Absent', '${attendance['Absent'] ?? 0}'),
                _row('Leave', '${attendance['Leave'] ?? 0}'),
                _row('Total Days',
                    '${(attendance['Present'] ?? 0) + (attendance['Absent'] ?? 0) + (attendance['Leave'] ?? 0)}'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Mid Term Marks', style: _titleStyle),
            pw.SizedBox(height: 8),
            _marksTable(midTermMarks),
            pw.SizedBox(height: 16),
            pw.Text('Final Marks', style: _titleStyle),
            pw.SizedBox(height: 8),
            _marksTable(finalMarks),
            pw.SizedBox(height: 20),
            pw.Text('Fee Status', style: _titleStyle),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: const {
                0: pw.FractionColumnWidth(0.4),
                1: pw.FractionColumnWidth(0.6)
              },
              children: [
                _row('Balance Due', 'Rs ${feeBalance.toStringAsFixed(0)}'),
                _row('Last Date', feeLastDate),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Teacher Comments', style: _titleStyle),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration:
                  pw.BoxDecoration(border: pw.Border.all(color: _grey700)),
              child: pw.Text(
                  teacherComment.isNotEmpty ? teacherComment : 'No comments.'),
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Class Teacher Signature: ______________',
                    style: _subStyle),
                pw.Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                    style: _subStyle),
              ],
            ),
          ],
        );
      },
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/ReportCard_${student.rollNo}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.TableRow _row(String label, String value) => pw.TableRow(
        children: [
          pw.Container(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(label, style: _cellBold)),
          pw.Container(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(value, style: _cell)),
        ],
      );

  static pw.Widget _marksTable(List<Mark> marks) {
    if (marks.isEmpty) {
      return pw.Text('No marks recorded.',
          style: pw.TextStyle(fontSize: 10, color: PdfColor(0x47, 0x55, 0x69)));
    }
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: const {
        0: pw.FractionColumnWidth(0.4),
        1: pw.FractionColumnWidth(0.3),
        2: pw.FractionColumnWidth(0.3)
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Subject', style: _cellBold)),
            pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Obtained', style: _cellBold)),
            pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Total', style: _cellBold)),
          ],
        ),
        ...marks.map((m) => pw.TableRow(
              children: [
                pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(m.subject, style: _cell)),
                pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${m.marksObtained.toStringAsFixed(0)}',
                        style: _cell)),
                pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${m.totalMarks.toStringAsFixed(0)}',
                        style: _cell)),
              ],
            )),
      ],
    );
  }

  /// Weekly report PDF to send to parents via WhatsApp.
  static Future<File> generateWeeklyReport({
    required Student student,
    required double attendancePercent,
    required int presentDays,
    required int absentDays,
    required String homeworkStatus,
    required String teacherComment,
    required double feeBalance,
    required String feeLastDate,
    required String weekStart,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: _schoolBlue),
              child: pw.Column(
                children: [
                  pw.Text('THE SCHOOL',
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.Text('Weekly Progress Report',
                      style:
                          pw.TextStyle(fontSize: 16, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Student: ${student.name}',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('Roll: ${student.rollNo}',
                    style: pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Class: ${student.className} ${student.section}',
                    style: pw.TextStyle(fontSize: 12)),
                pw.Text('Week: $weekStart', style: pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                  color: PdfColor(0xEF, 0xF6, 0xFF),
                  border: pw.Border.all(color: _schoolBlue)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      'Attendance: ${attendancePercent.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Present: $presentDays  |  Absent: $absentDays',
                      style: pw.TextStyle(fontSize: 11)),
                  pw.Text('Homework: $homeworkStatus',
                      style: pw.TextStyle(fontSize: 11)),
                  pw.Text('Fee Balance: Rs ${feeBalance.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontSize: 11)),
                  pw.Text('Last Date: $feeLastDate',
                      style: pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Teacher Comments',
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration:
                  pw.BoxDecoration(border: pw.Border.all(color: _grey700)),
              child: pw.Text(
                  teacherComment.isNotEmpty
                      ? teacherComment
                      : 'No comments this week.',
                  style: pw.TextStyle(fontSize: 11)),
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Class Teacher: ______________',
                    style: pw.TextStyle(fontSize: 11)),
                pw.Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('This report was sent via WhatsApp to parents.',
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor(0x47, 0x55, 0x69),
                      fontStyle: pw.FontStyle.italic)),
            ),
          ],
        );
      },
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/WeeklyReport_${student.rollNo}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
