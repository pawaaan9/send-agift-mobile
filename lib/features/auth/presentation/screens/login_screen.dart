import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../data/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Customer sign-in. Reached only when the customer chooses to — from
/// checkout, order history, or the account tab.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go(AppRoutes.account);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle:
          'Sign in to check out, track deliveries, and keep your saved gifts '
          'across devices.',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) ...[
              AuthAlert(message: _error!),
              const SizedBox(height: 18),
            ],
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: AuthField(
                label: 'Email',
                controller: _emailController,
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Enter a valid email address'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 190),
              child: AuthField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Your password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Enter your password'
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: SizedBox(
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
                      : const Text('Sign in'),
                ),
              ),
            ),
          ],
        ),
      ),
      footer: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New to SendAgift?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () => context.pushReplacement(AppRoutes.register),
                child: const Text('Create an account'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.go(AppRoutes.explore),
            child: const Text('Keep browsing as a guest'),
          ),
        ],
      ),
    );
  }
}
