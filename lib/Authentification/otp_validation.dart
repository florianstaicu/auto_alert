import 'dart:async';

import 'package:auto_alert/Pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPVerification extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPVerification({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPVerification> createState() => _OTPVerificationState();
}

class _OTPVerificationState extends State<OTPVerification> {
  bool invalidOTP = false;
  bool isVerifying = false;

  int resendTime = 30;
  late Timer countdownTimer;

  TextEditingController fieldOne = TextEditingController();
  TextEditingController fieldTwo = TextEditingController();
  TextEditingController fieldThree = TextEditingController();
  TextEditingController fieldFour = TextEditingController();
  TextEditingController fieldFive = TextEditingController();
  TextEditingController fieldSix = TextEditingController();

  @override
  void initState() {
    startTimer();

    super.initState();
  }

  @override
  void dispose() {
    stopTimer();

    fieldOne.dispose();
    fieldTwo.dispose();
    fieldThree.dispose();
    fieldFour.dispose();

    super.dispose();
  }

  startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        resendTime = resendTime - 1;
      });
      if (resendTime < 1) {
        countdownTimer.cancel();
      }
    });
  }

  stopTimer() {
    if (countdownTimer.isActive) {
      countdownTimer.cancel();
    }
  }

  void verifyOTP() async {
    String OTP =
        fieldOne.text +
        fieldTwo.text +
        fieldThree.text +
        fieldFour.text +
        fieldFive.text +
        fieldSix.text;

    if (OTP.length != 6) {
      setState(() {
        invalidOTP = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid -digit OTP.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      isVerifying = true;
      invalidOTP = false;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: OTP,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        stopTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP Verified Successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isVerifying = false;
        invalidOTP = true;
      });

      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The OTP code is invalid. Please try again.';
          break;
        case 'session-expired':
          errorMessage =
              'The OTP session has expired. Please request a new code.';
          break;
        default:
          errorMessage = 'Failed to verify OTP. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      setState(() {
        isVerifying = false;
        invalidOTP = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void resendOTP() async {
    setState(() {
      invalidOTP = false;
      resendTime = 30;
    });
    startTimer();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend OTP: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New code resent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend code.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Verification',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Enter your OTP code number',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 50,
                        child: TextFormField(
                          controller: fieldOne,
                          onChanged: (value) {
                            if (value.length == 1) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                          style: Theme.of(context).textTheme.headlineMedium,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 50,
                        child: TextFormField(
                          controller: fieldTwo,
                          onChanged: (value) {
                            if (value.length == 1) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                          style: Theme.of(context).textTheme.headlineMedium,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 50,
                        child: TextFormField(
                          controller: fieldThree,
                          onChanged: (value) {
                            if (value.length == 1) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                          style: Theme.of(context).textTheme.headlineMedium,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 50,
                        child: TextFormField(
                          controller: fieldFour,
                          onChanged: (value) {
                            if (value.length == 1) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                          style: Theme.of(context).textTheme.headlineMedium,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 50,
                        child: TextFormField(
                          controller: fieldFive,
                          onChanged: (value) {
                            if (value.length == 1) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                          style: Theme.of(context).textTheme.headlineMedium,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 50,
                        child: TextFormField(
                          controller: fieldSix,
                          onChanged: (value) {
                            if (value.length == 1) {
                              FocusScope.of(context).unfocus();
                              verifyOTP();
                            }
                          },
                          style: Theme.of(context).textTheme.headlineMedium,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                invalidOTP
                    ? Text('Invalid OTP', style: TextStyle(color: Colors.red))
                    : SizedBox.shrink(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't receive the code?"),
                    TextButton(
                      onPressed: () {
                        invalidOTP = false;
                        resendTime = 30;
                        startTimer();
                      },
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                resendTime != 0
                    ? Text(
                        'Resend code in $resendTime s',
                        style: TextStyle(color: Colors.grey),
                      )
                    : SizedBox.shrink(),
                ElevatedButton(
                  onPressed: () {
                    isVerifying ? null : verifyOTP();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(
                      horizontal: 100,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isVerifying
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
