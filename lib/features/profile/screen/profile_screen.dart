import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../model/business_profile_model.dart';
import '../provider/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _gstController = TextEditingController();
  }

  void _populateFields(BusinessProfileModel profile) {
    _nameController.text = profile.businessName;
    _addressController.text = profile.address;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email ?? '';
    _gstController.text = profile.gstNumber ?? '';
  }

  Future<void> _saveProfile(BusinessProfileModel currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = BusinessProfileModel(
        id: currentProfile.id,
        businessName: currentProfile.businessName, // Locked
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await ref.read(profileRepositoryProvider).updateProfile(updated);
      ref.invalidate(businessProfileProvider);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile updated successfully!'),
            backgroundColor: AppColors.profit,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(businessProfileProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Official business information and office contact details.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: profileAsync.when(
                loading: () => const LoadingWidget(message: 'Loading profile...'),
                error: (err, stack) => Center(
                  child: Text('Error loading profile: $err', style: const TextStyle(color: AppColors.loss)),
                ),
                data: (profile) {
                  if (!_isEditing && _nameController.text.isEmpty) {
                    _populateFields(profile);
                  }

                  return SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.business,
                                            size: 28,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.businessName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryText,
                                              ),
                                            ),
                                            const Text(
                                              'Official Office Information',
                                              style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (!_isEditing)
                                      AppButton(
                                        text: 'Edit Profile',
                                        icon: Icons.edit_outlined,
                                        isSecondary: true,
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = true;
                                            _populateFields(profile);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const Divider(height: 32),

                                // Business Name Field (Locked)
                                AppTextField(
                                  label: 'Business Name (Locked)',
                                  hint: "BROTHER'S AUTO CONSULTING",
                                  controller: _nameController,
                                  readOnly: true, // Always locked
                                  suffixIcon: const Icon(Icons.lock, size: 18, color: Color(0xFF64748B)),
                                  validator: (val) => Validators.requiredField(val, 'Business Name'),
                                ),
                                const SizedBox(height: 16),

                                // Office Address
                                AppTextField(
                                  label: 'Office Address *',
                                  hint: 'Full street address',
                                  controller: _addressController,
                                  readOnly: !_isEditing,
                                  maxLines: 2,
                                  validator: (val) => Validators.requiredField(val, 'Address'),
                                ),
                                const SizedBox(height: 16),

                                // Contact Phone Numbers
                                AppTextField(
                                  label: 'Contact Numbers *',
                                  hint: 'e.g. 9578940360, 8072663566',
                                  controller: _phoneController,
                                  readOnly: !_isEditing,
                                  validator: (val) => Validators.requiredField(val, 'Contact Number'),
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Email Address',
                                        hint: 'office@example.com',
                                        controller: _emailController,
                                        readOnly: !_isEditing,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppTextField(
                                        label: 'GST Number',
                                        hint: 'Optional GST Registration',
                                        controller: _gstController,
                                        readOnly: !_isEditing,
                                      ),
                                    ),
                                  ],
                                ),

                                if (_isEditing) ...[
                                  const SizedBox(height: 28),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      AppButton(
                                        text: 'Cancel',
                                        isSecondary: true,
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = false;
                                            _populateFields(profile);
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      AppButton(
                                        text: 'Save Changes',
                                        isLoading: _isSaving,
                                        onPressed: () => _saveProfile(profile),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
