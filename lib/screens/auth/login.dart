import 'package:decormate_android/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import '../launch/welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // NOTE: removed horizontal padding from the scroll view so the arrow can be flush-left
      body: SafeArea(
        child: SingleChildScrollView(
          // keep top padding but no horizontal padding here
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // <-- ARROW: outside the horizontal padding so it can be extreme left -->
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  padding: EdgeInsets.only(left:20),
                  constraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  onPressed: () {
                    // Go back to previous screen (preferred) or replace:
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      // fallback to replacement if there's no back stack
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF4B4544),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // <-- MAIN CONTENT: wrapped with horizontal padding so design stays identical -->
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Title "Log In"
                    Center(
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: const Color(0xFFF4B5A4),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Poppins",
                        color: const Color(0xFF363130),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Please enter your details to proceed.",
                      style: TextStyle(
                        fontFamily: "League Spartan",
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF363130),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // EMAIL label
                    Text(
                      "Email",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: const Color(0xFF363130),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // EMAIL FIELD (WRITABLE)
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
                          hintStyle: TextStyle(
                            color: Color(0xFFDCBEB6),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // PASSWORD LABEL
                    Text(
                      "Password",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: const Color(0xFF363130),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // PASSWORD INPUT (WRITABLE)
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
                                hintStyle: TextStyle(
                                  color: Color(0xFFDCBEB6),
                                ),
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
                              color: const Color(0xFFCC7861).withValues(alpha:0.45),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // LOGIN BUTTON
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
                          child: Text(
                            "Log In",
                            style: TextStyle(
                              color: const Color(0xFFCC7861),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontFamily: "League Spartan",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF363130),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // OR sign up with
                    Center(
                      child: Text(
                        "or log in with",
                        style: TextStyle(
                          fontFamily: "League Spartan",
                          fontWeight: FontWeight.w300,
                          fontSize: 13,
                          color: const Color(0xFF363130),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ONLY GOOGLE BUTTON (BIGGER + CLICKABLE)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          debugPrint("Google clicked");
                        },
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

                    // Bottom signup text
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Don’t have an account? ",
                          style: TextStyle(
                            fontFamily: "League Spartan",
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                            color: const Color(0xFF363130),
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFCC7861),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ), // end Padding
            ],
          ),
        ),
      ),
    );
  }
}
