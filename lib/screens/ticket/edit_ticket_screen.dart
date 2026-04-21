import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class EditTicketScreen extends StatefulWidget {
  final String ticketId;
  const EditTicketScreen({super.key, required this.ticketId});

  @override
  State<EditTicketScreen> createState() => _EditTicketScreenState();
}

class _EditTicketScreenState extends State<EditTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late String _category;
  late String _priority;
  bool _loading = false;

  final categories = ['Hardware', 'Software', 'Network', 'Account', 'Other'];
  final priorities = [
    ('low', 'Rendah', AppTheme.successGreen),
    ('medium', 'Sedang', AppTheme.accentAmber),
    ('high', 'Tinggi', AppTheme.dangerRed),
  ];

  @override
  void initState() {
    super.initState();
    final ticket = context.read<AppProvider>().getTicketById(widget.ticketId)!;
    _titleCtrl = TextEditingController(text: ticket.title);
    _descCtrl = TextEditingController(text: ticket.description);
    _category = ticket.category;
    _priority = ticket.priority;
  }

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
    context.read<AppProvider>().updateTicket(
      ticketId: widget.ticketId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      priority: _priority,
    );
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tiket berhasil diperbarui!', style: GoogleFonts.plusJakartaSans()),
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
        title: const Text('Edit Tiket'),
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
              _label('Judul Tiket *'),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Judul diperlukan' : null,
              ),
              const SizedBox(height: 20),
              _label('Kategori *'),
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
              _label('Prioritas *'),
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
                                  fontSize: 12, fontWeight: FontWeight.w700,
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
              _label('Deskripsi *'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Deskripsi diperlukan' : null,
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
                      : Text('Simpan Perubahan', style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
