import 'dart:async';
import 'dart:math';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // clientId is provided in google-services.json
  scopes: <String>[CalendarApi.calendarScope],
);

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<bool?> initNotificationPlugin() async {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
          // onDidReceiveLocalNotification: (int resp){}
          );
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux);
  return flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (resp) {});
}

sendNotification(String title, {String body = '', String payload = ''}) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'calendarAlarms', 'Calendar alarms',
    channelDescription: 'Makes alarm sound on the important calendar events',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    // Make notification notisable with fullscreen intent and gentle long alarm sound
    ongoing: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
    fullScreenIntent: true,
  );
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
  await flutterLocalNotificationsPlugin
      .show(0, title, body, notificationDetails, payload: payload);
}

Future<void> checkAndSendEventAlarm() async {
  // TODO ensure that recurring events have different ids
  await _googleSignIn.signInSilently();
  List<Event> currentEvents = await getCurrentEvents();
  // TODO: for location-based events, alarm 1h before
  if (currentEvents.length != 0) {
    final prefs = await SharedPreferences.getInstance();
    List<String> alarmedEvents = prefs.getStringList('alarmedEvents') ?? [];
    print('alarmed events $alarmedEvents');

    for (Event currentEvent in currentEvents) {
      if (!alarmedEvents.contains(currentEvent.id)) {
        if (currentEvent.id == null) {
          throw ('Current event doesnt have id $currentEvent)');
        } else {
          alarmedEvents.add(currentEvent.id ?? 'noid');
          prefs.setStringList('alarmedEvents', alarmedEvents);
          await sendNotification('Event is starting now',
              body:
                  '"${currentEvent.summary}"\n${currentEvent.start?.dateTime.toString()}');
        }
      }
    }
  }
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print(
          "Native called background task: $task"); //simpleTask will be emitted here.
      await checkAndSendEventAlarm();
      registerNextCalendarCheckTask();
    } catch (error) {
      sendNotification('Error accessing calendar events',
          body: 'Calendar alarm is not working. Please sign in again.');
    }

    return Future.value(true);
  });
}

void registerNextCalendarCheckTask() {
  final randomId = Random().nextInt(1 << 32).toString();
  final taskId = "check-starting-events-$randomId";
  // TODO only for debug, 5 sec refresh will drain the battery, use firebase / 15min interval starting at :00
  Workmanager().registerOneOffTask(taskId, taskId,
      initialDelay: const Duration(seconds: 2));
}

void main() async {
  runApp(const MyApp());
  Workmanager().initialize(
    callbackDispatcher, // The top level function, aka callbackDispatcher
    // isInDebugMode:
    // true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );
  Workmanager().cancelAll();
  registerNextCalendarCheckTask();
  await initNotificationPlugin();
}

Future<List<Event>> getCurrentEvents() async {
  // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
  final auth.AuthClient? client = await _googleSignIn.authenticatedClient();
  assert(client != null, 'Authenticated client missing!');
  // Prepare a People Service authenticated client.
  final CalendarApi calendarApi = CalendarApi(client!);
  // Retrieve a list of events happening now
  final Events events = await calendarApi.events.list('primary',
  singleEvents: true,
      timeMin: DateTime.now(), timeMax: DateTime.now().add(const Duration(minutes: 1)), orderBy: 'updated');
  print('current events ${events.items?.map((e) => e.summary)}');
  return events.items ?? [];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          // primarySwatch: Colors.amber,
          ),
      home: const LoginPage(title: 'Flutter Max Demo Home Page'),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
