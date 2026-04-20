import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/validators.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        name: _fullNameController.text,
        mobile: _mobileController.text,
        dob: _dobController.text,
      );
      // GoRouter redirect handles navigation
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message = 'An error occurred';
      if (e is FirebaseAuthException) {
        if (e.code == 'weak-password') {
          message = 'The password is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'An account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email format.';
        } else {
          message = e.message ?? 'Authentication failed';
        }
      } else if (e.toString().contains('email-already-in-use')) {
        message = 'An account already exists for that email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/welcome');
                          }
                        },
                        icon: const Icon(Icons.arrow_back, color: AppColors.subtleText),
                      ),
                      const SizedBox(width: 50),
                      const Center(
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                            color: AppColors.primaryPink,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Full Name"),
                      _buildField(_fullNameController, "John Doe", validator: Validators.validateName),
                      const SizedBox(height: 16),
                      _buildLabel("Email"),
                      _buildField(_emailController, "example@example.com",
                          type: TextInputType.emailAddress, validator: Validators.validateEmail),
                      const SizedBox(height: 16),
                      _buildLabel("Mobile Number"),
                      _buildField(_mobileController, "+ 123 456 789",
                          type: TextInputType.phone, validator: Validators.validatePhone),
                      const SizedBox(height: 16),
                      _buildLabel("Date Of Birth"),
                      _buildField(
                        _dobController,
                        "DD/MM/YYYY",
                        type: TextInputType.datetime,
                        validator: Validators.validateDob,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          DateInputFormatter(),
                        ],
                        suffixIcon: IconButton(
                          onPressed: _pickDob,
                          icon: const Icon(Icons.calendar_today_outlined, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel("Password"),
                      _buildPasswordField(_passwordController, _obscurePass, () {
                        setState(() => _obscurePass = !_obscurePass);
                      }, validator: Validators.validatePassword),
                      const SizedBox(height: 16),
                      _buildLabel("Confirm Password"),
                      _buildPasswordField(_confirmPasswordController, _obscureConfirm, () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      }, validator: (v) => Validators.validateConfirmPassword(v, _passwordController.text)),
                      const SizedBox(height: 20),

                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, color: AppColors.subtleText),
                            children: [
                              TextSpan(text: "By continuing, you agree to\n"),
                              TextSpan(text: "Terms of Use", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: " and "),
                              TextSpan(text: "Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: "."),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // SIGN UP BUTTON
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _signUp,
                          child: Container(
                            width: 220,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/login');
                            }
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(fontWeight: FontWeight.w300, fontSize: 13, color: AppColors.darkText),
                              children: [
                                TextSpan(
                                  text: "Log in",
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.darkText),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      {
      TextInputType type = TextInputType.text,
      String? Function(String?)? validator,
      List<TextInputFormatter>? inputFormatters,
      Widget? suffixIcon,
    }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.hintColor),
        filled: true,
        fillColor: AppColors.backgroundBeige,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: const TextStyle(color: AppColors.hintColor),
        filled: true,
        fillColor: AppColors.backgroundBeige,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        suffixIcon: GestureDetector(
          onTap: toggle,
          child: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.accent.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

}

class DateInputFormatter extends TextInputFormatter {
  const DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (var index = 0; index < limitedDigits.length; index += 1) {
      buffer.write(limitedDigits[index]);
      if ((index == 1 || index == 3) && index != limitedDigits.length - 1) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
