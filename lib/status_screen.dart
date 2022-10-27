import 'dart:async';
import 'package:calendar_alarm/login_screen.dart';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // clientId is provided in google-services.json
  scopes: <String>[CalendarApi.calendarScope],
);

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
  String _contactText = '';

  Future<void> _handleGetEvent() async {
    setState(() {
      _contactText = 'Loading contact info...';
    });

    final String? firstEventName =
        ''; //(await getCurrentEvents()).first.summary;
    setState(() {
      if (firstEventName != null) {
        _contactText = 'Your last event is $firstEventName!';
      } else {
        _contactText = 'No events to display.';
      }
    });
  }

  Future<void> _handleSignOut() async {
     await _googleSignIn.signOut();
     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
          return LoginScreen();
        }));
  }

  Widget _buildBody() {
    final GoogleSignInAccount user = widget.user;
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
