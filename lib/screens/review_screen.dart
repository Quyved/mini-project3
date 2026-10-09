import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../models/expense.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../services/receipt_storage.dart';
import '../state/providers.dart';
import '../widgets/receipt_preview.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, this.imagePath, this.ocr, this.existing});
  final String? imagePath;
  final OcrResult? ocr;
  final Expense? existing;
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _merchant, _amount, _note;
  late final ParsedReceipt _parsed;
  DateTime? _date;
  ExpenseCategory _category = ExpenseCategory.food;
  bool _confirmed = false, _saving = false, _boxes = true;
  @override
  void initState() {
    super.initState();
    _parsed = ReceiptParser().parse(widget.ocr?.text ?? '');
    final e = widget.existing;
    _merchant = TextEditingController(text: e?.merchant ?? _parsed.merchant);
    _amount = TextEditingController(
      text: (e?.amount ?? _parsed.amount)?.toString() ?? '',
    );
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? _parsed.date;
    _category = e?.category ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) {
      return;
    }
    if (_date == null || !_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn ngày và xác nhận đã kiểm tra thông tin.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    StoredReceipt? stored;
    final storage = ReceiptStorage();
    try {
      if (widget.existing == null && widget.imagePath != null) {
        stored = await storage.persist(widget.imagePath!);
      }
      final expense = Expense(
        id: widget.existing?.id,
        merchant: _merchant.text.trim(),
        amount: ReceiptParser.parseVnd(_amount.text)!,
        date: _date!,
        category: _category,
        imagePath: stored?.image ?? widget.existing?.imagePath,
        thumbnailPath: stored?.thumbnail ?? widget.existing?.thumbnailPath,
        rawText: widget.ocr?.text ?? widget.existing?.rawText ?? '',
        note: _note.text.trim(),
      );
      // A database commit is the boundary. Never remove its receipt on a later refresh error.
      await ref.read(repositoryProvider).save(expense);
      stored = null;
      try {
        await ref.read(expensesProvider.notifier).refresh();
      } catch (_) {
        ref.invalidate(expensesProvider);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (stored != null) {
        await storage.cleanup(stored);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể hoàn tất: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.imagePath ?? widget.existing?.imagePath;
    final raw = widget.ocr?.text ?? widget.existing?.rawText ?? '';
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existing != null
                ? 'Sửa giao dịch'
                : path == null
                ? 'Thêm chi tiêu'
                : 'Kiểm tra hóa đơn',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (path != null) ...[
                      ReceiptPreview(
                        path: path,
                        ocr: widget.ocr,
                        showBoxes: _boxes,
                      ),
                      if (widget.ocr != null)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Hiển thị vùng chữ OCR'),
                          subtitle: Text(
                            'Nhận diện: ${widget.ocr!.elapsed.inMilliseconds} ms',
                          ),
                          value: _boxes,
                          onChanged: (v) => setState(() => _boxes = v),
                        ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.ocr != null) ...[
                      Card(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            [
                              'OCR có thể sai. Đối chiếu tên, tổng tiền và ngày với ảnh.',
                              ..._parsed.warnings,
                            ].join('\n'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      key: const Key('merchant'),
                      controller: _merchant,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Tên cửa hàng',
                        prefixIcon: Icon(Icons.storefront),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nhập tên cửa hàng'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('amount'),
                      controller: _amount,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tổng tiền (VND)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (v) => ReceiptParser.parseVnd(v ?? '') == null
                          ? 'Nhập số tiền từ 1 đến 1.000.000.000 đ'
                          : null,
                    ),
                    if (_parsed.candidates.isNotEmpty &&
                        widget.existing == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          children: _parsed.candidates
                              .take(5)
                              .map(
                                (c) => ActionChip(
                                  label: Text(money(c.amount)),
                                  tooltip: c.line,
                                  onPressed: _saving
                                      ? null
                                      : () => setState(
                                          () => _amount.text = c.amount
                                              .toString(),
                                        ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const Key('date'),
                      onPressed: _saving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100, 12, 31),
                              );
                              if (picked != null && mounted) {
                                setState(() => _date = picked);
                              }
                            },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _date == null
                            ? 'Chọn ngày giao dịch *'
                            : shortDate(_date!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: ExpenseCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (c) => setState(() => _category = c!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _note,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (tùy chọn)',
                      ),
                      maxLines: 2,
                    ),
                    if (raw.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ExpansionTile(
                          title: const Text('Văn bản OCR gốc'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(raw),
                            ),
                          ],
                        ),
                      ),
                    CheckboxListTile(
                      key: const Key('confirm'),
                      value: _confirmed,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Tôi đã kiểm tra tên, tổng tiền và ngày.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _confirmed = v ?? false),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('save'),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _saving ? 'Đang lưu...' : 'Xác nhận và lưu',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
