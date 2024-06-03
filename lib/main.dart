import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:ssg_application_1/OnBoarding/onBoardingpage.dart';
import 'package:ssg_application_1/chatScreen/chat_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SSG Technologies',
      routes: {
        '/': (context) => OnBoarding(),
        '/chat': (context) => ChatScreen(
              connection: ModalRoute.of(context)!.settings.arguments
                  as BluetoothConnection,
            ),
      },
    );
  }
}
