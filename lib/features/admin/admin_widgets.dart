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
  final amount =
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
  return NumberFormat.currency(
    symbol: '₹',
    decimalDigits: amount == 0 ? 0 : 2,
  ).format(amount);
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    final key = label.toLowerCase();
    final color = switch (key) {
      'active' ||
      'successful' ||
      'published' ||
      'recorded' => const Color(0xFF059669),
      'pending' || 'requested' || 'pending_payment' => const Color(0xFFD97706),
      'failed' ||
      'inactive' ||
      'rejected' ||
      'cancelled' => const Color(0xFFDC2626),
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    final tint = accentColor ?? colors.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: colors.isDark ? 0.18 : 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tint, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      letterSpacing: -0.4,
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

class AdminBarChart extends StatelessWidget {
  const AdminBarChart({required this.title, required this.points, super.key});

  final String title;
  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    final values =
        points
            .map((point) => (point['value'] as num?)?.toDouble() ?? 0)
            .toList();
    final maxValue = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 142,
              child:
                  values.isEmpty
                      ? Center(
                        child: Text(
                          'No records in this period.',
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      )
                      : Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _AdminChartGrid(colors.border),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < values.length; i++)
                                Expanded(
                                  child: Tooltip(
                                    message:
                                        '${points[i]['label']}: ${values[i]}',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          height:
                                              maxValue == 0
                                                  ? 2
                                                  : 6 +
                                                      (values[i] / maxValue) *
                                                          108,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                colors.accent.withValues(
                                                  alpha:
                                                      values[i] == 0
                                                          ? 0.2
                                                          : 0.65,
                                                ),
                                                colors.accent,
                                              ],
                                            ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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

class _AdminChartGrid extends CustomPainter {
  const _AdminChartGrid(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 1;
    for (var row = 0; row < 4; row++) {
      final y = size.height * row / 3;
      canvas.drawLine(
        Offset.zero.translate(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AdminChartGrid oldDelegate) => oldDelegate.color != color;
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: colors.accent,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    super.key,
  });

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 1.4),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: colors.muted, size: 28),
            const SizedBox(height: 8),
            Text(
              'Nothing matches these filters.',
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          horizontalMargin: 18,
          columnSpacing: 26,
          headingRowHeight: 48,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 64,
          headingRowColor: WidgetStatePropertyAll(colors.cardAlt),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return colors.accentSoft;
            return colors.card;
          }),
          border: TableBorder(
            horizontalInside: BorderSide(
              color: colors.border.withValues(alpha: 0.6),
            ),
          ),
          headingTextStyle: TextStyle(
            color: colors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          dataTextStyle: TextStyle(color: colors.text, fontSize: 13),
          columns: [
            for (final column in columns) DataColumn(label: Text(column)),
          ],
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
  const AdminPager({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPage,
    super.key,
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = total == 0 ? 1 : ((total + pageSize - 1) / pageSize).ceil();
    final colors = DashboardColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
      child: Row(
        children: [
          Text(
            '$total records',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '$page / $pages',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: page < pages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
