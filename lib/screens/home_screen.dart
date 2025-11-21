import 'package:flutter/material.dart';
import '../models/receipt.dart';

enum _Sort { dateDesc, dateAsc, totalDesc, totalAsc, storeAsc }

class HomeScreen extends StatefulWidget {
  final Stream<List<Receipt>> receiptsStream;
  final VoidCallback onScanReceipt,
      onOpenSearch,
      onClearFilters,
      onOpenInsights;
  final void Function(Receipt) onEditReceipt, onDeleteReceipt;
  final Map<String, dynamic>? filters;

  const HomeScreen({
    super.key,
    required this.receiptsStream,
    required this.onScanReceipt,
    required this.onOpenSearch,
    required this.onClearFilters,
    required this.onOpenInsights,
    required this.onEditReceipt,
    required this.onDeleteReceipt,
    required this.filters,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Sort _sort = _Sort.dateDesc;

  bool get _hasFilters => widget.filters?.isNotEmpty ?? false;

  String get _filterLabel {
    if (!_hasFilters) return 'Tap to filter';
    final f = widget.filters!;
    final parts = [
      if ((f['storePrefix'] ?? '').isNotEmpty) 'Store: "${f['storePrefix']}"',
      if (f['startDate'] != null || f['endDate'] != null)
        '${_fmt(f['startDate'])} - ${_fmt(f['endDate'])}',
      if (f['minTotal'] != null || f['maxTotal'] != null)
        '\$${f['minTotal'] ?? 0} - \$${f['maxTotal'] ?? '∞'}',
      if (f['withImage'] == true) 'Has image',
    ];
    return parts.isEmpty ? 'Filtered' : parts.join(' • ');
  }

  String _fmt(dynamic d) =>
      d is DateTime ? '${d.month}/${d.day}' : (d == null ? '...' : '');

  List<Receipt> _sorted(List<Receipt> list) {
    final l = List<Receipt>.of(list);
    switch (_sort) {
      case _Sort.dateDesc:
        l.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _Sort.dateAsc:
        l.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _Sort.totalDesc:
        l.sort((a, b) => b.total.compareTo(a.total));
        break;
      case _Sort.totalAsc:
        l.sort((a, b) => a.total.compareTo(b.total));
        break;
      case _Sort.storeAsc:
        l.sort(
          (a, b) => a.store.toLowerCase().compareTo(b.store.toLowerCase()),
        );
        break;
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text(
          'Receipts',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: c.surface,
        actions: [
          IconButton(
            tooltip: 'Insights',
            onPressed: widget.onOpenInsights,
            icon: const Icon(Icons.pie_chart_outline_rounded),
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Filters',
                onPressed: widget.onOpenSearch,
                icon: Icon(
                  _hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _hasFilters ? c.primary : null,
                ),
              ),
              if (_hasFilters)
                Positioned(
                  right: 12,
                  top: 12,
                  child: CircleAvatar(radius: 4, backgroundColor: c.error),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Receipt>>(
        stream: widget.receiptsStream,
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint("Firestore Query Error: ${snap.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: c.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Database Error",
                      style: TextStyle(
                        color: c.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "This filter requires a Firestore Index.\nCheck your Debug Console for the link to create it.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final waiting =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;
          final list = _sorted(snap.data ?? []);

          return Column(
            children: [
              // Filter Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(
                    bottom: BorderSide(color: c.outlineVariant, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    PopupMenuButton<_Sort>(
                      tooltip: 'Sort',
                      onSelected: (v) => setState(() => _sort = v),
                      position: PopupMenuPosition.under,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: _Sort.dateDesc,
                          child: Text('Newest first'),
                        ),
                        PopupMenuItem(
                          value: _Sort.dateAsc,
                          child: Text('Oldest first'),
                        ),
                        PopupMenuItem(
                          value: _Sort.totalDesc,
                          child: Text('Highest price'),
                        ),
                        PopupMenuItem(
                          value: _Sort.totalAsc,
                          child: Text('Lowest price'),
                        ),
                        PopupMenuItem(
                          value: _Sort.storeAsc,
                          child: Text('Store A–Z'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: c.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort,
                              size: 16,
                              color: c.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sort',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _hasFilters
                          ? InkWell(
                              onTap: widget.onOpenSearch,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: c.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: c.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      size: 16,
                                      color: c.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _filterLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: widget.onClearFilters,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: c.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                waiting
                                    ? 'Loading…'
                                    : '${list.length} Receipt${list.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: c.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: waiting
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? _EmptyState(
                        hasFilters: _hasFilters,
                        onAdd: widget.onScanReceipt,
                        onClear: widget.onClearFilters,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ReceiptItem(
                          r: list[i],
                          onEdit: widget.onEditReceipt,
                          onDelete: widget.onDeleteReceipt,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onScanReceipt,
        elevation: 4,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Scan Receipt'),
      ),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  final Receipt r;
  final Function(Receipt) onEdit, onDelete;
  const _ReceiptItem({
    required this.r,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final card = Card(
      elevation: 0,
      color: c.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => onEdit(r),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: c.surfaceContainerHighest,
                  border: Border.all(color: c.outlineVariant.withOpacity(0.3)),
                ),
                child: r.imageUrl?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          r.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.receipt, color: c.outline),
                        ),
                      )
                    : Center(
                        child: Text(
                          r.store.isNotEmpty ? r.store[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.onSurfaceVariant,
                            fontSize: 20,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r.store,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${r.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: c.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${r.date.month}/${r.date.day}/${r.date.year}',
                          style: TextStyle(
                            color: c.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        if (r.category?.isNotEmpty == true) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: c.outline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.category!,
                              style: TextStyle(
                                color: c.onSurfaceVariant,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: c.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: c.onErrorContainer, size: 28),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete?'),
          content: const Text('Undoing not possible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: c.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(r),
      child: card,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onAdd, onClear;
  const _EmptyState({
    required this.hasFilters,
    required this.onAdd,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off_outlined : Icons.receipt_outlined,
            size: 48,
            color: c.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No matches' : 'No receipts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          hasFilters
              ? OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Clear Filters'),
                )
              : FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Receipt'),
                ),
        ],
      ),
    );
  }
}
