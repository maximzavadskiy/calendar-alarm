import 'dart:async';
import 'dart:math';

import 'google_signin.dart';
import 'notifications_api.dart';

import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';


initializeCalendarCheckWorker() {
  Workmanager().initialize(
    _callbackDispatcher, // The top level function, aka callbackDispatcher
    // isInDebugMode:
    // true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );
  Workmanager().cancelAll();
  NotificationsAPI().initialize();
  _registerNextCalendarCheckTask();
}


void _registerNextCalendarCheckTask() {
  print('in registerNextCalendarCheckTask');

  final randomId = Random().nextInt(1 << 32).toString();
  final taskId = "check-starting-events-$randomId";
  // TODO only for debug, 5 sec refresh will drain the battery, use firebase / 15min interval starting at :00
  Workmanager().registerOneOffTask(taskId, taskId,
      initialDelay: const Duration(seconds: 15));
  print('dod registerOneOffTask');

}

Future<void> _checkAndSendEventAlarm() async {
  // TODO ensure that recurring events have different ids
  await googleSignIn.signInSilently();
  List<Event> currentEvents = await _getCurrentEvents();
  // TODO: for location-based events, alarm 1h before
  if (currentEvents.length != 0) {
    final prefs = await SharedPreferences.getInstance();
    List<String> alarmedEvents = prefs.getStringList('alarmedEvents') ?? [];
    print('alarmed events $alarmedEvents');

    for (Event currentEvent in currentEvents) {
      // TODO: this won't work when moving event to a new time after the alarm. Mark events as alarmed by starttime timestamp
      if (!alarmedEvents.contains(currentEvent.id)) {
        if (currentEvent.id == null) {
          throw ('Current event doesnt have id $currentEvent)');
        } else {
          alarmedEvents.add(currentEvent.id ?? 'noid');
          prefs.setStringList('alarmedEvents', alarmedEvents);
          // TODO: add direct link to Google Calendar  / show event info in the app
          await NotificationsAPI().sendNotification('Event is starting now',
              body:
                  '"${currentEvent.summary}"');
        }
      }
    }
  }
}

Future<List<Event>> _getCurrentEvents() async {
  // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
  final auth.AuthClient? client = await googleSignIn.authenticatedClient();
  assert(client != null, 'Authenticated client missing!');
  // Prepare a People Service authenticated client.
  final CalendarApi calendarApi = CalendarApi(client!);
  // Retrieve a list of events happening now
  final Events events = await calendarApi.events.list('primary',
      singleEvents: true,
      timeMin: DateTime.now(),
      timeMax: DateTime.now().add(const Duration(minutes: 1)),
      orderBy: 'updated');
  print('current events ${events.items?.map((e) => e.summary)}');
  return events.items ?? [];
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
  void _callbackDispatcher() {
  print('in callbackdispatcher');
  Workmanager().executeTask((task, inputData) async {
      print(
          "Native called background task: $task"); //simpleTask will be emitted here.
      try {
      await _checkAndSendEventAlarm();
    } catch (error) {
      // TODO: calendar check requires an app restart after relogin
      print('ERROR in worker: $error');
      NotificationsAPI().sendNotification('Error accessing calendar events',
          body: 'Calendar alarm is not working. Please sign in again.');
    } finally {
      // Even if e.g. auth fails we will retry
      _registerNextCalendarCheckTask();
     }

    return Future.value(true);
  });
}
