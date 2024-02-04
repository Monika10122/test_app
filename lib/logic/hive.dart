import 'package:hive/hive.dart';

class HiveBoxes {
  static Future<void> init() async {
    await Hive.openBox('savedCities');
  }

  static Box get savedCities => Hive.box('savedCities');
}
