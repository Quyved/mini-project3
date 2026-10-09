import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../models/expense.dart';
import '../state/providers.dart';
import '../widgets/expense_charts.dart';
import 'capture_screen.dart';
import 'review_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  ExpenseCategory? _category;
  String _search = '';
  Future<void> _delete(Expense expense) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: Text(
          '${expense.merchant} • ${money(expense.amount)}\nẢnh hóa đơn cũng sẽ bị xóa khỏi bộ nhớ ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (yes != true) {
      return;
    }
    try {
      await ref.read(expensesProvider.notifier).delete(expense);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
      }
    }
  }

  Future<void> _add() async {
    final scan = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Quét hóa đơn'),
                subtitle: const Text('Chụp ảnh hoặc chọn từ thư viện'),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Nhập thủ công'),
                subtitle: const Text('Thêm chi tiêu không có hóa đơn'),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (scan == null || !mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => scan ? const CaptureScreen() : const ReviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Receipt Lens',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('theme'),
            tooltip: dark ? 'Chế độ sáng' : 'Chế độ tối',
            onPressed: () => ref.read(themeProvider.notifier).toggle(dark),
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Không tải được dữ liệu: $error',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(expensesProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (expenses) {
          final total = expenses.fold(0, (sum, e) => sum + e.amount);
          final month = DateTime.now();
          final monthTotal = expenses
              .where(
                (e) => e.date.year == month.year && e.date.month == month.month,
              )
              .fold(0, (sum, e) => sum + e.amount);
          final filtered = expenses
              .where(
                (e) =>
                    (_category == null || e.category == _category) &&
                    ('${e.merchant} ${e.note}'.toLowerCase().contains(
                      _search.toLowerCase(),
                    )),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(expensesProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tab == 0
                              ? 'Chi tiêu trong tầm tay'
                              : 'Lịch sử giao dịch',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tab == 0
                              ? 'Quét hóa đơn, kiểm tra và lưu ngay trên thiết bị.'
                              : '${expenses.length} giao dịch • Tổng ${money(total)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        if (_tab == 0) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                colors: [Color(0xff116c60), Color(0xff179c80)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THÁNG ${month.month}/${month.year}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  money(monthTotal),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Dữ liệu được lưu trên thiết bị',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ExpenseCharts(expenses: expenses),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Giao dịch gần đây',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton(
                                onPressed: () => setState(() => _tab = 1),
                                child: const Text('Xem tất cả'),
                              ),
                            ],
                          ),
                        ] else ...[
                          TextField(
                            key: const Key('search'),
                            decoration: const InputDecoration(
                              hintText: 'Tìm cửa hàng hoặc ghi chú',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: _category == null,
                                onSelected: (_) =>
                                    setState(() => _category = null),
                              ),
                              ...ExpenseCategory.values.map(
                                (c) => ChoiceChip(
                                  label: Text(c.label),
                                  selected: _category == c,
                                  onSelected: (_) => setState(
                                    () => _category = _category == c ? null : c,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if ((_tab == 0 ? expenses : filtered).isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      expenses.isEmpty
                                          ? 'Chưa có giao dịch'
                                          : 'Không có kết quả phù hợp',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    if (expenses.isEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Bắt đầu bằng một hóa đơn hoặc nhập thủ công.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ...(_tab == 0 ? expenses.take(5) : filtered).map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  leading: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: e.thumbnailPath == null
                                        ? _categoryIcon(e)
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              File(e.thumbnailPath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, error, stack) =>
                                                  _categoryIcon(e),
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    e.merchant,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${e.category.label} • ${shortDate(e.date)}',
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReviewScreen(existing: e),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        money(e.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Thao tác',
                                        onSelected: (action) {
                                          if (action == 'delete') {
                                            _delete(e);
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ReviewScreen(existing: e),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Sửa'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Xóa'),
                                          ),
                                        ],
                                      ),
                                    ],
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
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add'),
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Thêm chi tiêu'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Giao dịch',
          ),
        ],
      ),
    );
  }

  Widget _categoryIcon(Expense e) => Container(
    decoration: BoxDecoration(
      color: categoryColors[e.category.index].withValues(alpha: .13),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      categoryIcons[e.category.index],
      color: categoryColors[e.category.index],
    ),
  );
}
