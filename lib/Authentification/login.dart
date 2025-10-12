import 'package:auto_alert/Authentification/fadeAnimation.dart';
import 'package:auto_alert/Authentification/forgot_password.dart';
import 'package:auto_alert/Authentification/otp_validation.dart';
import 'package:auto_alert/Authentification/sign_up.dart';
import 'package:auto_alert/Pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isPasswordVisible = false;
  bool isLoading = false;
  bool isGoogleLoading = false;
  int loginType = 0;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

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

  void checkInputType(String text) {
    setState(() {
      if (text.isEmpty) {
        loginType == 0;
      } else if (RegExp(r'^\+?[0-9]{7,15}$').hasMatch(text)) {
        loginType = 1;
        print('$text is a phone number');
      } else if (RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(text)) {
        loginType = 2;
        print('$text is an email address');
      }
    });
  }

  void signUserIn() async {
    if (usernameController.text.isEmpty) {

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));

      return;
    }

    if (!isValidEmailOrPhone(usernameController.text.trim())) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address or phone number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (loginType == 1) {
      signUpWithPhone();
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      await resetAppData();

      Navigator.pop(context);

      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        await FirebaseAuth.instance.currentUser?.sendEmailVerification();

        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please verify your email before logging in.'),
            backgroundColor: Colors.orange[600],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      String errorMessage;
      print('Firebase Error Code: ${e.code}');
      print('Firebase Error Message: ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to sign in. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
      String phoneNumber = usernameController.text.trim();

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
        codeAutoRetrievalTimeout: (String verificationId) {},
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

  Future<void> resetAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;
      final currentUserEmail = currentUser?.email;
      final lastUserId = prefs.getString('last_user_id');
      final lastUserEmail = prefs.getString('last_user_email');

      print('Current User Email: $currentUserEmail');
      print('Current User ID: $currentUserId');

      print('Last User Email: $lastUserEmail');
      print('Last User ID: $lastUserId');

      bool isDifferentUser =
          (currentUserId != lastUserId) || (currentUserEmail != lastUserEmail);

      if (isDifferentUser && currentUserId != null) {
        print('Resetting app data for new user...');

        final keysToKeep = [
          'firebase_auth_token',
          'last_user_id',
          'app_settings',
          'last_user_email',
        ];

        final allKeys = prefs.getKeys();
        print('All Keys: $allKeys');

        for (String key in allKeys) {
          if (!keysToKeep.contains(key)) {
            await prefs.remove(key);
            print('Removed key: $key');
          }
        }

        await prefs.setString('last_user_id', currentUserId);

        if (currentUserEmail != null) {
          await prefs.setString('last_user_email', currentUserEmail);
        }
      }
    } catch (e) {
      print('Error resetting app data: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        isGoogleLoading = true;
      });

      GoogleSignIn googleSignIn = GoogleSignIn.instance;

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      await resetAppData();

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
      backgroundColor: Color(0xAA1A1B1E),
      body: Container(
        padding: EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FadeAnimation(
              1.2,
              Text(
                "Let's sign you in.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 30),
            FadeAnimation(
              1.5,
              Container(
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xAA1A1B1E),
                  border: Border.all(color: Color(0xFF373A3F)),
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF373A3F)),
                        ),
                      ),
                      child: TextField(
                        controller: usernameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Color(0xFF5C5F65)),
                          hintText: "Email or Phone number",
                          prefixIcon: Icon(
                            loginType == 0
                                ? Icons.person
                                : (loginType == 1
                                      ? Icons.phone
                                      : Icons.email_outlined),
                            color: Colors.grey,
                          ),
                        ),
                        onChanged: checkInputType,
                      ),
                    ),
                    if (loginType == 2)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(),
                        child: TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Color(0xFF5C5F65)),
                            suffixIcon: InkWell(
                              onTap: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                              child: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                            ),
                            hintText: "Password",
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (loginType == 1)
              FadeAnimation(
                0.5,
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "A verification code will be sent to your phone number.",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (loginType == 2)
              FadeAnimation(
                1.4,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),
            FadeAnimation(
              1.6,
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Color(0xFF5C5F65)),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Sign up",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      signInWithGoogle();
                    },
                    child: Container(
                      height: 50.0,
                      width: 70.0,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        image: DecorationImage(
                          image: AssetImage('assets/icon_google.png'),
                          fit: BoxFit.cover,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            FadeAnimation(
              1.8,
              Center(
                child: MaterialButton(
                  onPressed: () {
                    signUserIn();
                  },
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
                            loginType == 1 ? "Send Code" : "Login",
                            style: TextStyle(
                              color: Colors.white.withOpacity(.7),
                              fontSize: 16,
                            ),
                          ),
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
