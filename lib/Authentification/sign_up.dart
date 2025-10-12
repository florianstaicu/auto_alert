import 'package:auto_alert/Authentification/fadeAnimation.dart';
import 'package:auto_alert/Authentification/login.dart';
import 'package:auto_alert/Authentification/otp_validation.dart';
import 'package:auto_alert/Pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isLoading = false;
  int which = 0; // 0 = neither, 1 = phone, 2 = email

  bool isPasswordVisible = false;

  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasLongEnough = false;

  String? verificationId;
  bool smsCodeSent = false;
  final TextEditingController smsController = TextEditingController();

  bool isGoogleLoading = false;
  GoogleSignInAccount? googleUser;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    smsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  bool isValidEmailOrPhone(String input) {
    if (RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(input)) {
      return true;
    }
    if (RegExp(r'^\+?[0-9]{10,15}$').hasMatch(input)) {
      return true;
    }
    return false;
  }

  bool isValidPassword(String password) {
    hasUppercase = password.contains(RegExp(r'[A-Z]'));
    hasLowercase = password.contains(RegExp(r'[a-z]'));
    hasNumber = password.contains(RegExp(r'[0-9]'));
    hasLongEnough = password.length >= 6;
    return hasUppercase && hasLowercase && hasNumber && hasLongEnough;
  }

  void showPasswordRequirements() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Password Requirements',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your password must contain:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 15),
                  buildRequirement(
                    'At least 6 characters',
                    hasLongEnough,
                    Icons.check_circle,
                    Icons.radio_button_unchecked,
                  ),
                  SizedBox(height: 8),
                  buildRequirement(
                    'One uppercase letter (A-Z)',
                    hasUppercase,
                    Icons.check_circle,
                    Icons.radio_button_unchecked,
                  ),
                  SizedBox(height: 8),
                  buildRequirement(
                    'One lowercase letter (a-z)',
                    hasLowercase,
                    Icons.check_circle,
                    Icons.radio_button_unchecked,
                  ),
                  SizedBox(height: 8),
                  buildRequirement(
                    'One number (0-9)',
                    hasNumber,
                    Icons.check_circle,
                    Icons.radio_button_unchecked,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildRequirement(
    String text,
    bool isMet,
    IconData checkedIcon,
    IconData uncheckedIcon,
  ) {
    return Row(
      children: [
        Icon(
          isMet ? checkedIcon : uncheckedIcon,
          color: isMet ? Colors.green : Colors.grey,
          size: 20,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey[700],
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void signUpUser() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter email address or phone number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isValidEmailOrPhone(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address or phone number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (which == 1) {
      signUpWithPhone();
      return;
    }

    if (which == 2) {
      if (passwordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all password fields.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!isValidPassword(passwordController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password must meet all requirements.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (which == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address or phone number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await userCredential.user?.updateDisplayName(emailController.text.trim());
      await userCredential.user?.sendEmailVerification();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User registered successfully! Please check your email for verification.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void checktext(String text) {
    setState(() {
      if (text.isEmpty) {
        which = 0;
      } else if (RegExp(r'^\+?[0-9]{10,15}$').hasMatch(text.trim())) {
        which = 1;
        print('$text is a phone number');
      } else if (RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(text.trim())) {
        which = 2;
        print('$text is Email');
      } else {
        which = 0;
      }
    });
  }

  void signUpWithPhone() async {
    setState(() {
      isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      String phoneNumber = emailController.text.trim();

      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '+40${phoneNumber.substring(1)}';
        } else {
          phoneNumber = '+40$phoneNumber';
        }
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phone number verified automatically!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to sign in: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          Navigator.pop(context);
          print('Verification failed: ${e.message}');

          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'The phone number format is invalid.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              errorMessage = 'Phone verification failed: ${e.message}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.pop(context);

          this.verificationId = verificationId;
          smsCodeSent = true;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerification(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void signInWithGoogle() async {
    try {
      setState(() {
        isGoogleLoading = true;
      });

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        setState(() {
          isGoogleLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() {
        isGoogleLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      setState(() {
        isGoogleLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 40),
        height: MediaQuery.of(context).size.height - 50,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              children: <Widget>[
                SizedBox(height: 60.0),
                Text(
                  "Sign up",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Create your account",
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 30),
            Column(
              children: <Widget>[
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Email or Phone Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    prefixIcon: Icon(
                      which == 0
                          ? Icons.person
                          : (which == 1 ? Icons.phone : Icons.email),
                    ),
                  ),
                  onChanged: (text) {
                    checktext(text);
                  },
                ),
                SizedBox(height: 20),

                // Show password fields only for email registration
                if (which == 2) ...[
                  FadeAnimation(
                    1.3,
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        hintText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        prefixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        suffixIcon: IconButton(
                          onPressed: showPasswordRequirements,
                          icon: Icon(Icons.info_outline),
                        ),
                      ),
                      obscureText: !isPasswordVisible,
                      onChanged: (password) {
                        isValidPassword(password);
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  FadeAnimation(
                    1.6,
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        prefixIcon: Icon(Icons.password),
                      ),
                      obscureText: true,
                    ),
                  ),
                ],

                // Show info text for phone registration
                if (which == 1) ...[
                  FadeAnimation(
                    0.5,
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You will receive an SMS with a verification code.',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.only(top: 3, left: 3),
              child: ElevatedButton(
                onPressed: () {
                  signUpUser();
                },
                style: ElevatedButton.styleFrom(
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        which == 1 ? "Send SMS Code" : "Sign up",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
              ),
            ),

            // Center(child: Text("Or")),

            // Container(
            //   height: 45,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(25),
            //     border: Border.all(color: Colors.black),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.white.withOpacity(0.5),
            //         spreadRadius: 1,
            //         blurRadius: 1,
            //         offset: Offset(0, 1),
            //       ),
            //     ],
            //   ),
            //   child: TextButton(
            //     onPressed: isGoogleLoading ? null : signInWithGoogle,
            //     child: isGoogleLoading
            //         ? SizedBox(
            //             width: 20,
            //             height: 20,
            //             child: CircularProgressIndicator(strokeWidth: 2),
            //           )
            //         : Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Text(
            //                 "Sign in with Google",
            //                 style: TextStyle(fontSize: 16, color: Colors.black),
            //               ),
            //             ],
            //           ),
            //   ),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Already have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text("Login", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
