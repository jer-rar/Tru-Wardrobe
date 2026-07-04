import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.skipAutoLogin = false});
  final bool skipAutoLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _autoLogging = false;
  bool _obscurePassword = true;
  String? _error;
  bool _signUpPending = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    if (!widget.skipAutoLogin) _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    if (!remember) return;
    final email = prefs.getString('saved_email') ?? '';
    final password = prefs.getString('saved_password') ?? '';
    if (email.isEmpty || password.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _rememberMe = true;
      _emailCtrl.text = email;
      _passwordCtrl.text = password;
    });
    _submit(autoLogin: true);
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', true);
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  Future<void> _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({bool autoLogin = false}) async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      if (!autoLogin) setState(() => _error = 'Please enter your email and password.');
      return;
    }
    if (autoLogin) {
      if (mounted) setState(() => _autoLogging = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      if (_isLogin) {
        await Supabase.instance.client.auth
            .signInWithPassword(email: email, password: password);
        if (_rememberMe) {
          await _saveCredentials(email, password);
        } else {
          await _clearSavedCredentials();
        }
      } else {
        final res =
            await Supabase.instance.client.auth.signUp(email: email, password: password);
        if (res.session == null && mounted) {
          setState(() {
            _signUpPending = true;
            _loading = false;
            _autoLogging = false;
          });
          return;
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _autoLogging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_autoLogging) {
      return const Scaffold(
        backgroundColor: Color(kBgColor),
        body: Center(child: CircularProgressIndicator(color: Color(kAccentColor))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.checkroom, color: Color(kAccentColor), size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Tru Wardrobe',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your closet, organized.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 40),
                if (_signUpPending)
                  const Column(children: [
                    Icon(Icons.mark_email_read, color: Colors.green, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Check your email to confirm your account, then log in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ])
                else ...[
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(kCardColor),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(kCardColor),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(kAccentColor),
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember me', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _submit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(kAccentColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isLogin ? 'Log In' : 'Sign Up',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            }),
                    child: Text(
                      _isLogin ? "Don't have an account? Sign up" : 'Already have an account? Log in',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
