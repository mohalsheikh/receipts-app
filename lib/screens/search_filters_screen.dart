import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SearchFiltersScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>> onApply;
  const SearchFiltersScreen({
    super.key,
    required this.onBack,
    required this.onApply,
  });

  @override
  State<SearchFiltersScreen> createState() => _State();
}

class _State extends State<SearchFiltersScreen> {
  final _store = TextEditingController(),
      _min = TextEditingController(),
      _max = TextEditingController(),
      _cat = TextEditingController();
  DateTime? _from, _to;
  int? _exp;
  final _cats = <String>[];
  final _allCats = [
    'Groceries',
    'Dining',
    'Electronics',
    'Home',
    'Clothing',
    'Utilities',
    'Transport',
  ];

  @override
  void dispose() {
    for (var c in [_store, _min, _max, _cat]) c.dispose();
    super.dispose();
  }

  void _apply() {
    FocusScope.of(context).unfocus();
    widget.onApply({
      if (_store.text.isNotEmpty) 'storePrefix': _store.text.trim(),
      if (_from != null) 'startDate': _from,
      if (_to != null)
        'endDate': _to!.add(const Duration(hours: 23, minutes: 59)),
      if (_min.text.isNotEmpty) 'minTotal': double.tryParse(_min.text),
      if (_max.text.isNotEmpty) 'maxTotal': double.tryParse(_max.text),
      if (_exp != null) 'expiringInDays': _exp,
      if (_cats.isNotEmpty) 'categories': _cats,
    });
    widget.onBack();
  }

  Future<void> _pick(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (start ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => start ? _from = d : _to = d);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        leading: CloseButton(onPressed: widget.onBack),
        title: const Text('Filters'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _store.clear();
              _min.clear();
              _max.clear();
              _cats.clear();
              _from = _to = null;
              _exp = null;
            }),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _head('Merchant', Icons.storefront),
          TextField(
            controller: _store,
            decoration: _dec('Store name', Icons.search),
          ),
          const SizedBox(height: 20),
          _head('Date Range', Icons.calendar_today),
          Row(
            children: [
              Expanded(child: _dateBtn('From', _from, () => _pick(true))),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward, size: 16),
              const SizedBox(width: 10),
              Expanded(child: _dateBtn('To', _to, () => _pick(false))),
            ],
          ),
          const SizedBox(height: 20),
          _head('Amount', Icons.attach_money),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Min', null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Max', null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _head('Categories', Icons.category),
          TextField(
            controller: _cat,
            onSubmitted: (v) {
              if (v.isNotEmpty) {
                setState(() {
                  _cats.add(v);
                  _cat.clear();
                });
              }
            },
            decoration: _dec('Add custom...', Icons.add),
          ),
          Wrap(
            spacing: 8,
            children: {..._cats, ..._allCats}
                .map(
                  (x) => FilterChip(
                    label: Text(x),
                    selected: _cats.contains(x),
                    onSelected: (s) =>
                        setState(() => s ? _cats.add(x) : _cats.remove(x)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          _head('Expiring Soon', Icons.timer),
          ToggleButtons(
            isSelected: [7, 14, 30].map((d) => _exp == d).toList(),
            onPressed: (i) => setState(
              () => _exp = [7, 14, 30][i] == _exp ? null : [7, 14, 30][i],
            ),
            borderRadius: BorderRadius.circular(12),
            children: const [Text('7 Days'), Text('14 Days'), Text('30 Days')],
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: _apply,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Show Results'),
          ),
        ],
      ),
    );
  }

  Widget _head(String t, IconData i) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(i, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
  InputDecoration _dec(String h, IconData? i) => InputDecoration(
    hintText: h,
    prefixIcon: i != null ? Icon(i) : null,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
  Widget _dateBtn(String l, DateTime? d, VoidCallback t) => InkWell(
    onTap: t,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: d != null
            ? Border.all(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(fontSize: 11)),
          Text(
            d == null ? 'Select' : DateFormat.yMMMd().format(d),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
