import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:laboratorio_aberto_do_saber_professor/pages/home_page_autenticado.dart';
import 'package:laboratorio_aberto_do_saber_professor/pages/home_page_nao_autenticado.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue[700],
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
          ),
          centerTitle: true
        ),
      ),
      home: HomePageNaoLogado(),
    );
  }
}
