import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../../models/access_level.dart';
import 'access_level_dropdown.dart';
import 'department_agencies_field.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _cityRegionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AccessLevel _accessLevel = AccessLevel.resident;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _departmentController.dispose();
    _cityRegionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthRepository.instance.signUp(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        accessLevel: _accessLevel,
        cityRegion: _cityRegionController.text,
        departmentAgencies: _accessLevel == AccessLevel.cityLeader
            ? _departmentController.text
            : null,
      );

      if (mounted) {
        final hasSession = AuthRepository.instance.currentSession != null;
        context.go(hasSession ? '/about' : '/login');
      }
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'Failed to create account. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              setState(() => _accessLevel = level);
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
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: passwordValidator,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) =>
                confirmPasswordValidator(value, _passwordController.text),
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
          PrimaryButton(
            label: AppStrings.signupButton,
            onPressed: _handleSubmit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
