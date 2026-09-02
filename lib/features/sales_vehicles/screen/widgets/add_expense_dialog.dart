import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../model/expense_model.dart';

class AddExpenseDialog extends StatefulWidget {
  final int vehicleId;
  final VehicleExpenseModel? expenseToEdit;

  const AddExpenseDialog({
    super.key,
    required this.vehicleId,
    this.expenseToEdit,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.expenseToEdit;
    _titleController = TextEditingController(text: e?.expenseTitle ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(0) : '',
    );
    _selectedDate = e != null ? AppDateUtils.parseIso(e.expenseDate) : DateTime.now();
    _dateController = TextEditingController(
      text: AppDateUtils.formatDisplay(_selectedDate),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = AppDateUtils.formatDisplay(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now().toIso8601String();

    final expense = VehicleExpenseModel(
      id: widget.expenseToEdit?.id,
      vehicleId: widget.vehicleId,
      expenseTitle: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      expenseDate: AppDateUtils.toIso(_selectedDate),
      createdAt: widget.expenseToEdit?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(expense);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expenseToEdit != null;

    return AppDialog(
      title: isEdit ? 'Edit Expense' : 'Add Expense',
      confirmText: isEdit ? 'Update Expense' : 'Save Expense',
      onConfirm: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              label: 'Expense Title *',
              hint: 'e.g. Painting / Service / RC Transfer',
              controller: _titleController,
              validator: (val) => Validators.requiredField(val, 'Expense Title'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Amount (₹) *',
              hint: 'e.g. 5000',
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (val) => Validators.strictlyPositiveAmount(val, 'Amount'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Expense Date *',
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Description / Details',
              hint: 'Optional notes',
              controller: _descriptionController,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
