import 'package:decormate_android/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../launch/welcome_screen.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // --- FIREBASE SIGN UP LOGIC ---
  Future<void> _signUp() async {
    // 1. Close Keyboard (Important for navigation stability)
    FocusScope.of(context).unfocus();

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Create User
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 3. Save User Details to Cloud Firestore
      if (userCredential.user != null) {
        // Update display name in Auth
        await userCredential.user!.updateDisplayName(fullNameController.text.trim());

        // Save detailed info to Database
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'mobile': mobileController.text.trim(),
          'dob': dobController.text.trim(),
          'created_at': DateTime.now(),
        });
      }

      // 4. Stop Loading BEFORE Navigating
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // 5. Navigate to Home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      // CATCH ALL ERRORS (Not just Auth Exceptions)
      // This catches Firestore errors, network errors, etc.
      if (mounted) {
        setState(() => _isLoading = false);

        String message = "An error occurred: $e";

        // Make the error message user-friendly if it's a known Auth error
        if (e is FirebaseAuthException) {
          if (e.code == 'weak-password') message = "The password provided is too weak.";
          else if (e.code == 'email-already-in-use') message = "The account already exists for that email.";
          else message = e.message ?? "Authentication failed";
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  // --- GOOGLE SIGN UP LOGIC ---
  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 1. Sign In
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      // 2. Save/Update Google User in Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? "No Name",
          'email': user.email,
          'last_login': DateTime.now(),
        }, SetOptions(merge: true));
      }

      // 3. Navigate
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-In Failed: $e")));
      }
    }
  }

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      padding: const EdgeInsets.only(left: 0),
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
                    const Center(
                      child: Text(
                        "Create Account",
                        style: TextStyle(
                          color: Color(0xFFF4B5A4),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Poppins",
                        ),
                      ),
                    )
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
                    _buildField(fullNameController, "John Doe"),
                    const SizedBox(height: 16),

                    _buildLabel("Email"),
                    _buildField(emailController, "example@example.com", type: TextInputType.emailAddress),
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

                    // Terms text...
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: "League Spartan",
                            fontSize: 14,
                            color: Color(0xFF4B4544),
                          ),
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
                            color: const Color(0xFFF4B5A4),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                              : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        "or sign up with",
                        style: TextStyle(
                          fontFamily: "League Spartan",
                          fontWeight: FontWeight.w300,
                          fontSize: 13,
                          color: Color(0xFF363130),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton("assets/images/google.png", _signUpWithGoogle),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // LOGIN LINK
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if(Navigator.canPop(context)){
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(
                              fontFamily: "League Spartan",
                              fontWeight: FontWeight.w300,
                              fontSize: 13,
                              color: Color(0xFF363130),
                            ),
                            children: [
                              TextSpan(
                                text: "Log in",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFCC7861),
                                ),
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: "Poppins",
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF363130),
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
              color: const Color(0xFFCC7861).withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
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