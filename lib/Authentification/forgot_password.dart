import 'package:auto_alert/Authentification/fadeAnimation.dart';
import 'package:auto_alert/Authentification/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final emailController = TextEditingController();
  bool isLoading = false;
  bool emailSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
  
  void resetPassword() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // setState(() {
    //   isLoading = true;
    // });

    try {

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      
      setState(() {
        emailSent = true;
        isLoading = false;
      });
      print("Password reset email sent to ${emailController.text.trim()}");
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange[600],
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xAA1A1B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FadeAnimation(
              1.2,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emailSent ? "Check your email" : "Reset your password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    emailSent 
                        ? "We've sent a password reset link to ${emailController.text.trim()}"
                        : "Enter your email address and we'll send you a link to reset your password.",
                    style: TextStyle(
                      color: Color(0xFF5C5F65),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            if (!emailSent) ...[
              FadeAnimation(
                1.4,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xAA1A1B1E),
                    border: Border.all(color: Color(0xFF373A3F)),
                  ),
                  child: TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFF5C5F65)),
                      hintText: "Email address",
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color(0xFF5C5F65),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),

              FadeAnimation(
                1.6,
                Center(
                  child: MaterialButton(
                    onPressed: isLoading ? null : resetPassword,
                    color: Color(0xAA3A5BDA),
                    padding: EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Send Reset Email",
                              style: TextStyle(
                                color: Colors.white.withOpacity(.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              FadeAnimation(
                1.4,
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xFF2D5016),
                    border: Border.all(color: Color(0xFF4CAF50)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Reset email sent successfully!",
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              FadeAnimation(
                1.6,
                Text(
                  "Didn't receive the email? Check your spam folder or try again.",
                  style: TextStyle(
                    color: Color(0xFF5C5F65),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 20),

              FadeAnimation(
                1.8,
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        emailSent = false;
                      });
                    },
                    child: Text(
                      "Send again",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 40),

            FadeAnimation(
              2.0,
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.blue,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Back to Login",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 