import 'dart:async';

import 'status_screen.dart';
import 'google_signin.dart';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
          return StatusScreen(user: account);
        }));
      }
    });
    googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      print('Signing in...'); // ignore: avoid_print
      GoogleSignInAccount? user = await googleSignIn.signIn();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
          return StatusScreen(user: user!);
        }));
      print('Signed in successfully'); // ignore: avoid_print
    } catch (error) {
      print('Error occured in _handleSignIn'); // ignore: avoid_print
      print(error); // ignore: avoid_print
      setState(() {
        _errorText = 'Error signing in';
      });
    }
  }

  Widget _buildBody() {
    return SafeArea(
        child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              Row(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Image.asset(
                        'assets/firebase_logo.png',
                        height: 160,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Calendar Alarm',
                      style: TextStyle(
                        // color: CustomColors.firebaseYellow,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: const ButtonStyle(
                  padding:
                      MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.all(20)),
                ),
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 30,
                ),
                onPressed: _handleSignIn,
                label: const Text('SIGN IN',
                    style: const TextStyle(
                      fontSize: 20,
                    )),
              ),
              Text(_errorText, style: const TextStyle(color: Color.fromRGBO(255, 0, 0, 1)))
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
