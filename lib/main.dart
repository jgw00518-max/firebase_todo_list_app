import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_todo_list_app/controller/todo_controller.dart';
import 'package:firebase_todo_list_app/firebase_options.dart';
import 'package:firebase_todo_list_app/repository/todo_repository.dart';
import 'package:firebase_todo_list_app/view/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(TodoController(repository: TodoRepository()));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const Home(),
    );
  }
}
