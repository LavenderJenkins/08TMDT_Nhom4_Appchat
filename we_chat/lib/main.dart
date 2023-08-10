import 'package:flutter/material.dart';


import 'package:firebase_core/firebase_core.dart' ;
import 'package:flutter/services.dart';
import 'package:we_chat/screens/splash_screen.dart'; 
import 'firebase_options.dart' ; 



late Size mq;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
  .then((value) {
     _initializeFirebase();
  runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'We Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle( color: Colors.black, fontWeight: FontWeight.normal, fontSize: 19),
          backgroundColor: Colors.white,
        ) 
      ),
      home: const SplashScreen(),
    );
  }
}

_initializeFirebase() async {
  await Firebase . initializeApp (
    options : DefaultFirebaseOptions . currentPlatform ,
  );
}
  