import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../services/receipt_service.dart';
import '../utils/pdf_report.dart';

class SpendingInsightsScreen extends StatefulWidget {
  final String uid;
  final ReceiptService receiptService;
  const SpendingInsightsScreen({
    super.key,
    required this.uid,
    required this.receiptService,
  });
  @override
  State<SpendingInsightsScreen> createState() => _State();
}

class _State extends State<SpendingInsightsScreen> {
  final _shareKey = GlobalKey();
  DateTime? _start, _end;
  List<Receipt> _list = [];
  bool _load = false;

  double get _tot => _list.fold(0, (p, c) => p + c.total);

  Map<String, double> _group(String Function(Receipt) f) {
    final m = <String, double>{};
    for (var r in _list)
      m.update(f(r), (v) => v + r.total, ifAbsent: () => r.total);
    return m;
  }

  @override
  void initState() {
    super.initState();
    _end = DateTime.now();
    _start = _end!.subtract(const Duration(days: 30));
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _load = true);
    final res = await widget.receiptService.fetchReceiptsInRange(
      widget.uid,
      startDate: _start,
      endDate: _end,
    );
    if (mounted)
      setState(() {
        _list = res;
        _load = false;
      });
  }

  Future<void> _pick(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => start ? _start = d : _end = d);
      _fetch();
    }
  }

  Future<void> _export() async {
    if (_list.isEmpty) return;
    final f = File('${(await getTemporaryDirectory()).path}/report.pdf');
    await f.writeAsBytes(
      await generateSpendingReportPdf(
        PdfReportInput(
          title: 'Report',
          rangeStart: _start!,
          rangeEnd: _end!,
          receipts: _list,
          spendByCategory: _group((r) => r.category ?? 'Other'),
          spendByStore: _group((r) => r.store),
          grandTotal: _tot,
        ),
      ),
    );

    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    await Share.shareXFiles([XFile(f.path)], sharePositionOrigin: rect);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            key: _shareKey,
            icon: const Icon(Icons.ios_share),
            onPressed: _list.isEmpty ? null : _export,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _dateBtn('From', _start, () => _pick(true))),
                const SizedBox(width: 10),
                Expanded(child: _dateBtn('To', _end, () => _pick(false))),
              ],
            ),
          ),
          Expanded(
            child: _load
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                ? const Center(child: Text('No receipts'))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [c.primary, c.primaryContainer],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Spent',
                              style: TextStyle(
                                color: c.onPrimary.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              '\$${_tot.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: c.onPrimary,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  '${_list.length} Receipts',
                                  style: TextStyle(color: c.onPrimary),
                                ),
                                Text(
                                  'Avg \$${(_tot / _list.length).toStringAsFixed(2)}',
                                  style: TextStyle(color: c.onPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _head('Activity'),
                      _DailyChart(_list, c),
                      const SizedBox(height: 30),
                      _head('Breakdown'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _RankList(
                              'Top Categories',
                              _group(
                                (r) => (r.category ?? '').isEmpty
                                    ? 'Uncategorized'
                                    : r.category!,
                              ),
                              c.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _RankList(
                              'Top Stores',
                              _group((r) => r.store),
                              c.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _head(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
  Widget _dateBtn(String l, DateTime? d, VoidCallback t) => OutlinedButton.icon(
    onPressed: t,
    icon: const Icon(Icons.calendar_today, size: 16),
    label: Text('$l: ${d != null ? DateFormat('MM/dd').format(d) : '-'}'),
  );
}

class _DailyChart extends StatelessWidget {
  final List<Receipt> list;
  final ColorScheme c;
  const _DailyChart(this.list, this.c);
  @override
  Widget build(BuildContext context) {
    final g =
        groupBy(list, (r) => DateTime(r.date.year, r.date.month, r.date.day))
            .entries
            .map(
              (e) => MapEntry(e.key, e.value.fold(0.0, (p, c) => p + c.total)),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    if (g.isEmpty) return const SizedBox();
    final maxV = g.map((e) => e.value).fold(0.0, max);

    return Container(
      height: 180, // Increased height to accommodate text
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: g
            .map(
              (e) => Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // The Bar
                    Expanded(
                      child: Tooltip(
                        message:
                            '${DateFormat('MM/dd').format(e.key)}: \$${e.value.toStringAsFixed(2)}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FractionallySizedBox(
                            heightFactor: e.value / maxV,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: c.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // The Date Label
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DateFormat('M/d').format(e.key),
                        style: TextStyle(
                          fontSize: 10,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  final String t;
  final Map<String, double> data;
  final Color col;
  const _RankList(this.t, this.data, this.col);
  @override
  Widget build(BuildContext context) {
    final l = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...l
            .take(5)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Text(
                          '\$${e.value.toInt()}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: e.value / (l.first.value),
                        color: col,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
