import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../services/ocr_service.dart';

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

  late final TextEditingController _store;
  late final TextEditingController _total;
  late final TextEditingController _cat;

  late final ReceiptOcrService _ocrService;
  bool _ocrRunning = false;
  String? _ocrMessage;

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

    _store = TextEditingController();
    _total = TextEditingController();
    _cat = TextEditingController();
    _ocrService = ReceiptOcrService();

    if (widget.existing != null) {
      final r = widget.existing!;
      _store.text = r.store;
      _total.text = r.total.toStringAsFixed(2);
      _cat.text = r.category ?? '';
      _date = r.date;
      _ret = r.returnBy;
      _war = r.warrantyEnds;
    } else {
      final path = widget.imagePath;
      if (path != null && path.isNotEmpty) {
        _runOcr(path);
      }
    }
  }

  @override
  void dispose() {
    _store.dispose();
    _total.dispose();
    _cat.dispose();
    _ocrService.dispose();
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

  Future<void> _runOcr(String path) async {
    setState(() {
      _ocrRunning = true;
      _ocrMessage = 'Scanning receipt…';
    });

    try {
      final parsed = await _ocrService.parseImage(path);

      if (!mounted) return;

      setState(() {
        // Only fill fields if user hasn't typed anything yet.
        if (_store.text.trim().isEmpty && parsed.store != null) {
          _store.text = parsed.store!;
        }
        if (_total.text.trim().isEmpty && parsed.total != null) {
          _total.text = parsed.total!.toStringAsFixed(2);
        }
        if (parsed.date != null) {
          _date = parsed.date!;
        }
        if (_cat.text.trim().isEmpty && parsed.categoryHint != null) {
          _cat.text = parsed.categoryHint!;
        }

        _ocrMessage = 'Scanned with AI. Please double-check values.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ocrMessage = 'Could not read text automatically.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _ocrRunning = false;
        });
      }
    }
  }

  void _openImageViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ReceiptImageViewer(
          imagePath: widget.imagePath,
          imageUrl: widget.existing?.imageUrl,
        ),
      ),
    );
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
                child: GestureDetector(
                  onTap: _openImageViewer,
                  child: Hero(
                    tag: 'receipt_image',
                    child: Container(
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.imagePath != null
                                ? Image.file(
                                    File(widget.imagePath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Image.network(
                                    widget.existing!.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to view full image',
                  style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_ocrMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.outlineVariant.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    if (_ocrRunning)
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.primary,
                        ),
                      )
                    else
                      Icon(Icons.auto_awesome, size: 18, color: c.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ocrRunning ? 'Scanning receipt…' : _ocrMessage ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (!_ocrRunning && widget.imagePath != null)
                      TextButton(
                        onPressed: () => _runOcr(widget.imagePath!),
                        child: const Text('Rescan'),
                      ),
                  ],
                ),
              ),

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
                    decoration: const InputDecoration(
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
    String label,
    DateTime? value,
    IconData icon,
    VoidCallback onTap, {
    VoidCallback? onClear,
  }) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: value != null
              ? Border.all(color: c.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: value != null ? c.primary : c.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                  ),
                  Text(
                    value == null
                        ? 'Not set'
                        : DateFormat.yMMMd().format(value),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: value != null
                          ? c.onSurface
                          : c.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (value != null && onClear != null)
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

class _ReceiptImageViewer extends StatefulWidget {
  final String? imagePath;
  final String? imageUrl;

  const _ReceiptImageViewer({this.imagePath, this.imageUrl});

  @override
  State<_ReceiptImageViewer> createState() => _ReceiptImageViewerState();
}

class _ReceiptImageViewerState extends State<_ReceiptImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx, -position.dy)
        ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Receipt Image',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: 'receipt_image',
              child: widget.imagePath != null
                  ? Image.file(File(widget.imagePath!), fit: BoxFit.contain)
                  : Image.network(widget.imageUrl!, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
