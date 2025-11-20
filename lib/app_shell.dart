import 'dart:io';
import 'package:flutter/material.dart';
import 'models/receipt.dart';
import 'services/receipt_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_receipt_screen.dart';
import 'screens/ocr_review_screen.dart';
import 'screens/search_filters_screen.dart';
import 'screens/spending_insights_screen.dart';

enum _Screen { home, camera, ocr, search }

class AppShell extends StatefulWidget {
  final String uid;
  const AppShell({super.key, required this.uid});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _svc = ReceiptService();
  _Screen _scr = _Screen.home;
  final _nav = [_Screen.home];
  Map<String, dynamic>? _filters;
  String? _img;
  Receipt? _edit;

  void _push(_Screen s) => setState(() {
    _scr = s;
    _nav.add(s);
  });
  void _back() => setState(() {
    if (_nav.length > 1) _nav.removeLast();
    _scr = _nav.last;
  });

  Stream<List<Receipt>> _stream() {
    final f = _filters ?? {};
    return _svc.watchReceiptsFiltered(
      widget.uid,
      storePrefix: f['storePrefix'],
      startDate: f['startDate'],
      endDate: f['endDate'],
      minTotal: f['minTotal'],
      maxTotal: f['maxTotal'],
      withImage: f['withImage'],
      categories: f['categories'],
    );
  }

  void _toInsights() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          SpendingInsightsScreen(uid: widget.uid, receiptService: _svc),
    ),
  );
  void _toOCR(Receipt? r, String? path) => setState(() {
    _edit = r;
    _img = path;
    _push(_Screen.ocr);
  });

  Future<void> _del(Receipt r) async {
    await _svc.deleteReceipt(uid: widget.uid, receipt: r);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${r.store} • \$${r.total.toStringAsFixed(2)}'),
        ),
      );
    }
  }

  Future<void> _save(Receipt draft) async {
    var r = (_edit != null) ? draft.copyWith(id: _edit!.id) : draft;
    if (_img != null) {
      try {
        r = r.copyWith(
          imageUrl: await _svc.uploadImage(
            uid: widget.uid,
            receiptId: r.id,
            file: File(_img!),
          ),
        );
      } catch (_) {}
    }
    await _svc.saveReceipt(uid: widget.uid, receipt: r);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved ${r.store} • \$${r.total.toStringAsFixed(2)}'),
      ),
    );
    setState(() {
      _edit = null;
      _img = null;
      _nav
        ..clear()
        ..add(_Screen.home);
      _scr = _Screen.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_scr) {
      case _Screen.home:
        return HomeScreen(
          receiptsStream: _stream(),
          filters: _filters,
          onScanReceipt: () => _push(_Screen.camera),
          onOpenSearch: () => _push(_Screen.search),
          onClearFilters: () => setState(() => _filters = null),
          onOpenInsights: _toInsights,
          onEditReceipt: (r) => _toOCR(r, null),
          onDeleteReceipt: _del,
        );
      case _Screen.camera:
        return AddReceiptScreen(
          onBack: _back,
          onCaptured: (p) => _toOCR(null, p),
        );
      case _Screen.ocr:
        return OCRReviewScreen(
          onBack: _back,
          onSave: _save,
          imagePath: _img,
          existing: _edit,
        );
      case _Screen.search:
        return SearchFiltersScreen(
          onBack: _back,
          onApply: (f) {
            setState(() => _filters = f);
            _back();
          },
        );
    }
  }
}

extension on Receipt {
  Receipt copyWith({
    String? id,
    String? store,
    DateTime? date,
    double? total,
    DateTime? returnBy,
    DateTime? warrantyEnds,
    String? category,
    String? imageUrl,
  }) {
    return Receipt(
      id: id ?? this.id,
      store: store ?? this.store,
      date: date ?? this.date,
      total: total ?? this.total,
      returnBy: returnBy ?? this.returnBy,
      warrantyEnds: warrantyEnds ?? this.warrantyEnds,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
