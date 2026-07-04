import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// "Send to Dev" feedback dialog — same format/features as TruBrief's:
/// pick a type (bug/feature/contact), write a message, optionally attach up
/// to 3 screenshots, submit. Inserts into tw_feedback; a DB trigger emails the dev.
Future<void> showFeedbackDialog(BuildContext context) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  final messageController = TextEditingController();
  String? selectedType;
  bool sending = false;
  List<XFile> attachedImages = [];

  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        final maxDialogHeight = MediaQuery.of(context).size.height * 0.6;
        return Dialog(
          backgroundColor: const Color(kCardColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Send to Dev', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    GestureDetector(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Type', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            ...[
                              ('bug', Icons.bug_report_rounded, 'Report Bug', 'Tell us what went wrong'),
                              ('feature', Icons.lightbulb_rounded, 'Request Feature', 'Suggest an improvement'),
                              ('contact', Icons.mail_rounded, 'Contact Dev', 'General message'),
                            ].asMap().entries.map((entry) {
                              final idx = entry.key;
                              final (type, icon, label, sublabel) = entry.value;
                              final selected = selectedType == type;
                              final isLast = idx == 2;
                              return GestureDetector(
                                onTap: () => setDialogState(() => selectedType = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(kAccentColor).withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: isLast
                                        ? const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))
                                        : BorderRadius.zero,
                                    border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : Colors.white.withValues(alpha: 0.06))),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: selected ? const Color(kAccentColor).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(icon, color: selected ? const Color(kAccentColor) : Colors.white38, size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700, fontSize: 13)),
                                          Text(sublabel, style: TextStyle(color: selected ? const Color(kAccentColor).withValues(alpha: 0.8) : Colors.white30, fontSize: 10, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      const Spacer(),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected ? const Color(kAccentColor) : Colors.transparent,
                                          border: Border.all(color: selected ? const Color(kAccentColor) : Colors.white24, width: 1.5),
                                        ),
                                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 11) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Message', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        minLines: 4,
                        maxLines: null,
                        scrollPadding: const EdgeInsets.only(bottom: 120),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Describe your issue or idea...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(kAccentColor), width: 1.5)),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (attachedImages.isNotEmpty) ...[
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: attachedImages.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, i) => Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(attachedImages[i].path), width: 64, height: 64, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => setDialogState(() => attachedImages.removeAt(i)),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                                      child: const Icon(Icons.close, size: 11, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          GestureDetector(
                            onTap: attachedImages.length >= 3
                                ? null
                                : () async {
                                    final picker = ImagePicker();
                                    final remaining = 3 - attachedImages.length;
                                    final picked = await picker.pickMultiImage(imageQuality: 80, limit: remaining);
                                    if (picked.isNotEmpty) setDialogState(() => attachedImages.addAll(picked.take(remaining)));
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: attachedImages.isNotEmpty ? const Color(kAccentColor).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: attachedImages.isNotEmpty ? const Color(kAccentColor).withValues(alpha: 0.5) : Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.attach_file_rounded, size: 15, color: attachedImages.isNotEmpty ? const Color(kAccentColor) : Colors.white38),
                                  const SizedBox(width: 6),
                                  Text(
                                    attachedImages.isEmpty
                                        ? 'Attach Screenshot'
                                        : attachedImages.length < 3
                                            ? 'Add Another (${attachedImages.length}/3)'
                                            : 'Max 3 Screenshots',
                                    style: TextStyle(color: attachedImages.isNotEmpty ? const Color(kAccentColor) : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: sending
                                ? null
                                : () async {
                                    if (selectedType == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a type.')));
                                      return;
                                    }
                                    if (messageController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message.')));
                                      return;
                                    }
                                    setDialogState(() => sending = true);
                                    try {
                                      String? screenshotUrl;
                                      if (attachedImages.isNotEmpty) {
                                        final urls = <String>[];
                                        for (final img in attachedImages) {
                                          try {
                                            final bytes = await File(img.path).readAsBytes();
                                            final fileName = 'feedback_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                            await supabase.storage.from('tw-feedback-screenshots').uploadBinary(
                                                  fileName,
                                                  bytes,
                                                  fileOptions: const FileOptions(contentType: 'image/jpeg'),
                                                );
                                            urls.add(supabase.storage.from('tw-feedback-screenshots').getPublicUrl(fileName));
                                          } catch (e) {
                                            debugPrint('Screenshot upload failed: $e');
                                          }
                                        }
                                        if (urls.isNotEmpty) screenshotUrl = urls.join(',');
                                      }
                                      final now = DateTime.now().toUtc().toIso8601String();
                                      final record = {
                                        'user_id': user?.id,
                                        'user_email': user?.email,
                                        'type': selectedType,
                                        'message': messageController.text.trim(),
                                        'screenshot_url': screenshotUrl,
                                        'created_at': now,
                                        'read': false,
                                      };
                                      await supabase.from('tw_feedback').insert(record);
                                      if (ctx.mounted) {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        Navigator.of(ctx).pop();
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted. Thank you!')));
                                      }
                                    } catch (e) {
                                      setDialogState(() => sending = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
                                      }
                                    }
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: sending ? [Colors.grey.shade800, Colors.grey.shade700] : [const Color(kAccentColor), const Color(0xFFA85F42)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: sending ? [] : [BoxShadow(color: const Color(kAccentColor).withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
                              ),
                              child: sending
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3)),
                                        SizedBox(width: 6),
                                        Icon(Icons.send_rounded, color: Colors.white, size: 13),
                                      ],
                                    ),
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
        );
      },
    ),
  );
}
