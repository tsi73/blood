import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mcp_project/firebase_options.dart';
import 'package:mcp_project/screens/splash_screen.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(BloodApp());
}

class BloodApp extends StatelessWidget {
  const BloodApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Yilegesu',
    theme: ThemeData(
      primarySwatch: Colors.red,
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.pink),
    ),
    home: SplashScreen(),
  );
}
}

