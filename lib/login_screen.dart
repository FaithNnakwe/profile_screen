import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true; // Toggle between Login & Signup

  String emailError = '';
  String passwordError = '';


Future<void> _authenticate() async {
  String email = emailController.text.trim();
  String password = passwordController.text.trim();

  // Email validation: only allow common domains
  final emailRegex = RegExp(r'^[\w-\.]+@(gmail|outlook|yahoo|hotmail)\.(com|net|org)$');
  
  // Password validation: must contain at least 1 uppercase, 1 number, and be at least 8 chars
  final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');

  setState(() {
    emailError = '';
    passwordError = '';
  });

  bool hasError = false;

  if (email.isEmpty) {
    setState(() => emailError = 'Email is required');
    hasError = true;
  } else if (!emailRegex.hasMatch(email)) {
    setState(() => emailError = 'Please use a valid Gmail, Outlook, or Yahoo email');
    hasError = true;
  }

  if (password.isEmpty) {
    setState(() => passwordError = 'Password is required');
    hasError = true;
  } else if (!passwordRegex.hasMatch(password)) {
    setState(() => passwordError = 'Password must contain at least one uppercase letter, one number, and be at least 8 characters');
    hasError = true;
  }

  if (hasError) return;

  try {
    UserCredential userCredential;
    if (isLogin) {
      // Log in user
      userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    } else {
      // Register new user first, then log in the user
      userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // After sign-up, you may want to send a verification email (optional)
      await userCredential.user?.sendEmailVerification();
      
      // Then log the user in immediately after successful registration
      userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    }

    if (userCredential.user != null) {
      // Navigate to ProfileScreen after successful login or sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
  } catch (e) {
    // Display Firebase error messages
    String message = "Something went wrong.";
    if (e is FirebaseAuthException) {
      if (e.code == 'user-not-found') {
        message = "No user found for that email. Please register";
      // ignore: curly_braces_in_flow_control_structures
      } else if (e.code == 'wrong-password') message = "Wrong password.";
      // ignore: curly_braces_in_flow_control_structures
      else if (e.code == 'email-already-in-use') message = "Email is already registered.";
      // ignore: curly_braces_in_flow_control_structures
      else message = e.message ?? message;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD0E1F9),
      appBar: AppBar(title: Text(isLogin ? "Login" : "Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email", 
               errorText: emailError.isNotEmpty ? emailError : null,),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password", 
              errorText: passwordError.isNotEmpty ? passwordError : null,),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: Text(isLogin ? "Login" : "Sign Up"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Create an account" : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
