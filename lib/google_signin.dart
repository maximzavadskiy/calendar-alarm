import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';

final GoogleSignIn googleSignIn = GoogleSignIn(
  // clientId is provided in google-services.json
  scopes: <String>[CalendarApi.calendarScope],
);
