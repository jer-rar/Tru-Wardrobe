import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class LegalContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalContentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(kAccentColor),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 64),
            const Center(
              child: Opacity(
                opacity: 0.2,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Tru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      TextSpan(
                        text: 'Wardrobe',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(kAccentColor), fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Your Closet, Organized',
                style: TextStyle(color: Colors.white10, fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
