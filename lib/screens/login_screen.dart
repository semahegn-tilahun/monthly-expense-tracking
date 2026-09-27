import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../providers/budget_provider.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Owner');
  final _emailController = TextEditingController(text: AppConstants.defaultEmail);
  final _pinController = TextEditingController(text: AppConstants.defaultPin);
  bool _isRegister = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<BudgetProvider>();
    try {
      if (_isRegister) {
        await provider.register(_nameController.text, _emailController.text, _pinController.text);
      } else {
        final ok = await provider.login(_emailController.text, _pinController.text);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email or PIN')));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: AppConstants.primary,
                    child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isRegister ? 'Create account' : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegister ? 'Register a local user on this phone.' : 'Use the seeded login or your registered account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isRegister) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                                validator: (value) => Validators.requiredText(value, 'Full name'),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                              validator: (value) => Validators.requiredText(value, 'Email'),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _pinController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'PIN', prefixIcon: Icon(Icons.lock_outline)),
                              validator: Validators.pin,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: _submitting
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(_isRegister ? Icons.person_add_alt_1 : Icons.login),
                                label: Text(_isRegister ? 'Register' : 'Login'),
                              ),
                            ),
                            TextButton(
                              onPressed: _submitting ? null : () => setState(() => _isRegister = !_isRegister),
                              child: Text(_isRegister ? 'Already have account? Login' : 'Create new account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Default: owner@local.app / 1234',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
