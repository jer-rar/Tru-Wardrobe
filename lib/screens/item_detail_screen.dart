import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/supabase_service.dart';
import '../widgets/color_swatch.dart';
import 'wear_timeline_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});
  final Map<String, dynamic> item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Map<String, dynamic> _item;
  bool _editing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _colorPrimaryOtherCtrl;
  late TextEditingController _colorSecondaryOtherCtrl;
  late TextEditingController _sizeOtherCtrl;
  late String _category;
  late String _pattern;
  late String _season;
  late String _formality;
  late String _colorPrimary;
  late String _colorSecondary;
  late String _size;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _resetEditState();
  }

  void _resetEditState() {
    _nameCtrl = TextEditingController(text: _item['name']?.toString() ?? '');
    _brandCtrl = TextEditingController(text: _item['brand']?.toString() ?? '');
    _notesCtrl = TextEditingController(text: _item['notes']?.toString() ?? '');

    final primaryRaw = _item['color_primary']?.toString();
    _colorPrimary = matchColorOption(primaryRaw);
    _colorPrimaryOtherCtrl = TextEditingController(text: _colorPrimary == 'Other' ? (primaryRaw ?? '') : '');

    final secondaryRaw = _item['color_secondary']?.toString();
    _colorSecondary = (secondaryRaw == null || secondaryRaw.trim().isEmpty) ? kNoneOption : matchColorOption(secondaryRaw);
    _colorSecondaryOtherCtrl = TextEditingController(text: _colorSecondary == 'Other' ? (secondaryRaw ?? '') : '');

    final sizeRaw = _item['size']?.toString();
    _size = (sizeRaw != null && kSizeOptions.contains(sizeRaw)) ? sizeRaw : (sizeRaw == null || sizeRaw.isEmpty ? kSizeOptions.first : 'Other');
    _sizeOtherCtrl = TextEditingController(text: _size == 'Other' ? (sizeRaw ?? '') : '');

    _category = kItemCategories.contains(_item['category']) ? _item['category'] : kItemCategories.first;
    _pattern = kItemPatterns.contains(_item['pattern']) ? _item['pattern'] : kItemPatterns.first;
    _season = kItemSeasons.contains(_item['season']) ? _item['season'] : kItemSeasons.last;
    _formality = kItemFormality.contains(_item['formality']) ? _item['formality'] : kItemFormality.first;
  }

  void _disposeEditControllers() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _notesCtrl.dispose();
    _colorPrimaryOtherCtrl.dispose();
    _colorSecondaryOtherCtrl.dispose();
    _sizeOtherCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeEditControllers();
    super.dispose();
  }

  Future<void> _saveEdits() async {
    final colorPrimaryValue = _colorPrimary == 'Other' ? _colorPrimaryOtherCtrl.text.trim() : _colorPrimary;
    final colorSecondaryValue = _colorSecondary == kNoneOption
        ? null
        : (_colorSecondary == 'Other' ? _colorSecondaryOtherCtrl.text.trim() : _colorSecondary);
    final sizeValue = _size == 'Other' ? _sizeOtherCtrl.text.trim() : _size;

    final fields = {
      'name': _nameCtrl.text.trim(),
      'category': _category,
      'color_primary': colorPrimaryValue.isEmpty ? null : colorPrimaryValue,
      'color_secondary': (colorSecondaryValue == null || colorSecondaryValue.isEmpty) ? null : colorSecondaryValue,
      'pattern': _pattern,
      'size': sizeValue.isEmpty ? null : sizeValue,
      'brand': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      'season': _season,
      'formality': _formality,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };
    await SupabaseService.updateItem(_item['id'], fields);
    setState(() {
      _item = {..._item, ...fields};
      _editing = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final newValue = !(_item['favorite'] == true);
    setState(() => _item['favorite'] = newValue);
    await SupabaseService.updateItem(_item['id'], {'favorite': newValue});
  }

  Future<void> _logWearDialog() async {
    DateTime selectedDate = DateTime.now();
    final occasionCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(kCardColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Mark as Worn', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(kAccentColor), size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setStateDialog(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: occasionCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Occasion (optional) — e.g. "Work", "Date night"',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(kBgColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save', style: TextStyle(color: Color(kAccentColor))),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final count = (_item['wear_count'] as num?)?.toInt() ?? 0;
    final currentLastWorn = DateTime.tryParse(_item['last_worn_at']?.toString() ?? '');
    await SupabaseService.logWear(
      _item['id'],
      count,
      wornAt: selectedDate,
      occasion: occasionCtrl.text,
      currentLastWornAt: currentLastWorn,
    );
    setState(() {
      _item['wear_count'] = count + 1;
      if (currentLastWorn == null || selectedDate.isAfter(currentLastWorn)) {
        _item['last_worn_at'] = selectedDate.toIso8601String();
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wear logged')));
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(kCardColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Item?', style: TextStyle(color: Colors.white)),
        content: Text('Permanently delete "${_item['name']}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true) return;
    await SupabaseService.deleteItem(_item['id']);
    if (mounted) Navigator.pop(context);
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _colorRow(String label, String? colorName) {
    if (colorName == null || colorName.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13))),
          ColorSwatchDot(colorName: colorName),
          const SizedBox(width: 8),
          Text(colorName, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(kCardColor),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(kCardColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) => onChanged(v ?? value),
    );
  }

  Widget _textField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(kCardColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _item['name']?.toString() ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _row('Category', _item['category']?.toString()),
        _colorRow('Primary Color', _item['color_primary']?.toString()),
        _colorRow('Secondary Color', _item['color_secondary']?.toString()),
        _row('Pattern', _item['pattern']?.toString()),
        _row('Season', _item['season']?.toString()),
        _row('Formality', _item['formality']?.toString()),
        _row('Size', _item['size']?.toString()),
        _row('Brand', _item['brand']?.toString()),
        _row('Notes', _item['notes']?.toString()),
        _row('Times worn', (_item['wear_count'] ?? 0).toString()),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logWearDialog,
            icon: const Icon(Icons.checkroom, color: Color(kAccentColor)),
            label: const Text('Mark as worn today', style: TextStyle(color: Color(kAccentColor))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(kAccentColor)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WearTimelineScreen(itemId: _item['id'], itemName: _item['name']?.toString() ?? 'Item'),
              ),
            ),
            icon: const Icon(Icons.timeline, color: Colors.white70),
            label: const Text('View wear timeline', style: TextStyle(color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField('Name', _nameCtrl),
        const SizedBox(height: 12),
        _dropdown('Category', _category, kItemCategories, (v) => setState(() => _category = v)),
        const SizedBox(height: 12),
        _dropdown('Primary color', _colorPrimary, kColorOptions, (v) => setState(() => _colorPrimary = v)),
        if (_colorPrimary == 'Other') ...[
          const SizedBox(height: 12),
          _textField('Primary color (custom)', _colorPrimaryOtherCtrl),
        ],
        const SizedBox(height: 12),
        _dropdown('Secondary color', _colorSecondary, [kNoneOption, ...kColorOptions], (v) => setState(() => _colorSecondary = v)),
        if (_colorSecondary == 'Other') ...[
          const SizedBox(height: 12),
          _textField('Secondary color (custom)', _colorSecondaryOtherCtrl),
        ],
        const SizedBox(height: 12),
        _dropdown('Pattern', _pattern, kItemPatterns, (v) => setState(() => _pattern = v)),
        const SizedBox(height: 12),
        _dropdown('Season', _season, kItemSeasons, (v) => setState(() => _season = v)),
        const SizedBox(height: 12),
        _dropdown('Formality', _formality, kItemFormality, (v) => setState(() => _formality = v)),
        const SizedBox(height: 12),
        _dropdown('Size', _size, kSizeOptions, (v) => setState(() => _size = v)),
        if (_size == 'Other') ...[
          const SizedBox(height: 12),
          _textField('Size (custom)', _sizeOtherCtrl),
        ],
        const SizedBox(height: 12),
        _textField('Brand', _brandCtrl),
        const SizedBox(height: 12),
        _textField('Notes', _notesCtrl),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _disposeEditControllers();
                  _resetEditState();
                  _editing = false;
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveEdits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(kAccentColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _item['image_url']?.toString();
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(
        actions: [
          if (!_editing) ...[
            IconButton(
              icon: Icon(
                _item['favorite'] == true ? Icons.favorite : Icons.favorite_border,
                color: const Color(kAccentColor),
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _editing = true)),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(kCardColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.checkroom, color: Colors.white24, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            _editing ? _buildEditMode() : _buildViewMode(),
          ],
        ),
      ),
    );
  }
}
