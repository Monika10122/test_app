import 'package:hive/hive.dart';
import 'weather_api.dart';

class WeatherDetailsAdapter extends TypeAdapter<WeatherDetails> {
  @override
  final int typeId = 1;

  @override
  WeatherDetails read(BinaryReader reader) {
    return WeatherDetails(
      dayOfWeek: reader.read(),
      temperature: reader.read(),
      windSpeed: reader.read(),
      precipitation: reader.read(),
      notes: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, WeatherDetails obj) {
    writer.write(obj.dayOfWeek);
    writer.write(obj.temperature);
    writer.write(obj.windSpeed);
    writer.write(obj.precipitation);
    writer.write(obj.notes);
  }
}
