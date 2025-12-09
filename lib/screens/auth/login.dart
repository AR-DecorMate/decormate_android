import 'package:decormate_android/screens/home/home_screen.dart';
import 'package:decormate_android/screens/auth/signup.dart'; // Make sure this path is correct
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../launch/welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _isLoading = false; // To show spinner

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // --- FIREBASE LOGIN LOGIC ---
  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Invalid Credentials";
      if (e.code == 'user-not-found') message = "No user found for that email.";
      else if (e.code == 'wrong-password') message = "Wrong password provided.";
      else if (e.code == 'invalid-email') message = "Invalid email format.";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- GOOGLE SIGN IN LOGIC ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false); // User canceled
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In Failed: $e")),
        );
      }
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
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  padding: const EdgeInsets.only(left: 20),
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
              ),

              const SizedBox(height: 5),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: Color(0xFFF4B5A4),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Poppins",
                        color: Color(0xFF363130),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please enter your details to proceed.",
                      style: TextStyle(
                        fontFamily: "League Spartan",
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF363130),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // EMAIL
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF363130),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF0E6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: "example@example.com",
                          hintStyle: TextStyle(color: Color(0xFFDCBEB6)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // PASSWORD
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF363130),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
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
                              controller: passwordController,
                              obscureText: _obscure,
                              style: const TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: "Password",
                                hintStyle: TextStyle(color: Color(0xFFDCBEB6)),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscure = !_obscure;
                              });
                            },
                            child: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFFCC7861).withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // LOGIN BUTTON
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _login, // Disable if loading
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
                            child: CircularProgressIndicator(color: Color(0xFFCC7861), strokeWidth: 2),
                          )
                              : const Text(
                            "Log In",
                            style: TextStyle(
                              color: Color(0xFFCC7861),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontFamily: "League Spartan",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF363130),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    const Center(
                      child: Text(
                        "or log in with",
                        style: TextStyle(
                          fontFamily: "League Spartan",
                          fontWeight: FontWeight.w300,
                          fontSize: 13,
                          color: Color(0xFF363130),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // GOOGLE BUTTON
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _signInWithGoogle,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4B4544),
                              width: 1.3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            "assets/images/google.png",
                            height: 28,
                            width: 28,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // SIGN UP LINK
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to SignUp Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "Don’t have an account? ",
                            style: TextStyle(
                              fontFamily: "League Spartan",
                              fontWeight: FontWeight.w300,
                              fontSize: 13,
                              color: Color(0xFF363130),
                            ),
                            children: [
                              TextSpan(
                                text: "Sign Up",
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

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}