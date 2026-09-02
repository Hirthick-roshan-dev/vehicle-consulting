import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../model/payment_method.dart';
import '../../model/vehicle_model.dart';
import '../../model/vehicle_status.dart';
import '../../model/vehicle_type.dart';

class AddVehicleDialog extends StatefulWidget {
  final VehicleModel? vehicleToEdit;

  const AddVehicleDialog({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _vehicleNumberController;
  late TextEditingController _vehicleNameController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerPhoneController;
  late TextEditingController _mfgYearController;
  late TextEditingController _regYearController;
  late TextEditingController _purchaseDateController;
  late TextEditingController _purchaseAmountController;
  late TextEditingController _referenceController;
  late TextEditingController _commissionController;
  late TextEditingController _salePriceController;
  late TextEditingController _notesController;

  VehicleType _selectedType = VehicleType.fourWheeler;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedPurchaseDate = DateTime.now();
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;
    _vehicleNumberController = TextEditingController(text: v?.vehicleNumber ?? '');
    _vehicleNameController = TextEditingController(text: v?.vehicleName ?? '');
    _vehicleModelController = TextEditingController(text: v?.vehicleModel ?? '');
    _ownerNameController = TextEditingController(text: v?.ownerName ?? '');
    _ownerPhoneController = TextEditingController(
      text: v != null ? Validators.extract10Digits(v.ownerPhone) : '',
    );
    _mfgYearController = TextEditingController(
      text: v != null ? v.manufacturingYear.toString() : DateTime.now().year.toString(),
    );
    _regYearController = TextEditingController(
      text: v != null ? v.registrationYear.toString() : DateTime.now().year.toString(),
    );
    _selectedPurchaseDate = v != null
        ? AppDateUtils.parseIso(v.purchaseDate)
        : DateTime.now();
    _purchaseDateController = TextEditingController(
      text: AppDateUtils.formatDisplay(_selectedPurchaseDate),
    );
    _purchaseAmountController = TextEditingController(
      text: v != null ? v.purchaseAmount.toStringAsFixed(0) : '',
    );
    _referenceController = TextEditingController(text: v?.referenceName ?? '');
    _commissionController = TextEditingController(
      text: v != null && v.commissionAmount > 0 ? v.commissionAmount.toStringAsFixed(0) : '0',
    );
    _salePriceController = TextEditingController(
      text: v != null && v.salePrice > 0 ? v.salePrice.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: v?.notes ?? '');
    _imagePath = v?.imagePath;

    if (v != null) {
      _selectedType = v.vehicleType;
      _selectedPaymentMethod = v.paymentMethod;
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imagePath = result.files.single.path;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPurchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedPurchaseDate = picked;
        _purchaseDateController.text = AppDateUtils.formatDisplay(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? finalImagePath = _imagePath;
    if (_imagePath != null && File(_imagePath!).existsSync()) {
      try {
        final vehicleNum = _vehicleNumberController.text.trim().toUpperCase();
        finalImagePath = await ImageStorageService.saveVehicleImage(
          sourceFilePath: _imagePath!,
          vehicleNumber: vehicleNum,
        );
      } catch (_) {
        finalImagePath = _imagePath;
      }
    }

    final now = DateTime.now().toIso8601String();
    final vehicle = VehicleModel(
      id: widget.vehicleToEdit?.id,
      vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
      vehicleName: _vehicleNameController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      vehicleType: _selectedType,
      ownerName: _ownerNameController.text.trim(),
      ownerPhone: Validators.formatIndianPhone(_ownerPhoneController.text),
      manufacturingYear: int.parse(_mfgYearController.text.trim()),
      registrationYear: int.parse(_regYearController.text.trim()),
      purchaseDate: AppDateUtils.toIso(_selectedPurchaseDate),
      purchaseAmount: double.parse(_purchaseAmountController.text.trim()),
      paymentMethod: _selectedPaymentMethod,
      referenceName: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      commissionAmount: double.tryParse(_commissionController.text.trim()) ?? 0.0,
      salePrice: double.tryParse(_salePriceController.text.trim()) ?? 0.0,
      status: widget.vehicleToEdit?.status ?? VehicleStatus.available,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imagePath: finalImagePath,
      createdAt: widget.vehicleToEdit?.createdAt ?? now,
      updatedAt: now,
    );

    if (mounted) {
      Navigator.of(context).pop(vehicle);
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _vehicleNameController.dispose();
    _vehicleModelController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _mfgYearController.dispose();
    _regYearController.dispose();
    _purchaseDateController.dispose();
    _purchaseAmountController.dispose();
    _referenceController.dispose();
    _commissionController.dispose();
    _salePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicleToEdit != null;

    return AppDialog(
      title: isEdit ? 'Edit Vehicle Details' : 'Add New Vehicle',
      confirmText: isEdit ? 'Update Vehicle' : 'Add Vehicle',
      isLoading: _isLoading,
      onConfirm: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Attachment Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath != null && File(_imagePath!).existsSync()
                        ? Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            _selectedType == VehicleType.twoWheeler
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 36,
                            color: AppColors.secondaryText,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Photo / Image',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _imagePath != null
                              ? 'Copied to vehicle_consulting/images (${_imagePath!.split(Platform.pathSeparator).last})'
                              : 'Attach a photo to copy & store permanently in the app',
                          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.add_a_photo, size: 14),
                              label: Text(_imagePath != null ? 'Change Photo' : 'Attach Photo'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (_imagePath != null) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() => _imagePath = null);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.loss,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                                child: const Text('Remove', style: TextStyle(fontSize: 12)),
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
            const SizedBox(height: 20),

            // Section 1: Vehicle & Owner Info
            const Text(
              'Vehicle & Owner Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Vehicle Number *',
                    hint: 'e.g. TN-39-AB-1234',
                    controller: _vehicleNumberController,
                    validator: Validators.vehicleNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Vehicle Name *',
                    hint: 'e.g. Swift / Activa',
                    controller: _vehicleNameController,
                    validator: (val) => Validators.requiredField(val, 'Vehicle Name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Model / Variant *',
                    hint: 'e.g. VXI / 6G',
                    controller: _vehicleModelController,
                    validator: (val) => Validators.requiredField(val, 'Model'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Type *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<VehicleType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(),
                        items: VehicleType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Previous Owner Name *',
                    hint: 'Previous owner name',
                    controller: _ownerNameController,
                    validator: (val) => Validators.requiredField(val, 'Owner Name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Owner Mobile Number *',
                    hint: '10-digit mobile number',
                    controller: _ownerPhoneController,
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
                    label: 'Manufacturing Year *',
                    hint: 'e.g. 2020',
                    controller: _mfgYearController,
                    keyboardType: TextInputType.number,
                    validator: (val) => Validators.year(val, 'Manufacturing Year'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Registration Year *',
                    hint: 'e.g. 2020',
                    controller: _regYearController,
                    keyboardType: TextInputType.number,
                    validator: (val) => Validators.year(val, 'Registration Year'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 2: Purchase & Selling Pricing Information
            const Text(
              'Purchase & Selling Price Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Purchase Date *',
                    controller: _purchaseDateController,
                    readOnly: true,
                    onTap: _pickDate,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Purchase Amount (₹) *',
                    hint: 'e.g. 500000',
                    controller: _purchaseAmountController,
                    keyboardType: TextInputType.number,
                    validator: (val) => Validators.strictlyPositiveAmount(val, 'Purchase Amount'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: _selectedPaymentMethod,
                        decoration: const InputDecoration(),
                        items: PaymentMethod.values.map((pm) {
                          return DropdownMenuItem(
                            value: pm,
                            child: Text(pm.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentMethod = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Reference / Broker Name',
                    hint: 'Agent / Broker reference',
                    controller: _referenceController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Commission Amount (₹)',
                    hint: 'e.g. 5000',
                    controller: _commissionController,
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? null : Validators.positiveAmount(val, 'Commission'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Target Selling Price (₹) *',
                    hint: 'e.g. 550000 (Expected Customer Price)',
                    controller: _salePriceController,
                    keyboardType: TextInputType.number,
                    validator: (val) => Validators.strictlyPositiveAmount(val, 'Selling Price'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dedicated Full-Width Notes Field
            AppTextField(
              label: 'Notes & Vehicle Remarks',
              hint: 'Enter any additional details, vehicle condition, document remarks, etc...',
              controller: _notesController,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
