import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dashboard/widgets/dashboard_colors.dart';

String adminWhen(Object? value) {
  if (value == null || value.toString().isEmpty) return '—';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return DateFormat('d MMM yyyy, HH:mm').format(parsed.toLocal());
}

String adminMoney(Object? value) {
  final amount = value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
  return NumberFormat.currency(symbol: '₹', decimalDigits: amount == 0 ? 0 : 2).format(amount);
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    final key = label.toLowerCase();
    final color = switch (key) {
      'active' || 'successful' || 'published' || 'recorded' => const Color(0xFF059669),
      'pending' || 'requested' || 'pending_payment' => const Color(0xFFD97706),
      'failed' || 'inactive' || 'rejected' || 'cancelled' => const Color(0xFFDC2626),
      'admin' => colors.accent,
      _ => colors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({required this.title, required this.value, required this.icon, super.key});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, style: TextStyle(color: colors.muted, fontSize: 12, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminBarChart extends StatelessWidget {
  const AdminBarChart({required this.title, required this.points, super.key});

  final String title;
  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    final values = points.map((point) => (point['value'] as num?)?.toDouble() ?? 0).toList();
    final maxValue = values.fold<double>(0, (max, value) => value > max ? value : max);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: values.isEmpty
                  ? Text('No records in this period.', style: TextStyle(color: colors.muted))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < values.length; i++)
                          Expanded(
                            child: Tooltip(
                              message: '${points[i]['label']}: ${values[i]}',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: maxValue == 0 ? 2 : 8 + (values[i] / maxValue) * 100,
                                    decoration: BoxDecoration(
                                      color: colors.accent.withValues(alpha: values[i] == 0 ? 0.25 : 1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStateMessage extends StatelessWidget {
  const AdminStateMessage({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: colors.accent, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.text, height: 1.4)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({required this.controller, required this.hint, required this.onChanged, super.key});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: colors.text, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.field,
        hintText: hint,
        hintStyle: TextStyle(color: colors.muted),
        prefixIcon: Icon(Icons.search, color: colors.accent, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
      ),
    );
  }
}

class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    required this.columns,
    required this.rows,
    this.onRow,
    super.key,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final void Function(int index)? onRow;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text('Nothing matches these filters.', style: TextStyle(color: colors.muted)),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingTextStyle: TextStyle(color: colors.muted, fontWeight: FontWeight.w700, fontSize: 12),
          dataTextStyle: TextStyle(color: colors.text, fontSize: 13),
          columns: [for (final column in columns) DataColumn(label: Text(column))],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
                onSelectChanged: onRow == null ? null : (_) => onRow!(i),
                cells: [for (final cell in rows[i]) DataCell(cell)],
              ),
          ],
        ),
      ),
    );
  }
}

class AdminPager extends StatelessWidget {
  const AdminPager({required this.page, required this.pageSize, required this.total, required this.onPage, super.key});

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = total == 0 ? 1 : ((total + pageSize - 1) / pageSize).ceil();
    final colors = DashboardColors.of(context);
    return Row(
      children: [
        Text('$total records', style: TextStyle(color: colors.muted, fontSize: 12)),
        const Spacer(),
        IconButton(
          onPressed: page > 1 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $pages', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: page < pages ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
