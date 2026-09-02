import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../model/payment_method.dart';
import '../../model/payment_model.dart';

class AddPaymentDialog extends StatefulWidget {
  final int vehicleId;
  final int saleId;
  final double currentBalance;

  const AddPaymentDialog({
    super.key,
    required this.vehicleId,
    required this.saleId,
    required this.currentBalance,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _notesController;

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentBalance.toStringAsFixed(0),
    );
    _selectedDate = DateTime.now();
    _dateController = TextEditingController(
      text: AppDateUtils.formatDisplay(_selectedDate),
    );
    _notesController = TextEditingController();
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

    final payAmount = double.parse(_amountController.text.trim());
    if (payAmount > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment amount (${CurrencyUtils.format(payAmount)}) cannot exceed remaining balance (${CurrencyUtils.format(widget.currentBalance)}).',
          ),
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }

    final payment = VehiclePaymentModel(
      vehicleId: widget.vehicleId,
      saleId: widget.saleId,
      amount: payAmount,
      paymentDate: AppDateUtils.toIso(_selectedDate),
      paymentMethod: _selectedMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(payment);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Record Payment',
      confirmText: 'Save Payment',
      onConfirm: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.partialPayment.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining Balance Due:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyUtils.format(widget.currentBalance),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.partialPayment,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Payment Amount (₹) *',
              hint: 'e.g. 100000',
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (val) => Validators.strictlyPositiveAmount(val, 'Payment Amount'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Payment Date *',
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: _selectedMethod,
                        decoration: const InputDecoration(),
                        items: PaymentMethod.values.map((pm) {
                          return DropdownMenuItem(
                            value: pm,
                            child: Text(pm.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMethod = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Notes / Reference',
              hint: 'Optional notes',
              controller: _notesController,
            ),
          ],
        ),
      ),
    );
  }
}
