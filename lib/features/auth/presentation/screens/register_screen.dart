import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_controller.dart';
import '../../data/countries_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Customer registration. Sellers and admins register on the web app only.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _countryId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_countryId == null) {
      setState(() => _error = 'Choose the country you are gifting from.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
            countryId: _countryId!,
          );
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go(AppRoutes.account);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not create your account. Try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);

    return AuthScaffold(
      title: 'Create your account',
      subtitle:
          'Save gifts across devices, check out faster, and track every '
          'delivery you send.',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) ...[
              AuthAlert(message: _error!),
              const SizedBox(height: 18),
            ],
            AuthField(
              label: 'Name',
              controller: _nameController,
              hintText: 'How should we greet you?',
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 16),
            AuthField(
              label: 'Email',
              controller: _emailController,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || !value.contains('@'))
                  ? 'Enter a valid email address'
                  : null,
            ),
            const SizedBox(height: 16),
            AuthField(
              label: 'Password',
              controller: _passwordController,
              hintText: 'At least 8 characters',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) => (value == null || value.length < 8)
                  ? 'Use at least 8 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Country',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 7),
                countries.when(
                  loading: () => const _CountryPlaceholder(
                    label: 'Loading countries…',
                  ),
                  error: (error, stack) => const _CountryPlaceholder(
                    label: 'Countries unavailable — try again later',
                  ),
                  data: (list) => DropdownButtonFormField<String>(
                    initialValue: _countryId,
                    isExpanded: true,
                    hint: const Text('Select your country'),
                    items: [
                      for (final country in list)
                        DropdownMenuItem(
                          value: country.id,
                          child: Text('${country.name} (${country.isoCode})'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _countryId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryForeground,
                        ),
                      )
                    : const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => context.pushReplacement(AppRoutes.login),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _CountryPlaceholder extends StatelessWidget {
  const _CountryPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
