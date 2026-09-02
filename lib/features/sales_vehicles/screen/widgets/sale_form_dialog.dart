import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../model/payment_method.dart';
import '../../model/sale_model.dart';

class SaleFormResult {
  final String customerName;
  final String customerPhone;
  final String saleDate;
  final PaymentMethod paymentType;
  final bool isEmi;
  final String? financeName;
  final double totalSaleAmount;
  final double advanceAmount;
  final String? notes;

  SaleFormResult({
    required this.customerName,
    required this.customerPhone,
    required this.saleDate,
    required this.paymentType,
    required this.isEmi,
    this.financeName,
    required this.totalSaleAmount,
    required this.advanceAmount,
    this.notes,
  });
}

class SaleFormDialog extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;
  final String vehicleNumber;
  final double suggestedPrice;
  final VehicleSaleModel? saleToEdit;

  const SaleFormDialog({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.suggestedPrice,
    this.saleToEdit,
  });

  @override
  State<SaleFormDialog> createState() => _SaleFormDialogState();
}

class _SaleFormDialogState extends State<SaleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _saleDateController;
  late TextEditingController _totalAmountController;
  late TextEditingController _advanceAmountController;
  late TextEditingController _financeNameController;
  late TextEditingController _notesController;

  PaymentMethod _selectedPaymentType = PaymentMethod.cash;
  bool _isEmi = false;
  DateTime _selectedSaleDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final s = widget.saleToEdit;
    _customerNameController = TextEditingController(text: s?.customerName ?? '');
    _customerPhoneController = TextEditingController(
      text: s != null ? Validators.extract10Digits(s.customerPhone) : '',
    );
    _selectedSaleDate = s != null ? AppDateUtils.parseIso(s.saleDate) : DateTime.now();
    _saleDateController = TextEditingController(
      text: AppDateUtils.formatDisplay(_selectedSaleDate),
    );
    _totalAmountController = TextEditingController(
      text: s != null
          ? s.totalAmount.toStringAsFixed(0)
          : (widget.suggestedPrice > 0 ? widget.suggestedPrice.toStringAsFixed(0) : ''),
    );
    _advanceAmountController = TextEditingController(text: '0');
    _financeNameController = TextEditingController(text: s?.financeName ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');

    if (s != null) {
      _selectedPaymentType = s.paymentType;
      _isEmi = s.isEmi;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedSaleDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedSaleDate = picked;
        _saleDateController.text = AppDateUtils.formatDisplay(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final totalSale = double.parse(_totalAmountController.text.trim());
    final advance = double.tryParse(_advanceAmountController.text.trim()) ?? 0.0;

    if (widget.saleToEdit == null) {
      final paymentError = Validators.validatePayment(
        advancePaid: advance,
        totalSaleAmount: totalSale,
      );

      if (paymentError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paymentError), backgroundColor: AppColors.loss),
        );
        return;
      }
    }

    if (_isEmi && _financeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finance company name is required when EMI is enabled.'),
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }

    final result = SaleFormResult(
      customerName: _customerNameController.text.trim(),
      customerPhone: Validators.formatIndianPhone(_customerPhoneController.text),
      saleDate: AppDateUtils.toIso(_selectedSaleDate),
      paymentType: _selectedPaymentType,
      isEmi: _isEmi,
      financeName: _isEmi ? _financeNameController.text.trim() : null,
      totalSaleAmount: totalSale,
      advanceAmount: advance,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _saleDateController.dispose();
    _totalAmountController.dispose();
    _advanceAmountController.dispose();
    _financeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.saleToEdit != null;

    return AppDialog(
      title: isEdit ? 'Edit Sale Information' : 'Complete / Sell Vehicle',
      confirmText: isEdit ? 'Update Sale Details' : 'Record Sale',
      onConfirm: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.vehicleName} (${widget.vehicleNumber})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Customer Name *',
                    hint: 'Full name',
                    controller: _customerNameController,
                    validator: (val) => Validators.requiredField(val, 'Customer Name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Customer Mobile Number *',
                    hint: '10-digit mobile number',
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    prefixText: '+91 ',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: Validators.phoneNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Sale Date *',
                    controller: _saleDateController,
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
                        'Payment Type *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: _selectedPaymentType,
                        decoration: const InputDecoration(),
                        items: PaymentMethod.values.map((pm) {
                          return DropdownMenuItem(
                            value: pm,
                            child: Text(pm.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentType = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // EMI Checkbox
            Row(
              children: [
                Checkbox(
                  value: _isEmi,
                  onChanged: (val) {
                    setState(() {
                      _isEmi = val ?? false;
                    });
                  },
                ),
                const Text(
                  'Vehicle Sold via Finance / EMI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            if (_isEmi) ...[
              const SizedBox(height: 8),
              AppTextField(
                label: 'Finance / Bank Company Name *',
                hint: 'e.g. HDFC Finance / TVS Credit',
                controller: _financeNameController,
                validator: (val) => _isEmi ? Validators.requiredField(val, 'Finance Company Name') : null,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Total Sale Amount (₹) *',
                    hint: 'e.g. 500000',
                    controller: _totalAmountController,
                    keyboardType: TextInputType.number,
                    validator: (val) => Validators.strictlyPositiveAmount(val, 'Total Sale Amount'),
                  ),
                ),
                if (!isEdit) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Advance Amount Paid (₹)',
                      hint: 'e.g. 200000 (Enter 0 if unpaid)',
                      controller: _advanceAmountController,
                      keyboardType: TextInputType.number,
                      validator: (val) => Validators.positiveAmount(val, 'Advance Paid'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Dedicated Sale Notes Field
            AppTextField(
              label: 'Sale Notes & Delivery Remarks',
              hint: 'Enter delivery remarks, RTO documentation notes, buyer instructions...',
              controller: _notesController,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
