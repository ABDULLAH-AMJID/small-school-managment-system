import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppService {
  /// Open a WhatsApp chat (wa.me) with a pre-filled text message.
  /// phone must be in international format WITHOUT the '+', e.g. "923001234567"
  static Future<bool> openChat(String phone, String text) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/$clean?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Send a weekly report PDF to a parent via WhatsApp share sheet.
  static Future<bool> sendReportPdf(BuildContext context, {
    required String parentPhone,
    required String studentName,
    required File pdfFile,
    String? comment,
  }) async {
    final clean = parentPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final text = comment != null && comment.isNotEmpty
        ? 'Assalam-o-Alaikum! $studentName ki haftawar report file share kar rahe hain.\n$comment\n\n- School Management'
        : 'Assalam-o-Alaikum! $studentName ki haftawar report file share kar rahe hain.\n- School Management';
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: text,
        subject: '$studentName - Weekly Report',
      );
      return true;
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
      // Fallback: open chat with text only
      return await openChat(clean, text);
    }
  }

  /// Send a plain text message (fee reminder, homework, etc.) via WhatsApp.
  static Future<bool> sendText(String phone, String text) =>
      openChat(phone, text);

  static String formatPhonePK(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('92')) return clean;
    if (clean.startsWith('0')) return '92${clean.substring(1)}';
    return clean;
  }
}
