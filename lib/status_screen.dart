import 'dart:async';

import 'google_signin.dart';

import 'package:calendar_alarm/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, required this.user});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final GoogleSignInAccount user;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  Future<void> _handleSignOut() async {
     await googleSignIn.signOut();
     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
          return LoginScreen();
        }));
  }

  Widget _buildBody() {
    final GoogleSignInAccount user = widget.user;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        const SizedBox(height: 20),
        Column(children: <Widget>[
        const Text('All set!', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 20),
        // TODO display current event, so that when clicking on notification user will see something
        const Text('You can close the app.\nListening to the calendar of:', style: TextStyle(fontSize: 20)),
         ListTile(
          leading: GoogleUserCircleAvatar(
            identity: user,
          ),
          title: Text(user.displayName ?? ''),
          subtitle: Text(user.email),
        ),
        ]),
        ElevatedButton(
          onPressed: _handleSignOut,
          child: const Text('SIGN OUT'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Calendar Alarm'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
