import 'package:Medwise/modules/auth_module/home.dart';
import 'package:Medwise/modules/auth_module/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", name = "";
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Force account chooser
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
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    }
  }

  Future<void> registration() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registered Successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      final errorMessage = e.code == 'weak-password'
          ? "Password Provided is too Weak"
          : e.code == 'email-already-in-use'
          ? "Account Already exists"
          : e.message ?? "An error occurred";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(errorMessage)),
      );
    }
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction inputAction = TextInputAction.next,
    String? autofillHint,
  }) {
    return StatefulBuilder(
      builder: (context, setFieldState) {
        return TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          textInputAction: inputAction,
          autofillHints: autofillHint != null ? [autofillHint] : null,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFFb2b7bf)),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFFb2b7bf),
              ),
              onPressed: () => setFieldState(() => _obscurePassword = !_obscurePassword),
            )
                : null,
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(color: Color(0xFFb2b7bf)),
            hintStyle: TextStyle(color: Color(0xFFb2b7bf)),
            filled: true,
            fillColor: Color(0xFFedf0f8),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Color(0xFF273671), width: 1),
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
              height: 220, // Same height as login screen
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
                      controller: nameController,
                      label: "Name",
                      hint: "Enter your name",
                      icon: Icons.person,
                      autofillHint: AutofillHints.name,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Name is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
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
                      hint: "Create a password",
                      icon: Icons.lock,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      autofillHint: AutofillHints.newPassword,
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
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            email = emailController.text.trim();
                            name = nameController.text.trim();
                            password = passwordController.text.trim();
                          });
                          registration();
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(vertical: 13.0),
                        decoration: BoxDecoration(
                          color: Color(0xFF273671),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40.0),
            const Text("or LogIn with",
                style: TextStyle(color: Color(0xFF273671), fontSize: 22.0, fontWeight: FontWeight.w500)),
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
                const Text("Already have an account?",
                    style: TextStyle(color: Color(0xFF8c8e98), fontSize: 18.0, fontWeight: FontWeight.w500)),
                const SizedBox(width: 5.0),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn())),
                  child: const Text("LogIn",
                      style: TextStyle(color: Color(0xFF273671), fontSize: 20.0, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
