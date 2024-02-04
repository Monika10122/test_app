import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'logic/hive.dart';
import 'logic/weather_details_adapter.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WeatherDetailsAdapter()); 
  await HiveBoxes.init();
  runApp(const MainApp());
}



class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: HomePage(),
        ),
      ),
    );
  }
}
