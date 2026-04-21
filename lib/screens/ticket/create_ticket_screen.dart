import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Hardware';
  String _priority = 'medium';
  bool _loading = false;
  File? _attachment;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachment = File(pickedFile.path);
      });
    }
  }

  final categories = ['Hardware', 'Software', 'Network', 'Account', 'Other'];
  final priorities = [
    ('low', 'Rendah', AppTheme.successGreen),
    ('medium', 'Sedang', AppTheme.accentAmber),
    ('high', 'Tinggi', AppTheme.dangerRed),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.read<AppProvider>().createTicket(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      priority: _priority,
    );
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tiket berhasil dibuat!', style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Judul Tiket *'),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Laptop tidak bisa menyala',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Judul diperlukan' : null,
              ),
              const SizedBox(height: 20),
              _sectionLabel('Kategori *'),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat, style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : null,
                      fontSize: 12,
                    )),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: AppTheme.primaryBlue,
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Prioritas *'),
              Row(
                children: priorities.map((p) {
                  final selected = _priority == p.$1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? p.$3 : p.$3.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.$3.withOpacity(0.5)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: selected ? Colors.white : p.$3,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.$2,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : p.$3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Deskripsi *'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan masalah Anda secara detail...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_outlined),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Deskripsi diperlukan' : null,
              ),
              const SizedBox(height: 16),
              // Attachment Section
              _sectionLabel('Lampiran Foto (Opsional)'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.darkSurface 
                        : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                  ),
                  child: _attachment == null
                      ? Column(
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryBlue, size: 32),
                            const SizedBox(height: 8),
                            Text('Ketuk untuk memilih foto dari galeri',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, 
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6)
                                )),
                          ],
                        )
                      : Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _attachment!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _attachment!.path.split('/').last,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: AppTheme.dangerRed),
                              onPressed: () => setState(() => _attachment = null),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Kirim Tiket', style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }
}
