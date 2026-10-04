import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  void _handleLogin() {
    setState(() {
      _error = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.trim().isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    final auth = context.read<AuthProvider>();
    final result = auth.login(email, password);

    setState(() {
      _loading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully! Welcome to POS.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } else {
      setState(() {
        _error = result['error'] ?? 'Invalid credentials.';
      });
    }
  }

  void _autoFillDemo() {
    _emailController.text = 'admin@example.com';
    _passwordController.text = 'Admin@123';
    setState(() {
      _error = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.darkCardBorder),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, Color(0xFF2DD4BF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.store, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kunjuppa POS',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Smart Retail Billing & Store Management',
                  style: TextStyle(color: AppColors.darkSubtext, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // Demo Notice Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.shieldAlert, color: AppColors.warning, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demo Authentication Notice\nCredentials are authenticated locally in SharedPreferences.',
                          style: TextStyle(color: Colors.amberAccent, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error alert
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email Address', style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.mail, size: 18, color: AppColors.darkSubtext),
                    hintText: 'admin@example.com',
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Password', style: TextStyle(color: AppColors.darkText.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.darkText, fontSize: 13),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.lock, size: 18, color: AppColors.darkSubtext),
                    hintText: '••••••••',
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _loading ? null : _handleLogin,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Sign In to POS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(LucideIcons.arrowRight, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Auto-fill button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkInputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Email: admin@example.com', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontFamily: 'monospace')),
                          Text('Pass: Admin@123', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _autoFillDemo,
                        icon: const Icon(LucideIcons.sparkles, size: 14),
                        label: const Text('Auto-fill', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Kunjuppa Retail POS Engine • Flutter Mobile POS',
                  style: TextStyle(color: AppColors.darkSubtext, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
