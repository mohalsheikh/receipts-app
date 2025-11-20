import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';

class OCRReviewScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(Receipt) onSave;
  final String? imagePath;
  final Receipt? existing;
  const OCRReviewScreen({
    super.key,
    required this.onBack,
    required this.onSave,
    this.imagePath,
    this.existing,
  });

  @override
  State<OCRReviewScreen> createState() => _OCRReviewScreenState();
}

class _OCRReviewScreenState extends State<OCRReviewScreen> {
  final _form = GlobalKey<FormState>();
  late final _store = TextEditingController(),
      _total = TextEditingController(),
      _cat = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _ret, _war;
  static const _cats = [
    'Groceries',
    'Dining',
    'Utilities',
    'Electronics',
    'Clothing',
    'Home',
    'Health',
    'Transport',
    'Office',
    'Fuel',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final r = widget.existing!;
      _store.text = r.store;
      _total.text = r.total.toStringAsFixed(2);
      _cat.text = r.category ?? '';
      _date = r.date;
      _ret = r.returnBy;
      _war = r.warrantyEnds;
    }
  }

  @override
  void dispose() {
    for (var c in [_store, _total, _cat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(DateTime start, ValueChanged<DateTime> onSet) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) onSet(d);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    widget.onSave(
      Receipt(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        store: _store.text.trim(),
        date: _date,
        total: double.tryParse(_total.text.trim()) ?? 0.0,
        returnBy: _ret,
        warrantyEnds: _war,
        category: _cat.text.trim().isEmpty ? null : _cat.text.trim(),
        imageUrl: widget.existing?.imageUrl,
        hasImage:
            (widget.existing?.imageUrl ?? '').isNotEmpty ||
            (widget.imagePath ?? '').isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final hasImg =
        (widget.imagePath ?? '').isNotEmpty ||
        (widget.existing?.imageUrl ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onBack,
        ),
        title: Text(
          widget.existing == null ? 'New Receipt' : 'Edit Receipt',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: c.surface,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
            if (hasImg) ...[
              Center(
                child: SizedBox(
                  height: 160,
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.imagePath != null
                        ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                        : Image.network(
                            widget.existing!.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _total,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: c.primary,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  ),
                  const Divider(),
                  TextFormField(
                    controller: _store,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Store',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _dateTile(
              'Purchase Date',
              _date,
              Icons.event,
              () => _pick(_date, (d) => setState(() => _date = d)),
            ),
            const SizedBox(height: 8),
            _dateTile(
              'Return By',
              _ret,
              Icons.restart_alt,
              () => _pick(
                _ret ?? _date.add(const Duration(days: 30)),
                (d) => setState(() => _ret = d),
              ),
              onClear: () => setState(() => _ret = null),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _cat,
              decoration: InputDecoration(
                hintText: 'Category',
                prefixIcon: const Icon(Icons.category_outlined),
                filled: true,
                fillColor: c.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cats
                  .map(
                    (t) => FilterChip(
                      selected: _cat.text == t,
                      label: Text(t),
                      onSelected: (_) => setState(() => _cat.text = t),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save Receipt'),
      ),
    );
  }

  Widget _dateTile(
    String l,
    DateTime? d,
    IconData i,
    VoidCallback tap, {
    VoidCallback? onClear,
  }) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: d != null
              ? Border.all(color: c.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(i, color: d != null ? c.primary : c.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l,
                    style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                  ),
                  Text(
                    d == null ? 'Not set' : DateFormat.yMMMd().format(d),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: d != null
                          ? c.onSurface
                          : c.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (d != null && onClear != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              )
            else
              const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
