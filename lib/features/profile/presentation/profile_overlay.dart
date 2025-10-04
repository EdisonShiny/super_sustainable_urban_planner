import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/models/access_level.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/presentation/widgets/access_level_dropdown.dart';
import '../../auth/presentation/widgets/department_agencies_field.dart';
import '../data/profile_repository.dart';

class ProfileOverlay extends StatefulWidget {
  const ProfileOverlay({
    super.key,
    required this.profile,
    required this.onUpdated,
  });

  final UserProfile profile;
  final ValueChanged<UserProfile> onUpdated;

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required ValueChanged<UserProfile> onUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ProfileOverlay(profile: profile, onUpdated: onUpdated),
      ),
    );
  }

  @override
  State<ProfileOverlay> createState() => _ProfileOverlayState();
}

class _ProfileOverlayState extends State<ProfileOverlay> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityRegionController;
  late final TextEditingController _departmentController;
  late AccessLevel _accessLevel;
  bool _isSaving = false;
  String? _error;
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isUpdatingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _emailController = TextEditingController(text: widget.profile.email);
    _cityRegionController = TextEditingController(
      text: widget.profile.cityRegion,
    );
    _departmentController = TextEditingController(
      text: widget.profile.departmentAgencies ?? '',
    );
    _accessLevel = widget.profile.accessLevel;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _cityRegionController.dispose();
    _departmentController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final department = _accessLevel == AccessLevel.cityLeader
          ? _departmentController.text.trim()
          : null;

      final updated = widget.profile.copyWith(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        accessLevel: _accessLevel,
        cityRegion: _cityRegionController.text.trim(),
        departmentAgencies: department?.isEmpty == true ? null : department,
      );

      final persisted = await ProfileRepository.instance.updateProfile(updated);
      widget.onUpdated(persisted);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = 'Unable to update profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handlePasswordUpdate() async {
    final formState = _passwordFormKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await ProfileRepository.instance.updatePassword(
        _newPasswordController.text.trim(),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      formState.reset();
      setState(() {
        _passwordSuccess = AppStrings.passwordUpdated;
      });
    } on AuthException catch (error) {
      setState(() => _passwordError = error.message);
    } catch (_) {
      setState(
        () => _passwordError = 'Unable to update password. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.navProfile,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Update your account details to keep the portal personalized.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: requiredValidator,
                    ),
                    const SizedBox(height: 20),
                    AccessLevelDropdown(
                      value: _accessLevel,
                      onChanged: (level) {
                        setState(() {
                          _accessLevel = level;
                          if (_accessLevel != AccessLevel.cityLeader) {
                            _departmentController.clear();
                          }
                        });
                      },
                    ),
                    if (_accessLevel == AccessLevel.cityLeader) ...[
                      const SizedBox(height: 20),
                      DepartmentAgenciesField(
                        controller: _departmentController,
                        validator: requiredValidator,
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _cityRegionController,
                      decoration: const InputDecoration(
                        labelText: 'City / Region',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: requiredValidator,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: emailValidator,
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                AppStrings.passwordSectionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.passwordSectionDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.newPasswordLabel,
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: passwordValidator,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.confirmPasswordLabel,
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) => confirmPasswordValidator(
                        value,
                        _newPasswordController.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (_passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _passwordError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_passwordSuccess != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _passwordSuccess!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 200,
                  child: PrimaryButton(
                    label: AppStrings.updatePassword,
                    onPressed: _handlePasswordUpdate,
                    isLoading: _isUpdatingPassword,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.cancel),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: PrimaryButton(
                      label: AppStrings.saveChanges,
                      onPressed: _handleSave,
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
