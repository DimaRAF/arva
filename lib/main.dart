
import 'package:flutter/material.dart';
import 'screens/splashscreen.dart';


// The main entry point of the application.
void main() {
  runApp(const MyApp());
}

// The root widget of your application.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Start the app with the SplashScreen.
      home: SplashScreen(),
    );
  }
}
