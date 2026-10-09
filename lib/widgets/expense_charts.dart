import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../models/expense.dart';

const categoryColors = [
  Color(0xff159d82),
  Color(0xff6587dc),
  Color(0xffe3a444),
  Color(0xff9e78d5),
  Color(0xffde7d8e),
];
const categoryIcons = [
  Icons.restaurant_rounded,
  Icons.school_rounded,
  Icons.directions_bus_rounded,
  Icons.shopping_bag_rounded,
  Icons.movie_rounded,
];

class ExpenseCharts extends StatefulWidget {
  const ExpenseCharts({super.key, required this.expenses});
  final List<Expense> expenses;
  @override
  State<ExpenseCharts> createState() => _ExpenseChartsState();
}

class _ExpenseChartsState extends State<ExpenseCharts> {
  int? selectedCategory, selectedDay;
  @override
  Widget build(BuildContext context) {
    final values = List<double>.filled(5, 0);
    final days = List<double>.filled(7, 0);
    final today = dayOnly(DateTime.now());
    final start = DateTime(today.year, today.month, today.day - 6);
    for (final e in widget.expenses) {
      values[e.category.index] += e.amount;
      final diff = dayOnly(e.date).difference(start).inDays;
      if (diff >= 0 && diff < 7) {
        days[diff] += e.amount;
      }
    }
    final total = values.fold(0.0, (a, b) => a + b);
    final text = Theme.of(context).colorScheme.onSurface;
    final key = ValueKey(
      widget.expenses
          .map((e) => '${e.id}:${e.amount}:${e.category}:${e.date}')
          .join('|'),
    );
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiêu theo danh mục',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 230,
                      height: 230,
                      child: GestureDetector(
                        onTapUp: (event) {
                          final d =
                              event.localPosition - const Offset(115, 115);
                          if (d.distance < 77 ||
                              d.distance > 108 ||
                              total == 0) {
                            return;
                          }
                          var angle = math.atan2(d.dy, d.dx) + math.pi / 2;
                          if (angle < 0) {
                            angle += math.pi * 2;
                          }
                          var end = 0.0;
                          for (var i = 0; i < values.length; i++) {
                            end += values[i] / total * math.pi * 2;
                            if (angle <= end) {
                              setState(
                                () => selectedCategory = selectedCategory == i
                                    ? null
                                    : i,
                              );
                              break;
                            }
                          }
                        },
                        child: CustomPaint(
                          painter: DonutPainter(
                            values,
                            progress,
                            selectedCategory,
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedCategory == null
                                      ? 'TỔNG CHI TIÊU'
                                      : ExpenseCategory
                                            .values[selectedCategory!]
                                            .label
                                            .toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  money(
                                    selectedCategory == null
                                        ? total
                                        : values[selectedCategory!],
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      5,
                      (i) => ChoiceChip(
                        selected: selectedCategory == i,
                        onSelected: (_) => setState(
                          () => selectedCategory = selectedCategory == i
                              ? null
                              : i,
                        ),
                        avatar: CircleAvatar(
                          radius: 5,
                          backgroundColor: categoryColors[i],
                        ),
                        label: Text(
                          '${ExpenseCategory.values[i].label} ${total == 0 ? 0 : (values[i] / total * 100).round()}%',
                        ),
                      ),
                    ),
                  ),
                  if (total == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Thêm giao dịch để xem phân bố chi tiêu.'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7 ngày gần đây',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedDay == null
                        ? 'Chạm vào cột để xem số tiền'
                        : '${shortDate(DateTime(start.year, start.month, start.day + selectedDay!))}: ${money(days[selectedDay!])}',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, box) => GestureDetector(
                        onTapUp: (event) => setState(
                          () => selectedDay =
                              (event.localPosition.dx / box.maxWidth * 7)
                                  .floor()
                                  .clamp(0, 6),
                        ),
                        child: CustomPaint(
                          painter: WeeklyPainter(
                            days,
                            start,
                            progress,
                            selectedDay,
                            text,
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.values, this.progress, this.selected, this.track);
  final List<double> values;
  final double progress;
  final int? selected;
  final Color track;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: 91);
    canvas.drawCircle(
      center,
      91,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24,
    );
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2 * progress;
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          start,
          math.max(0, sweep - .025),
          false,
          Paint()
            ..color = categoryColors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = (selected == i ? 32 : 24),
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => true;
}

class WeeklyPainter extends CustomPainter {
  WeeklyPainter(
    this.values,
    this.start,
    this.progress,
    this.selected,
    this.textColor,
    this.track,
  );
  final List<double> values;
  final DateTime start;
  final double progress;
  final int? selected;
  final Color textColor, track;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(1.0, values.reduce(math.max));
    final cell = size.width / 7, height = size.height - 48;
    for (var i = 0; i < 7; i++) {
      final x = cell * i + cell * .26, width = cell * .48;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 6, width, height),
          const Radius.circular(7),
        ),
        Paint()..color = track,
      );
      final h = values[i] / maxValue * height * progress;
      if (h > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, height + 6 - h, width, h),
            const Radius.circular(7),
          ),
          Paint()
            ..color = selected == i
                ? const Color(0xffe3a444)
                : categoryColors.first,
        );
      }
      final d = DateTime(start.year, start.month, start.day + i);
      final label = TextPainter(
        text: TextSpan(
          text: '${d.day}/${d.month}',
          style: TextStyle(color: textColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(cell * i + (cell - label.width) / 2, height + 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyPainter old) => true;
}
