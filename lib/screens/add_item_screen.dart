import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import '../widgets/color_swatch.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, required this.sectionId});
  final String sectionId;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  File? _photo;
  String? _uploadedImageUrl;
  bool _uploading = false;
  bool _tagging = false;
  bool _saving = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _colorPrimaryOtherCtrl = TextEditingController();
  final _colorSecondaryOtherCtrl = TextEditingController();
  final _sizeOtherCtrl = TextEditingController();

  String _category = kItemCategories.first;
  String _pattern = kItemPatterns.first;
  String _season = kItemSeasons.last;
  String _formality = kItemFormality.first;
  String _colorPrimary = 'Other';
  String _colorSecondary = kNoneOption;
  String _size = kSizeOptions.first;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _notesCtrl.dispose();
    _colorPrimaryOtherCtrl.dispose();
    _colorSecondaryOtherCtrl.dispose();
    _sizeOtherCtrl.dispose();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _photo = File(picked.path);
      _error = null;
    });
    await _uploadAndTag();
  }

  Future<void> _uploadAndTag() async {
    if (_photo == null) return;
    setState(() => _uploading = true);
    try {
      final url = await SupabaseService.uploadItemImage(_photo!);
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = url;
        _uploading = false;
        _tagging = true;
      });
      try {
        final tags = await AiService.tagItem(url);
        if (!mounted) return;
        setState(() {
          _nameCtrl.text = tags['name']?.toString() ?? '';
          _category = kItemCategories.contains(tags['category']) ? tags['category'] : _category;
          _pattern = kItemPatterns.contains(tags['pattern']) ? tags['pattern'] : _pattern;
          _season = kItemSeasons.contains(tags['season']) ? tags['season'] : _season;
          _formality = kItemFormality.contains(tags['formality']) ? tags['formality'] : _formality;

          final primaryRaw = tags['color_primary']?.toString();
          _colorPrimary = matchColorOption(primaryRaw);
          if (_colorPrimary == 'Other') _colorPrimaryOtherCtrl.text = primaryRaw ?? '';

          final secondaryRaw = tags['color_secondary']?.toString();
          _colorSecondary = (secondaryRaw == null || secondaryRaw.trim().isEmpty)
              ? kNoneOption
              : matchColorOption(secondaryRaw);
          if (_colorSecondary == 'Other') _colorSecondaryOtherCtrl.text = secondaryRaw ?? '';

          _tagging = false;
        });
      } catch (e) {
        // AI tagging is a convenience, not a requirement — manual entry always works.
        if (mounted) {
          setState(() {
            _tagging = false;
            _error = 'AI tagging unavailable — fill in the details manually.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Upload failed: $e';
        });
      }
    }
  }

  Future<void> _save() async {
    if (_uploadedImageUrl == null) {
      setState(() => _error = 'Take a photo first.');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Give this item a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final colorPrimaryValue = _colorPrimary == 'Other' ? _colorPrimaryOtherCtrl.text.trim() : _colorPrimary;
      final colorSecondaryValue = _colorSecondary == kNoneOption
          ? null
          : (_colorSecondary == 'Other' ? _colorSecondaryOtherCtrl.text.trim() : _colorSecondary);
      final sizeValue = _size == 'Other' ? _sizeOtherCtrl.text.trim() : _size;

      await SupabaseService.createItem({
        'section_id': widget.sectionId,
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'color_primary': colorPrimaryValue.isEmpty ? null : colorPrimaryValue,
        'color_secondary': (colorSecondaryValue == null || colorSecondaryValue.isEmpty) ? null : colorSecondaryValue,
        'pattern': _pattern,
        'size': sizeValue.isEmpty ? null : sizeValue,
        'brand': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        'season': _season,
        'formality': _formality,
        'image_url': _uploadedImageUrl,
        'thumbnail_url': _uploadedImageUrl,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Save failed: $e'; });
    }
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged, {Widget? prefix}) {
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
      items: options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefix != null && o != kNoneOption && o != 'Other') ...[
                      ColorSwatchDot(colorName: o, size: 12),
                      const SizedBox(width: 8),
                    ],
                    Text(o),
                  ],
                ),
              ))
          .toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(title: const Text('Add Item')),
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
                child: _photo != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_photo!, fit: BoxFit.cover),
                          if (_uploading || _tagging)
                            Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(color: Color(kAccentColor)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _uploading ? 'Uploading...' : 'AI is tagging your item...',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_a_photo, color: Colors.white38, size: 48),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _capture(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(kAccentColor)),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _capture(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library, color: Colors.white70),
                                  label: const Text('Gallery', style: TextStyle(color: Colors.white70)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            _textField('Name', _nameCtrl),
            const SizedBox(height: 12),
            _dropdown('Category', _category, kItemCategories, (v) => setState(() => _category = v)),
            const SizedBox(height: 12),
            _dropdown('Primary color', _colorPrimary, kColorOptions, (v) => setState(() => _colorPrimary = v), prefix: const SizedBox()),
            if (_colorPrimary == 'Other') ...[
              const SizedBox(height: 12),
              _textField('Primary color (custom)', _colorPrimaryOtherCtrl),
            ],
            const SizedBox(height: 12),
            _dropdown('Secondary color', _colorSecondary, [kNoneOption, ...kColorOptions], (v) => setState(() => _colorSecondary = v), prefix: const SizedBox()),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _uploading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(kAccentColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
