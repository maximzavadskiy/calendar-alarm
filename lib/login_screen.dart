import 'dart:async';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // clientId is provided in google-services.json
  scopes: <String>[CalendarApi.calendarScope],
);


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GoogleSignInAccount? _currentUser;
  String _contactText = '';

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetEvent();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleGetEvent() async {
    setState(() {
      _contactText = 'Loading contact info...';
    });

    final String? firstEventName = ''; //(await getCurrentEvents()).first.summary;
    setState(() {
      if (firstEventName != null) {
        _contactText = 'Your last event is $firstEventName!';
      } else {
        _contactText = 'No events to display.';
      }
    });
  }

  Future<void> _handleSignIn() async {
    try {
      print('Signing in...'); // ignore: avoid_print

      await _googleSignIn.signIn();
      print('Signed in successfully'); // ignore: avoid_print
    } catch (error) {
      print('Error occured in _handleSignIn'); // ignore: avoid_print
      print(error); // ignore: avoid_print
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: user,
            ),
            title: Text(user.displayName ?? ''),
            subtitle: Text(user.email),
          ),
          const Text('Signed in successfully.'),
          Text(_contactText),
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('SIGN OUT'),
          ),
          ElevatedButton(
            onPressed: _handleGetEvent,
            child: const Text('REFRESH'),
          ),
        ],
      );
    } else {
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
                    padding: MaterialStatePropertyAll<EdgeInsets>(
                        EdgeInsets.all(20)),
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
                )
              ])));
    }
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
