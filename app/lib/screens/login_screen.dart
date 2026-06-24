import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() { _loading = true; _error = null; });

    final prov = context.read<AppProvider>();
    final err = prov.login(_idCtrl.text, _pwCtrl.text);

    setState(() { _loading = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Center(
                      child: Text('ج', style: TextStyle(fontSize: 44, color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // App name
                Center(child: Text('جمعيتي', style: GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.primary))),
                Center(child: Text(s('app.tagline'), style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textSecondary))),
                const SizedBox(height: 48),

                // Login card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s('auth.login'), style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(s('auth.loginSubtitle'), style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(height: 24),

                      // Identifier field
                      TextFormField(
                        controller: _idCtrl,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: s('auth.identifier'),
                          labelStyle: GoogleFonts.cairo(),
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                          hintText: '0661234567',
                          hintStyle: GoogleFonts.cairo(color: AppTheme.border),
                        ),
                        style: GoogleFonts.cairo(),
                        validator: (v) => (v?.isEmpty == true) ? s('auth.required') : null,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _pwCtrl,
                        obscureText: _obscure,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: s('auth.password'),
                          labelStyle: GoogleFonts.cairo(),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v?.isEmpty == true) ? s('auth.required') : null,
                      ),

                      // Error message
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: GoogleFonts.cairo(color: AppTheme.danger, fontSize: 13))),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(s('auth.loginBtn'), style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Default credentials hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(s('auth.defaultCredentials'), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _credRow(Icons.phone_android_rounded, s('auth.identifier'), '0661234567'),
                      const SizedBox(height: 6),
                      _credRow(Icons.lock_outline_rounded, s('auth.password'), 'admin123'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Language switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _langBtn(context, prov, 'ar', 'العربية'),
                    const SizedBox(width: 8),
                    _langBtn(context, prov, 'fr', 'Français'),
                    const SizedBox(width: 8),
                    _langBtn(context, prov, 'en', 'English'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _credRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text('$label: ', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary)),
      ],
    );
  }

  Widget _langBtn(BuildContext context, AppProvider prov, String code, String label) {
    final selected = prov.language == code;
    return GestureDetector(
      onTap: () => prov.setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(label, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}
