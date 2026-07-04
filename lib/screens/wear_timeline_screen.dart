import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/supabase_service.dart';

class WearTimelineScreen extends StatefulWidget {
  const WearTimelineScreen({super.key, required this.itemId, required this.itemName});
  final String itemId;
  final String itemName;

  @override
  State<WearTimelineScreen> createState() => _WearTimelineScreenState();
}

class _WearTimelineScreenState extends State<WearTimelineScreen> {
  List<Map<String, dynamic>> _log = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final log = await SupabaseService.fetchWearLog(widget.itemId);
    if (!mounted) return;
    setState(() {
      _log = log;
      _loading = false;
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(title: Text('${widget.itemName} — Worn Timeline')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(kAccentColor)))
          : _log.isEmpty
              ? const Center(
                  child: Text("You haven't logged wearing this item yet.", style: TextStyle(color: Colors.white38)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _log.length,
                  itemBuilder: (context, index) {
                    final entry = _log[index];
                    final isLast = index == _log.length - 1;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(kAccentColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(width: 2, color: Colors.white12),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(entry['worn_at']?.toString()),
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  if ((entry['occasion']?.toString() ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      entry['occasion'].toString(),
                                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                  ],
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
}
