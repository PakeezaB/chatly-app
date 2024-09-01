import 'package:chatly_app/screens/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: 'AIzaSyDRPqYcQ0Ahy-1DykNu-C1mwBz2b3oAd4s',
    appId: '1:130185560048:web:0db8fd1198d6ab4746e735',
    messagingSenderId: '130185560048',
    projectId: 'chatly-app-e00bb',
    authDomain: 'chatly-app-e00bb.firebaseapp.com',
    storageBucket: 'chatly-app-e00bb.appspot.com',
    measurementId: 'G-YZCQ65BZPD',
  ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: SignUpScreen());
  }
}
