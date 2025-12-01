import 'package:decormate_android/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import '../launch/welcome_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -----------------------------------------
              // BACK ARROW + TITLE (same row)
              // -----------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.only(left:0),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4544)),
                    ),
                    const SizedBox(width: 50),
                    Center(child:Text(
                      "Create Account",
                      style: TextStyle(
                        color: const Color(0xFFF4B5A4),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Poppins",
                      ),
                    ),)

                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -----------------------------------------
              // MAIN CONTENT
              // -----------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildLabel("Full Name"),
                    _buildField(fullNameController, "Example@example.com"),
                    const SizedBox(height: 16),

                    _buildLabel("Email"),
                    _buildField(emailController, "Example@example.com"),
                    const SizedBox(height: 16),

                    _buildLabel("Mobile Number"),
                    _buildField(mobileController, "+ 123 456 789", type: TextInputType.phone),
                    const SizedBox(height: 16),

                    _buildLabel("Date Of Birth"),
                    _buildField(dobController, "DD / MM / YYYY", type: TextInputType.datetime),
                    const SizedBox(height: 16),

                    _buildLabel("Password"),
                    _buildPasswordField(passwordController, _obscurePass, () {
                      setState(() => _obscurePass = !_obscurePass);
                    }),
                    const SizedBox(height: 16),

                    _buildLabel("Confirm Password"),
                    _buildPasswordField(confirmPasswordController, _obscureConfirm, () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    }),

                    const SizedBox(height: 20),

                    // -----------------------------------------
                    // TERMS TEXT (bolded as requested)
                    // -----------------------------------------
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: "League Spartan",
                            fontSize: 14,
                            color: const Color(0xFF4B4544),
                          ),
                          children: [
                            const TextSpan(text: "By continuing, you agree to\n"),
                            const TextSpan(text: "Terms of Use", style: TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: " and "),
                            const TextSpan(text: "Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // -----------------------------------------
                    // SIGN UP BUTTON (fixed text color)
                    // -----------------------------------------
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        },
                        child: Container(
                          width: 220,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4B5A4),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,     // ✅ FIXED TEXT COLOR
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        "or sign up with",
                        style: TextStyle(
                          fontFamily: "League Spartan",
                          fontWeight: FontWeight.w300,
                          fontSize: 13,
                          color: const Color(0xFF363130),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton("assets/images/google.png"),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                            fontFamily: "League Spartan",
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                            color: const Color(0xFF363130),
                          ),
                          children: [
                            TextSpan(
                              text: "Log in",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFCC7861),
                              ),
                            ),
                          ],
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
    );
  }

  // ----------------------------------------------------------------
  // REUSABLE COMPONENTS
  // ----------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: "Poppins",
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF363130),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {TextInputType type = TextInputType.text}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0E6),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontFamily: "Poppins", fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFDCBEB6)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, bool obscure, VoidCallback toggle) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0E6),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(fontFamily: "Poppins", fontSize: 16),
              decoration: const InputDecoration(
                hintText: "Password",
                hintStyle: TextStyle(color: Color(0xFFDCBEB6)),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: toggle,
            child: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFCC7861).withValues(alpha:0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(String asset) {
    return GestureDetector(
      onTap: () => debugPrint("$asset pressed"),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4B4544), width: 1.3),
        ),
        alignment: Alignment.center,
        child: Image.asset(asset, width: 26),
      ),
    );
  }
}
