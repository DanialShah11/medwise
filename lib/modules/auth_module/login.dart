import 'package:Medwise/modules/auth_module/signup.dart';
import 'package:flutter/material.dart';
import 'package:Medwise/modules/auth_module/forgot_password.dart';
import 'package:Medwise/modules/auth_module/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "", password = "";

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // force account selection
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    }
  }

  login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Login Successful", style: TextStyle(fontSize: 20.0)),
      ));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided.";
      } else {
        errorMessage = e.message ?? "An error occurred.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(errorMessage, style: TextStyle(fontSize: 18.0)),
      ));
    }
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction inputAction = TextInputAction.next,
    bool autoFocus = false,
    String? autofillHint,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          textInputAction: inputAction,
          autofocus: autoFocus,
          autofillHints: autofillHint != null ? [autofillHint] : null,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: Color(0xFFb2b7bf),
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFFb2b7bf),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
                : null,
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(color: Color(0xFFb2b7bf)),
            hintStyle: TextStyle(color: Color(0xFFb2b7bf)),
            filled: true,
            fillColor: Color(0xFFedf0f8),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),

            // ✅ Preserve rounded shape
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none, // no visible line
            ),

            // ✅ Show border on focus
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Color(0xFF273671),
                width: 1,
              ),
            ),

            errorStyle: TextStyle(fontSize: 14),
          ),

        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 230, // ⬅️ adjust height here
              child: Image.asset(
                "images/medwise.png",
                fit: BoxFit.cover,
              ),
            ),


            const SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildInputField(
                      controller: emailController,
                      label: "Email",
                      hint: "Enter your email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHint: AutofillHints.email,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email is required";
                        }
                        if (!value.contains('@')) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    buildInputField(
                      controller: passwordController,
                      label: "Password",
                      hint: "Enter your password",
                      icon: Icons.lock,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      autofillHint: AutofillHints.password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password is required";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30.0),
                    GestureDetector(
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            email = emailController.text.trim();
                            password = passwordController.text.trim();
                          });
                          login();
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 30.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF273671),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "Log In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPassword()),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color(0xFF273671),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40.0),
            const Text(
              "or LogIn with",
              style: TextStyle(
                color: Color(0xFF273671),
                fontSize: 22.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: signInWithGoogle,
                  child: Image.asset("images/google.png", height: 45, width: 45),
                ),
                const SizedBox(width: 30.0),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Apple Sign-In is only available on iOS devices.")),
                    );
                  },
                  child: Image.asset("images/apple1.png", height: 50, width: 50),
                ),
              ],
            ),
            const SizedBox(height: 40.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                      color: Color(0xFF8c8e98),
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 5.0),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUp()));
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Color(0xFF273671),
                      fontSize: 20.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
