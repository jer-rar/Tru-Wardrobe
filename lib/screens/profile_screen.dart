import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/legal_text.dart';
import '../widgets/feedback_dialog.dart';
import 'legal_content_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openLegal(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LegalContentScreen(title: title, content: content)),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(kCardColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await Supabase.instance.client.auth.signOut();
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
      );

  Widget _tile({required IconData icon, required String label, required VoidCallback onTap, Color? iconColor}) {
    return Material(
      color: const Color(kCardColor),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.white70, size: 20),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(kCardColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(kAccentColor),
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Signed in',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text('Tru Wardrobe account', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sectionLabel('SUPPORT'),
            _tile(
              icon: Icons.chat_bubble_outline,
              label: 'Send to Dev',
              iconColor: const Color(kAccentColor),
              onTap: () => showFeedbackDialog(context),
            ),
            _sectionLabel('LEGAL'),
            _tile(
              icon: Icons.info_outline,
              label: 'Disclaimer',
              onTap: () => _openLegal(context, 'Disclaimer', kDisclaimerContent),
            ),
            const SizedBox(height: 8),
            _tile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () => _openLegal(context, 'Terms of Service', kTermsContent),
            ),
            const SizedBox(height: 8),
            _tile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _openLegal(context, 'Privacy Policy', kPrivacyContent),
            ),
            _sectionLabel('ACCOUNT'),
            _tile(
              icon: Icons.logout,
              label: 'Sign Out',
              iconColor: Colors.redAccent,
              onTap: () => _confirmSignOut(context),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Tru Wardrobe v$kAppVersion',
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
